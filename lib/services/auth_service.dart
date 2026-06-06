import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _dbUrl =
      'https://foodq-canteen-system-default-rtdb.asia-southeast1.firebasedatabase.app';

  String? currentUserId;
  String? currentUserRole;

  bool get isLoggedIn => currentUserId != null;

  bool get isManager {
    final role = currentUserRole?.toLowerCase().replaceAll(' ', '_');
    return role == 'manager' || role == 'canteen_manager';
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_dbUrl/users.json');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': 'customer',
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to register');
    }

    final data = jsonDecode(response.body);
    currentUserId = data['name'];
    currentUserRole = 'customer';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUserId', currentUserId!);
    await prefs.setString('currentUserRole', currentUserRole!);
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_dbUrl/users.json');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to login');
    }

    final data = jsonDecode(response.body);

    if (data == null) {
      return false;
    }

    for (final user in data.entries) {
      if (user.value['email'] == email && user.value['password'] == password) {
        currentUserId = user.key;
        currentUserRole = user.value['role']?.toString() ?? 'customer';

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString(
          'currentUserId',
          user.key,
        );
        await prefs.setString(
          'currentUserRole',
          currentUserRole!,
        );

        return true;
      }
    }

    return false;
  }

  Future<Map<String, dynamic>> getProfile(String userId) async {
    final url = Uri.parse('$_dbUrl/users/$userId.json');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to load profile');
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  Future<void> updateProfile({
    required String userId,
    required String name,
  }) async {
    final url = Uri.parse('$_dbUrl/users/$userId.json');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to update profile');
    }
  }

  Future<void> deleteUser(String userId) async {
    final url = Uri.parse('$_dbUrl/users/$userId.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to delete user');
    }
  }

  Future<void> logout() async {
    currentUserId = null;
    currentUserRole = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('currentUserId');
    await prefs.remove('currentUserRole');
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    currentUserId = prefs.getString('currentUserId');
    currentUserRole = prefs.getString('currentUserRole');
  }
}
