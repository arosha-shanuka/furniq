import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart' as model;

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';

  // Get all categories
  Future<List<model.Category>> getAll() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs
          .map((doc) => model.Category.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Get all categories error: $e');
      return [];
    }
  }

  // Add category with custom ID
  Future<bool> addCategory(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).set(data);
      return true;
    } catch (e) {
      debugPrint('Add category error: $e');
      return false;
    }
  }

  // Update category
  Future<bool> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).update(data);
      return true;
    } catch (e) {
      debugPrint('Update category error: $e');
      return false;
    }
  }

  // Delete category
  Future<bool> deleteCategory(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Delete category error: $e');
      return false;
    }
  }

  // Get category count
  Future<int> getCategoryCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Get category count error: $e');
      return 0;
    }
  }
}
