import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/app_notification.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected(String uid) async {
    if (_selectedIds.isEmpty) return;
    
    final firestore = FirestoreService();
    final idsToDelete = _selectedIds.toList();
    
    // Clear selection immediately for better UX
    _clearSelection();
    
    try {
      await firestore.deleteNotifications(uid, idsToDelete);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete notifications: $e')),
        );
      }
    }
  }

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

  Widget _buildNotificationIcon(AppNotification n) {
    if (n.imageId != null && n.imageId!.isNotEmpty) {
      final url = n.imageId!.startsWith('http') 
          ? n.imageId! 
          : 'https://images.unsplash.com/photo-${n.imageId}?w=150&q=70&auto=format&fit=crop';
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(url, width: 48, height: 48, fit: BoxFit.cover),
      );
    }
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: _colorFor(n.type).withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Icon(_iconFor(n.type), size: 24, color: _colorFor(n.type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final firestore = FirestoreService();
    
    final isSelectionMode = _selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text(
          isSelectionMode ? '${_selectedIds.length} Selected' : 'Notifications',
          style: nunito(size: 20, weight: FontWeight.w800),
        ),
        centerTitle: false,
        elevation: 0,
        leading: IconButton(
          icon: Icon(isSelectionMode ? Icons.close : Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (isSelectionMode) {
              _clearSelection();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => uid != null ? _deleteSelected(uid) : null,
            ),
        ],
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
                
                // If a notification was deleted externally but still in selection, remove it.
                // We do this silently without setState to avoid build loops.
                final validNotifIds = notifs.map((n) => n.id).toSet();
                _selectedIds.retainWhere((id) => validNotifIds.contains(id));

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
                    final isSelected = _selectedIds.contains(n.id);
                    
                    return GestureDetector(
                      onLongPress: () {
                        if (!isSelectionMode) {
                          _toggleSelection(n.id);
                        }
                      },
                      onTap: () {
                        if (isSelectionMode) {
                          _toggleSelection(n.id);
                        } else {
                          firestore.markNotificationRead(uid, n.id);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.primary.withValues(alpha: 0.1) 
                              : (n.read ? Colors.white : AppColors.primaryPale),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: (n.read && !isSelected)
                              ? [BoxShadow(color: AppColors.dark.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
                              : [],
                          border: isSelected 
                              ? Border.all(color: AppColors.primary, width: 2)
                              : (n.read ? Border.all(color: AppColors.warmBorder) : null),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isSelectionMode) ...[
                              Container(
                                margin: const EdgeInsets.only(top: 12, right: 12),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.muted,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected 
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                            ] else ...[
                              _buildNotificationIcon(n),
                              const SizedBox(width: 16),
                            ],
                            
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
                            if (!n.read && !isSelectionMode)
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
