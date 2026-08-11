import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Help Center', style: nunito(size: 18, weight: FontWeight.w800, color: textColor)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHelpTile(context, Icons.question_answer_outlined, 'Frequently Asked Questions', () {}),
          _buildHelpTile(context, Icons.support_agent_outlined, 'Contact Support', () {}),
          _buildHelpTile(context, Icons.report_problem_outlined, 'Report a Problem', () {}),
          _buildHelpTile(context, Icons.email_outlined, 'Email Support', () {}),
          
          const SizedBox(height: 32),
          Center(
            child: Text('App Version 1.0.0', style: outfit(size: 14, color: AppColors.muted)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
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
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: nunito(size: 15, weight: FontWeight.w700, color: isDark ? Colors.white : AppColors.dark)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      ),
    );
  }
}
