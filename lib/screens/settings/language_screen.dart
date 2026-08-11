import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/settings_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Language', style: nunito(size: 18, weight: FontWeight.w800, color: textColor)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildLangTile(context, 'en', 'English (US)', settings),
          _buildLangTile(context, 'te', 'Telugu (తెలుగు)', settings),
          _buildLangTile(context, 'hi', 'Hindi (हिन्दी)', settings),
        ],
      ),
    );
  }

  Widget _buildLangTile(BuildContext context, String code, String label, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkMid : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.transparent : AppColors.warmBorder),
      ),
      child: ListTile(
        title: Text(label, style: nunito(size: 15, weight: FontWeight.w700, color: isDark ? Colors.white : AppColors.dark)),
        trailing: Radio<String>(
          value: code,
          // ignore: deprecated_member_use
          groupValue: settings.languageCode,
          // ignore: deprecated_member_use
          onChanged: (v) {
            if (v != null) settings.setLanguage(v);
          },
          activeColor: AppColors.primary,
        ),
        onTap: () => settings.setLanguage(code),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
