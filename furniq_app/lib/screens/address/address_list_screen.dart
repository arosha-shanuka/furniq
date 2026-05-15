import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/address_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      Provider.of<AddressProvider>(context, listen: false)
          .listenToAddresses(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Addresses')),
      body: Consumer<AddressProvider>(
        builder: (context, addressProvider, _) {
          if (addressProvider.isLoading && addressProvider.addresses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (addressProvider.addresses.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: addressProvider.addresses.length,
                  itemBuilder: (context, index) {
                    final address = addressProvider.addresses[index];
                    return _buildAddressCard(context, address, addressProvider);
                  },
                ),
              ),
              _buildAddButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No saved addresses',
                  style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add an address to make checkout faster',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildAddressCard(BuildContext context, Address address, AddressProvider provider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: address.isDefault
            ? const BorderSide(color: AppColors.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  address.label.toLowerCase() == 'office'
                      ? Icons.business_outlined
                      : Icons.home_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  address.label,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(color: AppColors.textLight, fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(address.fullName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(address.street, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            Text('${address.city} ${address.postalCode}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            if (address.phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(address.phone, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (!address.isDefault)
                  TextButton.icon(
                    onPressed: () async {
                      await provider.setDefault(authProvider.user!.id, address.id);
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Set as Default'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.addressForm, arguments: address);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.textSecondary,
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context, address, provider),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Address address, AddressProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${address.label}" address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteAddress(address.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, AppRouter.addressForm, arguments: null);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add New Address'),
        ),
      ),
    );
  }
}
