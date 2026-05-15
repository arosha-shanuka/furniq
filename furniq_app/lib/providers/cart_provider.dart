import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;

  // Calculate subtotal
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Calculate tax (8%)
  double get tax {
    return subtotal * 0.08;
  }

  // Delivery fee
  double get deliveryFee => 0.0; // Free delivery

  // Calculate total
  double get total {
    return subtotal + tax + deliveryFee;
  }

  // Load cart items
  Future<void> loadCart(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _items = await _cartService.getCartItems(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add product to cart
  Future<bool> addToCart({
    required String userId,
    required Product product,
    int quantity = 1,
    ProductColor? selectedColor,
  }) async {
    try {
      final cartItem = await _cartService.addToCart(
        userId: userId,
        product: product,
        quantity: quantity,
        selectedColor: selectedColor,
      );

      // Reload cart
      await loadCart(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update item quantity
  Future<void> updateQuantity(String userId, String cartItemId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeItem(userId, cartItemId);
        return;
      }

      await _cartService.updateQuantity(cartItemId, quantity);
      await loadCart(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Remove item from cart
  Future<void> removeItem(String userId, String cartItemId) async {
    try {
      await _cartService.removeFromCart(cartItemId);
      await loadCart(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear cart
  Future<void> clearCart(String userId) async {
    try {
      await _cartService.clearCart(userId);
      _items = [];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Increment quantity
  Future<void> incrementQuantity(String userId, String cartItemId) async {
    final item = _items.firstWhere((item) => item.id == cartItemId);
    await updateQuantity(userId, cartItemId, item.quantity + 1);
  }

  // Decrement quantity
  Future<void> decrementQuantity(String userId, String cartItemId) async {
    final item = _items.firstWhere((item) => item.id == cartItemId);
    await updateQuantity(userId, cartItemId, item.quantity - 1);
  }

  /// Clear all local state (e.g. on logout)
  void clear() {
    _items = [];
    notifyListeners();
  }
}
