import 'package:flutter/material.dart';
import '../models/category_model.dart' as model;
import '../services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  List<model.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<model.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryService.getAll();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addCategory(String id, Map<String, dynamic> data) async {
    try {
      final success = await _categoryService.addCategory(id, data);
      if (success) await loadCategories();
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      final success = await _categoryService.updateCategory(id, data);
      if (success) await loadCategories();
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      final success = await _categoryService.deleteCategory(id);
      if (success) await loadCategories();
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
