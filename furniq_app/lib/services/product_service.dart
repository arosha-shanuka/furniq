import 'package:flutter/foundation.dart' hide Category;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all categories
  Future<List<Category>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      return snapshot.docs
          .map((doc) => Category.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Get categories error: $e');
      return [];
    }
  }

  // Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Get products error: $e');
      return [];
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('categoryId', isEqualTo: categoryId)
          .get();
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Get products by category error: $e');
      return [];
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final doc =
          await _firestore.collection('products').doc(productId).get();
      if (!doc.exists || doc.data() == null) return null;
      return Product.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Get product by ID error: $e');
      return null;
    }
  }

  // Search products (client-side filter on Firestore results)
  Future<List<Product>> searchProducts(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .where((p) =>
              p.name.toLowerCase().contains(lowerQuery) ||
              p.description.toLowerCase().contains(lowerQuery) ||
              p.material.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      debugPrint('Search products error: $e');
      return [];
    }
  }

  // Get featured products
  Future<List<Product>> getFeaturedProducts() async {
    try {
      // Try to get products marked as featured first
      final snapshot = await _firestore
          .collection('products')
          .where('isFeatured', isEqualTo: true)
          .limit(4)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => Product.fromMap(doc.data(), doc.id))
            .toList();
      }

      // Fallback: return first 4 products
      final fallbackSnapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(4)
          .get();
      return fallbackSnapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Get featured products error: $e');
      return [];
    }
  }
}
