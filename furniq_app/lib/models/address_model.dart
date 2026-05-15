import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String userId;
  final String label;      // e.g. "Home", "Office"
  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String postalCode;
  final bool isDefault;
  final DateTime createdAt;

  Address({
    required this.id,
    required this.userId,
    this.label = 'Home',
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.postalCode,
    this.isDefault = false,
    required this.createdAt,
  });

  String get fullAddress => '$street, $city $postalCode';

  factory Address.fromMap(Map<String, dynamic> map, String documentId) {
    return Address(
      id: documentId,
      userId: map['userId'] ?? '',
      label: map['label'] ?? 'Home',
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      postalCode: map['postalCode'] ?? '',
      isDefault: map['isDefault'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'label': label,
      'fullName': fullName,
      'phone': phone,
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Address copyWith({
    String? id,
    String? userId,
    String? label,
    String? fullName,
    String? phone,
    String? street,
    String? city,
    String? postalCode,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
