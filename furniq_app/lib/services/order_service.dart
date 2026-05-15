import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order_model.dart';

/// OrderService — Firestore-backed order persistence.
///
/// Orders are stored in Firestore at: orders/{orderId}
/// Indexed by userId for efficient per-user queries.
class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ──────────────────────────────────────────────────────────
  // Create
  // ──────────────────────────────────────────────────────────

  /// Creates a new order document in Firestore.
  /// Returns the saved Order with the Firestore-generated ID.
  Future<Order> createOrder(Order order) async {
    try {
      final docRef = _firestore.collection('orders').doc();

      // Build the data map explicitly — spread operator causes type issues
      final Map<String, dynamic> orderData = {
        'userId': order.userId,
        'items': order.items.map((item) => item.toMap()).toList(),
        'subtotal': order.subtotal,
        'tax': order.tax,
        'deliveryFee': order.deliveryFee,
        'total': order.total,
        'paymentMethod': order.paymentMethod.name,
        'status': order.status.name,
        'paymentStatus': order.paymentStatus.name,
        // Server timestamp overrides any local DateTime for consistency
        'createdAt': FieldValue.serverTimestamp(),
        'shippingAddress': order.shippingAddress.toMap(),
        if (order.stripePaymentIntentId != null)
          'stripePaymentIntentId': order.stripePaymentIntentId,
      };

      await docRef.set(orderData);

      debugPrint('Order created: ${docRef.id}');

      // Return the order with the real Firestore document ID
      return Order(
        id: docRef.id,
        userId: order.userId,
        items: order.items,
        subtotal: order.subtotal,
        tax: order.tax,
        deliveryFee: order.deliveryFee,
        total: order.total,
        paymentMethod: order.paymentMethod,
        status: order.status,
        paymentStatus: order.paymentStatus,
        createdAt: order.createdAt,
        shippingAddress: order.shippingAddress,
        stripePaymentIntentId: order.stripePaymentIntentId,
      );
    } catch (e) {
      debugPrint('Create order error: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────
  // Read
  // ──────────────────────────────────────────────────────────

  /// Returns all orders for a specific user, sorted newest first.
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint('OrderService: Found ${snapshot.docs.length} orders for user $userId');

      final orders = snapshot.docs
          .map((doc) => Order.fromMap(doc.data(), doc.id))
          .toList();

      // Sort in memory to avoid needing a composite Firestore index
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      debugPrint('Get user orders error: $e');
      return [];
    }
  }

  /// Returns a single order by its Firestore document ID.
  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc =
          await _firestore.collection('orders').doc(orderId).get();

      if (!doc.exists || doc.data() == null) return null;
      return Order.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Get order by ID error: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────
  // Update & Stream
  // ──────────────────────────────────────────────────────────

  /// Stream a single order in real-time
  Stream<Order?> streamOrder(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Order.fromMap(doc.data()!, doc.id);
    });
  }

  /// Stream all orders for a specific user in real-time
  Stream<List<Order>> streamUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => Order.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in memory to avoid needing a composite Firestore index
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  /// Updates the order status (called by admin panel or delivery flow).
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Order $orderId status → ${status.name}');
    } catch (e) {
      debugPrint('Update order status error: $e');
      rethrow;
    }
  }

  /// Updates the payment status (e.g. after a Stripe webhook confirms payment).
  Future<void> updatePaymentStatus(
      String orderId, PaymentStatus paymentStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'paymentStatus': paymentStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Order $orderId paymentStatus → ${paymentStatus.name}');
    } catch (e) {
      debugPrint('Update payment status error: $e');
      rethrow;
    }
  }
}
