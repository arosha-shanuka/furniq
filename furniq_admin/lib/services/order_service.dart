import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all orders across all users, sorted by latest first.
  Stream<List<Order>> streamAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Order.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get single order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists || doc.data() == null) return null;
      return Order.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error fetching order: $e');
      return null;
    }
  }

  /// Updates the order status and trigger notifications.
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Order $orderId status updated to ${status.name}');
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }
}
