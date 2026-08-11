import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final int reviews;
  final double iconSize;
  final double textSize;

  const RatingWidget({
    super.key,
    required this.rating,
    required this.reviews,
    this.iconSize = 16,
    this.textSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: AppColors.accent, size: iconSize),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: nunito(size: textSize, weight: FontWeight.w800),
        ),
        const SizedBox(width: 4),
        Text(
          '($reviews reviews)',
          style: outfit(size: textSize, color: AppColors.muted),
        ),
      ],
    );
  }
}
