import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String text;
  final String senderUid;
  final DateTime? sentAt;
  final String type; // text | image

  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderUid,
    required this.sentAt,
    this.type = 'text',
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      text: map['text'] ?? '',
      senderUid: map['senderUid'] ?? '',
      sentAt: (map['sentAt'] is Timestamp) ? (map['sentAt'] as Timestamp).toDate() : null,
      type: map['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text,
        'senderUid': senderUid,
        'sentAt': FieldValue.serverTimestamp(),
        'type': type,
      };
}

/// Mirrors `Chat` from types.ts. Stored in Firestore `chats/{chatId}` with a
/// `messages` subcollection, one doc per message.
class Chat {
  final String id;
  final String petId;
  final String petName;
  final String petImageId;
  final List<String> participantUids;
  final Map<String, String> participantNames; // uid -> display name
  final Map<String, String> participantAvatarIds; // uid -> unsplash id
  final String lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts; // uid -> unread count

  const Chat({
    required this.id,
    required this.petId,
    required this.petName,
    required this.petImageId,
    required this.participantUids,
    required this.participantNames,
    required this.participantAvatarIds,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCounts,
  });

  String otherUserName(String myUid) => participantNames.entries
      .firstWhere((e) => e.key != myUid, orElse: () => const MapEntry('', 'Unknown'))
      .value;

  String otherUserAvatarId(String myUid) => participantAvatarIds.entries
      .firstWhere((e) => e.key != myUid, orElse: () => const MapEntry('', ''))
      .value;

  int unreadFor(String myUid) => unreadCounts[myUid] ?? 0;

  factory Chat.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return Chat(
      id: doc.id,
      petId: map['petId'] ?? '',
      petName: map['petName'] ?? '',
      petImageId: map['petImageId'] ?? '',
      participantUids: List<String>.from(map['participantUids'] ?? const []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? const {}),
      participantAvatarIds: Map<String, String>.from(map['participantAvatarIds'] ?? const {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt: (map['lastMessageAt'] is Timestamp)
          ? (map['lastMessageAt'] as Timestamp).toDate()
          : null,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? const {}),
    );
  }
}
