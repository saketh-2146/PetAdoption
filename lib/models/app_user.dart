import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at `users/{uid}`. Created on sign up, updated as the user
/// interacts with the app (likes, listings, etc).
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String avatarId;
  final List<String> likedPetIds;
  final DateTime? createdAt;
  
  // Personal Information
  final String? mobileNumber;
  final String? address;
  final String? city;
  final String? state;

  // Notification Settings
  final bool pushNotifications;
  final bool adoptionRequestNotifications;
  final bool newPetAlerts;
  final bool chatNotifications;
  final bool promotionalNotifications;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.avatarId,
    required this.likedPetIds,
    this.createdAt,
    this.mobileNumber,
    this.address,
    this.city,
    this.state,
    this.pushNotifications = true,
    this.adoptionRequestNotifications = true,
    this.newPetAlerts = true,
    this.chatNotifications = true,
    this.promotionalNotifications = false,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        avatarId: map['avatarId'] ?? '1535713875-d780bfbbd5d4',
        likedPetIds: List<String>.from(map['likedPetIds'] ?? const []),
        createdAt: (map['createdAt'] is Timestamp) ? (map['createdAt'] as Timestamp).toDate() : null,
        mobileNumber: map['mobileNumber'],
        address: map['address'],
        city: map['city'],
        state: map['state'],
        pushNotifications: map['pushNotifications'] ?? true,
        adoptionRequestNotifications: map['adoptionRequestNotifications'] ?? true,
        newPetAlerts: map['newPetAlerts'] ?? true,
        chatNotifications: map['chatNotifications'] ?? true,
        promotionalNotifications: map['promotionalNotifications'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'avatarId': avatarId,
        'likedPetIds': likedPetIds,
        'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
        'mobileNumber': mobileNumber,
        'address': address,
        'city': city,
        'state': state,
        'pushNotifications': pushNotifications,
        'adoptionRequestNotifications': adoptionRequestNotifications,
        'newPetAlerts': newPetAlerts,
        'chatNotifications': chatNotifications,
        'promotionalNotifications': promotionalNotifications,
      };
}
