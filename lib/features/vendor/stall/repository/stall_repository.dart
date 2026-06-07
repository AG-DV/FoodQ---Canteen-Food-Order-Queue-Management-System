import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../shared/models/stall_model.dart';
import '../../../../services/auth_service.dart';

const String _dbUrl =
    'https://foodq-canteen-system-default-rtdb.asia-southeast1.firebasedatabase.app/';

class StallRepository {
  final _auth = AuthService();
  String get _token => _auth.idToken ?? '';
  String get _uid => _auth.uid ?? '';

  Future<StallModel?> getMyStall() async {
    final res = await http.get(
      Uri.parse('$_dbUrl/stalls.json?auth=$_token&orderBy="ownerId"&equalTo="$_uid"'),
    );
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    if (data == null || data is! Map) return null;
    final entry = data.entries.first;
    return StallModel.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
  }

  Future<String?> createStall(StallModel stall) async {
    final res = await http.post(
      Uri.parse('$_dbUrl/stalls.json?auth=$_token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(stall.toMap()),
    );
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body)['name'] as String?;
  }

  Future<void> updateStall(String stallId, Map<String, dynamic> fields) async {
    await http.patch(
      Uri.parse('$_dbUrl/stalls/$stallId.json?auth=$_token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fields),
    );
  }

  Future<void> setStallActive(String stallId, bool isActive) async {
    await updateStall(stallId, {'isActive': isActive});
  }
}
