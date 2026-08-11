import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pet.dart';
import '../services/firestore_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/rating_widget.dart';
import '../widgets/loading_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'adoption_screen.dart';
import 'edit_pet_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final String petId;
  const PetDetailScreen({super.key, required this.petId});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  final _firestore = FirestoreService();
  int _galleryIndex = 0;


  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: StreamBuilder<Pet?>(
        stream: _firestore.pet(widget.petId),
        builder: (context, snapshot) {
          final pet = snapshot.data;
          if (pet == null) {
            return const LoadingWidget();
          }
          final liked = appState.isLiked(pet.id);
          final gallery = (pet.imageUrls != null && pet.imageUrls!.isNotEmpty) 
              ? pet.imageUrls! 
              : (pet.galleryIds.isEmpty ? [pet.imageId] : pet.galleryIds);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 0.9,
                      child: CachedNetworkImage(
                        imageUrl: pet.galleryUrl(gallery[_galleryIndex]),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.warm),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 16,
                      child: _circleButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 16,
                      right: 16,
                      child: Row(
                        children: [
                          _circleButton(
                            icon: Icons.share,
                            onTap: () {}, // share logic
                          ),
                          const SizedBox(width: 12),
                          _circleButton(
                            icon: liked ? Icons.favorite : Icons.favorite_border,
                            iconColor: liked ? AppColors.error : AppColors.muted,
                            onTap: () => appState.toggleLike(pet.id),
                          ),
                        ],
                      ),
                    ),
                    if (gallery.length > 1)
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(gallery.length, (i) {
                            final active = i == _galleryIndex;
                            return GestureDetector(
                              onTap: () => setState(() => _galleryIndex = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: active ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pet.name, style: nunito(size: 32, weight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text('${pet.breed} · ${pet.age}', style: outfit(size: 16, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          Text(
                            '₹${pet.adoptionFee?.toStringAsFixed(0) ?? '0'}',
                            style: nunito(size: 24, weight: FontWeight.w900, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('${pet.location} · ${pet.distance}', style: outfit(size: 14, color: AppColors.darkMid)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: pet.personality
                            .map((p) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPale,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(p, style: nunito(size: 13, weight: FontWeight.w800, color: AppColors.primary)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: AppColors.dark.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: CachedNetworkImageProvider(pet.galleryUrl(pet.owner.avatarId, w: 100, q: 80)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(pet.owner.name, style: nunito(size: 16, weight: FontWeight.w800)),
                                      if (pet.owner.verified) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, size: 16, color: AppColors.primary),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  RatingWidget(rating: pet.owner.rating, reviews: pet.owner.reviews),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryPale,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text('About', style: nunito(size: 20, weight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      Text(pet.description, style: outfit(size: 15, height: 1.6, color: AppColors.darkMid)),
                      const SizedBox(height: 32),
                      Text('Health & Medical', style: nunito(size: 20, weight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _healthTag('Vaccinated', pet.health.vaccinated),
                          _healthTag('Neutered', pet.health.neutered),
                          _healthTag('Dewormed', pet.health.dewormed),
                          _healthTag('Microchipped', pet.health.microchipped),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text('Details', style: nunito(size: 20, weight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: AppColors.dark.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          children: [
                            _detailRow('Color', pet.color),
                            const Divider(height: 24, color: AppColors.warmBorder),
                            _detailRow('Weight', pet.weight),
                            const Divider(height: 24, color: AppColors.warmBorder),
                            _detailRow('Gender', pet.gender[0].toUpperCase() + pet.gender.substring(1)),
                            if (pet.contactEmail != null && pet.contactEmail!.isNotEmpty) ...[
                              const Divider(height: 24, color: AppColors.warmBorder),
                              _detailRow('Email', pet.contactEmail!),
                            ],
                            if (pet.contactMobile != null && pet.contactMobile!.isNotEmpty) ...[
                              const Divider(height: 24, color: AppColors.warmBorder),
                              _detailRow('Mobile', pet.contactMobile!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: StreamBuilder<Pet?>(
        stream: _firestore.pet(widget.petId),
        builder: (context, snapshot) {
          final pet = snapshot.data;
          if (pet == null) return const SizedBox.shrink();
          
          final isOwner = FirebaseAuth.instance.currentUser?.uid == pet.listedByUid;
          
          return Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: AppColors.dark.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: Row(
              children: isOwner ? [
                Expanded(
                  child: CustomButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EditPetScreen(pet: pet)),
                    ),
                    text: 'Edit Listing',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Listing'),
                          content: const Text('Are you sure you want to delete this listing? This action cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                         if (pet.listedByUid != null) {
                           await SupabaseStorageService().deleteFolder(
                             userId: pet.listedByUid!, 
                             petId: pet.id
                           );
                         }
                         await _firestore.deletePet(pet.id, pet.listedByUid!);
                         if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: Text('Delete', style: nunito(size: 16, weight: FontWeight.w800)),
                  ),
                ),
              ] : [
                Expanded(
                  child: CustomButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AdoptionScreen(petId: pet.id)),
                    ),
                    text: 'Adopt Now',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap, Color iconColor = AppColors.dark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
          ],
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }

  Widget _healthTag(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ok ? AppColors.primaryPale : AppColors.warm,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel, size: 18, color: ok ? AppColors.primary : AppColors.muted),
          const SizedBox(width: 8),
          Text(label, style: nunito(size: 14, weight: FontWeight.w800, color: ok ? AppColors.primary : AppColors.muted)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: outfit(size: 15, color: AppColors.muted)),
        Text(value, style: nunito(size: 15, weight: FontWeight.w800)),
      ],
    );
  }
}
