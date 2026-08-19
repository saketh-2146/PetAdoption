import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/pet.dart';
import '../models/app_notification.dart';
import '../services/firestore_service.dart';
import '../services/email_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../config/api_config.dart';

class AdoptionScreen extends StatefulWidget {
  final String petId;
  const AdoptionScreen({super.key, required this.petId});

  @override
  State<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  final _formKey = GlobalKey<FormState>();
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

  Future<void> _submit(Pet pet) async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to apply.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // ── Send application to Node.js Backend ─────────────────────────────────
      final backendPayload = {
        'applicantUid': user.uid,
        'applicantEmail': user.email ?? '',
        'applicantName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'note': _noteCtrl.text.trim(),
        'petName': pet.name,
        'petBreed': pet.breed,
        'type': pet.type,
      };

      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/applications'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(backendPayload),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 201) {
          debugPrint('[AdoptionScreen] Backend returned status ${response.statusCode} — continuing with Firestore.');
        } else {
          debugPrint('[AdoptionScreen] Backend acknowledged application successfully.');
        }
      } catch (e) {
        // Backend is unavailable or timed out — log and continue with Firestore.
        // Do NOT block the adoption for a backend issue.
        debugPrint('[AdoptionScreen] Node.js backend unavailable ($e) — proceeding with Firestore only.');
      }

      // Save application to Firestore under the pet's subcollection
      // and capture the document reference to get the ID
      final appDocRef = await FirebaseFirestore.instance
          .collection('pets')
          .doc(pet.id)
          .collection('applications')
          .add({
        'applicantUid': user.uid,
        'applicantEmail': user.email ?? '',
        'applicantName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'note': _noteCtrl.text.trim(),
        'petName': pet.name,
        'petBreed': pet.breed,
        'type': pet.type,
        'status': 'approved',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // ── Immediately mark pet as Adopted → removes from marketplace ─────────
      // The home screen only streams status == 'Approved' pets, so changing
      // to 'Adopted' hides it instantly for all users.
      await _firestore.markPetAdopted(pet.id, appDocRef.id);

      // ── Notify the buyer (applicant) ──────────────────────────────────────
      await _firestore.addNotification(
        user.uid,
        AppNotification(
          id: '',
          type: 'adoption',
          title: 'Application Submitted 🐾',
          body:
              'Your adoption request for ${pet.name} has been sent to the seller. '
              'They will contact you at ${_phoneCtrl.text.trim()} shortly.',
          time: null,
          read: false,
          imageId: pet.imageUrls?.isNotEmpty == true
              ? pet.imageUrls!.first
              : pet.imageId,
        ),
      );

      // ── Notify the seller with full applicant details ─────────────────────
      if (pet.listedByUid != null) {
        await _firestore.addNotification(
          pet.listedByUid!,
          AppNotification(
            id: '',
            type: 'adoption',
            title: '🎉 New Adoption Request for ${pet.name}!',
            body: 'Applicant: ${_nameCtrl.text.trim()}\n'
                'Email: ${user.email ?? 'Not provided'}\n'
                'Phone: ${_phoneCtrl.text.trim()}\n'
                'Address: ${_addressCtrl.text.trim()}\n'
                'Message: ${_noteCtrl.text.trim().isEmpty ? 'No message provided.' : _noteCtrl.text.trim()}',
            time: null,
            read: false,
            imageId: pet.imageUrls?.isNotEmpty == true
                ? pet.imageUrls!.first
                : pet.imageId,
          ),
        );
      }

      // ── Fetch Seller's Registered Email ───────────────────────────────────
      String? sellerRegisteredEmail;
      if (pet.listedByUid != null) {
        try {
          final sellerDoc = await FirebaseFirestore.instance.collection('users').doc(pet.listedByUid).get();
          if (sellerDoc.exists && sellerDoc.data() != null) {
            sellerRegisteredEmail = sellerDoc.data()!['email'] as String?;
          }
        } catch (e) {
          debugPrint('[AdoptionScreen] Failed to fetch seller email: $e');
        }
      }
      
      // Fallback to pet's contact email if registered email is missing
      final emailToSendTo = sellerRegisteredEmail ?? pet.contactEmail;

      // ── Send Email to the seller via Brevo (best-effort — non-fatal) ────────
      // If the API key is invalid or Brevo is unreachable, we log the error
      // but do NOT block the adoption — the application is already saved.
      if (emailToSendTo != null && emailToSendTo.isNotEmpty) {
        try {
          await EmailService.sendAdoptionEmail(
            sellerEmail: emailToSendTo,
            petName: pet.name,
            applicantName: _nameCtrl.text.trim(),
            applicantPhone: _phoneCtrl.text.trim(),
            applicantEmail: user.email ?? 'Not provided',
            applicantAddress: _addressCtrl.text.trim(),
            note: _noteCtrl.text.trim(),
          );
        } catch (emailError) {
          // Email failed (e.g. invalid API key) — adoption is already saved,
          // notifications are sent. Just log and continue.
          debugPrint('[EmailService] Failed to send adoption email: $emailError');
        }
      }

      if (mounted) {
        // Show success dialog with seller contact info
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 10),
                Text('Application Sent!', style: nunito(size: 18, weight: FontWeight.w800)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your application for ${pet.name} has been submitted successfully.',
                  style: outfit(size: 14, color: AppColors.darkMid),
                ),
                const SizedBox(height: 16),
                Text('Seller Contact Details', style: nunito(size: 14, weight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (pet.contactMobile != null && pet.contactMobile!.isNotEmpty)
                  _successDetailRow(Icons.phone_outlined, 'Phone', pet.contactMobile!),
                if (pet.contactEmail != null && pet.contactEmail!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _successDetailRow(Icons.email_outlined, 'Email', pet.contactEmail!),
                ],
                if (pet.location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _successDetailRow(Icons.location_on_outlined, 'Location', pet.location),
                ],
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  child: Text('Done', style: nunito(size: 16, weight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit application: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _successDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: outfit(size: 11, color: AppColors.muted)),
              Text(value, style: outfit(size: 13, weight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
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
              Text(value,
                  style: outfit(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppColors.dark)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Adoption Application',
            style: nunito(size: 16, weight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: StreamBuilder<Pet?>(
        stream: _firestore.pet(widget.petId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          final pet = snapshot.data;
          if (pet == null) {
            return Center(
              child: Text('Pet not found.',
                  style: outfit(size: 16, color: AppColors.muted)),
            );
          }

          return Theme(
            data: AppTheme.light,
            child: Form(
              key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Pet summary card ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.warmBorder),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.dark.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            pet.imageUrl(w: 200, q: 70),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 64,
                              height: 64,
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
                                  style: nunito(
                                      size: 16, weight: FontWeight.w800)),
                              Text('${pet.breed} · ${pet.age}',
                                  style: outfit(
                                      size: 13, color: AppColors.muted)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 13, color: AppColors.primary),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(pet.location,
                                        style: outfit(
                                            size: 12,
                                            color: AppColors.darkMid),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${pet.adoptionFee?.toStringAsFixed(0) ?? '0'}',
                          style: nunito(
                              size: 20,
                              weight: FontWeight.w900,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Seller Contact Details ────────────────────────────────
                  Text('Seller Contact Details',
                      style: nunito(size: 15, weight: FontWeight.w800)),
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
                        _buildDetailRow(Icons.person_outline, 'Listed By',
                            pet.owner.name),
                        if (pet.contactMobile != null &&
                            pet.contactMobile!.isNotEmpty) ...[
                          const Divider(
                              height: 24, color: AppColors.warmBorder),
                          _buildDetailRow(Icons.phone_outlined,
                              'Contact Number', pet.contactMobile!),
                        ],
                        if (pet.contactEmail != null &&
                            pet.contactEmail!.isNotEmpty) ...[
                          const Divider(
                              height: 24, color: AppColors.warmBorder),
                          _buildDetailRow(Icons.email_outlined,
                              'Email Address', pet.contactEmail!),
                        ],
                        const Divider(height: 24, color: AppColors.warmBorder),
                        _buildDetailRow(
                            Icons.location_on_outlined, 'Location', pet.location),
                        const Divider(height: 24, color: AppColors.warmBorder),
                        _buildDetailRow(
                          Icons.medical_services_outlined,
                          'Health Info',
                          'Vaccinated: ${pet.health.vaccinated ? '✅ Yes' : '❌ No'}  '
                              'Neutered: ${pet.health.neutered ? '✅ Yes' : '❌ No'}\n'
                              'Dewormed: ${pet.health.dewormed ? '✅ Yes' : '❌ No'}  '
                              'Microchipped: ${pet.health.microchipped ? '✅ Yes' : '❌ No'}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Your Information ──────────────────────────────────────
                  Text('Your Information',
                      style: nunito(size: 15, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('The seller will use this to contact you.',
                      style: outfit(size: 13, color: AppColors.muted)),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 10) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Home Address *',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Why do you want to adopt? (Optional)',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.edit_note_outlined),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _submitting ? null : () => _submit(pet),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Submit Application',
                              style: nunito(
                                  size: 16,
                                  weight: FontWeight.w800,
                                  color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }
}
