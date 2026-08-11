import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

/// Lightweight app-wide state: which pets the signed-in user has liked
/// (kept in sync with Firestore `users/{uid}.likedPetIds`).
class AppState extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  Set<String> likedIds = {};
  String? _uid;
  String? loginRole; // 'user' or 'admin'

  void bindUser(User? user) {
    _uid = user?.uid;
    likedIds = {};
    if (_uid == null) {
      notifyListeners();
      return;
    }
    _firestore.user(_uid!).listen((appUser) {
      likedIds = appUser?.likedPetIds.toSet() ?? {};
      notifyListeners();
    });
  }

  bool isLiked(String petId) => likedIds.contains(petId);

  Future<void> toggleLike(String petId) async {
    if (_uid == null) return;
    final liked = !isLiked(petId);
    // Optimistic UI update.
    liked ? likedIds.add(petId) : likedIds.remove(petId);
    notifyListeners();
    await _firestore.toggleLike(_uid!, petId, liked);
  }
}
