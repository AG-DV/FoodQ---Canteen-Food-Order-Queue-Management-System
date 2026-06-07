import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../models/models.dart';

// Import the same constants used in auth_service.dart
// Replace with your actual values if not already set
const String _dbUrl = 'https://foodq-canteen-system-default-rtdb.asia-southeast1.firebasedatabase.app/';

class CanteenService {
  final http.Client _client;
  CanteenService._internal() : _client = http.Client();
  // Add this for testing only
  CanteenService.withClient(this._client);

  // ─── Canteens ─────────────────────────────────────────────────────────────

  Future<List<Canteen>> getCanteens() async {
    final res = await _client.get(Uri.parse('$_dbUrl/canteens.json'));
    if (res.statusCode != 200) throw Exception('Failed to load canteens');
    final data = jsonDecode(res.body);
    if (data == null) return [];
    final map = Map<String, dynamic>.from(data);
    return map.entries
        .map((e) => Canteen.fromMap(e.key, Map<dynamic, dynamic>.from(e.value)))
        .toList();
  }

  // ─── Stalls ───────────────────────────────────────────────────────────────

  Future<List<Stall>> getStalls(String canteenId) async {
    final res =
        await _client.get(Uri.parse('$_dbUrl/canteens/$canteenId/stalls.json'));
    if (res.statusCode != 200) throw Exception('Failed to load stalls');
    final data = jsonDecode(res.body);
    if (data == null) return [];
    final map = Map<String, dynamic>.from(data);
    return map.entries
        .map((e) => Stall.fromMap(e.key, Map<dynamic, dynamic>.from(e.value)))
        .toList();
  }

  // ─── Menu ─────────────────────────────────────────────────────────────────

  Future<List<MenuItem>> getMenu(String canteenId, String stallId) async {
    final res = await _client.get(
        Uri.parse('$_dbUrl/canteens/$canteenId/stalls/$stallId/menu.json'));
    if (res.statusCode != 200) throw Exception('Failed to load menu');
    final data = jsonDecode(res.body);
    if (data == null) return [];
    final map = Map<String, dynamic>.from(data);
    return map.entries
        .map((e) =>
            MenuItem.fromMap(e.key, Map<dynamic, dynamic>.from(e.value)))
        .toList();
  }

  // ─── Orders ───────────────────────────────────────────────────────────────

  /// Places a new order under /orders/{uid}/{orderId}
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
    final orderId =
        'ORD${DateTime.now().millisecondsSinceEpoch}';
    final pickupCode = (1000 + Random().nextInt(9000)).toString();

    final orderData = {
      'stallId': stallId,
      'stallName': stallName,
      'canteenId': canteenId,
      'items': cartItems
          .map((c) => {
                'name': c.item.name,
                'price': c.item.price,
                'quantity': c.quantity,
              })
          .toList(),
      'total': total,
      'pickupTime': pickupTime,
      'note': note,
      'status': 'pending',
      'pickupCode': pickupCode,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final res = await _client.put(
      Uri.parse('$_dbUrl/orders/$userId/$orderId.json?'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(orderData),
    );
    if (res.statusCode != 200) throw Exception('Failed to place order');

    // Also write to /stall_orders/{stallId}/{orderId} so vendor can see it
    await _client.put(
      Uri.parse('$_dbUrl/stall_orders/$stallId/$orderId.json?'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({...orderData, 'customerId': userId}),
    );

    return orderId;
  }

  /// Fetches a single order (for live tracking via polling)
  Future<Order?> getOrder(String userId, String orderId) async {
    final res = await _client.get(
        Uri.parse('$_dbUrl/orders/$userId/$orderId.json'));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    if (data == null) return null;
    return Order.fromMap(orderId, Map<dynamic, dynamic>.from(data));
  }

  /// Fetches all orders for the customer (order history)
  Future<List<Order>> getOrderHistory(String userId) async {
    final res = await _client.get(
        Uri.parse('$_dbUrl/orders/$userId.json'));
    if (res.statusCode != 200) throw Exception('Failed to load orders');
    final data = jsonDecode(res.body);
    if (data == null) return [];
    final map = Map<String, dynamic>.from(data);
    final orders = map.entries
        .map((e) => Order.fromMap(e.key, Map<dynamic, dynamic>.from(e.value)))
        .toList();
    // Newest first
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  /// Marks a completed order as picked up (sets status to completed)
  Future<void> confirmPickup(
      String userId, String orderId) async {
    await _client.patch(
      Uri.parse('$_dbUrl/orders/$userId/$orderId.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': 'completed'}),
    );
  }
}
