enum OrderStatus { pending, preparing, ready, completed, cancelled }

class OrderItemModel {
  final String itemId, name, customization;
  final int quantity;
  final double price;

  OrderItemModel({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.customization,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) => OrderItemModel(
        itemId: map['itemId'] ?? '',
        name: map['name'] ?? '',
        quantity: map['quantity'] ?? 1,
        price: (map['price'] ?? 0).toDouble(),
        customization: map['customization'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'name': name,
        'quantity': quantity,
        'price': price,
        'customization': customization,
      };
}

class OrderModel {
  final String orderId, customerId, stallId, pickupTime, createdAt, updatedAt;
  final List<OrderItemModel> items;
  final double totalAmount;
  final OrderStatus status;
  final String? groupSessionId;

  OrderModel({
    required this.orderId,
    required this.customerId,
    required this.stallId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.pickupTime,
    required this.createdAt,
    required this.updatedAt,
    this.groupSessionId,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    final rawItems = map['items'];
    List<OrderItemModel> parsedItems = [];
    if (rawItems is Map) {
      parsedItems = rawItems.values
          .map((i) => OrderItemModel.fromMap(Map<String, dynamic>.from(i)))
          .toList();
    } else if (rawItems is List) {
      parsedItems = rawItems
          .map((i) => OrderItemModel.fromMap(Map<String, dynamic>.from(i)))
          .toList();
    }
    return OrderModel(
      orderId: id,
      customerId: map['customerId'] ?? '',
      stallId: map['stallId'] ?? '',
      items: parsedItems,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      pickupTime: map['pickupTime'] ?? '',
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] ?? '',
      groupSessionId: map['groupSessionId'],
    );
  }

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'stallId': stallId,
        'items': items.map((i) => i.toMap()).toList(),
        'totalAmount': totalAmount,
        'status': status.name,
        'pickupTime': pickupTime,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'groupSessionId': groupSessionId,
      };

  OrderModel copyWith({OrderStatus? status, String? updatedAt}) => OrderModel(
        orderId: orderId,
        customerId: customerId,
        stallId: stallId,
        items: items,
        totalAmount: totalAmount,
        status: status ?? this.status,
        pickupTime: pickupTime,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        groupSessionId: groupSessionId,
      );
}
