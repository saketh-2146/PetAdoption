import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: IndexedStack(
        index: AppTab.values.indexOf(_tab),
        children: AppTab.values.map((t) => _screens[t]!).toList(),
      ),
      bottomNavigationBar: BottomNav(activeTab: _tab, onTabChange: (t) => setState(() => _tab = t)),
    );
  }
}
