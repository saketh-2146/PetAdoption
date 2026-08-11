import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/settings_provider.dart';
import 'settings/edit_profile_screen.dart';
import 'settings/saved_addresses_screen.dart';
import 'settings/notification_settings_screen.dart';
import 'settings/language_screen.dart';
import 'settings/help_center_screen.dart';
import 'settings/policy_screen.dart';
import 'package:petconnect/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsMenu, style: nunito(size: 20, weight: FontWeight.w800, color: textColor)),
        centerTitle: false,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(l10n.accountSection),
          _buildSettingsTile(
            context: context,
            icon: Icons.person_outline, 
            title: l10n.personalInfo, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.location_on_outlined, 
            title: l10n.savedAddresses, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen())),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.preferencesSection),
          _buildSettingsTile(
            context: context,
            icon: Icons.notifications_none, 
            title: l10n.notificationSettings, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.language, 
            title: l10n.language, 
            subtitle: settings.languageCode == 'hi' ? 'Hindi (हिन्दी)' : settings.languageCode == 'te' ? 'Telugu (తెలుగు)' : 'English (US)', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen())),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.dark_mode_outlined, 
            title: l10n.darkMode, 
            trailing: Switch(
              value: settings.themeMode == ThemeMode.dark, 
              onChanged: (v) => settings.setThemeMode(v ? ThemeMode.dark : ThemeMode.light), 
              activeThumbColor: AppColors.primary,
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.supportSection),
          _buildSettingsTile(
            context: context,
            icon: Icons.help_outline, 
            title: l10n.helpCenter, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.privacy_tip_outlined, 
            title: l10n.privacyPolicy, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PolicyScreen(title: l10n.privacyPolicy, assetPath: 'assets/text/privacy_policy.txt'))),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.article_outlined, 
            title: l10n.termsOfService, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PolicyScreen(title: l10n.termsOfService, assetPath: 'assets/text/terms_of_service.txt'))),
          ),
          
          const SizedBox(height: 32),
          Center(
            child: Text('PetConnect v1.0.0', style: outfit(size: 13, color: AppColors.muted)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: nunito(size: 16, weight: FontWeight.w800, color: AppColors.primary)),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkMid : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.transparent : AppColors.warmBorder),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: AppColors.primaryPale, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: nunito(size: 15, weight: FontWeight.w700, color: isDark ? Colors.white : AppColors.dark)),
        subtitle: subtitle != null ? Text(subtitle, style: outfit(size: 13, color: isDark ? Colors.white70 : AppColors.muted)) : null,
        trailing: trailing ?? Icon(Icons.chevron_right, color: isDark ? Colors.white70 : AppColors.muted),
      ),
    );
  }
}

