import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors `AppNotification` from types.ts. Stored at
/// `users/{uid}/notifications/{id}` so every user has their own feed.
class AppNotification {
  final String id;
  final String type; // adoption | message | offer | reminder | system
  final String title;
  final String body;
  final DateTime? time;
  final bool read;
  final String? imageId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.read,
    this.imageId,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      type: map['type'] ?? 'system',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      time: (map['time'] is Timestamp) ? (map['time'] as Timestamp).toDate() : null,
      read: map['read'] ?? false,
      imageId: map['imageId'],
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'title': title,
        'body': body,
        'time': FieldValue.serverTimestamp(),
        'read': read,
        if (imageId != null) 'imageId': imageId,
      };
}
