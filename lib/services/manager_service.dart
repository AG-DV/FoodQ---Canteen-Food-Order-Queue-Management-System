import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manager_models.dart';
import '../services/auth_service.dart';

const String _dbUrl =
    'https://foodq-canteen-system-default-rtdb.asia-southeast1.firebasedatabase.app';

class ManagerService {
  static final ManagerService _instance = ManagerService._internal();
  factory ManagerService() => _instance;
  ManagerService._internal();

  String get _token => AuthService().idToken ?? '';

  Future<List<ManagerStall>> getStalls(String canteenId) async {
    final stallResponse = await http.get(
      Uri.parse('$_dbUrl/canteens/$canteenId/stalls.json?auth=$_token'),
    );
    final orderResponse = await http.get(
      Uri.parse('$_dbUrl/stall_orders.json?auth=$_token'),
    );

    if (stallResponse.statusCode != 200) {
      throw Exception('Failed to load manager stall data');
    }

    final stallData = jsonDecode(stallResponse.body);
    if (stallData == null) return [];

    final stalls = Map<String, dynamic>.from(stallData);
    final rawOrderData =
        orderResponse.statusCode == 200 ? jsonDecode(orderResponse.body) : null;
    final allOrders = rawOrderData is Map
        ? Map<String, dynamic>.from(rawOrderData)
        : <String, dynamic>{};

    final result = <ManagerStall>[];

    for (final entry in stalls.entries) {
      final stall = Map<String, dynamic>.from(entry.value);
      final rawOrders = allOrders[entry.key];
      final orders = rawOrders is Map
          ? Map<String, dynamic>.from(rawOrders)
          : <String, dynamic>{};

      var activeOrders = 0;
      var weeklyOrders = 0;
      var weeklyRevenue = 0.0;

      for (final value in orders.values) {
        if (value is! Map) continue;
        final order = Map<String, dynamic>.from(value);
        final status = order['status']?.toString() ?? 'pending';
        if (status != 'completed' && status != 'rejected') activeOrders++;
        final createdAt = DateTime.tryParse(order['createdAt']?.toString() ?? '');
        if (createdAt != null &&
            createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
          weeklyOrders++;
          weeklyRevenue += (order['total'] as num?)?.toDouble() ?? 0;
        }
      }

      result.add(ManagerStall(
        id: entry.key,
        name: stall['name']?.toString() ?? 'Unknown Stall',
        queueCount: (stall['queueCount'] as num?)?.toInt() ?? activeOrders,
        activeOrders: activeOrders,
        weeklyOrders: weeklyOrders,
        weeklyRevenue: weeklyRevenue,
        rating: (stall['rating'] as num?)?.toDouble() ?? 0,
        isOpen: stall['isOpen'] ?? true,
      ));
    }

    return result;
  }

  Future<List<ManagerComplaint>> getComplaints() async {
    final response = await http.get(
      Uri.parse('$_dbUrl/complaints.json?auth=$_token'),
    );
    if (response.statusCode != 200) throw Exception('Failed to load complaints');
    final data = jsonDecode(response.body);
    if (data == null) return [];
    return Map<String, dynamic>.from(data)
        .entries
        .where((e) => e.value is Map)
        .map((e) => ManagerComplaint.fromMap(
            e.key, Map<dynamic, dynamic>.from(e.value)))
        .toList();
  }

  Future<void> updateComplaint({
    required String complaintId,
    required String status,
    required String notes,
  }) async {
    final response = await http.patch(
      Uri.parse('$_dbUrl/complaints/$complaintId.json?auth=$_token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status, 'resolutionNotes': notes}),
    );
    if (response.statusCode >= 400) throw Exception('Failed to update complaint');
  }

  Future<void> sendRedirectNotice(String stallName) async {
    final response = await http.post(
      Uri.parse('$_dbUrl/manager_notices.json?auth=$_token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': 'Crowded Stall Notice',
        'message': '$stallName is crowded. Please consider another stall.',
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
    if (response.statusCode >= 400) throw Exception('Failed to send notice');
  }

  // Account management — list all users (manager only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$_dbUrl/users.json?auth=$_token'),
    );
    if (response.statusCode != 200) throw Exception('Failed to load users');
    final data = jsonDecode(response.body);
    if (data == null) return [];
    return Map<String, dynamic>.from(data).entries.map((e) {
      final user = Map<String, dynamic>.from(e.value);
      user['uid'] = e.key;
      return user;
    }).toList();
  }

  // Update a user's role (manager only)
  Future<void> updateUserRole(String uid, String role) async {
    final response = await http.patch(
      Uri.parse('$_dbUrl/users/$uid.json?auth=$_token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'role': role}),
    );
    if (response.statusCode >= 400) throw Exception('Failed to update user role');
  }
}
