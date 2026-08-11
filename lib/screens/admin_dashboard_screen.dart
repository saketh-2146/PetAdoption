import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../models/app_notification.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import 'pet_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _firestore = FirestoreService();
  Map<String, int>? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await _firestore.adminStats();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _approvePet(Pet pet) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve Listing?'),
        content: Text('Are you sure you want to approve ${pet.name}? It will become visible to all users.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Approve')),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.approvePet(pet.id, user.uid);
      if (pet.listedByUid != null) {
        await _firestore.addNotification(
          pet.listedByUid!,
          AppNotification(
            id: '',
            type: 'system',
            title: 'Listing Approved! 🎉',
            body: 'Great news! Your listing for ${pet.name} has been approved and is now live on PetConnect.',
            time: null,
            read: false,
          ),
        );
      }
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing approved!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _rejectPet(Pet pet) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Listing?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject ${pet.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Reject', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final reason = reasonController.text.trim();
      await _firestore.rejectPet(pet.id, user.uid, reason: reason);
      if (pet.listedByUid != null) {
        await _firestore.addNotification(
          pet.listedByUid!,
          AppNotification(
            id: '',
            type: 'system',
            title: 'Listing Rejected',
            body: 'Unfortunately, your listing for ${pet.name} was rejected. ${reason.isNotEmpty ? "Reason: $reason" : ""}',
            time: null,
            read: false,
          ),
        );
      }
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing rejected!'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warmBorder),
          boxShadow: [
            BoxShadow(color: AppColors.dark.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(value, style: nunito(size: 24, weight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: outfit(size: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Admin Control Panel', style: nunito(size: 20, weight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: CustomScrollView(
          slivers: [
            // Stats Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _loadingStats
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Statistics', style: nunito(size: 18, weight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildStatCard('Total', '${_stats?['totalListings'] ?? 0}', AppColors.dark),
                              _buildStatCard('Users', '${_stats?['totalUsers'] ?? 0}', Colors.blue),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatCard('Pending', '${_stats?['pending'] ?? 0}', Colors.orange),
                              _buildStatCard('Approved', '${_stats?['approved'] ?? 0}', Colors.green),
                              _buildStatCard('Rejected', '${_stats?['rejected'] ?? 0}', Colors.red),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            
            // Queue Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Approval Queue', style: nunito(size: 18, weight: FontWeight.w800)),
              ),
            ),

            // Queue List
            StreamBuilder<List<Pet>>(
              stream: _firestore.pendingPets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(child: LoadingWidget());
                }

                final pets = snapshot.data ?? [];
                if (pets.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text('No pending listings!', style: outfit(color: AppColors.muted)),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final pet = pets[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warmBorder),
                          boxShadow: [
                            BoxShadow(color: AppColors.dark.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(pet.imageUrl(w: 200), width: 60, height: 60, fit: BoxFit.cover),
                              ),
                              title: Text(pet.name, style: nunito(size: 18, weight: FontWeight.w800)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('${pet.breed} • ${pet.age}', style: outfit(size: 14)),
                                  const SizedBox(height: 4),
                                  Text('Seller: ${pet.owner.name}', style: outfit(size: 12, color: AppColors.muted)),
                                  Text('Price: ₹${pet.price ?? pet.adoptionFee}', style: outfit(size: 12, color: AppColors.muted)),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => PetDetailScreen(petId: pet.id)));
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: AppColors.warmBorder)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _rejectPet(pet),
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      label: const Text('Reject', style: TextStyle(color: Colors.red)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.red),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _approvePet(pet),
                                      icon: const Icon(Icons.check, color: Colors.white),
                                      label: const Text('Approve', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                    childCount: pets.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }
}
