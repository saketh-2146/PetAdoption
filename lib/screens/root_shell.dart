import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'marketplace_screen.dart';
import 'sell_pet_screen.dart';
import 'profile_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  AppTab _tab = AppTab.home;

  static const _screens = {
    AppTab.home: HomeScreen(),
    AppTab.search: SearchScreen(),
    AppTab.adoptions: MarketplaceScreen(),
    AppTab.addPet: SellPetScreen(),
    AppTab.profile: ProfileScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<AppUser?>(
      stream: FirestoreService().user(uid),
      builder: (context, snapshot) {
        final role = snapshot.data?.role ?? 'user';
        final showAddPet = role == 'seller' || role == 'admin';

        // If the user's tab is AddPet but they lost permission, switch to home
        if (_tab == AppTab.addPet && !showAddPet) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _tab = AppTab.home);
          });
        }

        final visibleTabs = AppTab.values.where((t) {
          if (t == AppTab.addPet) return showAddPet;
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.cream,
          body: IndexedStack(
            index: AppTab.values.indexOf(_tab),
            children: AppTab.values.map((t) => _screens[t]!).toList(),
          ),
          bottomNavigationBar: BottomNav(
            activeTab: _tab, 
            visibleTabs: visibleTabs,
            onTabChange: (t) => setState(() => _tab = t)
          ),
        );
      }
    );
  }
}
