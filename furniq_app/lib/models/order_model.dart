enum PaymentMethod {
  cashOnDelivery,
  onlinePayment, // Stripe card payment
}

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
}

enum PaymentStatus {
  notPaid,
  paid,
  failed,
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double total;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;
  final ShippingAddress shippingAddress;
  /// Stripe PaymentIntent ID — only set when paymentMethod is onlinePayment.
  /// Stored for audit trail and potential refund processing.
  final String? stripePaymentIntentId;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.notPaid,
    required this.createdAt,
    required this.shippingAddress,
    this.stripePaymentIntentId,
  });

  String get orderNumber => 'ORD$id';

  String get paymentMethodText {
    return paymentMethod == PaymentMethod.cashOnDelivery
        ? 'Cash on Delivery'
        : 'Stripe — Card Payment';
  }

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get itemsSummary {
    if (items.isEmpty) return 'No items';
    if (items.length == 1) {
      return '${items[0].name} × ${items[0].quantity}';
    }
    return '${items[0].name} × ${items[0].quantity} + ${items.length - 1} more';
  }

  factory Order.fromMap(Map<String, dynamic> map, String documentId) {
    return Order(
      id: documentId,
      userId: map['userId'] ?? '',
      items: (map['items'] as List?)
              ?.map((item) => OrderItem.fromMap(item))
              .toList() ??
          [],
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      paymentMethod: _paymentMethodFromString(map['paymentMethod']),
      status: _orderStatusFromString(map['status']),
      paymentStatus: _paymentStatusFromString(map['paymentStatus']),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      shippingAddress: ShippingAddress.fromMap(map['shippingAddress'] ?? {}),
      stripePaymentIntentId: map['stripePaymentIntentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'total': total,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'createdAt': createdAt,
      'shippingAddress': shippingAddress.toMap(),
      // Only included when payment was made via Stripe
      if (stripePaymentIntentId != null)
        'stripePaymentIntentId': stripePaymentIntentId,
    };
  }

  static PaymentMethod _paymentMethodFromString(String? method) {
    return method == 'onlinePayment'
        ? PaymentMethod.onlinePayment
        : PaymentMethod.cashOnDelivery;
  }

  static OrderStatus _orderStatusFromString(String? status) {
    switch (status) {
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  static PaymentStatus _paymentStatusFromString(String? status) {
    switch (status) {
      case 'paid':
        return PaymentStatus.paid;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.notPaid;
    }
  }
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String? selectedColorHex;
  final String? selectedColorName;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.selectedColorHex,
    this.selectedColorName,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      lineTotal: (map['lineTotal'] ?? 0).toDouble(),
      selectedColorHex: map['selectedColorHex'],
      selectedColorName: map['selectedColorName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
      'selectedColorHex': selectedColorHex,
      'selectedColorName': selectedColorName,
    };
  }
}

class ShippingAddress {
  final String fullName;
  final String email;
  final String phone;
  final String street;
  final String city;
  final String postalCode;

  ShippingAddress({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.street,
    required this.city,
    required this.postalCode,
  });

  String get fullAddress => '$street, $city $postalCode';

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      postalCode: map['postalCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'street': street,
      'city': city,
      'postalCode': postalCode,
    };
  }
}
