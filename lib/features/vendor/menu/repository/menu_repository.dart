import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../shared/models/menu_item_model.dart';
import '../../../../services/auth_service.dart';

const String _dbUrl =
    'https://foodq-canteen-system-default-rtdb.asia-southeast1.firebasedatabase.app/';

class MenuRepository {
  final _auth = AuthService();
  String get _token => _auth.idToken ?? '';

  Future<List<MenuItemModel>> getMenuItems(String stallId) async {
    final res = await http.get(
      Uri.parse('$_dbUrl/stalls/$stallId/menuItems.json?auth=$_token'),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data == null || data is! Map) return [];
    return data.entries
        .map((e) => MenuItemModel.fromMap(Map<String, dynamic>.from(e.value), e.key))
        .toList();
  }

  Stream<List<MenuItemModel>> watchMenuItems(String stallId) {
    final controller = StreamController<List<MenuItemModel>>();
    Future<void> poll() async {
      while (!controller.isClosed) {
        try {
          final items = await getMenuItems(stallId);
          if (!controller.isClosed) controller.add(items);
        } catch (_) {}
        await Future.delayed(const Duration(seconds: 5));
      }
    }
    poll();
    return controller.stream;
  }

  Future<void> addMenuItem(String stallId, MenuItemModel item) async {
    await http.post(
      Uri.parse('$_dbUrl/stalls/$stallId/menuItems.json?auth=$_token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toMap()),
    );
  }

  Future<void> updateMenuItem(String stallId, String itemId, Map<String, dynamic> fields) async {
    await http.patch(
      Uri.parse('$_dbUrl/stalls/$stallId/menuItems/$itemId.json?auth=$_token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fields),
    );
  }

  Future<void> toggleAvailability(String stallId, String itemId, bool isAvailable) async {
    await updateMenuItem(stallId, itemId, {'isAvailable': isAvailable});
  }

  Future<void> deleteMenuItem(String stallId, String itemId) async {
    await http.delete(
      Uri.parse('$_dbUrl/stalls/$stallId/menuItems/$itemId.json?auth=$_token'),
    );
  }
}
