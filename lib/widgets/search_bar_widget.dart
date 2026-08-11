import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onFilterTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmit;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onFilterTap,
    this.hintText = 'Search pets, breeds, etc...',
    this.onChanged,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: (_) {
          if (onSubmit != null) onSubmit!();
        },
        style: outfit(size: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: outfit(size: 16, color: AppColors.muted),
          prefixIcon: const Icon(Icons.search, color: AppColors.muted),
          suffixIcon: GestureDetector(
            onTap: onFilterTap,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 20),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
