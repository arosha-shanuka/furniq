const admin = require('firebase-admin');
let serviceAccount;

try {
  serviceAccount = require('./serviceAccountKey.json');
} catch (e) {
  // Continue without it, relying on GOOGLE_APPLICATION_CREDENTIALS
}

try {
  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  } else {
    admin.initializeApp();
  }
} catch (e) {
  console.log("Failed to initialize Firebase Admin:", e.message);
}

const args = process.argv.slice(2);
const email = args[0];

if (!email) {
  console.error("Please provide an email address. Usage: node set_admin.js <email>");
  process.exit(1);
}

async function setAdmin() {
  try {
    const user = await admin.auth().getUserByEmail(email);
    
    // Set admin custom claim
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });
    
    console.log(`Successfully set admin claim for ${email} (uid: ${user.uid}).`);
    console.log("The user will need to sign out and sign back in for the changes to take effect.");
  } catch (error) {
    console.error(`Error setting admin claim: ${error.message}`);
  } finally {
    process.exit();
  }
}

setAdmin();
