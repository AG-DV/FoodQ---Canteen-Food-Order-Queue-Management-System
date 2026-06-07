import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../shared/models/order_model.dart';
import '../../../../services/auth_service.dart';

const String _dbUrl =
    'https://foodq-canteen-system-default-rtdb.asia-southeast1.firebasedatabase.app/';

class OrderRepository {
  final _auth = AuthService();
  String get _token => _auth.idToken ?? '';

  // Fetch active orders from /stall_orders/{stallId}
  // This is where canteen_service writes orders for the vendor to read
  Future<List<OrderModel>> getActiveOrders(String stallId) async {
    final res = await http.get(
      Uri.parse('$_dbUrl/stall_orders/$stallId.json?auth=$_token'),
    );

    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data == null || data is! Map) return [];

    return (data as Map)
        .entries
        .map((e) => OrderModel.fromMap(
            Map<String, dynamic>.from(e.value), e.key))
        .where((o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.preparing ||
            o.status == OrderStatus.ready)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // Poll every 5 seconds
  Stream<List<OrderModel>> watchOrders(String stallId) {
    final controller = StreamController<List<OrderModel>>();
    Future<void> poll() async {
      while (!controller.isClosed) {
        try {
          final orders = await getActiveOrders(stallId);
          if (!controller.isClosed) controller.add(orders);
        } catch (_) {}
        await Future.delayed(const Duration(seconds: 5));
      }
    }
    poll();
    return controller.stream;
  }

  // Update status in both /stall_orders/{stallId}/{orderId}
  // and /orders/{customerId}/{orderId} so customer tracking updates too
  Future<void> updateOrderStatus(String orderId, OrderStatus status,
      {String? customerId, String? stallId}) async {
    final updates = {
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    // Update in stall_orders (vendor view)
    if (stallId != null) {
      await http.patch(
        Uri.parse('$_dbUrl/stall_orders/$stallId/$orderId.json?auth=$_token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );
    }

    // Update in orders/{customerId} (customer tracking view)
    if (customerId != null) {
      await http.patch(
        Uri.parse(
            '$_dbUrl/orders/$customerId/$orderId.json?auth=$_token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );
    }
  }

  Future<List<OrderModel>> getCompletedOrdersToday(String stallId) async {
    final res = await http.get(
      Uri.parse('$_dbUrl/stall_orders/$stallId.json?auth=$_token'),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data == null || data is! Map) return [];

    final startOfDay =
        DateTime.now().copyWith(hour: 0, minute: 0, second: 0).toIso8601String();

    return (data as Map)
        .entries
        .map((e) => OrderModel.fromMap(
            Map<String, dynamic>.from(e.value), e.key))
        .where((o) =>
            o.status == OrderStatus.completed &&
            o.createdAt.compareTo(startOfDay) >= 0)
        .toList();
  }
}
