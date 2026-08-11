import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      
      final appUserDoc = await FirestoreService().user(user.uid).first;
      if (appUserDoc != null) {
        _nameController.text = appUserDoc.name;
        _mobileController.text = appUserDoc.mobileNumber ?? '';
        _addressController.text = appUserDoc.address ?? '';
        _cityController.text = appUserDoc.city ?? '';
        _stateController.text = appUserDoc.state ?? '';
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update Firebase Auth profile
        await user.updateDisplayName(_nameController.text.trim());

        // Update Firestore profile
        await FirestoreService().updateUserProfile(user.uid, {
          'name': _nameController.text.trim(),
          'mobileNumber': _mobileController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: nunito(size: 18, weight: FontWeight.w800, color: isDark ? Colors.white : AppColors.dark)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primaryPale,
                            child: Icon(Icons.person, size: 50, color: AppColors.primary),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              child: const Icon(Icons.edit, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: email,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        fillColor: isDark ? AppColors.darkMid.withValues(alpha: 0.5) : AppColors.warm,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(labelText: 'Mobile Number'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(labelText: 'City'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(labelText: 'State'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        onPressed: _isSaving ? () {} : _saveProfile,
                        text: 'Save Changes',
                        isLoading: _isSaving,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
