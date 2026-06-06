import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manager_models.dart';

const String _dbUrl =
    'https://foodq-canteen-system-default-rtdb.asia-southeast1.firebasedatabase.app';

class ManagerService {
  static final ManagerService _instance = ManagerService._internal();
  factory ManagerService() => _instance;
  ManagerService._internal();

  Future<List<ManagerStall>> getStalls(String canteenId) async {
    final stallResponse = await http.get(
      Uri.parse('$_dbUrl/canteens/$canteenId/stalls.json'),
    );
    final orderResponse = await http.get(
      Uri.parse('$_dbUrl/stall_orders.json'),
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

        if (status != 'completed' && status != 'rejected') {
          activeOrders++;
        }

        final createdAt = DateTime.tryParse(
          order['createdAt']?.toString() ?? '',
        );
        if (createdAt != null &&
            createdAt.isAfter(
              DateTime.now().subtract(const Duration(days: 7)),
            )) {
          weeklyOrders++;
          weeklyRevenue += (order['total'] as num?)?.toDouble() ?? 0;
        }
      }

      result.add(
        ManagerStall(
          id: entry.key,
          name: stall['name']?.toString() ?? 'Unknown Stall',
          queueCount: (stall['queueCount'] as num?)?.toInt() ?? activeOrders,
          activeOrders: activeOrders,
          weeklyOrders: weeklyOrders,
          weeklyRevenue: weeklyRevenue,
          rating: (stall['rating'] as num?)?.toDouble() ?? 0,
          isOpen: stall['isOpen'] ?? true,
        ),
      );
    }

    return result;
  }

  Future<List<ManagerComplaint>> getComplaints() async {
    final response = await http.get(Uri.parse('$_dbUrl/complaints.json'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load complaints');
    }

    final data = jsonDecode(response.body);
    if (data == null) return [];

    final complaints = Map<String, dynamic>.from(data);
    return complaints.entries
        .where((entry) => entry.value is Map)
        .map(
          (entry) => ManagerComplaint.fromMap(
            entry.key,
            Map<dynamic, dynamic>.from(entry.value),
          ),
        )
        .toList();
  }

  Future<void> updateComplaint({
    required String complaintId,
    required String status,
    required String notes,
  }) async {
    final response = await http.patch(
      Uri.parse('$_dbUrl/complaints/$complaintId.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'status': status,
        'resolutionNotes': notes,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to update complaint');
    }
  }

  Future<void> sendRedirectNotice(String stallName) async {
    final response = await http.post(
      Uri.parse('$_dbUrl/manager_notices.json'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': 'Crowded Stall Notice',
        'message': '$stallName is crowded. Please consider another stall.',
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to send notice');
    }
  }
}
