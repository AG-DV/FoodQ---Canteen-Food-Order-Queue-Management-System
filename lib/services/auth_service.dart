import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase Web API key — replace with your project's key from
/// Firebase Console → Project Settings → General → Web API Key
const String _apiKey = 'AIzaSyBVEKOEK2-hNKzB3HmzJYuGhiZADGBICgY';

/// Firebase Realtime Database URL — replace with your project's URL
/// e.g. https://your-project-default-rtdb.asia-southeast1.firebasedatabase.app
const String _dbUrl = 'https://foodq-canteen-system-default-rtdb.asia-southeast1.firebasedatabase.app/';

const String _baseAuth = 'https://identitytoolkit.googleapis.com/v1/accounts';
const String _prefsTokenKey = 'idToken';
const String _prefsUidKey = 'uid';

class AuthService {
  // ─── Singleton ───────────────────────────────────────────────────────────
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _idToken;
  String? _uid;

  String? get idToken => _idToken;
  String? get uid => _uid;
  bool get isLoggedIn => _idToken != null;

  // ─── Persistence ─────────────────────────────────────────────────────────

  /// Call once at app start (in main.dart) to restore session.
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _idToken = prefs.getString(_prefsTokenKey);
    _uid = prefs.getString(_prefsUidKey);
  }

  Future<void> _saveSession(String idToken, String uid) async {
    _idToken = idToken;
    _uid = uid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsTokenKey, idToken);
    await prefs.setString(_prefsUidKey, uid);
  }

  Future<void> _clearSession() async {
    _idToken = null;
    _uid = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsTokenKey);
    await prefs.remove(_prefsUidKey);
  }

  // ─── Register ────────────────────────────────────────────────────────────

  /// Creates a Firebase Auth account, then stores the user profile
  /// (name, email) in Realtime Database under /users/{uid}.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseAuth:signUp?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw _parseError(body);
    }

    final idToken = body['idToken'] as String;
    final uid = body['localId'] as String;

    // Save profile to Realtime Database
    await _writeUserProfile(uid: uid, idToken: idToken, name: name, email: email);

    await _saveSession(idToken, uid);
  }

  // ─── Login ───────────────────────────────────────────────────────────────

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseAuth:signInWithPassword?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw _parseError(body);
    }

    await _saveSession(body['idToken'], body['localId']);
  }

  // ─── Logout ──────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _clearSession();
  }

  // ─── Forgot Password ─────────────────────────────────────────────────────

  /// Sends a password-reset email via Firebase Auth REST API.
  Future<void> sendPasswordReset(String email) async {
    final res = await http.post(
      Uri.parse('$_baseAuth:sendOobCode?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requestType': 'PASSWORD_RESET',
        'email': email,
      }),
    );

    final body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw _parseError(body);
    }
  }

  // ─── Profile ─────────────────────────────────────────────────────────────

  /// Reads the user's profile from Realtime Database.
  Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$_dbUrl/users/$_uid.json?auth=$_idToken'),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load profile');
    }

    final data = jsonDecode(res.body);
    if (data == null) throw Exception('Profile not found');
    return Map<String, dynamic>.from(data);
  }

  /// Updates the user's name in Realtime Database.
  Future<void> updateProfile({required String name}) async {
    final res = await http.patch(
      Uri.parse('$_dbUrl/users/$_uid.json?auth=$_idToken'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<void> _writeUserProfile({
    required String uid,
    required String idToken,
    required String name,
    required String email,
  }) async {
    final res = await http.put(
      Uri.parse('$_dbUrl/users/$uid.json?auth=$idToken'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'role': 'customer',
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to save user profile');
    }
  }

  String _parseError(Map<String, dynamic> body) {
    final message = body['error']?['message'] ?? 'Unknown error';
    switch (message) {
      case 'EMAIL_EXISTS':
        return 'This email is already registered.';
      case 'EMAIL_NOT_FOUND':
        return 'No account found with this email.';
      case 'INVALID_PASSWORD':
        return 'Incorrect password.';
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Invalid email or password.';
      case 'USER_DISABLED':
        return 'This account has been disabled.';
      case 'WEAK_PASSWORD : Password should be at least 6 characters':
        return 'Password must be at least 6 characters.';
      default:
        return message;
    }
  }
}
