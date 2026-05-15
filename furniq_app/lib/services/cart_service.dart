import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

// Mock cart service - replace with Firestore when configured
class CartService {
  final List<CartItem> _cartItems = [];

  // Get cart items for user
  Future<List<CartItem>> getCartItems(String userId) async {
    try {
      // TODO: Replace with Firestore query
      // final snapshot = await FirebaseFirestore.instance
      //     .collection('cart')
      //     .where('userId', isEqualTo: userId)
      //     .get();
      
      await Future.delayed(const Duration(milliseconds: 300));
      return List.from(_cartItems.where((item) => item.userId == userId));
    } catch (e) {
      debugPrint('Get cart items error: $e');
      return [];
    }
  }

  // Add product to cart
  Future<CartItem> addToCart({
    required String userId,
    required Product product,
    int quantity = 1,
    ProductColor? selectedColor,
  }) async {
    try {
      // Check if item already exists in cart with same product AND color
      final existingIndex = _cartItems.indexWhere(
        (item) => item.userId == userId && 
                  item.productId == product.id && 
                  item.selectedColorHex == selectedColor?.hex,
      );

      if (existingIndex >= 0) {
        // Update quantity
        final existing = _cartItems[existingIndex];
        final updated = existing.copyWith(
          quantity: existing.quantity + quantity,
        );
        _cartItems[existingIndex] = updated;
        
        // TODO: Update in Firestore
        return updated;
      } else {
        // Add new item
        final cartItem = CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          productId: product.id,
          productName: product.name,
          productImage: product.mainImageUrl,
          material: product.material,
          quantity: quantity,
          unitPrice: product.price,
          selectedColorHex: selectedColor?.hex,
          selectedColorName: selectedColor?.name,
        );
        
        _cartItems.add(cartItem);
        
        // TODO: Add to Firestore
        // await FirebaseFirestore.instance
        //     .collection('cart')
        //     .add(cartItem.toMap());
        
        return cartItem;
      }
    } catch (e) {
      debugPrint('Add to cart error: $e');
      rethrow;
    }
  }

  // Update cart item quantity
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    try {
      final index = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (index >= 0) {
        _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      }
      
      // TODO: Update in Firestore
      // await FirebaseFirestore.instance
      //     .collection('cart')
      //     .doc(cartItemId)
      //     .update({'quantity': quantity});
    } catch (e) {
      debugPrint('Update quantity error: $e');
      rethrow;
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String cartItemId) async {
    try {
      _cartItems.removeWhere((item) => item.id == cartItemId);
      
      // TODO: Delete from Firestore
      // await FirebaseFirestore.instance
      //     .collection('cart')
      //     .doc(cartItemId)
      //     .delete();
    } catch (e) {
      debugPrint('Remove from cart error: $e');
      rethrow;
    }
  }

  // Clear cart for user
  Future<void> clearCart(String userId) async {
    try {
      _cartItems.removeWhere((item) => item.userId == userId);
      
      // TODO: Delete all cart items from Firestore
      // final batch = FirebaseFirestore.instance.batch();
      // final snapshot = await FirebaseFirestore.instance
      //     .collection('cart')
      //     .where('userId', isEqualTo: userId)
      //     .get();
      // for (var doc in snapshot.docs) {
      //   batch.delete(doc.reference);
      // }
      // await batch.commit();
    } catch (e) {
      debugPrint('Clear cart error: $e');
      rethrow;
    }
  }
}
