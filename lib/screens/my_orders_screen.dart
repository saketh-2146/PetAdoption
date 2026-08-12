import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';
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
        title: Text('My Orders', style: nunito(size: 16, weight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: uid == null 
        ? const Center(child: Text('Not logged in'))
        : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('applications')
                .where('applicantUid', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: outfit(color: Colors.red)));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final docs = snapshot.data!.docs.toList();
              
              docs.sort((a, b) {
                final ad = (a.data() as Map<String, dynamic>)['submittedAt'] as Timestamp?;
                final bd = (b.data() as Map<String, dynamic>)['submittedAt'] as Timestamp?;
                return (bd?.millisecondsSinceEpoch ?? 0).compareTo(ad?.millisecondsSinceEpoch ?? 0);
              });

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pets, size: 64, color: AppColors.muted),
                      const SizedBox(height: 16),
                      Text('No orders yet', style: nunito(size: 18, weight: FontWeight.w700, color: AppColors.muted)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final appData = docs[index].data() as Map<String, dynamic>;
                  final petRef = docs[index].reference.parent.parent;
                  
                  if (petRef == null) return const SizedBox.shrink();

                  return FutureBuilder<DocumentSnapshot>(
                    future: petRef.get(),
                    builder: (context, petSnap) {
                      if (!petSnap.hasData || !petSnap.data!.exists) {
                        return const SizedBox.shrink();
                      }
                      
                      final pet = Pet.fromMap(petSnap.data!.id, petSnap.data!.data() as Map<String, dynamic>);
                      final status = appData['status'] ?? 'pending';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => PetDetailScreen(petId: pet.id),
                            ));
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    pet.imageUrl(w: 200, q: 70),
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(pet.name, style: nunito(size: 16, weight: FontWeight.w800)),
                                      const SizedBox(height: 4),
                                      Text('Status: ${status.toUpperCase()}', 
                                        style: outfit(
                                          size: 12, 
                                          weight: FontWeight.w700,
                                          color: status == 'pending' ? Colors.orange : (status == 'approved' ? Colors.green : Colors.red)
                                        )
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.muted),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  );
                },
              );
            },
          ),
    );
  }
}
