import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'seed_data.dart';

/// Pushes the demo pet catalogue into Firestore the first time the app runs
/// against an empty database, so the Flutter app shows the exact same data
/// as the original Figma prototype. Safe to call repeatedly — it checks
/// first and does nothing if `pets` already has documents.
class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedPetsIfEmpty() async {
    final existing = await _db.collection('pets').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final pet in seedPets) {
      final ref = _db.collection('pets').doc(pet.id);
      batch.set(ref, pet.toMap());
    }
    await batch.commit();
  }

  /// Wipes all pets from the Firestore database.
  Future<void> clearAllPets() async {
    final snapshot = await _db.collection('pets').get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    debugPrint('Wiped ${snapshot.docs.length} pets from Firestore.');
  }

  /// Adds a couple of welcome notifications for a freshly-created user.
  Future<void> seedWelcomeNotifications(String uid) async {
    final ref = _db.collection('users').doc(uid).collection('notifications');
    final existing = await ref.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    await ref.add({
      'type': 'system',
      'title': 'Welcome to PetConnect! 🐾',
      'body': 'Browse pets nearby, save your favorites, and chat with owners to find your new best friend.',
      'time': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
  Future<void> ensureAdminExists() async {
    try {
      // Attempt to create the admin account with a default password.
      // This will fail silently if the account already exists.
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'admin2026@petconnect.com',
        password: 'admin123',
      );
    } catch (e) {
      // Ignore errors (like email-already-in-use)
    }
  }
}
