import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/chat.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Text('Messages', style: nunito(size: 20, weight: FontWeight.w900)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: StreamBuilder<List<Chat>>(
          stream: firestore.chatsFor(uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LoadingWidget();
            }
            final chats = snapshot.data!;
            if (chats.isEmpty) {
              return const EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'No conversations yet',
                message: 'Message a pet owner from their listing to start chatting.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: chats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final chat = chats[i];
                final unread = chat.unreadFor(uid);
                return GestureDetector(
                  onTap: () {
                    firestore.markChatRead(chat.id, uid);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ChatDetailScreen(chatId: chat.id)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppColors.dark.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: CachedNetworkImageProvider(
                                'https://images.unsplash.com/photo-${chat.otherUserAvatarId(uid)}?w=120&q=80&auto=format&fit=crop',
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: 'https://images.unsplash.com/photo-${chat.petImageId}?w=80&q=80&auto=format&fit=crop',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(chat.otherUserName(uid), style: nunito(size: 15, weight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  Text(
                                    chat.lastMessageAt != null ? DateFormat.jm().format(chat.lastMessageAt!) : '',
                                    style: outfit(size: 12, color: unread > 0 ? AppColors.primary : AppColors.muted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      chat.lastMessage.isEmpty ? 'About ${chat.petName}' : chat.lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: outfit(size: 13, color: unread > 0 ? AppColors.dark : AppColors.muted),
                                    ),
                                  ),
                                  if (unread > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                      child: Text('$unread', style: nunito(size: 11, weight: FontWeight.w800, color: Colors.white)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
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
    );
  }
}
