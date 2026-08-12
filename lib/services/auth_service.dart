import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around FirebaseAuth. Also makes sure every signed-up user
/// gets a matching `users/{uid}` document in Firestore.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(name);

    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'email': email.trim(),
      'role': role,
      'avatarId': '1535713875-d780bfbbd5d4',
      'likedPetIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserCredential?> signInWithGoogle() async {
    // Determine configuration based on platform
    final GoogleSignIn googleSignIn = GoogleSignIn(
      // On Web, GoogleSignIn requires a clientId. 
      // Replace with your actual Web Client ID from Firebase Console -> Authentication -> Google -> Web SDK configuration
      clientId: kIsWeb ? '669329188204-upr670084o64t7dj3a44ndftidh2qder.apps.googleusercontent.com' : null,
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw PlatformException(code: 'sign_in_canceled', message: 'Sign-in canceled by user.');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    
    // Check if user is new, if so create firestore record
    if (userCredential.additionalUserInfo?.isNewUser == true) {
      final u = userCredential.user!;
      await _db.collection('users').doc(u.uid).set({
        'uid': u.uid,
        'name': u.displayName ?? 'Pet Lover',
        'displayName': u.displayName ?? 'Pet Lover',
        'email': u.email ?? '',
        'photoURL': u.photoURL ?? '',
        'phoneNumber': u.phoneNumber ?? '',
        'role': 'user',
        'avatarId': '1535713875-d780bfbbd5d4',
        'likedPetIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return userCredential;
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Ignore Google Sign In errors during sign out
    }
    await _auth.signOut();
  }

  /// Maps FirebaseAuthException codes to friendly messages for the UI.
  static String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }
    if (error is PlatformException) {
      if (error.code == 'sign_in_canceled') {
        return 'Sign-in canceled.';
      } else if (error.code == 'network_error') {
        return 'Network unavailable. Please check your connection.';
      } else if (error.code == 'sign_in_failed') {
        return 'Google Sign-In failed. Please check Google Play Services and OAuth configuration.';
      }
      return error.message ?? 'Google Sign-In failed. Please ensure Firebase is configured.';
    }
    if (error.runtimeType.toString() == 'MissingPluginException') {
      return 'Please stop and restart the app completely. Hot reload cannot add new native plugins.';
    }
    return error.toString();
  }
}
