import express from "express";
import path from "path";
import { createServer as createViteServer } from "vite";
import admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";
import fs from "node:fs";

// Load Firebase Config
const firebaseConfig = JSON.parse(fs.readFileSync(path.join(process.cwd(), 'firebase-applet-config.json'), 'utf-8'));

// Initialize Firebase Admin with project ID from config
if (admin.apps.length === 0) {
  admin.initializeApp({
    projectId: firebaseConfig.projectId
  });
  console.log(`[INIT] Firebase Admin initialized for project: ${firebaseConfig.projectId}`);
}

let db: admin.firestore.Firestore;
const dbId = (firebaseConfig.firestoreDatabaseId && firebaseConfig.firestoreDatabaseId !== "(default)")
  ? firebaseConfig.firestoreDatabaseId
  : undefined;

try {
  if (dbId) {
    db = getFirestore(admin.app(), dbId);
    console.log(`[INIT] Firestore initialized with database: ${dbId}`);
  } else {
    db = getFirestore(admin.app());
    console.log(`[INIT] Firestore initialized with (default) database`);
  }
} catch (e: any) {
  console.error("[INIT] Failed to initialize Firestore with database id, falling back to default:", e.message);
  db = getFirestore(admin.app());
}

// Push Notification Helpers
const sendPushNotification = async (userId: string, title: string, body: string, data?: any) => {
  try {
    // 1. Persist to Firestore notifications collection
    await db.collection('notifications').add({
      userId,
      message: body,
      title,
      type: data?.type || 'general',
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      data: data || {}
    });

    // 2. Fetch FCM tokens
    const tokensSnapshot = await db.collection('fcmTokens').where('userId', '==', userId).get();
    const tokens = tokensSnapshot.docs.map(doc => doc.data().token);
    
    if (tokens.length === 0) {
      console.log(`[FCM] No tokens found for user ${userId}`);
      return;
    }

    const message: any = {
      tokens,
      notification: {
        title,
        body,
      },
      data: data || {},
      webpush: {
        notification: {
          icon: '/pwa-192x192.png',
        }
      }
    };

    // Use default app for messaging too
    const response = await admin.messaging(admin.app()).sendEachForMulticast(message);
    console.log(`[FCM] Successfully sent ${response.successCount} messages to user ${userId}`);
    
    if (response.failureCount > 0) {
      const tokensToRemove: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success && resp.error) {
          const code = resp.error.code;
          if (code === 'messaging/invalid-registration-token' || 
              code === 'messaging/registration-token-not-registered') {
            tokensToRemove.push(tokens[idx]);
          }
        }
      });
      
      if (tokensToRemove.length > 0) {
        console.log(`[FCM] Cleaning up ${tokensToRemove.length} stale tokens for user ${userId}`);
        const batch = db.batch();
        const staleTokens = await db.collection('fcmTokens')
          .where('userId', '==', userId)
          .where('token', 'in', tokensToRemove.slice(0, 10)) 
          .get();
        staleTokens.docs.forEach(doc => batch.delete(doc.ref));
        await batch.commit();
      }
    }
  } catch (error) {
    console.error('[FCM] Error sending push notification:', error);
  }
};

const notifyAdmins = async (title: string, body: string, data?: any) => {
  try {
    const adminSnapshot = await db.collection('users').where('role', '==', 'admin').get();
    const adminIds = adminSnapshot.docs.map(doc => doc.id);
    for (const adminId of adminIds) {
      await sendPushNotification(adminId, title, body, data);
    }
  } catch (error) {
    console.error('[FCM] Error notifying admins:', error);
  }
};

async function startServer() {
  const app = express();
  const PORT = 3000;

  // Middleware for parsing JSON
  app.use(express.json());

  // Auth Middleware
  const authenticate = async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      console.log(`[AUTH] No token for ${req.method} ${req.url}`);
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const idToken = authHeader.split('Bearer ')[1];
    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      (req as any).user = decodedToken;
      next();
    } catch (error: any) {
      console.error(`[AUTH] Token verify failed for ${req.method} ${req.url}:`, error.message);
      res.status(401).json({ error: 'Unauthorized' });
    }
  };

  const requireAdmin = async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    try {
      const uid = (req as any).user.uid;
      const userDoc = await db.collection('users').doc(uid).get();
      if (!userDoc.exists || userDoc.data()?.role !== 'admin') {
        return res.status(403).json({ error: 'Forbidden: Admin access required' });
      }
      next();
    } catch (error) {
      res.status(500).json({ error: 'Internal Server Error' });
    }
  };

  const checkOwnership = (collection: string) => async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    try {
      const { id } = req.params;
      const uid = (req as any).user.uid;
      const userDoc = await db.collection('users').doc(uid).get();
      if (userDoc.data()?.role === 'admin') return next();
      const doc = await db.collection(collection).doc(id).get();
      if (!doc.exists) return res.status(404).json({ error: 'Not found' });
      const data = doc.data();
      const ownerField = ['shops'].includes(collection) ? 'ownerId' : 'userId';
      if (data?.[ownerField] !== uid) return res.status(403).json({ error: 'Forbidden' });
      next();
    } catch (error) {
      res.status(500).json({ error: 'Internal Server Error' });
    }
  };

  // API Routes
  app.get("/api/health", (req, res) => {
    res.json({ status: "ok" });
  });

  // Products API (Public)
  app.get("/api/products", async (req, res) => {
    try {
      const snapshot = await db.collection('products').get();
      const products = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      res.json(products);
    } catch (error: any) {
      console.error('Error fetching products:', error);
      res.status(500).json({ error: `Internal Server Error: ${error.message}` });
    }
  });

  // Seed Products (Admin only)
  app.post("/api/products/seed", authenticate, requireAdmin, async (req, res) => {
    const products = req.body.products;
    if (!Array.isArray(products)) {
        return res.status(400).json({ error: 'Invalid products data' });
    }
    try {
      const batch = db.batch();
      products.forEach((product: any) => {
        const docRef = db.collection('products').doc(product.id || String(Math.random()));
        batch.set(docRef, product);
      });
      await batch.commit();
      res.json({ message: 'Products seeded' });
    } catch (error) {
      console.error('Error seeding products:', error);
      res.status(500).json({ error: 'Error seeding products' });
    }
  });

  // Orders API (Protected)
  app.post("/api/orders", authenticate, async (req, res) => {
    try {
      const { items, totalAmount, paymentMethod, deliveryAddress, shopName } = req.body;
      if (!items || !Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ error: 'Order must contain items' });
      }
      const orderData = {
        userId: (req as any).user.uid,
        items,
        totalAmount,
        paymentMethod,
        deliveryAddress,
        shopName,
        status: 'Order Confirmed',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      const docRef = await db.collection('orders').add(orderData);
      res.json({ id: docRef.id, ...orderData });

      // Trigger Push Notifications
      sendPushNotification(
        (req as any).user.uid,
        'Order Confirmed!',
        `Your order from ${shopName} has been received and is being processed.`,
        { orderId: docRef.id, url: `/order-tracking` }
      );

      notifyAdmins(
        'New Order Received',
        `New order for ${totalAmount} from ${shopName}.`,
        { orderId: docRef.id, url: `/admin` }
      );
    } catch (error) {
      console.error('Error creating order:', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  });

  // Generic Data API (Protected with Ownership)
  app.get("/api/data/:collection", authenticate, async (req, res) => {
    try {
      const collectionName = req.params.collection;
      const uid = (req as any).user.uid;
      let query: admin.firestore.Query = db.collection(collectionName);
      if (collectionName === 'shops') {
        query = query.where('ownerId', '==', uid);
      } else if (['notifications', 'orders'].includes(collectionName)) {
        query = query.where('userId', '==', uid);
      } else if (collectionName === 'users') {
        const userDoc = await db.collection('users').doc(uid).get();
        if (userDoc.data()?.role !== 'admin') return res.status(403).json({ error: 'Forbidden' });
      }
      const snapshot = await query.get();
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      res.json(data);
    } catch (error: any) {
      res.status(500).json({ error: `Error fetching data: ${error.message}` });
    }
  });

  app.get("/api/data/:collection/:id", authenticate, async (req, res, next) => {
    const { collection } = req.params;
    if (['shops', 'notifications', 'orders'].includes(collection)) return checkOwnership(collection)(req, res, next);
    next();
  }, async (req, res) => {
    try {
      const { collection, id } = req.params;
      const doc = await db.collection(collection).doc(id).get();
      if (!doc.exists) return res.status(404).json({ error: 'Not found' });
      res.json({ id: doc.id, ...doc.data() });
    } catch (error: any) {
      res.status(500).json({ error: `Error fetching document: ${error.message}` });
    }
  });

  app.post("/api/data/:collection/:id", authenticate, async (req, res, next) => {
    const { collection, id } = req.params;
    const doc = await db.collection(collection).doc(id).get();
    if (doc.exists && ['shops', 'notifications', 'orders'].includes(collection)) return checkOwnership(collection)(req, res, next);
    next();
  }, async (req, res) => {
    try {
      const { collection, id } = req.params;
      const data = req.body;
      if (collection === 'users') delete data.role;
      
      const oldDoc = await db.collection(collection).doc(id).get();
      const oldData = oldDoc.data();

      await db.collection(collection).doc(id).set({ ...data, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
      res.json({ id, ...data });

      // Trigger Notifications for status changes
      if (collection === 'orders' && data.status && oldData?.status !== data.status) {
        sendPushNotification(
          oldData?.userId,
          'Order Update',
          `Your order status is now: ${data.status}`,
          { orderId: id, url: `/order-tracking` }
        );
      }
    } catch (error: any) {
      res.status(500).json({ error: `Error saving document: ${error.message}` });
    }
  });

  // Bulk Update API (example: mark notifications as read)
  app.post("/api/data-bulk/:collection/update", authenticate, async (req, res) => {
    try {
      const { collection } = req.params;
      const { ids, data } = req.body;
      if (!Array.isArray(ids)) return res.status(400).json({ error: 'ids must be an array' });
      
      const batch = db.batch();
      ids.forEach(id => {
        const ref = db.collection(collection).doc(id);
        batch.update(ref, data);
      });
      await batch.commit();
      res.json({ success: true, count: ids.length });
    } catch (error) {
      console.error('Bulk update error:', error);
      res.status(500).json({ error: 'Bulk update failed' });
    }
  });

  app.get("/api/orders", authenticate, async (req, res) => {
    try {
      const snapshot = await db.collection('orders')
        .where('userId', '==', (req as any).user.uid)
        .orderBy('createdAt', 'desc')
        .get();
      const orders = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      res.json(orders);
    } catch (error) {
      console.error('Error fetching orders:', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  });

  // User Profile (Protected)
  app.get("/api/user/profile", authenticate, async (req, res) => {
    try {
      const doc = await db.collection('users').doc((req as any).user.uid).get();
      if (!doc.exists) {
        return res.status(404).json({ error: 'User not found' });
      }
      res.json(doc.data());
    } catch (error: any) {
      console.error('Error fetching profile:', error);
      res.status(500).json({ error: `Internal Server Error: ${error.message}` });
    }
  });

  app.post("/api/user/profile", authenticate, async (req, res) => {
    try {
      const userData = req.body;
      const authUser = (req as any).user;
      const uid = authUser.uid;
      if (!uid) return res.status(400).json({ error: 'User UID missing' });
      const { role, uid: pUid, email: pEmail, ...safeData } = userData;
      const userRef = db.collection('users').doc(uid);
      const userDoc = await userRef.get();
      const isNewUser = !userDoc.exists;
      const profileUpdate: any = {
        ...safeData,
        uid: uid,
        email: authUser.email || userData.email || (userDoc.exists ? userDoc.data()?.email : ''),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };
      if (isNewUser) {
        profileUpdate.createdAt = admin.firestore.FieldValue.serverTimestamp();
        profileUpdate.role = 'customer';
        if (!profileUpdate.ownerName) {
          profileUpdate.ownerName = profileUpdate.firstName && profileUpdate.lastName 
            ? `${profileUpdate.firstName} ${profileUpdate.lastName}`.trim()
            : (authUser.name || 'User');
        }
      }
      await userRef.set(profileUpdate, { merge: true });

      // Trigger Welcome Notification & Email for new users
      if (isNewUser) {
        sendPushNotification(
          uid,
          'Welcome to SpazaLink! 👋',
          'We are glad to have you. Explore your dashboard to get started with better local deals.',
          { type: 'general', url: '/home' }
        );

        try {
          const userName = profileUpdate.ownerName || 'User';
          await db.collection('mail').add({
            to: authUser.email || profileUpdate.email,
            message: {
              subject: 'Welcome to SpazaLink!',
              html: `
                <p>Hi ${userName},</p>
                <p>Welcome to SpazaLink!</p>
                <p>We’re excited to have you join our growing community.</p>
                <p>With SpazaLink, you can:</p>
                <ul>
                  <li>Buy smarter together</li>
                  <li>Access better prices</li>
                  <li>Enjoy delivery to your doorstep</li>
                  <li>Connect with trusted local sellers</li>
                </ul>
                <p>Your account has been successfully created and you can now start exploring the platform.</p>
                <p>If you ever need assistance, our support team is ready to help.</p>
                <p>Thank you for choosing SpazaLink.</p>
                <p>Stronger together. Cheaper together.</p>
                <p>— The SpazaLink Team</p>
              `
            }
          });
        } catch (emailError) {
          console.error('[API] Failed to queue welcome email:', emailError);
          // We don't throw here so the user's profile still gets saved
        }
      }

      console.log(`[API] Profile updated successfully for ${uid}`);
      res.json({ success: true, updatedFields: Object.keys(profileUpdate) });
    } catch (error: any) {
      console.error('[API] Error saving profile:', error);
      res.status(500).json({ error: `Server Error: ${error.message}` });
    }
  });

  // Forgot Password API (Public)
  app.post("/api/auth/forgot-password", async (req, res) => {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });

    try {
      // 1. Check if user exists
      const user = await admin.auth().getUserByEmail(email);
      
      // 2. Generate reset link
      const resetLink = await admin.auth().generatePasswordResetLink(email);
      
      // 3. Get user profile for name
      const userProfile = await db.collection('users').doc(user.uid).get();
      const userName = userProfile.exists ? userProfile.data()?.ownerName : 'User';

      // 4. Send email via Trigger Email extension collection
      await db.collection('mail').add({
        to: email,
        message: {
          subject: 'Reset your SpazaLink password',
          html: `
            <p>Hi ${userName},</p>
            <p>We received a request to reset your SpazaLink account password.</p>
            <p>Click the secure link below to create a new password:</p>
            <p><a href="${resetLink}">${resetLink}</a></p>
            <p>If you did not request a password reset, you can safely ignore this email.</p>
            <p>For security reasons, this link may expire after some time.</p>
            <p>Thank you,<br>SpazaLink Support Team</p>
          `
        }
      });

      res.json({ success: true });
    } catch (error: any) {
      console.error('Error in forgot password:', error);
      if (error.code === 'auth/user-not-found') {
        // For security, don't reveal if user exists, but here we can be helpful or silent
        return res.status(404).json({ error: 'No user found with this email' });
      }
      res.status(500).json({ error: 'Internal Server Error' });
    }
  });

  // Vite middleware for development
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

startServer();
