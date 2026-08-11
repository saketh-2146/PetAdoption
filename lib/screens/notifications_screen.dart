import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/app_notification.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case 'adoption':
        return Icons.pets;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'offer':
        return Icons.local_offer_outlined;
      case 'reminder':
        return Icons.access_time;
      default:
        return Icons.notifications_none;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'adoption':
        return AppColors.secondary;
      case 'message':
        return AppColors.primary;
      case 'offer':
        return AppColors.accent;
      case 'reminder':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text('Notifications', style: nunito(size: 20, weight: FontWeight.w800)),
        centerTitle: false,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: uid == null
          ? const SizedBox.shrink()
          : StreamBuilder<List<AppNotification>>(
              stream: firestore.notificationsFor(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LoadingWidget();
                }
                final notifs = snapshot.data!;
                if (notifs.isEmpty) {
                  return const EmptyState(
                    icon: Icons.notifications_none,
                    title: 'No notifications',
                    message: 'You\'re all caught up! Check back later for updates.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: notifs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final n = notifs[i];
                    return GestureDetector(
                      onTap: () => firestore.markNotificationRead(uid, n.id),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: n.read ? Colors.white : AppColors.primaryPale,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: n.read
                              ? [BoxShadow(color: AppColors.dark.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
                              : [],
                          border: n.read ? Border.all(color: AppColors.warmBorder) : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: _colorFor(n.type).withValues(alpha: 0.15), shape: BoxShape.circle),
                              child: Icon(_iconFor(n.type), size: 24, color: _colorFor(n.type)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.title, style: nunito(size: 15, weight: n.read ? FontWeight.w700 : FontWeight.w900)),
                                  const SizedBox(height: 4),
                                  Text(n.body, style: outfit(size: 13, color: AppColors.darkMid, weight: n.read ? FontWeight.normal : FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Text(
                                    n.time != null ? DateFormat.MMMd().add_jm().format(n.time!) : '',
                                    style: outfit(size: 11, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            if (!n.read)
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
