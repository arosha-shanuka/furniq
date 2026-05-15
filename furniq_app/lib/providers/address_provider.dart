import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';

class AddressProvider with ChangeNotifier {
  final AddressService _addressService = AddressService();

  List<Address> _addresses = [];
  Address? _defaultAddress;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Address>>? _subscription;

  List<Address> get addresses => _addresses;
  Address? get defaultAddress => _defaultAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Start streaming addresses for a user.
  void listenToAddresses(String userId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _addressService.streamUserAddresses(userId).listen(
      (addresses) {
        _addresses = addresses;
        _defaultAddress = addresses.where((a) => a.isDefault).firstOrNull ??
            (addresses.isNotEmpty ? addresses.first : null);
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Load addresses once (non-streaming).
  Future<void> loadAddresses(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _addresses = await _addressService.getUserAddresses(userId);
      _defaultAddress = _addresses.where((a) => a.isDefault).firstOrNull ??
          (_addresses.isNotEmpty ? _addresses.first : null);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load just the default address (for checkout pre-fill).
  Future<void> loadDefaultAddress(String userId) async {
    try {
      _defaultAddress = await _addressService.getDefaultAddress(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Load default address error: $e');
    }
  }

  /// Create a new address. Auto-numbers the label if a duplicate exists.
  Future<bool> createAddress(Address address) async {
    try {
      _error = null;

      // Auto-number duplicate labels: Home → Home 2 → Home 3, etc.
      final uniqueLabel = _getUniqueLabel(address.label);
      final addressToSave = uniqueLabel != address.label
          ? address.copyWith(label: uniqueLabel)
          : address;

      final created = await _addressService.createAddress(addressToSave);
      
      // If it's the first address or set as default, update default
      if (address.isDefault || _addresses.isEmpty) {
        _defaultAddress = created;
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Returns a unique label by appending a number if duplicates exist.
  String _getUniqueLabel(String baseLabel) {
    final existingLabels = _addresses.map((a) => a.label).toSet();

    if (!existingLabels.contains(baseLabel)) return baseLabel;

    for (int i = 2; i <= 99; i++) {
      final candidate = '$baseLabel $i';
      if (!existingLabels.contains(candidate)) return candidate;
    }

    return '$baseLabel ${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Update an existing address.
  Future<bool> updateAddress(Address address) async {
    try {
      _error = null;
      await _addressService.updateAddress(address);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete an address.
  Future<bool> deleteAddress(String addressId) async {
    try {
      _error = null;
      await _addressService.deleteAddress(addressId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Set an address as default.
  Future<void> setDefault(String userId, String addressId) async {
    try {
      await _addressService.setDefaultAddress(userId, addressId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Clear all local state (e.g. on logout)
  void clear() {
    _addresses = [];
    _defaultAddress = null;
    _subscription?.cancel();
    notifyListeners();
  }
}
