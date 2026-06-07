import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../models/models.dart';
import '../../services/auth_service.dart';

const String _dbUrl =
    'https://foodq-canteen-system-default-rtdb.asia-southeast1.firebasedatabase.app/';

class CanteenService {
  static final CanteenService _instance = CanteenService._internal();
  factory CanteenService() => _instance;
  CanteenService._internal();

  String get _token => AuthService().idToken ?? '';

  Future<List<Canteen>> getCanteens() async {
    final res = await http.get(
      Uri.parse('$_dbUrl/canteens.json?auth=$_token'),
    );
    if (res.statusCode != 200) throw Exception('Failed to load canteens');
    final data = jsonDecode(res.body);
    if (data == null) return [];
    return Map<String, dynamic>.from(data)
        .entries
        .map((e) => Canteen.fromMap(e.key, Map<dynamic, dynamic>.from(e.value)))
        .toList();
  }

  Future<List<Stall>> getStalls(String canteenId) async {
    final res = await http.get(
      Uri.parse('$_dbUrl/canteens/$canteenId/stalls.json?auth=$_token'),
    );
    if (res.statusCode != 200) throw Exception('Failed to load stalls');
    final data = jsonDecode(res.body);
    if (data == null) return [];
    return Map<String, dynamic>.from(data)
        .entries
        .map((e) => Stall.fromMap(e.key, Map<dynamic, dynamic>.from(e.value)))
        .toList();
  }

  Future<List<MenuItem>> getMenu(String canteenId, String stallId) async {
    final res = await http.get(
      Uri.parse('$_dbUrl/canteens/$canteenId/stalls/$stallId/menu.json?auth=$_token'),
    );
    if (res.statusCode != 200) throw Exception('Failed to load menu');
    final data = jsonDecode(res.body);
    if (data == null) return [];
    return Map<String, dynamic>.from(data)
        .entries
        .map((e) => MenuItem.fromMap(e.key, Map<dynamic, dynamic>.from(e.value)))
        .toList();
  }

  Future<String> placeOrder({
    required String userId,
    required String canteenId,
    required String stallId,
    required String stallName,
    required List<CartItem> cartItems,
    required String pickupTime,
    required String note,
  }) async {
    final total = cartItems.fold(0.0, (sum, c) => sum + c.subtotal);
    final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
    final pickupCode = (1000 + Random().nextInt(9000)).toString();

    final orderData = {
      'stallId': stallId,
      'stallName': stallName,
      'canteenId': canteenId,
      'customerId': userId,
      'items': cartItems.map((c) => {
            'name': c.item.name,
            'price': c.item.price,
            'quantity': c.quantity,
          }).toList(),
      'total': total,
      'totalAmount': total,
      'pickupTime': pickupTime,
      'note': note,
      'status': 'pending',
      'pickupCode': pickupCode,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final res = await http.put(
      Uri.parse('$_dbUrl/orders/$userId/$orderId.json?auth=$_token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(orderData),
    );
    if (res.statusCode != 200) throw Exception('Failed to place order');

    // Also write to /stall_orders/{stallId}/{orderId} for vendor
    await http.put(
      Uri.parse('$_dbUrl/stall_orders/$stallId/$orderId.json?auth=$_token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(orderData),
    );

    return orderId;
  }

  Future<Order?> getOrder(String userId, String orderId) async {
    final res = await http.get(
      Uri.parse('$_dbUrl/orders/$userId/$orderId.json?auth=$_token'),
    );
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    if (data == null) return null;
    return Order.fromMap(orderId, Map<dynamic, dynamic>.from(data));
  }

  Future<List<Order>> getOrderHistory(String userId) async {
    final res = await http.get(
      Uri.parse('$_dbUrl/orders/$userId.json?auth=$_token'),
    );
    if (res.statusCode != 200) throw Exception('Failed to load orders');
    final data = jsonDecode(res.body);
    if (data == null) return [];
    final orders = Map<String, dynamic>.from(data)
        .entries
        .map((e) => Order.fromMap(e.key, Map<dynamic, dynamic>.from(e.value)))
        .toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Future<void> confirmPickup(String userId, String orderId) async {
    await http.patch(
      Uri.parse('$_dbUrl/orders/$userId/$orderId.json?auth=$_token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': 'completed'}),
    );
  }
}
