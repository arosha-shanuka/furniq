import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload product main image
  Future<String?> uploadProductImage(
      String productId, Uint8List bytes, String filename) async {
    try {
      final ext = filename.split('.').last;
      final ref = _storage.ref('products/$productId/main.$ext');
      final metadata = SettableMetadata(
        contentType: _getContentType(ext),
      );
      await ref.putData(bytes, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload product image error: $e');
      return null;
    }
  }

  // Upload additional product image
  Future<String?> uploadAdditionalImage(
      String productId, Uint8List bytes, String filename, int index) async {
    try {
      final ext = filename.split('.').last;
      final ref = _storage.ref('products/$productId/extra_$index.$ext');
      final metadata = SettableMetadata(
        contentType: _getContentType(ext),
      );
      await ref.putData(bytes, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload additional image error: $e');
      return null;
    }
  }

  // Upload 3D model file (.glb)
  Future<String?> uploadArModel(
      String productId, Uint8List bytes, String filename) async {
    try {
      final ext = filename.split('.').last;
      final ref = _storage.ref('products/$productId/model.$ext');
      final metadata = SettableMetadata(
        contentType: 'model/gltf-binary',
      );
      await ref.putData(bytes, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload AR model error: $e');
      return null;
    }
  }

  // Upload category thumbnail
  Future<String?> uploadCategoryImage(
      String categoryId, Uint8List bytes, String filename) async {
    try {
      final ext = filename.split('.').last;
      final ref = _storage.ref('categories/$categoryId.$ext');
      final metadata = SettableMetadata(
        contentType: _getContentType(ext),
      );
      await ref.putData(bytes, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload category image error: $e');
      return null;
    }
  }

  // Delete product folder
  Future<void> deleteProductFiles(String productId) async {
    try {
      final ref = _storage.ref('products/$productId');
      final result = await ref.listAll();
      for (final item in result.items) {
        await item.delete();
      }
    } catch (e) {
      debugPrint('Delete product files error: $e');
    }
  }

  String _getContentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'glb':
        return 'model/gltf-binary';
      case 'gltf':
        return 'model/gltf+json';
      default:
        return 'application/octet-stream';
    }
  }
}
