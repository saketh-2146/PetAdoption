import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'pet_detail_screen.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('My Orders', style: nunito(size: 16, weight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: uid == null
          ? Center(
              child: Text('Please log in to see your orders.',
                  style: outfit(size: 15, color: AppColors.muted)),
            )
          : StreamBuilder<QuerySnapshot>(
              // Use orderBy so Firestore uses the composite index correctly
              stream: FirebaseFirestore.instance
                  .collectionGroup('applications')
                  .where('applicantUid', isEqualTo: uid)
                  .orderBy('submittedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final err = snapshot.error.toString();
                  // Show a friendly message + the index creation link if present
                  final linkMatch = RegExp(r'https://\S+').firstMatch(err);
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 48, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text('Setup Required',
                            style: nunito(
                                size: 18, weight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(
                          'A Firestore index needs to be created. '
                          'Open the link below in your browser to create it, '
                          'then reload the app.',
                          style: outfit(
                              size: 13, color: AppColors.muted, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        if (linkMatch != null) ...[
                          const SizedBox(height: 12),
                          SelectableText(
                            linkMatch.group(0)!,
                            style: outfit(
                                size: 11,
                                color: AppColors.primary,
                                height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pets,
                            size: 64, color: AppColors.muted),
                        const SizedBox(height: 16),
                        Text('No applications yet',
                            style: nunito(
                                size: 18,
                                weight: FontWeight.w700,
                                color: AppColors.muted)),
                        const SizedBox(height: 8),
                        Text('Your adoption applications will appear here.',
                            style:
                                outfit(size: 14, color: AppColors.muted)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final appDoc = docs[index];
                    final appData = appDoc.data() as Map<String, dynamic>;
                    final petRef = appDoc.reference.parent.parent;

                    if (petRef == null) return const SizedBox.shrink();

                    return FutureBuilder<DocumentSnapshot>(
                      future: petRef.get(),
                      builder: (context, petSnap) {
                        if (!petSnap.hasData || !petSnap.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        final pet = Pet.fromMap(petSnap.data!.id,
                            petSnap.data!.data() as Map<String, dynamic>);
                        final status =
                            (appData['status'] ?? 'pending') as String;
                        final submittedAt =
                            appData['submittedAt'] as Timestamp?;

                        return _OrderCard(
                          pet: pet,
                          status: status,
                          applicationId: appDoc.id,
                          submittedAt: submittedAt,
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Pet pet;
  final String status;
  final String applicationId;
  final Timestamp? submittedAt;

  const _OrderCard({
    required this.pet,
    required this.status,
    required this.applicationId,
    this.submittedAt,
  });

  Color get _statusColor {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.hourglass_top;
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'approved':
        return 'Approved 🎉';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending Review';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PetDetailScreen(petId: pet.id)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Pet image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      pet.imageUrl(w: 200, q: 70),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        color: AppColors.warm,
                        child: const Icon(Icons.pets, color: AppColors.muted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pet.name,
                            style:
                                nunito(size: 16, weight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('${pet.breed} · ${pet.age}',
                            style: outfit(
                                size: 13, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(_statusIcon, size: 15, color: _statusColor),
                            const SizedBox(width: 4),
                            Text(_statusLabel,
                                style: outfit(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: _statusColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${pet.adoptionFee?.toStringAsFixed(0) ?? '0'}',
                    style: nunito(
                        size: 16,
                        weight: FontWeight.w900,
                        color: AppColors.primary),
                  ),
                ],
              ),
              if (submittedAt != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.warmBorder),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      'Applied: ${_formatDate(submittedAt!.toDate())}',
                      style: outfit(size: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
              // If approved, show "Pet Adopted" confirmation banner
              if (status == 'approved' && pet.status == 'Adopted') ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.home_outlined,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        '${pet.name} has been adopted! 🏠',
                        style: outfit(
                            size: 13,
                            weight: FontWeight.w600,
                            color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
              ],
              // Seller contact info shown when approved
              if (status == 'approved') ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seller Contact',
                          style: nunito(
                              size: 12, weight: FontWeight.w800,
                              color: AppColors.primary)),
                      if (pet.contactMobile != null &&
                          pet.contactMobile!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('📞 ${pet.contactMobile}',
                            style: outfit(size: 13)),
                      ],
                      if (pet.contactEmail != null &&
                          pet.contactEmail!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('✉️ ${pet.contactEmail}',
                            style: outfit(size: 13)),
                      ],
                    ],
                  ),
                ),
              ],
              // Button to mark as adopted (only if approved and not yet adopted)
              if (status == 'approved' && pet.status != 'Adopted') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: Text('I\'ve Adopted ${pet.name}!',
                        style: nunito(
                            size: 14,
                            weight: FontWeight.w700,
                            color: Colors.white)),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: Text('Confirm Adoption',
                              style:
                                  nunito(size: 17, weight: FontWeight.w800)),
                          content: Text(
                            'This will mark ${pet.name} as adopted and remove '
                            'them from the marketplace. This cannot be undone.',
                            style: outfit(size: 14, height: 1.5),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text('Yes, Adopted!',
                                  style:
                                      outfit(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirestoreService()
                            .markPetAdopted(pet.id, applicationId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '🎉 ${pet.name} has been marked as adopted!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
