class StallModel {
  final String stallId, ownerId, name, category, description, operatingHours;
  final bool isActive;
  final double averageRating;
  final int queueCount;

  StallModel({
    required this.stallId,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.description,
    required this.operatingHours,
    required this.isActive,
    required this.averageRating,
    required this.queueCount,
  });

  factory StallModel.fromMap(Map<String, dynamic> map, String id) => StallModel(
        stallId: id,
        ownerId: map['ownerId'] ?? '',
        name: map['name'] ?? '',
        category: map['category'] ?? '',
        description: map['description'] ?? '',
        operatingHours: map['operatingHours'] ?? '',
        isActive: map['isActive'] ?? false,
        averageRating: (map['averageRating'] ?? 0).toDouble(),
        queueCount: map['queueCount'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'name': name,
        'category': category,
        'description': description,
        'operatingHours': operatingHours,
        'isActive': isActive,
        'averageRating': averageRating,
        'queueCount': queueCount,
      };

  StallModel copyWith({
    String? name, String? category, String? description,
    String? operatingHours, bool? isActive, double? averageRating, int? queueCount,
  }) => StallModel(
        stallId: stallId,
        ownerId: ownerId,
        name: name ?? this.name,
        category: category ?? this.category,
        description: description ?? this.description,
        operatingHours: operatingHours ?? this.operatingHours,
        isActive: isActive ?? this.isActive,
        averageRating: averageRating ?? this.averageRating,
        queueCount: queueCount ?? this.queueCount,
      );
}
