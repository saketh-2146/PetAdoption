const { admin, getDb } = require('../config/firebase');

// POST /api/auth/register
exports.register = async (req, res, next) => {
  try {
    const { email, password, name, phone } = req.body;

    if (!email || !password || !name) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email, password, and name.'
      });
    }

    // 1. Create user in Firebase Auth
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });

    // 2. Save additional user details to Firestore (if DB is available)
    const db = getDb();
    if (db) {
      await db.collection('users').doc(userRecord.uid).set({
        uid: userRecord.uid,
        email: userRecord.email,
        name: name,
        phone: phone || '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        uid: userRecord.uid,
        email: userRecord.email,
        name: userRecord.displayName
      }
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/auth/login
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password.'
      });
    }

    const apiKey = process.env.FIREBASE_API_KEY;
    if (!apiKey) {
      return res.status(500).json({
        success: false,
        message: 'Server misconfiguration: FIREBASE_API_KEY is not set in .env'
      });
    }

    // Make request to Firebase Identity Toolkit REST API
    const response = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email,
          password,
          returnSecureToken: true
        })
      }
    );

    const data = await response.json();

    if (!response.ok) {
      return res.status(401).json({
        success: false,
        message: data.error?.message || 'Authentication failed'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        uid: data.localId,
        email: data.email,
        token: data.idToken,
        refreshToken: data.refreshToken,
        expiresIn: data.expiresIn
      }
    });
  } catch (error) {
    next(error);
  }
};
