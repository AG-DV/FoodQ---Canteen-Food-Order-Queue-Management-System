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
    // First try querying by ownerId
    final res = await http.get(
      Uri.parse(
          '$_dbUrl/stalls.json?auth=$_token&orderBy="ownerId"&equalTo="$_uid"'),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data != null && data is Map && data.isNotEmpty) {
        final entry = (data as Map).entries.first;
        return StallModel.fromMap(
            Map<String, dynamic>.from(entry.value), entry.key);
      }
    }

    // Fallback: fetch all stalls and filter in Dart
    // (used when RTDB index is not set up yet)
    final fallback = await http.get(
      Uri.parse('$_dbUrl/stalls.json?auth=$_token'),
    );
    if (fallback.statusCode != 200) return null;
    final allData = jsonDecode(fallback.body);
    if (allData == null || allData is! Map) return null;

    for (final entry in (allData as Map).entries) {
      final stall = Map<String, dynamic>.from(entry.value);
      if (stall['ownerId'] == _uid) {
        return StallModel.fromMap(stall, entry.key);
      }
    }
    return null;
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
