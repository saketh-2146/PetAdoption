import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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

    try {
      await cred.user?.sendEmailVerification();
      debugPrint('[AuthService] sendEmailVerification dispatched to ${cred.user?.email}');
    } on FirebaseAuthException catch (e) {
      // Log the real error so we can diagnose it
      debugPrint('[AuthService] sendEmailVerification FirebaseAuthException: code=${e.code} msg=${e.message}');
      // Rethrow so the UI can show the user a meaningful message
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] sendEmailVerification unknown error: $e');
      rethrow;
    }

    // Send welcome email via Firestore trigger extension
    await sendWelcomeEmail(
      uid: cred.user!.uid,
      name: name,
      email: email.trim(),
      role: role,
    );

    return cred;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
    String? role,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    if (role != null && cred.user != null) {
      await _db.collection('users').doc(cred.user!.uid).set({'role': role}, SetOptions(merge: true));
    }
    return cred;
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserCredential?> signInWithGoogle({String? role}) async {
    UserCredential userCredential;

    if (kIsWeb) {
      // On Web, use FirebaseAuth signInWithPopup instead of google_sign_in
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.setCustomParameters({'prompt': 'select_account'});
      userCredential = await _auth.signInWithPopup(googleProvider);
    } else {
      // Determine configuration based on platform
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw PlatformException(code: 'sign_in_canceled', message: 'Sign-in canceled by user.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      userCredential = await _auth.signInWithCredential(credential);
    }
    
    // Check if user is new, if so create firestore record, else just update role
    if (userCredential.additionalUserInfo?.isNewUser == true) {
      final u = userCredential.user!;
      final assignedRole = role ?? 'user';
      await _db.collection('users').doc(u.uid).set({
        'uid': u.uid,
        'name': u.displayName ?? 'Pet Lover',
        'displayName': u.displayName ?? 'Pet Lover',
        'email': u.email ?? '',
        'photoURL': u.photoURL ?? '',
        'phoneNumber': u.phoneNumber ?? '',
        'role': assignedRole,
        'avatarId': '1535713875-d780bfbbd5d4',
        'likedPetIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Send welcome email for new Google sign-in users
      if (u.email != null && u.email!.isNotEmpty) {
        await sendWelcomeEmail(
          uid: u.uid,
          name: u.displayName ?? 'Pet Lover',
          email: u.email!,
          role: assignedRole,
        );
      }
    } else if (role != null) {
      final u = userCredential.user!;
      await _db.collection('users').doc(u.uid).set({
        'role': role,
      }, SetOptions(merge: true));
    }

    return userCredential;
  }

  /// Sends a welcome email via the Brevo (Sendinblue) transactional email API.
  /// Free tier: 300 emails/day — no credit card or Firebase Blaze plan required.
  Future<void> sendWelcomeEmail({
    required String uid,
    required String name,
    required String email,
    required String role,
  }) async {
    const String brevoApiKey = String.fromEnvironment('BREVO_API_KEY', defaultValue: '');
    const String senderEmail = 'msaketh582@gmail.com';
    const String senderName  = 'PetConnect';

    final roleLabel = role[0].toUpperCase() + role.substring(1);
    final dateStr   = DateFormat('dd MMM yyyy').format(DateTime.now());

    final roleMessage = role == 'seller'
        ? 'As a <strong>Seller</strong>, you can now list your pets for adoption or sale and connect with loving families looking for their new best friend.'
        : 'As a <strong>User</strong>, you can now browse adorable pets, save your favorites to your wishlist, and connect with sellers to find your perfect companion.';

    final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; background-color: #f5f0eb; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 30px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #E8845C, #C5623C); padding: 40px 30px; text-align: center; }
    .header h1 { color: #ffffff; margin: 0; font-size: 28px; letter-spacing: 1px; }
    .header p { color: #fde8da; margin: 8px 0 0; font-size: 15px; }
    .body { padding: 36px 30px; }
    .body h2 { color: #333333; font-size: 22px; margin-top: 0; }
    .body p { color: #555555; font-size: 15px; line-height: 1.7; }
    .badge { display: inline-block; background: #fff3ee; color: #E8845C; border: 1.5px solid #E8845C; border-radius: 20px; padding: 4px 16px; font-size: 13px; font-weight: bold; margin-bottom: 16px; }
    .info-box { background: #fdf6f2; border-left: 4px solid #E8845C; border-radius: 8px; padding: 16px 20px; margin: 24px 0; }
    .info-box p { margin: 4px 0; color: #444; font-size: 14px; }
    .info-box strong { color: #C5623C; }
    .cta { text-align: center; margin: 28px 0; }
    .cta a { background: linear-gradient(135deg, #E8845C, #C5623C); color: #ffffff; text-decoration: none; padding: 14px 36px; border-radius: 30px; font-size: 16px; font-weight: bold; display: inline-block; }
    .footer { background: #f9f3ef; text-align: center; padding: 20px; font-size: 12px; color: #999999; }
    .paw { font-size: 32px; display: block; margin-bottom: 8px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <span class="paw">🐾</span>
      <h1>PetConnect</h1>
      <p>Adopt &amp; Find Your Perfect Pet</p>
    </div>
    <div class="body">
      <h2>Hi $name, welcome aboard! 🎉</h2>
      <span class="badge">$roleLabel Account</span>
      <p>Your registration on <strong>PetConnect</strong> was <strong>successful</strong>! We&apos;re thrilled to have you as part of our growing community of pet lovers.</p>
      <div class="info-box">
        <p><strong>Name:</strong> $name</p>
        <p><strong>Email:</strong> $email</p>
        <p><strong>Account Type:</strong> $roleLabel</p>
        <p><strong>Registered On:</strong> $dateStr</p>
      </div>
      <p>$roleMessage</p>
      <div class="cta">
        <a href="https://petsselling-d3076.web.app">Open PetConnect</a>
      </div>
      <p style="font-size:13px; color:#888;">If you did not create this account, please ignore this email or contact us immediately.</p>
    </div>
    <div class="footer">
      &copy; 2026 PetConnect &nbsp;|&nbsp; Bringing Pets &amp; People Together
    </div>
  </div>
</body>
</html>''';

    try {
      final response = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'accept':       'application/json',
          'api-key':      brevoApiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'sender':  {'name': senderName, 'email': senderEmail},
          'to':      [{'email': email, 'name': name}],
          'subject': '🐾 Welcome to PetConnect! Your Registration is Successful',
          'htmlContent': htmlBody,
        }),
      );

      if (response.statusCode == 201) {
        debugPrint('[AuthService] Welcome email sent to $email via Brevo ✓');
      } else {
        debugPrint('[AuthService] Brevo API error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Non-fatal — log but never block the registration flow
      debugPrint('[AuthService] sendWelcomeEmail failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      // Fire and forget Google Sign-Out to prevent it from hanging the app
      if (!kIsWeb) {
        GoogleSignIn().signOut().catchError((_) => null);
      }
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
        case 'popup-closed-by-user':
          return 'Sign-in canceled.';
        case 'popup-blocked':
          return 'Sign-in popup was blocked by your browser. Please allow popups for this site.';
        // Email verification specific errors
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'missing-email':
          return 'No email address associated with this account.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection and try again.';
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
