import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  Order? _lastCreatedOrder;
  Order? _currentOrder;
  StreamSubscription<List<Order>>? _ordersSubscription;
  StreamSubscription<Order?>? _currentOrderSubscription;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Order? get lastCreatedOrder => _lastCreatedOrder;
  Order? get currentOrder => _currentOrder;

  // Listen to user orders in real-time
  void listenToUserOrders(String userId) {
    _ordersSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _ordersSubscription = _orderService.streamUserOrders(userId).listen(
      (orders) {
        _orders = orders;
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

  // Listen to a single order
  void listenToOrder(String orderId) {
    _currentOrderSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _currentOrderSubscription = _orderService.streamOrder(orderId).listen(
      (order) {
        _currentOrder = order;
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

  // Kept for backward compatibility if needed, but streaming is preferred
  Future<void> loadOrders(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _orders = await _orderService.getUserOrders(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new order
  Future<Order?> createOrder(Order order) async {
    try {
      _isLoading = true;
      notifyListeners();

      final createdOrder = await _orderService.createOrder(order);
      _lastCreatedOrder = createdOrder;
      
      _isLoading = false;
      notifyListeners();
      
      return createdOrder;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Get order by ID (one-time fetch)
  Future<Order?> getOrderById(String orderId) async {
    try {
      return await _orderService.getOrderById(orderId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _currentOrderSubscription?.cancel();
    super.dispose();
  }

  // Update order status
  Future<void> updateOrderStatus(String userId, String orderId, OrderStatus status) async {
    try {
      await _orderService.updateOrderStatus(orderId, status);
      await loadOrders(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get recent order (for profile screen)
  Order? getRecentOrder() {
    if (_orders.isEmpty) return null;
    return _orders.first;
  }

  // Clear last created order
  void clearLastCreatedOrder() {
    _lastCreatedOrder = null;
    notifyListeners();
  }

  /// Clear all local state (e.g. on logout)
  void clear() {
    _orders = [];
    _lastCreatedOrder = null;
    _currentOrder = null;
    _ordersSubscription?.cancel();
    _currentOrderSubscription?.cancel();
    notifyListeners();
  }
}
