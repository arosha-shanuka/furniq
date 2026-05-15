import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  // Get all products
  Future<List<Product>> getAll() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Get all products error: $e');
      return [];
    }
  }

  // Get single product
  Future<Product?> getById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return Product.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Get product error: $e');
      return null;
    }
  }

  // Add product
  Future<String?> addProduct(Map<String, dynamic> data) async {
    try {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      final doc = await _firestore.collection(_collection).add(data);
      
      // Auto-increment the category item count
      if (data['categoryId'] != null) {
        await _firestore.collection('categories').doc(data['categoryId']).update({
          'itemCount': FieldValue.increment(1),
        });
      }
      
      return doc.id;
    } catch (e) {
      debugPrint('Add product error: $e');
      return null;
    }
  }

  // Update product
  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      // Check if categoryId changed
      String? oldCategoryId;
      if (data.containsKey('categoryId')) {
        final oldDoc = await _firestore.collection(_collection).doc(id).get();
        if (oldDoc.exists) {
          oldCategoryId = oldDoc.data()?['categoryId'];
        }
      }

      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).doc(id).update(data);

      // Auto-update category counts if category changed
      if (data.containsKey('categoryId') && oldCategoryId != null && oldCategoryId != data['categoryId']) {
        // Decrement old category
        await _firestore.collection('categories').doc(oldCategoryId).update({
          'itemCount': FieldValue.increment(-1),
        }).catchError((_) {}); // Ignore if category doesn't exist
        
        // Increment new category
        await _firestore.collection('categories').doc(data['categoryId']).update({
          'itemCount': FieldValue.increment(1),
        }).catchError((_) {});
      }

      return true;
    } catch (e) {
      debugPrint('Update product error: $e');
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String id) async {
    try {
      // Get categoryId before deleting to decrement count
      final oldDoc = await _firestore.collection(_collection).doc(id).get();
      final categoryId = oldDoc.data()?['categoryId'];

      await _firestore.collection(_collection).doc(id).delete();

      // Decrement the category item count
      if (categoryId != null) {
        await _firestore.collection('categories').doc(categoryId).update({
          'itemCount': FieldValue.increment(-1),
        }).catchError((_) {});
      }

      return true;
    } catch (e) {
      debugPrint('Delete product error: $e');
      return false;
    }
  }

  // Get product count
  Future<int> getProductCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Get product count error: $e');
      return 0;
    }
  }
}
