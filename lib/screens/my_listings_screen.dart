import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import 'pet_detail_screen.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case 'Pending':
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF57F17);
        text = '🟡 Pending Approval';
        break;
      case 'Approved':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        text = '🟢 Approved';
        break;
      case 'Rejected':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        text = '🔴 Rejected';
        break;
      default:
        bgColor = AppColors.warm;
        textColor = AppColors.darkMid;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: outfit(size: 12, weight: FontWeight.w700, color: textColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('My Listings', style: nunito(size: 18, weight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Pet>>(
        stream: FirestoreService().myListings(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          final pets = snapshot.data ?? [];
          if (pets.isEmpty) {
            return Center(
              child: Text('You have not listed any pets yet.', style: outfit(color: AppColors.muted)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PetDetailScreen(petId: pet.id)),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppColors.dark.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          pet.imageUrl(w: 200),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pet.name, style: nunito(size: 18, weight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('${pet.breed} • ${pet.age}', style: outfit(size: 14, color: AppColors.muted)),
                            const SizedBox(height: 8),
                            _buildStatusBadge(pet.status),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
