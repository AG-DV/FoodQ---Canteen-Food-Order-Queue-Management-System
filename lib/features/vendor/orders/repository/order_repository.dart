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

  Future<List<OrderModel>> getActiveOrders(String stallId) async {
    final res = await http.get(
      Uri.parse('$_dbUrl/orders.json?auth=$_token&orderBy="stallId"&equalTo="$stallId"'),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data == null || data is! Map) return [];

    return data.entries
        .map((e) => OrderModel.fromMap(Map<String, dynamic>.from(e.value), e.key))
        .where((o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.preparing ||
            o.status == OrderStatus.ready)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

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

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await http.patch(
      Uri.parse('$_dbUrl/orders/$orderId.json?auth=$_token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status.name, 'updatedAt': DateTime.now().toIso8601String()}),
    );
  }

  Future<List<OrderModel>> getCompletedOrdersToday(String stallId) async {
    final res = await http.get(
      Uri.parse('$_dbUrl/orders.json?auth=$_token&orderBy="stallId"&equalTo="$stallId"'),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data == null || data is! Map) return [];

    final startOfDay = DateTime.now().copyWith(hour: 0, minute: 0, second: 0).toIso8601String();
    return data.entries
        .map((e) => OrderModel.fromMap(Map<String, dynamic>.from(e.value), e.key))
        .where((o) => o.status == OrderStatus.completed && o.createdAt.compareTo(startOfDay) >= 0)
        .toList();
  }
}
