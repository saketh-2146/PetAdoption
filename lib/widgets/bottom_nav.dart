import 'package:flutter/material.dart';
import 'package:petconnect/l10n/app_localizations.dart';
import '../theme/app_theme.dart';

enum AppTab { home, search, adoptions, addPet, profile }

class BottomNav extends StatelessWidget {
  final AppTab activeTab;
  final List<AppTab> visibleTabs;
  final ValueChanged<AppTab> onTabChange;

  const BottomNav({
    super.key,
    required this.activeTab,
    required this.visibleTabs,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    final allItems = [
      (tab: AppTab.home, icon: Icons.home_rounded, label: l10n.navHome),
      (tab: AppTab.search, icon: Icons.search_rounded, label: l10n.searchHint),
      (tab: AppTab.adoptions, icon: Icons.pets_rounded, label: l10n.myAdoptionsMenu),
      (tab: AppTab.addPet, icon: Icons.add_circle_outline_rounded, label: l10n.sellAPet),
      (tab: AppTab.profile, icon: Icons.person_rounded, label: l10n.navProfile),
    ];

    final items = allItems.where((item) => visibleTabs.contains(item.tab)).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkMid : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.transparent : AppColors.warmBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final active = item.tab == activeTab;
            return InkWell(
              onTap: () => onTabChange(item.tab),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 24,
                      color: active ? AppColors.primary : (isDark ? Colors.white70 : AppColors.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: nunito(
                        size: 10,
                        weight: active ? FontWeight.w800 : FontWeight.w600,
                        color: active ? AppColors.primary : (isDark ? Colors.white70 : AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
