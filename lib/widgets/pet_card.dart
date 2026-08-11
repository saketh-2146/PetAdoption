import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pet.dart';
import '../theme/app_theme.dart';

class PetCard extends StatelessWidget {
  final Pet pet;
  final bool liked;
  final VoidCallback onTap;
  final VoidCallback onToggleLike;

  const PetCard({
    super.key,
    required this.pet,
    required this.liked,
    required this.onTap,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    final priceLabel = '₹${pet.adoptionFee?.toStringAsFixed(0) ?? '0'} fee';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.1,
                  child: CachedNetworkImage(
                    imageUrl: pet.imageUrl(),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.warm),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.warm,
                      child: const Icon(Icons.pets, color: AppColors.muted),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Adopt',
                      style: nunito(size: 11, weight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onToggleLike,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: liked ? AppColors.error : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          style: nunito(size: 16, weight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        pet.gender.toLowerCase() == 'male' ? Icons.male : Icons.female,
                        size: 16,
                        color: pet.gender.toLowerCase() == 'male' ? Colors.blue : Colors.pink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pet.breed,
                    style: outfit(size: 12, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        priceLabel,
                        style: nunito(size: 14, weight: FontWeight.w900, color: AppColors.primary),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            pet.distance,
                            style: outfit(size: 11, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
