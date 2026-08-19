import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pet.dart';
import '../models/app_notification.dart';
import '../services/firestore_service.dart';
import '../services/supabase_storage_service.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

import '../main.dart';

class SellPetScreen extends StatefulWidget {
  const SellPetScreen({super.key});

  @override
  State<SellPetScreen> createState() => _SellPetScreenState();
}

class _SellPetScreenState extends State<SellPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _age = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _pincode = TextEditingController();
  final _state = TextEditingController();
  final _district = TextEditingController();
  final _village = TextEditingController();
  final _contactEmail = TextEditingController();
  final _contactMobile = TextEditingController();
  
  String _species = 'dog';
  String _gender = 'male';
  bool _saving = false;
  
  // Image selection
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  bool _isUploading = false;
  int _uploadProgressCount = 0;

  @override
  void dispose() {
    for (final c in [_name, _breed, _age, _price, _description, _contactEmail, _contactMobile, _pincode, _state, _district, _village]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only select up to 5 images.')),
      );
      return;
    }
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 70, // Built-in compression to save bandwidth
          maxWidth: 1080, // Downscale massive camera images
          maxHeight: 1080,
        );
        
        if (!mounted) return;
        if (images.isNotEmpty) {
          debugPrint('[SellPetScreen] ${images.length} images selected.');
          setState(() {
            final remainingSlots = 5 - _selectedImages.length;
            _selectedImages.addAll(images.take(remainingSlots));
          });
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
          maxWidth: 1080,
          maxHeight: 1080,
        );
        if (!mounted) return;
        if (image != null) {
          setState(() {
            _selectedImages.add(image);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _saving = true;
      _isUploading = true;
      _uploadProgressCount = 0;
    });

    try {
      final List<String> uploadedUrls = [];
      
      final newPetId = FirebaseFirestore.instance.collection('pets').doc().id;

      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${timestamp}_$i.jpg';
        
        try {
          final url = await SupabaseStorageService().uploadPetImage(
            imageFile: image,
            userId: user.uid,
            petId: newPetId,
            fileName: fileName,
          );
          uploadedUrls.add(url);
          setState(() {
            _uploadProgressCount++;
          });
        } catch (uploadError) {
          throw Exception('Failed to upload image ${i + 1} (${image.name}): $uploadError');
        }
      }

      final priceValue = double.tryParse(_price.text.trim()) ?? 0;
      final locationStr = '${_village.text.trim()}, ${_district.text.trim()}, ${_state.text.trim()} - ${_pincode.text.trim()}';
      
      final pet = Pet(
        id: newPetId,
        name: _name.text.trim(),
        breed: _breed.text.trim(),
        species: _species,
        age: _age.text.trim(),
        gender: _gender,
        price: null,
        adoptionFee: priceValue,
        type: 'adopt',
        location: locationStr,
        distance: '0 km',
        imageId: '', // Legacy Unsplash ID left empty
        galleryIds: const [], // Legacy
        imageUrls: uploadedUrls, // The newly uploaded backend URLs
        description: _description.text.trim(),
        owner: PetOwner(
          name: user.displayName ?? 'You',
          avatarId: '1535713875-d780bfbbd5d4', // Can also be updated in future
          rating: 5.0,
          reviews: 0,
          memberSince: 'This year',
          verified: false,
        ),
        health: const PetHealth(vaccinated: false, neutered: false, dewormed: false, microchipped: false),
        personality: const [],
        color: '',
        weight: '',
        category: '${_species[0].toUpperCase()}${_species.substring(1)}s',
        listedByUid: user.uid,
        status: 'Pending',
        contactEmail: _contactEmail.text.trim(),
        contactMobile: _contactMobile.text.trim(),
        pincode: _pincode.text.trim(),
        state: _state.text.trim(),
        village: _village.text.trim(),
      );

      debugPrint('Saving to Firestore...');
      await FirestoreService().addPet(pet);
      debugPrint('Firestore save successful.');
      
      // Notify the user about the live status
      await FirestoreService().addNotification(
        user.uid,
        AppNotification(
          id: '',
          type: 'system',
          title: 'Listing Live! 🎉',
          body: 'Your pet listing for ${pet.name} is now live on the marketplace and home page.',
          time: null,
          read: false,
        ),
      );

      // Notify all admins (query by role field)
      try {
        final adminsQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .get();
        for (final adminDoc in adminsQuery.docs) {
          await FirestoreService().addNotification(
            adminDoc.id,
            AppNotification(
              id: '',
              type: 'system',
              title: 'New Pet Listing Pending Review 🐾',
              body: '${user.displayName ?? 'A seller'} has listed ${pet.name} and is awaiting your approval.',
              time: null,
              read: false,
            ),
          );
        }
      } catch (adminNotifError) {
        debugPrint('[SellPetScreen] Failed to notify admins: $adminNotifError');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your pet listing has been submitted and is now pending admin approval. You\'ll be notified once it goes live!', style: outfit()),
            backgroundColor: AppColors.primaryPale,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Upload Error'),
          content: SingleChildScrollView(
            child: Text(e.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text('List a Pet', style: nunito(size: 18, weight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Upload Section
              if (_selectedImages.isEmpty)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.warm,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.warmBorder, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo, size: 40, color: AppColors.muted),
                        const SizedBox(height: 12),
                        Text('Upload Pet Photos (Max 5)', style: nunito(size: 14, color: AppColors.muted)),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length + (_selectedImages.length < 5 ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length) {
                            return GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.warm,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.warmBorder),
                                ),
                                child: const Icon(Icons.add, size: 32, color: AppColors.muted),
                              ),
                            );
                          }
                          return Stack(
                            children: [
                              Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(
                                    image: kIsWeb 
                                        ? NetworkImage(_selectedImages[index].path) as ImageProvider
                                        : FileImage(File(_selectedImages[index].path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (_isUploading)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _uploadProgressCount == _selectedImages.length
                                  ? 'Image uploaded'
                                  : 'Uploading image...',
                              style: outfit(size: 14, color: AppColors.muted),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (_uploadProgressCount) / _selectedImages.length,
                              backgroundColor: AppColors.warmBorder,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 32),
              
              Text('Basic Information', style: nunito(size: 18, weight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _species,
                      decoration: const InputDecoration(labelText: 'Species', prefixIcon: Icon(Icons.pets, color: AppColors.muted)),
                      items: const [
                        DropdownMenuItem(value: 'dog', child: Text('Dog')),
                        DropdownMenuItem(value: 'cat', child: Text('Cat')),
                        DropdownMenuItem(value: 'rabbit', child: Text('Rabbit')),
                        DropdownMenuItem(value: 'bird', child: Text('Bird')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _species = v ?? 'dog'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Pet name', prefixIcon: Icon(Icons.badge_outlined, color: AppColors.muted)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _breed,
                decoration: const InputDecoration(labelText: 'Breed', prefixIcon: Icon(Icons.category_outlined, color: AppColors.muted)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(controller: _age, decoration: const InputDecoration(labelText: 'Age (e.g. 2 yrs)', prefixIcon: Icon(Icons.cake_outlined, color: AppColors.muted))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.transgender_outlined, color: AppColors.muted)),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? 'male'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Adoption fee (INR)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (v) => (v == null || double.tryParse(v.trim()) == null) ? 'Enter a number' : null,
              ),
              const SizedBox(height: 32),
              
              Text('Details & Location', style: nunito(size: 18, weight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pincode,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Pincode', prefixIcon: Icon(Icons.pin_drop_outlined)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _state,
                      decoration: const InputDecoration(labelText: 'State', prefixIcon: Icon(Icons.map_outlined, color: AppColors.muted)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _district,
                      decoration: const InputDecoration(labelText: 'District', prefixIcon: Icon(Icons.location_city_outlined, color: AppColors.muted)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _village,
                decoration: const InputDecoration(labelText: 'Village/City', prefixIcon: Icon(Icons.holiday_village_outlined, color: AppColors.muted)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              Text('Contact Information', style: nunito(size: 18, weight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty || !v.contains('@')) ? 'Valid email required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactMobile,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty || v.trim().length < 10) ? 'Valid mobile number required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  onPressed: () => _submit(),
                  text: 'Publish Listing',
                  isLoading: _saving,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
