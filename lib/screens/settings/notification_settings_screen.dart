import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../models/app_user.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    if (uid == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: nunito(size: 18, weight: FontWeight.w800, color: textColor)),
      ),
      body: StreamBuilder<AppUser?>(
        stream: FirestoreService().user(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('Error loading preferences'));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSwitchTile(
                context: context,
                title: 'Push Notifications',
                subtitle: 'Enable all push notifications',
                value: user.pushNotifications,
                onChanged: (v) => _updatePref(uid, 'pushNotifications', v),
              ),
              _buildSwitchTile(
                context: context,
                title: 'Adoption Requests',
                subtitle: 'Get notified when someone requests to adopt your pet',
                value: user.adoptionRequestNotifications,
                onChanged: (v) => _updatePref(uid, 'adoptionRequestNotifications', v),
              ),
              _buildSwitchTile(
                context: context,
                title: 'New Pet Alerts',
                subtitle: 'Get notified when new pets are added',
                value: user.newPetAlerts,
                onChanged: (v) => _updatePref(uid, 'newPetAlerts', v),
              ),
              _buildSwitchTile(
                context: context,
                title: 'Chat Notifications',
                subtitle: 'Get notified when you receive a new message',
                value: user.chatNotifications,
                onChanged: (v) => _updatePref(uid, 'chatNotifications', v),
              ),
              _buildSwitchTile(
                context: context,
                title: 'Promotional Notifications',
                subtitle: 'Receive updates about offers and news',
                value: user.promotionalNotifications,
                onChanged: (v) => _updatePref(uid, 'promotionalNotifications', v),
              ),
            ],
          );
        },
      ),
    );
  }

  void _updatePref(String uid, String key, bool value) {
    FirestoreService().updateNotificationSettings(uid, {key: value});
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkMid : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.transparent : AppColors.warmBorder),
      ),
      child: SwitchListTile(
        title: Text(title, style: nunito(size: 15, weight: FontWeight.w700, color: isDark ? Colors.white : AppColors.dark)),
        subtitle: Text(subtitle, style: outfit(size: 13, color: isDark ? Colors.white70 : AppColors.muted)),
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
