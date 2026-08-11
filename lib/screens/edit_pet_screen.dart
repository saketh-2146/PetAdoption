import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/pet.dart';
import '../services/firestore_service.dart';
import '../services/supabase_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class EditPetScreen extends StatefulWidget {
  final Pet pet;
  const EditPetScreen({super.key, required this.pet});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _breed;
  late final TextEditingController _age;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _pincode;
  late final TextEditingController _state;
  late final TextEditingController _district;
  late final TextEditingController _mandal;
  late final TextEditingController _village;
  late final TextEditingController _landmark;
  late final TextEditingController _contactEmail;
  late final TextEditingController _contactMobile;
  
  late String _species;
  late String _gender;
  bool _saving = false;
  
  // Image selection
  final ImagePicker _picker = ImagePicker();
  late List<String> _existingImages;
  final List<String> _imagesToDelete = [];
  final List<XFile> _newImages = [];
  bool _isUploading = false;
  int _uploadProgressCount = 0;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.pet.name);
    _breed = TextEditingController(text: widget.pet.breed);
    _age = TextEditingController(text: widget.pet.age);
    _price = TextEditingController(text: widget.pet.adoptionFee?.toStringAsFixed(0) ?? '');
    _description = TextEditingController(text: widget.pet.description);
    _pincode = TextEditingController(text: widget.pet.pincode ?? '');
    _state = TextEditingController(text: widget.pet.state ?? '');
    _district = TextEditingController(text: widget.pet.district ?? '');
    _mandal = TextEditingController(text: widget.pet.mandal ?? '');
    _village = TextEditingController(text: widget.pet.village ?? '');
    _landmark = TextEditingController(text: widget.pet.landmark ?? '');
    _contactEmail = TextEditingController(text: widget.pet.contactEmail ?? '');
    _contactMobile = TextEditingController(text: widget.pet.contactMobile ?? '');
    _species = widget.pet.species;
    _gender = widget.pet.gender;
    
    _existingImages = List.from(
      (widget.pet.imageUrls != null && widget.pet.imageUrls!.isNotEmpty) 
        ? widget.pet.imageUrls! 
        : (widget.pet.galleryIds.isEmpty ? [widget.pet.imageId] : widget.pet.galleryIds)
    );
  }

  @override
  void dispose() {
    for (final c in [_name, _breed, _age, _price, _description, _contactEmail, _contactMobile, _pincode, _state, _district, _mandal, _village, _landmark]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _totalImagesCount => _existingImages.length + _newImages.length;

  Future<void> _pickImages() async {
    if (_totalImagesCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only select up to 5 images in total.')),
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
          imageQuality: 70, // Built-in compression
        );
        
        if (!mounted) return;
        if (images.isNotEmpty) {
          setState(() {
            final remainingSlots = 5 - _totalImagesCount;
            _newImages.addAll(images.take(remainingSlots));
          });
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
        );
        if (!mounted) return;
        if (image != null) {
          setState(() {
            _newImages.add(image);
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

  void _removeExistingImage(int index) {
    setState(() {
      _imagesToDelete.add(_existingImages[index]);
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_totalImagesCount == 0) {
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
      // Upload new images
      final List<String> newlyUploadedUrls = [];
      for (int i = 0; i < _newImages.length; i++) {
        final image = _newImages[i];
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${timestamp}_$i.jpg';
        
        try {
          final url = await SupabaseStorageService().uploadPetImage(
            imageFile: image,
            userId: user.uid,
            petId: widget.pet.id,
            fileName: fileName,
          );
          newlyUploadedUrls.add(url);
          setState(() {
            _uploadProgressCount++;
          });
        } catch (uploadError) {
          throw Exception('Failed to upload image ${i + 1} (${image.name}): $uploadError');
        }
      }

      final finalImageUrls = [..._existingImages, ...newlyUploadedUrls];
      final priceValue = double.tryParse(_price.text.trim()) ?? 0;
      final locationStr = '${_village.text.trim()}, ${_mandal.text.trim()}, ${_district.text.trim()}, ${_state.text.trim()} - ${_pincode.text.trim()}';
      
      final updatedPet = Pet(
        id: widget.pet.id,
        name: _name.text.trim(),
        breed: _breed.text.trim(),
        species: _species,
        age: _age.text.trim(),
        gender: _gender,
        price: null,
        adoptionFee: priceValue,
        type: widget.pet.type,
        location: locationStr,
        distance: widget.pet.distance,
        imageId: widget.pet.imageId, 
        galleryIds: widget.pet.galleryIds, 
        imageUrls: finalImageUrls, // updated URLs
        description: _description.text.trim(),
        owner: widget.pet.owner,
        health: widget.pet.health,
        personality: widget.pet.personality,
        color: widget.pet.color,
        weight: widget.pet.weight,
        category: '${_species[0].toUpperCase()}${_species.substring(1)}s',
        listedByUid: widget.pet.listedByUid,
        status: widget.pet.status,
        contactEmail: _contactEmail.text.trim(),
        contactMobile: _contactMobile.text.trim(),
        pincode: _pincode.text.trim(),
        state: _state.text.trim(),
        district: _district.text.trim(),
        mandal: _mandal.text.trim(),
        village: _village.text.trim(),
        landmark: _landmark.text.trim(),
        createdAt: widget.pet.createdAt,
        approvedAt: widget.pet.approvedAt,
        approvedBy: widget.pet.approvedBy,
      );

      debugPrint('Saving to Firestore...');
      await FirestoreService().updatePet(updatedPet);
      debugPrint('Firestore save successful.');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your pet listing has been updated successfully.', style: outfit()),
            backgroundColor: AppColors.primaryPale,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
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
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('Edit Listing', style: nunito(size: 18, weight: FontWeight.w800)),
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
              if (_totalImagesCount == 0)
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
                        itemCount: _totalImagesCount + (_totalImagesCount < 5 ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _totalImagesCount) {
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
                          
                          // existing image
                          if (index < _existingImages.length) {
                            return Stack(
                              children: [
                                Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image: CachedNetworkImageProvider(widget.pet.galleryUrl(_existingImages[index])),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: () => _removeExistingImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // new image
                            final newIndex = index - _existingImages.length;
                            return Stack(
                              children: [
                                Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image: kIsWeb 
                                          ? NetworkImage(_newImages[newIndex].path) as ImageProvider
                                          : FileImage(File(_newImages[newIndex].path)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: () => _removeNewImage(newIndex),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
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
                              _uploadProgressCount == _newImages.length
                                  ? 'Image uploaded'
                                  : 'Uploading image...',
                              style: outfit(size: 14, color: AppColors.muted),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (_uploadProgressCount) / _newImages.length,
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
                      decoration: const InputDecoration(labelText: 'Species'),
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
                decoration: const InputDecoration(labelText: 'Pet name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _breed,
                decoration: const InputDecoration(labelText: 'Breed'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(controller: _age, decoration: const InputDecoration(labelText: 'Age (e.g. 2 yrs)')),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
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
                      decoration: const InputDecoration(labelText: 'State'),
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
                      decoration: const InputDecoration(labelText: 'District'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _mandal,
                      decoration: const InputDecoration(labelText: 'Mandal'),
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
                      controller: _village,
                      decoration: const InputDecoration(labelText: 'Village/City'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _landmark,
                      decoration: const InputDecoration(labelText: 'Landmark'),
                    ),
                  ),
                ],
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
                  text: 'Update Listing',
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
