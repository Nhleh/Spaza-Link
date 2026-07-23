import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

admin.initializeApp();

const db = admin.firestore();

// ── Order number generation ────────────────────────────────────────────────

/**
 * Generates a sequential SpazaLink order number when an order document is
 * created. Format: SL-YYYYMMDD-NNNN (e.g. SL-20240722-0001).
 */
export const onOrderCreated = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap, context) => {
    const orderId = context.params.orderId;
    const data = snap.data();
    if (data.orderNumber) return; // Already set (shouldn't happen).

    const today = new Date();
    const dateStr = today.toISOString().slice(0, 10).replace(/-/g, "");
    const counterRef = db.doc(`settings/orderCounter_${dateStr}`);

    const orderNumber = await db.runTransaction(async (tx) => {
      const counter = await tx.get(counterRef);
      const current: number = counter.exists
        ? (counter.data()!.count as number)
        : 0;
      const next = current + 1;
      tx.set(counterRef, { count: next }, { merge: true });
      return `SL-${dateStr}-${String(next).padStart(4, "0")}`;
    });

    await db.doc(`orders/${orderId}`).update({ orderNumber });
  });

// ── Shop approval notification ─────────────────────────────────────────────

/**
 * Sends an FCM notification to the shop owner when their shop status changes.
 */
export const onShopStatusChanged = functions.firestore
  .document("shops/{shopId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status) return;

    const ownerId: string = after.ownerId;
    const userDoc = await db.doc(`users/${ownerId}`).get();
    if (!userDoc.exists) return;

    const tokens: string[] = userDoc.data()!.fcmTokens ?? [];
    if (tokens.length === 0) return;

    let title = "SpazaLink";
    let body = "";

    switch (after.status) {
      case "approved":
        title = "Shop Approved! 🎉";
        body = `${after.shopName} is now live. Start ordering!`;
        break;
      case "rejected":
        title = "Application Update";
        body = `Your shop application was not approved. Tap for details.`;
        break;
      case "suspended":
        title = "Account Suspended";
        body = "Your account has been suspended. Contact support for help.";
        break;
      default:
        return;
    }

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: { type: "shop_approval", status: after.status },
    });
  });

// ── Order status notification ──────────────────────────────────────────────

/**
 * Notifies the customer when their order status changes.
 */
export const onOrderStatusChanged = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status) return;

    const customerId: string = after.customerId;
    const userDoc = await db.doc(`users/${customerId}`).get();
    if (!userDoc.exists) return;

    const tokens: string[] = userDoc.data()!.fcmTokens ?? [];
    if (tokens.length === 0) return;

    const statusMessages: Record<string, { title: string; body: string }> = {
      confirmed: {
        title: "Order Confirmed ✅",
        body: `Order ${after.orderNumber} has been confirmed.`,
      },
      preparing: {
        title: "Order Being Packed 📦",
        body: `Order ${after.orderNumber} is being packed for delivery.`,
      },
      out_for_delivery: {
        title: "Out for Delivery 🚚",
        body: `Order ${after.orderNumber} is on the way!`,
      },
      delivered: {
        title: "Order Delivered! 🎉",
        body: `Order ${after.orderNumber} has been delivered. Enjoy!`,
      },
      cancelled: {
        title: "Order Cancelled",
        body: `Order ${after.orderNumber} has been cancelled.`,
      },
    };

    const msg = statusMessages[after.status as string];
    if (!msg) return;

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: msg,
      data: {
        type: "order_status",
        orderId: change.after.id,
        status: after.status,
      },
    });
  });

// ── Admin user creation ────────────────────────────────────────────────────

/**
 * Creates a Firestore user document for a new admin. Called by admin setup
 * scripts — not triggered automatically.
 */
export const createAdminUser = functions.https.onCall(
  async (data, context) => {
    // Only existing admins can create new admins.
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const callerDoc = await db.doc(`users/${context.auth.uid}`).get();
    if (callerDoc.data()?.role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can create admin accounts."
      );
    }

    const { email, password, displayName } = data as {
      email: string;
      password: string;
      displayName: string;
    };

    const fbUser = await admin.auth().createUser({ email, password, displayName });

    const now = admin.firestore.Timestamp.now();
    await db.doc(`users/${fbUser.uid}`).set({
      uid: fbUser.uid,
      email,
      displayName,
      phoneNumber: "",
      role: "admin",
      isActive: true,
      fcmTokens: [],
      createdAt: now,
      updatedAt: now,
    });

    return { uid: fbUser.uid };
  }
);

// ── Driver pre-registration ────────────────────────────────────────────────

/**
 * Registers a new driver. Admin-only callable function.
 */
export const registerDriver = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const callerDoc = await db.doc(`users/${context.auth.uid}`).get();
    if (callerDoc.data()?.role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can register drivers."
      );
    }

    const { phoneNumber, displayName, vehicleType, vehicleReg } = data as {
      phoneNumber: string;
      displayName: string;
      vehicleType: string;
      vehicleReg: string;
    };

    // Create Firebase Auth user (phone-based; UID is the Firestore doc key).
    // Phone auth users are created on first OTP sign-in, so we just create
    // the Firestore document here.
    const driverRef = db.collection("users").doc();
    const now = admin.firestore.Timestamp.now();

    await driverRef.set({
      uid: driverRef.id,
      phoneNumber,
      displayName,
      email: null,
      role: "driver",
      isActive: true,
      fcmTokens: [],
      createdAt: now,
      updatedAt: now,
    });

    // Also create the driver profile doc.
    await db.doc(`drivers/${driverRef.id}`).set({
      driverId: driverRef.id,
      displayName,
      phoneNumber,
      vehicleType,
      vehicleReg,
      photoUrl: null,
      isAvailable: true,
      currentLocation: null,
      createdAt: now,
    });

    return { driverId: driverRef.id };
  }
);
