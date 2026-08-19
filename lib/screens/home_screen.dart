import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../services/firestore_service.dart';
import '../services/app_state.dart';
import '../services/seed_data.dart';
import '../theme/app_theme.dart';
import '../widgets/pet_card.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_card.dart';
import '../widgets/loading_widget.dart';
import 'pet_detail_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestore = FirestoreService();
  String _category = 'all';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: nunito(size: 20, weight: FontWeight.w800)),
          Text(
            'See All',
            style: outfit(size: 14, color: AppColors.primary, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalPetList(List<Pet> pets, AppState appState) {
    if (pets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text('No pets found.', style: outfit(color: AppColors.muted)),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: pets.length,
        itemBuilder: (context, i) {
          final pet = pets[i];
          return Container(
            width: 180,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: PetCard(
              pet: pet,
              liked: appState.isLiked(pet.id),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PetDetailScreen(petId: pet.id)),
              ),
              onToggleLike: () => appState.toggleLike(pet.id),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: StreamBuilder<List<Pet>>(
        stream: _firestore.pets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          final allPets = snapshot.data ?? [];
          final filtered = _category == 'all'
              ? allPets
              : allPets.where((p) => p.species == _category).toList();

          // Mocking different lists by sorting

          final recentlyAdded = List<Pet>.from(allPets)..sort((a, b) {
            final timeA = a.approvedAt ?? a.createdAt;
            final timeB = b.approvedAt ?? b.createdAt;
            return (timeB?.millisecondsSinceEpoch ?? 0).compareTo(timeA?.millisecondsSinceEpoch ?? 0);
          });
          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primaryPale,
                            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                            child: user?.photoURL == null ? const Icon(Icons.person, color: AppColors.primary) : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.displayName ?? 'Pet Lover', style: nunito(size: 18, weight: FontWeight.w900)),
                              Text(user?.email ?? 'No email', style: outfit(size: 13, color: AppColors.muted)),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        ),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.dark.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.notifications_none_rounded, color: AppColors.dark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar Fake
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.muted, size: 22),
                          const SizedBox(width: 12),
                          Text('Search breed, name, location…', style: outfit(size: 15, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Banner Carousel
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 24, bottom: 8),
                  child: BannerCarousel(
                    imageUrls: [
                      'https://images.unsplash.com/photo-1450778869180-41d0601e046e?w=800&q=80',
                      'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800&q=80',
                      'https://images.unsplash.com/photo-1548247416-ec66f4900b2e?w=800&q=80',
                    ],
                  ),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: seedCategories.map((c) {
                      return CategoryCard(
                        category: c,
                        isSelected: c['id'] == _category,
                        onTap: () => setState(() => _category = c['id']!),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // If specific category is selected, show grid of all filtered
              if (_category != 'all') ...[
                SliverToBoxAdapter(child: _buildSectionHeader(seedCategories.firstWhere((c) => c['id'] == _category)['label'] ?? 'Pets')),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(child: Text('No pets found yet.', style: outfit(color: AppColors.muted))),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.65,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final pet = filtered[i];
                          return PetCard(
                            pet: pet,
                            liked: appState.isLiked(pet.id),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PetDetailScreen(petId: pet.id)),
                            ),
                            onToggleLike: () => appState.toggleLike(pet.id),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ] else ...[
                // Home Sections when 'all' is selected
                SliverToBoxAdapter(child: _buildSectionHeader('Recently Added')),
                SliverToBoxAdapter(child: _buildHorizontalPetList(recentlyAdded.take(6).toList(), appState)),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ]
            ],
          );
        },
      ),
    );
  }
}
