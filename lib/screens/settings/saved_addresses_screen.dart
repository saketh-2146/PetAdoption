import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../models/address.dart';
import 'address_form_screen.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    if (uid == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Addresses', style: nunito(size: 18, weight: FontWeight.w800, color: textColor)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressFormScreen())),
          ),
        ],
      ),
      body: StreamBuilder<List<Address>>(
        stream: FirestoreService().streamAddresses(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final addresses = snapshot.data ?? [];
          if (addresses.isEmpty) {
            return Center(
              child: Text('No saved addresses.', style: outfit(size: 16, color: AppColors.muted)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Dismissible(
                key: Key(address.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: AppColors.error,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  FirestoreService().deleteAddress(uid, address.id);
                },
                child: _buildAddressCard(context, address, uid),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, Address address, String uid) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Text(address.title, style: nunito(size: 16, weight: FontWeight.w800, color: isDark ? Colors.white : AppColors.dark)),
            if (address.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primaryPale, borderRadius: BorderRadius.circular(8)),
                child: Text('Default', style: outfit(size: 11, color: AppColors.primary, weight: FontWeight.w700)),
              )
            ]
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text('${address.street}\n${address.city}, ${address.state} ${address.zipCode}', 
              style: outfit(size: 14, color: isDark ? Colors.white70 : AppColors.darkMid)),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: isDark ? Colors.white70 : AppColors.muted),
          onSelected: (val) {
            if (val == 'edit') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddressFormScreen(address: address)));
            } else if (val == 'default') {
              FirestoreService().markAddressDefault(uid, address.id);
            } else if (val == 'delete') {
              FirestoreService().deleteAddress(uid, address.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            if (!address.isDefault)
              const PopupMenuItem(value: 'default', child: Text('Set as Default')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
