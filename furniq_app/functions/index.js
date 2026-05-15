/**
 * Furniq — Firebase Cloud Functions
 * Stripe Payment Gateway Integration
 *
 * This function creates a Stripe PaymentIntent and returns the clientSecret
 * to the Flutter app so it can present the Stripe Payment Sheet.
 *
 * The Stripe SECRET key lives here (server-side) and is NEVER sent to the client.
 * The Flutter app only uses the PUBLISHABLE key.
 *
 * Deploy: firebase deploy --only functions
 * Set secret: firebase functions:config:set stripe.secret="sk_test_..."
 *             OR set STRIPE_SECRET_KEY in .env for local emulation
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

// Initialize Firebase Admin
admin.initializeApp();

// Define Stripe secret as a Firebase Secret (stored securely, not in code)
// For local dev, set STRIPE_SECRET_KEY in functions/.env
const stripeSecret = defineSecret("STRIPE_SECRET_KEY");

/**
 * createPaymentIntent — HTTPS Callable Function
 *
 * Called by Flutter app to create a Stripe PaymentIntent.
 * Requires the user to be authenticated via Firebase Auth.
 *
 * Request data:
 *   { amount: number (in LKR, e.g. 1500.50), currency: string (e.g. "lkr") }
 *
 * Response:
 *   { clientSecret: string, paymentIntentId: string }
 */
exports.createPaymentIntent = onCall(
  {
    secrets: [stripeSecret],
    region: "us-central1",
    // Allow unauthenticated HTTP invocations at the Cloud Run IAM layer.
    // Firebase Auth is still validated at the application level via request.auth.
    // Without this, Gen 2 Cloud Run rejects all requests with a 401 before
    // the function code even runs.
    invoker: "public",
    enforceAppCheck: false,
  },
  async (request) => {
    // 1. Ensure the user is authenticated
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be signed in to make a payment."
      );
    }

    const { amount, currency = "lkr" } = request.data;

    // 2. Validate inputs
    if (!amount || typeof amount !== "number" || amount <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "A valid positive amount is required."
      );
    }

    const allowedCurrencies = ["lkr", "usd", "eur"];
    if (!allowedCurrencies.includes(currency.toLowerCase())) {
      throw new HttpsError(
        "invalid-argument",
        `Currency '${currency}' is not supported.`
      );
    }

    // 3. Convert to smallest currency unit
    //    LKR & USD both use 2 decimal places (cents / cents)
    //    Stripe requires amount in smallest unit (e.g. cents for USD, cents for LKR)
    const amountInSmallestUnit = Math.round(amount * 100);

    if (amountInSmallestUnit < 15000) {
      throw new HttpsError(
        "invalid-argument",
        "Amount is too small. Minimum payment is LKR 150."
      );
    }

    try {
      // 4. Initialize Stripe with the secret key
      const Stripe = require("stripe");
      const secretKey = stripeSecret.value().trim();
      console.log(
        `Stripe key loaded (len=${secretKey.length}): ${secretKey ? secretKey.substring(0, 7) + "..." + secretKey.substring(secretKey.length - 4) : "MISSING"}`
      );
      const stripe = new Stripe(secretKey);

      // 5. Create the PaymentIntent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: amountInSmallestUnit,
        currency: currency.toLowerCase(),
        payment_method_types: ["card"],
        // Attach Firebase user ID for record-keeping
        metadata: {
          firebase_uid: request.auth.uid,
          firebase_email: request.auth.token.email || "unknown",
        },
        description: "Furniq — Furniture Purchase",
      });

      console.log(
        `PaymentIntent created: ${paymentIntent.id} for user: ${request.auth.uid}, amount: ${amountInSmallestUnit} ${currency}`
      );

      // 6. Return only what the client needs — NOT the full PaymentIntent object
      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      };
    } catch (error) {
      console.error("Stripe error:", error.message);
      console.error("Stripe error type:", error.type);
      console.error("Stripe raw:", JSON.stringify(error, null, 2));
      if (error.type === "StripeCardError") {
        throw new HttpsError("failed-precondition", error.message);
      } else if (error.type === "StripeInvalidRequestError") {
        throw new HttpsError("invalid-argument", "Invalid payment request.");
      } else {
        throw new HttpsError(
          "internal",
          `Stripe error: ${error.message}`
        );
      }
    }
  }
);

const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");

/**
 * onOrderStatusChange — Firestore Trigger
 *
 * Triggered whenever a document in the 'orders' collection is updated.
 * It checks if the 'status' field has changed, and if so, creates a new
 * notification document for the user.
 */
exports.onOrderStatusChange = onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    // Get an object with the current document value.
    // If the document does not exist, it has been deleted.
    const newValue = event.data.after.data();
    
    // Get an object with the previous document value (for update)
    const previousValue = event.data.before.data();
    
    if (!newValue || !previousValue) return;

    // Check if the status has actually changed
    if (newValue.status === previousValue.status) {
      return; // Nothing to do
    }

    const orderId = event.params.orderId;
    const userId = newValue.userId;
    const newStatus = newValue.status; // e.g. 'processing', 'shipped', 'delivered', 'cancelled'

    // Determine notification content based on status
    let title = "Order Update";
    let message = `Your order ORD${orderId} status changed to ${newStatus}.`;

    if (newStatus === "processing") {
      title = "Order Processing";
      message = `Your order ORD${orderId} is being prepared.`;
    } else if (newStatus === "shipped") {
      title = "Order Shipped";
      message = `Your order ORD${orderId} is on its way!`;
    } else if (newStatus === "delivered") {
      title = "Order Delivered";
      message = `Your order ORD${orderId} has been delivered. Enjoy!`;
    } else if (newStatus === "cancelled") {
      title = "Order Cancelled";
      message = `Your order ORD${orderId} has been cancelled.`;
    }

    // Create notification document
    try {
      await admin.firestore().collection("notifications").add({
        userId: userId,
        title: title,
        message: message,
        read: false,
        orderId: orderId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Notification created for user ${userId} for order ${orderId} (${newStatus})`);
      
      // Also send Push Notification if user has FCM tokens
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        // Check if push notifications are enabled and user has tokens
        if (userData.pushNotificationsEnabled !== false && userData.fcmTokens && userData.fcmTokens.length > 0) {
          const payload = {
            notification: {
              title: title,
              body: message,
            },
            data: {
              orderId: orderId,
              click_action: "FLUTTER_NOTIFICATION_CLICK"
            },
            tokens: userData.fcmTokens,
          };
          
          const response = await admin.messaging().sendEachForMulticast(payload);
          console.log(`Sent ${response.successCount} push notifications. Failed: ${response.failureCount}`);
          
          // Clean up invalid tokens
          if (response.failureCount > 0) {
            const failedTokens = [];
            response.responses.forEach((resp, idx) => {
              if (!resp.success) {
                const errCode = resp.error?.code;
                if (errCode === 'messaging/invalid-registration-token' || errCode === 'messaging/registration-token-not-registered') {
                  failedTokens.push(userData.fcmTokens[idx]);
                }
              }
            });
            
            if (failedTokens.length > 0) {
              await admin.firestore().collection("users").doc(userId).update({
                fcmTokens: admin.firestore.FieldValue.arrayRemove(...failedTokens)
              });
              console.log(`Removed ${failedTokens.length} invalid FCM tokens for user ${userId}`);
            }
          }
        }
      }
    } catch (error) {
      console.error("Error creating or sending notification:", error);
    }
  }
);

/**
 * onOrderCreated — Firestore Trigger
 *
 * Triggered whenever a new document is added to the 'orders' collection.
 * It loops through the items in the order and uses a transaction to
 * safely decrement the stock quantity and update the stock status.
 */
exports.onOrderCreated = onDocumentCreated(
  "orders/{orderId}",
  async (event) => {
    const orderData = event.data.data();
    if (!orderData || !orderData.items || !Array.isArray(orderData.items)) {
      return;
    }

    const items = orderData.items;
    const db = admin.firestore();

    // Process each item in the order
    for (const item of items) {
      const productId = item.productId;
      const quantityOrdered = item.quantity;

      if (!productId || typeof quantityOrdered !== "number" || quantityOrdered <= 0) {
        continue;
      }

      const productRef = db.collection("products").doc(productId);

      try {
        await db.runTransaction(async (transaction) => {
          const productDoc = await transaction.get(productRef);
          if (!productDoc.exists) {
            console.warn(`Product ${productId} not found during stock update.`);
            return;
          }

          const productData = productDoc.data();
          const currentStock = productData.stockQuantity || 0;
          let newStock = currentStock - quantityOrdered;

          // Prevent negative stock
          if (newStock < 0) {
            newStock = 0;
          }

          // Determine new stock status
          let newStatus = "inStock";
          if (newStock === 0) {
            newStatus = "outOfStock";
          } else if (newStock <= 5) {
            newStatus = "lowStock";
          }

          transaction.update(productRef, {
            stockQuantity: newStock,
            stockStatus: newStatus,
          });
        });

        console.log(`Successfully updated stock for product ${productId}. New quantity: ordered ${quantityOrdered}.`);
      } catch (error) {
        console.error(`Failed to update stock for product ${productId}:`, error);
      }
    }
  }
);
