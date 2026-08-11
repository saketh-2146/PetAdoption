import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../services/firestore_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/pet_card.dart';
import 'pet_detail_screen.dart';


class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final appState = context.watch<AppState>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available for Adoption', style: nunito(size: 20, weight: FontWeight.w900)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Pet>>(
              stream: firestore.pets(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final availablePets = snapshot.data!.toList();
                if (availablePets.isEmpty) {
                  return Center(child: Text('No pets available for adoption yet.', style: outfit(color: AppColors.muted)));
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: availablePets.length,
                  itemBuilder: (context, i) {
                    final pet = availablePets[i];
                    return PetCard(
                      pet: pet,
                      liked: appState.isLiked(pet.id),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PetDetailScreen(petId: pet.id)),
                      ),
                      onToggleLike: () => appState.toggleLike(pet.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
