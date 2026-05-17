import express from "express";
import path from "path";
import { createServer as createViteServer } from "vite";
import admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";
import fs from "node:fs";

// Load Firebase Config
const firebaseConfig = JSON.parse(fs.readFileSync(path.join(process.cwd(), 'firebase-applet-config.json'), 'utf-8'));

// Initialize Firebase Admin
if (admin.apps.length === 0) {
  admin.initializeApp({
    projectId: firebaseConfig.projectId,
  });
}

const db = (firebaseConfig.firestoreDatabaseId && firebaseConfig.firestoreDatabaseId !== "(default)")
  ? getFirestore(admin.app(), firebaseConfig.firestoreDatabaseId)
  : getFirestore(admin.app());

async function startServer() {
  const app = express();
  const PORT = 3000;

  // Middleware for parsing JSON
  app.use(express.json());

  // Auth Middleware
  const authenticate = async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const idToken = authHeader.split('Bearer ')[1];
    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      (req as any).user = decodedToken;
      next();
    } catch (error) {
      console.error('Error verifying token:', error);
      res.status(401).json({ error: 'Unauthorized' });
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
    } catch (error) {
      console.error('Error fetching products:', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  });

  // Seed Products (Internal/Admin only - for simplicity let's make it callable)
  app.post("/api/products/seed", async (req, res) => {
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
      const orderData = {
        ...req.body,
        userId: (req as any).user.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      const docRef = await db.collection('orders').add(orderData);
      res.json({ id: docRef.id, ...orderData });
    } catch (error) {
      console.error('Error creating order:', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  });

  // Generic Data API (Protected)
  app.get("/api/data/:collection", authenticate, async (req, res) => {
    try {
      const collectionName = req.params.collection;
      let query: admin.firestore.Query = db.collection(collectionName);

      // Simple owner filtering for specific collections
      if (collectionName === 'shops') {
        query = db.collection(collectionName).where('ownerId', '==', (req as any).user.uid);
      } else if (['notifications', 'orders'].includes(collectionName)) {
        query = query.where('userId', '==', (req as any).user.uid);
      }

      const snapshot = await query.get();
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      res.json(data);
    } catch (error) {
      console.error('Error fetching collection:', error);
      res.status(500).json({ error: 'Error fetching data' });
    }
  });

  app.get("/api/data/:collection/:id", authenticate, async (req, res) => {
    try {
      const { collection, id } = req.params;
      const doc = await db.collection(collection).doc(id).get();
      if (!doc.exists) return res.status(404).json({ error: 'Not found' });
      res.json({ id: doc.id, ...doc.data() });
    } catch (error) {
      res.status(500).json({ error: 'Error fetching document' });
    }
  });

  app.post("/api/data/:collection/:id", authenticate, async (req, res) => {
    try {
      const { collection, id } = req.params;
      const data = req.body;
      await db.collection(collection).doc(id).set(data, { merge: true });
      res.json({ id, ...data });
    } catch (error) {
      res.status(500).json({ error: 'Error saving document' });
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
    } catch (error) {
      console.error('Error fetching profile:', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  });

  app.post("/api/user/profile", authenticate, async (req, res) => {
    try {
      const userData = req.body;
      const uid = (req as any).user.uid;
      
      // Check if user is new (no profile yet)
      const userDoc = await db.collection('users').doc(uid).get();
      const isNewUser = !userDoc.exists;

      await db.collection('users').doc(uid).set(userData, { merge: true });

      // Trigger Welcome Email for new users
      if (isNewUser) {
        const userName = userData.ownerName || 'User';
        await db.collection('mail').add({
          to: (req as any).user.email,
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
      }

      res.json({ success: true });
    } catch (error) {
      console.error('Error saving profile:', error);
      res.status(500).json({ error: 'Internal Server Error' });
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
