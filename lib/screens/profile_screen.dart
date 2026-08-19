import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'my_orders_screen.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestore = FirestoreService();

    final menuItems = [
      (icon: Icons.notifications_none, label: 'Notifications', onTap: (BuildContext c) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
      (icon: Icons.shopping_bag_outlined, label: 'My Orders', onTap: (BuildContext c) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen()))),
      (icon: Icons.settings_outlined, label: 'Settings', onTap: (BuildContext c) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
    ];

    return SafeArea(
      child: user == null
          ? const SizedBox.shrink()
          : StreamBuilder<AppUser?>(
              stream: firestore.user(user.uid),
              builder: (context, snapshot) {
                final appUser = snapshot.data;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    Text('Profile', style: nunito(size: 24, weight: FontWeight.w900)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: AppColors.dark.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primaryPale,
                            backgroundImage: NetworkImage(
                              'https://images.unsplash.com/photo-${appUser?.avatarId ?? '1535713875-d780bfbbd5d4'}?w=150&q=80&auto=format&fit=crop',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(appUser?.name ?? user.displayName ?? 'Pet Lover', style: nunito(size: 18, weight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(appUser?.email ?? user.email ?? '', style: outfit(size: 14, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryPale,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('Account', style: nunito(size: 18, weight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    ...menuItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => item.onTap(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.warmBorder),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        color: AppColors.warm,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(item.icon, size: 20, color: AppColors.darkMid),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(child: Text(item.label, style: nunito(size: 15, weight: FontWeight.w700))),
                                    const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        onPressed: () => AuthService().signOut(),
                        text: 'Sign Out',
                        icon: Icons.logout,
                        isOutlined: true,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

}
