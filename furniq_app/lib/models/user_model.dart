class User {
  final String id;
  final String name;
  final String email;
  final bool premiumFlag;
  final String? defaultAddressId;
  final List<String> fcmTokens;
  final bool pushNotificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.premiumFlag = false,
    this.defaultAddressId,
    this.fcmTokens = const [],
    this.pushNotificationsEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get user initials for avatar
  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  // From Firestore
  factory User.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return User(
      id: documentId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      premiumFlag: map['premiumFlag'] ?? false,
      defaultAddressId: map['defaultAddressId'],
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      pushNotificationsEnabled: map['pushNotificationsEnabled'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'premiumFlag': premiumFlag,
      'defaultAddressId': defaultAddressId,
      'fcmTokens': fcmTokens,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    bool? premiumFlag,
    String? defaultAddressId,
    List<String>? fcmTokens,
    bool? pushNotificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      premiumFlag: premiumFlag ?? this.premiumFlag,
      defaultAddressId: defaultAddressId ?? this.defaultAddressId,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
