import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _apiKey = 'AIzaSyBVEKOEK2-hNKzB3HmzJYuGhiZADGBICgY';
const String _dbUrl =
    'https://foodq-canteen-system-default-rtdb.asia-southeast1.firebasedatabase.app/';
const String _baseAuth = 'https://identitytoolkit.googleapis.com/v1/accounts';
const String _prefsTokenKey = 'idToken';
const String _prefsUidKey = 'uid';
const String _prefsRoleKey = 'role';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _idToken;
  String? _uid;
  String? _role;

  String? get idToken => _idToken;
  String? get uid => _uid;
  String? get currentUserId => _uid; // alias used by customer screens
  String? get role => _role;
  bool get isLoggedIn => _idToken != null;
  bool get isVendor => _role == 'vendor';
  bool get isManager => _role == 'manager';
  bool get isCustomer => _role == 'customer';

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _idToken = prefs.getString(_prefsTokenKey);
    _uid = prefs.getString(_prefsUidKey);
    _role = prefs.getString(_prefsRoleKey);
    if (_idToken != null && _uid != null && _role == null) {
      await _fetchAndCacheRole();
    }
  }

  Future<void> _saveSession(String idToken, String uid, String role) async {
    _idToken = idToken;
    _uid = uid;
    _role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsTokenKey, idToken);
    await prefs.setString(_prefsUidKey, uid);
    await prefs.setString(_prefsRoleKey, role);
  }

  Future<void> _clearSession() async {
    _idToken = null;
    _uid = null;
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsTokenKey);
    await prefs.remove(_prefsUidKey);
    await prefs.remove(_prefsRoleKey);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String role = 'customer',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseAuth:signUp?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw _parseError(body);
    final idToken = body['idToken'] as String;
    final uid = body['localId'] as String;
    await _writeUserProfile(uid: uid, idToken: idToken, name: name, email: email, role: role);
    await _saveSession(idToken, uid, role);
  }

  // Returns true on success, throws on error
  Future<bool> login({required String email, required String password}) async {
    final res = await http.post(
      Uri.parse('$_baseAuth:signInWithPassword?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw _parseError(body);
    final idToken = body['idToken'] as String;
    final uid = body['localId'] as String;
    final role = await _fetchRole(uid: uid, idToken: idToken);
    await _saveSession(idToken, uid, role);
    return true;
  }

  Future<void> logout() async => await _clearSession();

  Future<void> sendPasswordReset(String email) async {
    final res = await http.post(
      Uri.parse('$_baseAuth:sendOobCode?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'requestType': 'PASSWORD_RESET', 'email': email}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw _parseError(body);
  }

  // Supports both getProfile() and getProfile(userId) calls
  Future<Map<String, dynamic>> getProfile([String? userId]) async {
    final id = userId ?? _uid;
    final res = await http.get(
      Uri.parse('$_dbUrl/users/$id.json?auth=$_idToken'),
    );
    if (res.statusCode != 200) throw Exception('Failed to load profile');
    final data = jsonDecode(res.body);
    if (data == null) throw Exception('Profile not found');
    return Map<String, dynamic>.from(data);
  }

  // Supports both updateProfile(name:) and updateProfile(userId:, name:) calls
  Future<void> updateProfile({String? userId, required String name}) async {
    final id = userId ?? _uid;
    final res = await http.patch(
      Uri.parse('$_dbUrl/users/$id.json?auth=$_idToken'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (res.statusCode != 200) throw Exception('Failed to update profile');
  }

  Future<String> _fetchRole({required String uid, required String idToken}) async {
    final res = await http.get(
      Uri.parse('$_dbUrl/users/$uid/role.json?auth=$idToken'),
    );
    if (res.statusCode != 200) return 'customer';
    final role = jsonDecode(res.body);
    return role?.toString() ?? 'customer';
  }

  Future<void> _fetchAndCacheRole() async {
    final role = await _fetchRole(uid: _uid!, idToken: _idToken!);
    _role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsRoleKey, role);
  }

  Future<void> _writeUserProfile({
    required String uid,
    required String idToken,
    required String name,
    required String email,
    required String role,
  }) async {
    final res = await http.put(
      Uri.parse('$_dbUrl/users/$uid.json?auth=$idToken'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'role': role,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to save user profile');
  }

  String _parseError(Map<String, dynamic> body) {
    final message = body['error']?['message'] ?? 'Unknown error';
    switch (message) {
      case 'EMAIL_EXISTS': return 'This email is already registered.';
      case 'EMAIL_NOT_FOUND': return 'No account found with this email.';
      case 'INVALID_PASSWORD': return 'Incorrect password.';
      case 'INVALID_LOGIN_CREDENTIALS': return 'Invalid email or password.';
      case 'USER_DISABLED': return 'This account has been disabled.';
      case 'WEAK_PASSWORD : Password should be at least 6 characters':
        return 'Password must be at least 6 characters.';
      default: return message;
    }
  }
}
