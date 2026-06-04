// ─── Canteen ─────────────────────────────────────────────────────────────────

class Canteen {
  final String id;
  final String name;
  final String location;

  Canteen({required this.id, required this.name, required this.location});

  factory Canteen.fromMap(String id, Map<dynamic, dynamic> map) => Canteen(
        id: id,
        name: map['name'] ?? '',
        location: map['location'] ?? '',
      );
}

// ─── Stall ────────────────────────────────────────────────────────────────────

class Stall {
  final String id;
  final String name;
  final String category; // e.g. "Main Course", "Snacks", "Drinks"
  final double rating;
  final int queueCount;
  final bool isOpen;

  Stall({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.queueCount,
    required this.isOpen,
  });

  factory Stall.fromMap(String id, Map<dynamic, dynamic> map) => Stall(
        id: id,
        name: map['name'] ?? '',
        category: map['category'] ?? 'Main Course',
        rating: (map['rating'] ?? 0.0).toDouble(),
        queueCount: (map['queueCount'] ?? 0) as int,
        isOpen: map['isOpen'] ?? true,
      );
}

// ─── Menu Item ────────────────────────────────────────────────────────────────

class MenuItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final bool isAvailable;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.isAvailable,
  });

  factory MenuItem.fromMap(String id, Map<dynamic, dynamic> map) => MenuItem(
        id: id,
        name: map['name'] ?? '',
        price: (map['price'] ?? 0.0).toDouble(),
        category: map['category'] ?? '',
        isAvailable: map['isAvailable'] ?? true,
      );
}

// ─── Cart Item ────────────────────────────────────────────────────────────────

class CartItem {
  final MenuItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  double get subtotal => item.price * quantity;
}

// ─── Order ────────────────────────────────────────────────────────────────────

class Order {
  final String id;
  final String stallId;
  final String stallName;
  final String canteenId;
  final List<Map<String, dynamic>> items; // [{name, price, quantity}]
  final double total;
  final String pickupTime;
  final String note;
  final String status; // pending | preparing | ready | completed
  final String pickupCode;
  final String createdAt;

  Order({
    required this.id,
    required this.stallId,
    required this.stallName,
    required this.canteenId,
    required this.items,
    required this.total,
    required this.pickupTime,
    required this.note,
    required this.status,
    required this.pickupCode,
    required this.createdAt,
  });

  factory Order.fromMap(String id, Map<dynamic, dynamic> map) {
    final rawItems = map['items'];
    List<Map<String, dynamic>> items = [];
    if (rawItems is List) {
      items = rawItems
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else if (rawItems is Map) {
      items = rawItems.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return Order(
      id: id,
      stallId: map['stallId'] ?? '',
      stallName: map['stallName'] ?? '',
      canteenId: map['canteenId'] ?? '',
      items: items,
      total: (map['total'] ?? 0.0).toDouble(),
      pickupTime: map['pickupTime'] ?? '',
      note: map['note'] ?? '',
      status: map['status'] ?? 'pending',
      pickupCode: map['pickupCode'] ?? '',
      createdAt: map['createdAt'] ?? '',
    );
  }

  /// Status index used by the tracking stepper (0–3)
  int get statusIndex {
    switch (status) {
      case 'pending':
        return 0;
      case 'preparing':
        return 1;
      case 'ready':
        return 2;
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }
}
