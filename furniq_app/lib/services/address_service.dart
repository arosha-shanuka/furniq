import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address_model.dart';

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all addresses for a user, sorted by creation date (newest first).
  Future<List<Address>> getUserAddresses(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('addresses')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint('AddressService: Found ${snapshot.docs.length} addresses for user $userId');

      final addresses = snapshot.docs
          .map((doc) => Address.fromMap(doc.data(), doc.id))
          .toList();

      // Sort in memory to avoid needing a composite Firestore index
      addresses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return addresses;
    } catch (e) {
      debugPrint('Get user addresses error: $e');
      return [];
    }
  }

  /// Stream all addresses for a user in real-time.
  Stream<List<Address>> streamUserAddresses(String userId) {
    return _firestore
        .collection('addresses')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final addresses = snapshot.docs
          .map((doc) => Address.fromMap(doc.data(), doc.id))
          .toList();
      addresses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return addresses;
    });
  }

  /// Create a new address.
  Future<Address> createAddress(Address address) async {
    try {
      // If this address is set as default, unset all others first
      if (address.isDefault) {
        await _unsetAllDefaults(address.userId);
      }

      final docRef = _firestore.collection('addresses').doc();
      await docRef.set(address.toMap());

      debugPrint('Address created: ${docRef.id}');
      return address.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Create address error: $e');
      rethrow;
    }
  }

  /// Update an existing address.
  Future<void> updateAddress(Address address) async {
    try {
      // If this address is set as default, unset all others first
      if (address.isDefault) {
        await _unsetAllDefaults(address.userId);
      }

      await _firestore.collection('addresses').doc(address.id).update({
        'label': address.label,
        'fullName': address.fullName,
        'phone': address.phone,
        'street': address.street,
        'city': address.city,
        'postalCode': address.postalCode,
        'isDefault': address.isDefault,
      });

      debugPrint('Address updated: ${address.id}');
    } catch (e) {
      debugPrint('Update address error: $e');
      rethrow;
    }
  }

  /// Delete an address.
  Future<void> deleteAddress(String addressId) async {
    try {
      await _firestore.collection('addresses').doc(addressId).delete();
      debugPrint('Address deleted: $addressId');
    } catch (e) {
      debugPrint('Delete address error: $e');
      rethrow;
    }
  }

  /// Set an address as the default, unsetting all others.
  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      await _unsetAllDefaults(userId);
      await _firestore.collection('addresses').doc(addressId).update({
        'isDefault': true,
      });
      debugPrint('Default address set: $addressId');
    } catch (e) {
      debugPrint('Set default address error: $e');
      rethrow;
    }
  }

  /// Get the default address for a user.
  Future<Address?> getDefaultAddress(String userId) async {
    try {
      // Get all addresses and find default in memory
      final snapshot = await _firestore
          .collection('addresses')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final addresses = snapshot.docs
          .map((doc) => Address.fromMap(doc.data(), doc.id))
          .toList();

      // Find the default one
      final defaultAddr = addresses.where((a) => a.isDefault).firstOrNull;
      if (defaultAddr != null) return defaultAddr;

      // Fall back to newest address
      addresses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return addresses.first;
    } catch (e) {
      debugPrint('Get default address error: $e');
      return null;
    }
  }

  /// Unset all default addresses for a user.
  Future<void> _unsetAllDefaults(String userId) async {
    final snapshot = await _firestore
        .collection('addresses')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      if (doc.data()['isDefault'] == true) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }
    await batch.commit();
  }
}
