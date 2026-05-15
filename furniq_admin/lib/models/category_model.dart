class Category {
  final String id;
  final String name;
  final int itemCount;
  final String thumbnailImageUrl;

  Category({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.thumbnailImageUrl,
  });

  factory Category.fromMap(Map<String, dynamic> map, String documentId) {
    return Category(
      id: documentId,
      name: map['name'] ?? '',
      itemCount: map['itemCount'] ?? 0,
      thumbnailImageUrl: map['thumbnailImageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'itemCount': itemCount,
      'thumbnailImageUrl': thumbnailImageUrl,
    };
  }
}
