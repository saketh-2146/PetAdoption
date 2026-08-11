import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../models/address.dart';
import '../../widgets/custom_button.dart';

class AddressFormScreen extends StatefulWidget {
  final Address? address;
  const AddressFormScreen({super.key, this.address});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  
  bool _isDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _titleController.text = widget.address!.title;
      _streetController.text = widget.address!.street;
      _cityController.text = widget.address!.city;
      _stateController.text = widget.address!.state;
      _zipController.text = widget.address!.zipCode;
      _isDefault = widget.address!.isDefault;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final data = {
          'title': _titleController.text.trim(),
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'zipCode': _zipController.text.trim(),
          'isDefault': _isDefault,
        };

        if (widget.address == null) {
          await FirestoreService().addAddress(uid, data);
        } else {
          await FirestoreService().updateAddress(uid, widget.address!.id, data);
        }
        
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address', 
            style: nunito(size: 18, weight: FontWeight.w800, color: isDark ? Colors.white : AppColors.dark)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title (e.g., Home, Work)'),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Street Address'),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'State'),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zipController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Zip Code'),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('Set as Default Address', style: outfit()),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                activeTrackColor: AppColors.primary,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  onPressed: _isSaving ? () {} : _save,
                  text: 'Save Address',
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
