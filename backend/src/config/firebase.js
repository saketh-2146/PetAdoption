const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Look for the service account key in the backend root directory
const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');

const initializeFirebase = () => {
  try {
    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = require(serviceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      console.log('Firebase Admin initialized successfully.');
    } else {
      console.warn(
        '⚠️ Firebase Admin not initialized: firebase-service-account.json not found in the backend directory. ' +
        'Please download it from your Firebase Console and place it in the backend folder.'
      );
    }
  } catch (error) {
    console.error('Error initializing Firebase Admin:', error);
  }
};

module.exports = {
  admin,
  initializeFirebase,
  getDb: () => admin.apps.length > 0 ? admin.firestore() : null,
  getAuth: () => admin.apps.length > 0 ? admin.auth() : null
};
