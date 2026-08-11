import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';
import '../models/chat.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/address.dart';

/// All reads/writes to Firestore live here so screens stay dumb and
/// declarative — they just listen to streams from this service.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _pets => _db.collection('pets');
  CollectionReference<Map<String, dynamic>> get _chats => _db.collection('chats');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  // ---------------- Pets ----------------

  Stream<List<Pet>> pets() {
    return _pets
        .where('status', isEqualTo: 'Approved')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => Pet.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
          return list;
        });
  }

  Stream<List<Pet>> pendingPets() {
    return _pets
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => Pet.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
          return list;
        });
  }

  Stream<List<Pet>> myListings(String uid) {
    return _pets
        .where('listedByUid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => Pet.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
          return list;
        });
  }

  Stream<Pet?> pet(String petId) {
    return _pets.doc(petId).snapshots().map(
          (d) => d.exists ? Pet.fromMap(d.id, d.data()!) : null,
        );
  }

  Future<String> addPet(Pet pet) async {
    // If the pet has an ID (e.g. we generated a temp ID for image uploads), we set it.
    if (pet.id.isNotEmpty) {
      await _pets.doc(pet.id).set(pet.toMap());
      return pet.id;
    } else {
      final doc = await _pets.add(pet.toMap());
      return doc.id;
    }
  }

  Future<void> updatePet(Pet pet) async {
    await _pets.doc(pet.id).update(pet.toMap());
  }

  Future<void> deletePet(String petId, String ownerUid) async {
    // Delete Firestore document
    await _pets.doc(petId).delete();
  }

  Future<void> approvePet(String petId, String adminUid) async {
    await _pets.doc(petId).update({
      'status': 'Approved',
      'approvedBy': adminUid,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectPet(String petId, String adminUid, {String? reason}) async {
    await _pets.doc(petId).update({
      'status': 'Rejected',
      'rejectedBy': adminUid,
      'rejectedAt': FieldValue.serverTimestamp(),
      if (reason != null) 'rejectionReason': reason,
    });
  }

  Future<Map<String, int>> adminStats() async {
    final listingsQuery = await _pets.get();
    final usersQuery = await _users.get();

    int pending = 0;
    int approved = 0;
    int rejected = 0;

    for (var doc in listingsQuery.docs) {
      final status = doc.data()['status'] ?? 'Approved';
      if (status == 'Pending') {
        pending++;
      } else if (status == 'Approved') {
        approved++;
      } else if (status == 'Rejected') {
        rejected++;
      }
    }

    return {
      'totalListings': listingsQuery.docs.length,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
      'totalUsers': usersQuery.docs.length,
    };
  }

  // ---------------- User / wishlist ----------------

  Stream<AppUser?> user(String uid) {
    return _users.doc(uid).snapshots().map(
          (d) => d.exists ? AppUser.fromMap(d.id, d.data()!) : null,
        );
  }

  Future<void> toggleLike(String uid, String petId, bool liked) {
    return _users.doc(uid).set({
      'likedPetIds': liked
          ? FieldValue.arrayUnion([petId])
          : FieldValue.arrayRemove([petId]),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    return _users.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> updateNotificationSettings(String uid, Map<String, dynamic> data) {
    return _users.doc(uid).set(data, SetOptions(merge: true));
  }

  // ---------------- Addresses ----------------

  Stream<List<Address>> streamAddresses(String uid) {
    return _users
        .doc(uid)
        .collection('addresses')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              return Address.fromMap(d.id, d.data());
            }).toList());
  }

  Future<void> addAddress(String uid, Map<String, dynamic> addressData) {
    return _users.doc(uid).collection('addresses').add(addressData);
  }

  Future<void> updateAddress(String uid, String addressId, Map<String, dynamic> addressData) {
    return _users.doc(uid).collection('addresses').doc(addressId).set(addressData, SetOptions(merge: true));
  }

  Future<void> deleteAddress(String uid, String addressId) {
    return _users.doc(uid).collection('addresses').doc(addressId).delete();
  }

  Future<void> markAddressDefault(String uid, String addressId) async {
    final batch = _db.batch();
    final addressesRef = _users.doc(uid).collection('addresses');
    
    final allAddresses = await addressesRef.get();
    for (var doc in allAddresses.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }
    await batch.commit();
  }

  // ---------------- Chats ----------------

  Stream<List<Chat>> chatsFor(String uid) {
    return _chats
        .where('participantUids', arrayContains: uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(Chat.fromDoc).toList();
          list.sort((a, b) => (b.lastMessageAt?.millisecondsSinceEpoch ?? 0).compareTo(a.lastMessageAt?.millisecondsSinceEpoch ?? 0));
          return list;
        });
  }

  Stream<Chat?> chat(String chatId) {
    return _chats.doc(chatId).snapshots().map((d) => d.exists ? Chat.fromDoc(d) : null);
  }

  Stream<List<ChatMessage>> messages(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderUid,
    required String otherUid,
    required String text,
  }) async {
    final chatRef = _chats.doc(chatId);
    await chatRef.collection('messages').add(
          ChatMessage(id: '', text: text, senderUid: senderUid, sentAt: null).toMap(),
        );
    await chatRef.set({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts.$otherUid': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<void> markChatRead(String chatId, String uid) {
    return _chats.doc(chatId).set({
      'unreadCounts.$uid': 0,
    }, SetOptions(merge: true));
  }

  /// Finds an existing chat about [petId] between [uid] and [otherUid], or
  /// creates a new one.
  Future<String> getOrCreateChat({
    required String petId,
    required String petName,
    required String petImageId,
    required String uid,
    required String uidName,
    required String uidAvatarId,
    required String otherUid,
    required String otherName,
    required String otherAvatarId,
  }) async {
    final existing = await _chats
        .where('petId', isEqualTo: petId)
        .where('participantUids', arrayContains: uid)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participantUids'] ?? []);
      if (participants.contains(otherUid)) return doc.id;
    }

    final doc = await _chats.add({
      'petId': petId,
      'petName': petName,
      'petImageId': petImageId,
      'participantUids': [uid, otherUid],
      'participantNames': {uid: uidName, otherUid: otherName},
      'participantAvatarIds': {uid: uidAvatarId, otherUid: otherAvatarId},
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts': {uid: 0, otherUid: 0},
    });
    return doc.id;
  }

  // ---------------- Notifications ----------------

  Stream<List<AppNotification>> notificationsFor(String uid) {
    return _users
        .doc(uid)
        .collection('notifications')
        .orderBy('time', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotification.fromDoc).toList());
  }

  Future<void> markNotificationRead(String uid, String notifId) {
    return _users
        .doc(uid)
        .collection('notifications')
        .doc(notifId)
        .set({'read': true}, SetOptions(merge: true));
  }

  Future<void> addNotification(String uid, AppNotification notif) {
    return _users.doc(uid).collection('notifications').add(notif.toMap());
  }
}
