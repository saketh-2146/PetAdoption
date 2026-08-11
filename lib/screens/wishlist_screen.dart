import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../services/firestore_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/pet_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';
import 'pet_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text('Wishlist', style: nunito(size: 20, weight: FontWeight.w800)),
        centerTitle: false,
        elevation: 0,
      ),
      body: StreamBuilder<List<Pet>>(
        stream: firestore.pets(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingWidget();
          }
          final liked = snapshot.data!.where((p) => appState.isLiked(p.id)).toList();
          if (liked.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              message: 'Tap the heart on a pet to save it here for later.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.65,
            ),
            itemCount: liked.length,
            itemBuilder: (context, i) {
              final pet = liked[i];
              return PetCard(
                pet: pet,
                liked: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PetDetailScreen(petId: pet.id)),
                ),
                onToggleLike: () => appState.toggleLike(pet.id),
              );
            },
          );
        },
      ),
    );
  }
}
