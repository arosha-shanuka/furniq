class CartItem {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String productImage;
  final String material;
  final int quantity;
  final double unitPrice;
  final String? selectedColorHex;
  final String? selectedColorName;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.material,
    required this.quantity,
    required this.unitPrice,
    this.selectedColorHex,
    this.selectedColorName,
  });

  double get totalPrice => unitPrice * quantity;

  factory CartItem.fromMap(Map<String, dynamic> map, String documentId) {
    return CartItem(
      id: documentId,
      userId: map['userId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      material: map['material'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      selectedColorHex: map['selectedColorHex'],
      selectedColorName: map['selectedColorName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'material': material,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'selectedColorHex': selectedColorHex,
      'selectedColorName': selectedColorName,
    };
  }

  CartItem copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    String? productImage,
    String? material,
    int? quantity,
    double? unitPrice,
    String? selectedColorHex,
    String? selectedColorName,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      material: material ?? this.material,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      selectedColorHex: selectedColorHex ?? this.selectedColorHex,
      selectedColorName: selectedColorName ?? this.selectedColorName,
    );
  }
}
