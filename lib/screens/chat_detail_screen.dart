import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/chat.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  const ChatDetailScreen({super.key, required this.chatId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _firestore = FirestoreService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) _firestore.markChatRead(widget.chatId, uid);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(Chat chat, String uid) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final otherUid = chat.participantUids.firstWhere((p) => p != uid, orElse: () => '');
    await _firestore.sendMessage(chatId: widget.chatId, senderUid: uid, otherUid: otherUid, text: text);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: StreamBuilder<Chat?>(
          stream: _firestore.chat(widget.chatId),
          builder: (context, chatSnap) {
            final chat = chatSnap.data;
            if (chat == null) return const LoadingWidget();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          'https://images.unsplash.com/photo-${chat.otherUserAvatarId(uid)}?w=100&q=80&auto=format&fit=crop',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(chat.otherUserName(uid), style: nunito(size: 16, weight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('About ${chat.petName}', style: outfit(size: 13, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.warmBorder),
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: _firestore.messages(widget.chatId),
                    builder: (context, msgSnap) {
                      final messages = msgSnap.data ?? [];
                      if (messages.isEmpty) {
                        return Center(
                          child: Text('Say hello to ${chat.otherUserName(uid)} 👋', style: outfit(color: AppColors.muted)),
                        );
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                        }
                      });
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final msg = messages[i];
                          final isMe = msg.senderUid == uid;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 20),
                                ),
                                boxShadow: [
                                  if (!isMe) BoxShadow(color: AppColors.dark.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    msg.text,
                                    style: outfit(size: 14, color: isMe ? Colors.white : AppColors.dark),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    msg.sentAt != null ? DateFormat.jm().format(msg.sentAt!) : '',
                                    style: outfit(size: 10, color: isMe ? Colors.white70 : AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.warmBorder),
                          ),
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(border: InputBorder.none, hintText: 'Type a message…', filled: false),
                            onSubmitted: (_) => _send(chat, uid),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _send(chat, uid),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
