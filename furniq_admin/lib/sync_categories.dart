import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  print('Starting category count sync...');
  
  final firestore = FirebaseFirestore.instance;
  
  try {
    // 1. Get all products
    final productsSnapshot = await firestore.collection('products').get();
    
    // Count products by category
    Map<String, int> categoryCounts = {};
    for (var doc in productsSnapshot.docs) {
      final categoryId = doc.data()['categoryId'] as String?;
      if (categoryId != null && categoryId.isNotEmpty) {
        categoryCounts[categoryId] = (categoryCounts[categoryId] ?? 0) + 1;
      }
    }
    
    // 2. Get all categories
    final categoriesSnapshot = await firestore.collection('categories').get();
    
    // 3. Update each category with the exact count
    for (var doc in categoriesSnapshot.docs) {
      final actualCount = categoryCounts[doc.id] ?? 0;
      final currentCount = doc.data()['itemCount'] ?? 0;
      
      print('Category ${doc.data()['name']} (ID: ${doc.id}): DB says $currentCount, actual is $actualCount');
      
      if (actualCount != currentCount) {
        await doc.reference.update({'itemCount': actualCount});
        print('Updated ${doc.data()['name']} to $actualCount items.');
      }
    }
    
    print('Sync complete!');
  } catch (e) {
    print('Error syncing categories: $e');
  }
}
