import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../services/firestore_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/pet_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state.dart';
import 'pet_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _firestore = FirestoreService();
  late final TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: nunito(size: 20, weight: FontWeight.w800)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildFilterSection('Category', ['All', 'Dogs', 'Cats', 'Birds', 'Rabbits']),
                  _buildFilterSection('Age', ['Baby', 'Young', 'Adult', 'Senior']),
                  _buildFilterSection('Gender', ['Male', 'Female', 'Any']),
                  _buildFilterSection('Distance', ['< 5km', '< 10km', '< 20km', 'Anywhere']),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: nunito(size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = opt == 'All' || opt == 'Any' || opt == 'Anywhere';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.warmBorder),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  opt,
                  style: nunito(
                    size: 14,
                    weight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.darkMid,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SearchBarWidget(
                      controller: _controller,
                      hintText: 'Search breed, name, location…',
                      onChanged: (v) => setState(() => _query = v),
                      onFilterTap: _showFilterSheet,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Pet>>(
                stream: _firestore.pets(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LoadingWidget();
                  }
                  final q = _query.trim().toLowerCase();
                  final results = q.isEmpty
                      ? <Pet>[]
                      : snapshot.data!.where((p) {
                          return p.name.toLowerCase().contains(q) ||
                              p.breed.toLowerCase().contains(q) ||
                              p.location.toLowerCase().contains(q) ||
                              p.category.toLowerCase().contains(q);
                        }).toList();

                  if (q.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search,
                      title: 'Search for pets',
                      message: 'Type a breed, name, or location to find your new best friend.',
                    );
                  }
                  if (results.isEmpty) {
                    return EmptyState(
                      icon: Icons.pets,
                      title: 'No matches found',
                      message: 'We couldn\'t find any pets matching "$q". Try another search or adjust your filters.',
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final pet = results[i];
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
      ),
    );
  }
}
