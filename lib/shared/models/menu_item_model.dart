class MenuItemModel {
  final String itemId, name, description, category;
  final double price;
  final bool isAvailable;
  final int dailyPreOrderLimit;

  MenuItemModel({
    required this.itemId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.isAvailable,
    required this.dailyPreOrderLimit,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> map, String id) => MenuItemModel(
        itemId: id,
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        category: map['category'] ?? 'Main Course',
        isAvailable: map['isAvailable'] ?? true,
        dailyPreOrderLimit: map['dailyPreOrderLimit'] ?? 50,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'isAvailable': isAvailable,
        'dailyPreOrderLimit': dailyPreOrderLimit,
      };

  MenuItemModel copyWith({
    String? name, String? description, double? price,
    String? category, bool? isAvailable, int? dailyPreOrderLimit,
  }) => MenuItemModel(
        itemId: itemId,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        category: category ?? this.category,
        isAvailable: isAvailable ?? this.isAvailable,
        dailyPreOrderLimit: dailyPreOrderLimit ?? this.dailyPreOrderLimit,
      );
}
