enum StockStatus {
  inStock,
  outOfStock,
  lowStock,
}

class ProductColor {
  final String hex;
  final String name;

  ProductColor({required this.hex, required this.name});

  factory ProductColor.fromMap(Map<String, dynamic> map) {
    return ProductColor(
      hex: map['hex'] ?? '',
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hex': hex,
      'name': name,
    };
  }

  // Parse legacy string colors or new map colors
  static List<ProductColor> parseColorsList(dynamic colorsData) {
    if (colorsData == null) return [];
    
    final List<ProductColor> result = [];
    if (colorsData is List) {
      for (var item in colorsData) {
        if (item is String) {
          result.add(ProductColor(hex: item, name: 'Default Color'));
        } else if (item is Map) {
          result.add(ProductColor.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    return result;
  }
}

class Product {
  final String id;
  final String name;
  final String categoryId;
  final double price;
  final String material;
  final ProductDimensions dimensions;
  final String description;
  final String materialAndCareText;
  final StockStatus stockStatus;
  final int stockQuantity;
  final String sku;
  final String mainImageUrl;
  final List<String> additionalImageUrls;
  final String arModelUrl;
  final List<ProductColor> availableColors;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.material,
    required this.dimensions,
    required this.description,
    required this.materialAndCareText,
    this.stockStatus = StockStatus.inStock,
    this.stockQuantity = 10,
    this.sku = '',
    required this.mainImageUrl,
    this.additionalImageUrls = const [],
    required this.arModelUrl,
    this.availableColors = const [],
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String get stockStatusText {
    switch (stockStatus) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
    }
  }

  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      name: map['name'] ?? '',
      categoryId: map['categoryId'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      material: map['material'] ?? '',
      dimensions: ProductDimensions.fromMap(map['dimensions'] ?? {}),
      description: map['description'] ?? '',
      materialAndCareText: map['materialAndCareText'] ?? '',
      stockStatus: _stockStatusFromString(map['stockStatus']),
      stockQuantity: map['stockQuantity'] ?? 10,
      sku: map['sku'] ?? '',
      mainImageUrl: map['mainImageUrl'] ?? '',
      additionalImageUrls: List<String>.from(map['additionalImageUrls'] ?? []),
      arModelUrl: map['arModelUrl'] ?? '',
      availableColors: ProductColor.parseColorsList(map['availableColors']),
      isFeatured: map['isFeatured'] ?? false,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categoryId': categoryId,
      'price': price,
      'material': material,
      'dimensions': dimensions.toMap(),
      'description': description,
      'materialAndCareText': materialAndCareText,
      'stockStatus': stockStatus.name,
      'stockQuantity': stockQuantity,
      'sku': sku,
      'mainImageUrl': mainImageUrl,
      'additionalImageUrls': additionalImageUrls,
      'arModelUrl': arModelUrl,
      'availableColors': availableColors.map((c) => c.toMap()).toList(),
      'isFeatured': isFeatured,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static StockStatus _stockStatusFromString(String? status) {
    switch (status) {
      case 'outOfStock':
        return StockStatus.outOfStock;
      case 'lowStock':
        return StockStatus.lowStock;
      default:
        return StockStatus.inStock;
    }
  }
}

class ProductDimensions {
  final double widthCm;
  final double heightCm;
  final double depthCm;

  ProductDimensions({
    required this.widthCm,
    required this.heightCm,
    required this.depthCm,
  });

  String get displayText => '${widthCm.toInt()}W × ${heightCm.toInt()}H × ${depthCm.toInt()}D cm';

  factory ProductDimensions.fromMap(Map<String, dynamic> map) {
    return ProductDimensions(
      widthCm: (map['widthCm'] ?? 0).toDouble(),
      heightCm: (map['heightCm'] ?? 0).toDouble(),
      depthCm: (map['depthCm'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'widthCm': widthCm,
      'heightCm': heightCm,
      'depthCm': depthCm,
    };
  }
}
