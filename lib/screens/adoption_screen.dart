import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../models/app_notification.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class AdoptionScreen extends StatefulWidget {
  final String petId;
  const AdoptionScreen({super.key, required this.petId});

  @override
  State<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  final _firestore = FirestoreService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: outfit(size: 12, color: AppColors.muted)),
              const SizedBox(height: 4),
              Text(value, style: outfit(size: 14, weight: FontWeight.w600, color: AppColors.dark)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit(Pet pet) async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in your name and phone number.')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      // Store the adoption/purchase application as a subcollection under the
      // pet, and drop a confirmation notification in the user's feed.
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(pet.id)
          .collection('applications')
          .add({
        'applicantUid': user.uid,
        'applicantName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'note': _noteCtrl.text.trim(),
        'type': pet.type,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Update pet status to remove it from the marketplace
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(pet.id)
          .update({'status': 'Adopted'});

      // Notify the buyer
      await _firestore.addNotification(
        user.uid,
        AppNotification(
          id: '',
          type: 'adoption',
          title: 'Application submitted 🐾',
          body: 'Your request for ${pet.name} is pending review from ${pet.owner.name}.',
          time: null,
          read: false,
          imageId: pet.imageUrls?.isNotEmpty == true ? pet.imageUrls!.first : pet.imageId,
        ),
      );

      // Notify the seller
      if (pet.listedByUid != null) {
        await _firestore.addNotification(
          pet.listedByUid!,
          AppNotification(
            id: '',
            type: 'adoption',
            title: 'New Application Received! 🎉',
            body: '${_nameCtrl.text.trim()} has applied for ${pet.name}.\nContact: ${_phoneCtrl.text.trim()}\nAddress: ${_addressCtrl.text.trim()}\nNote: ${_noteCtrl.text.trim()}',
            time: null,
            read: false,
            imageId: pet.imageUrls?.isNotEmpty == true ? pet.imageUrls!.first : pet.imageId,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application Submitted Successfully! 🎉'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text('Application', style: nunito(size: 16, weight: FontWeight.w800)),
      ),
      body: StreamBuilder<Pet?>(
        stream: _firestore.pet(widget.petId),
        builder: (context, snapshot) {
          final pet = snapshot.data;
          if (pet == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.warmBorder)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(pet.imageUrl(w: 200, q: 70), width: 56, height: 56, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pet.name, style: nunito(size: 14, weight: FontWeight.w800)),
                            Text(pet.breed, style: outfit(size: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Text(
                        '₹${pet.adoptionFee?.toStringAsFixed(0) ?? '0'}',
                        style: nunito(size: 24, weight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Pet & Contact Details', style: nunito(size: 15, weight: FontWeight.w800)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warmBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(Icons.location_on_outlined, 'Location', pet.location),
                      if (pet.contactMobile != null && pet.contactMobile!.isNotEmpty) ...[
                        const Divider(height: 24, color: AppColors.warmBorder),
                        _buildDetailRow(Icons.phone_outlined, 'Contact Number', pet.contactMobile!),
                      ],
                      if (pet.contactEmail != null && pet.contactEmail!.isNotEmpty) ...[
                        const Divider(height: 24, color: AppColors.warmBorder),
                        _buildDetailRow(Icons.email_outlined, 'Email Address', pet.contactEmail!),
                      ],
                      const Divider(height: 24, color: AppColors.warmBorder),
                      _buildDetailRow(Icons.medical_services_outlined, 'Health Info', 
                          'Vaccinated: ${pet.health.vaccinated ? 'Yes' : 'No'}\n'
                          'Neutered: ${pet.health.neutered ? 'Yes' : 'No'}\n'
                          'Dewormed: ${pet.health.dewormed ? 'Yes' : 'No'}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Your information', style: nunito(size: 15, weight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full name')),
                const SizedBox(height: 12),
                TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number')),
                const SizedBox(height: 12),
                TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Home address')),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Why do you want to adopt?',
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : () => _submit(pet),
                    child: _submitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Application'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}
