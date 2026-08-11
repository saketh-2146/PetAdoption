import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryCard extends StatelessWidget {
  final Map<String, String> category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: AppColors.dark.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.warmBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category['emoji'] ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              category['label'] ?? '',
              style: nunito(
                size: 14,
                weight: isSelected ? FontWeight.w800 : FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.darkMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
