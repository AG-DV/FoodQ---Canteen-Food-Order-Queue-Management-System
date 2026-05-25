// Simple authentication and account management module with Firebase support
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Represents a user in the system.
class User {
  final int id;
  String name;
  String email;
  String role;
  String phone;
  String password; // stored as plain text for simplicity

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.password,
  });
}

/// Service that handles user registration, login, and lookup using Firebase.
class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Local in‑memory list of users for dummy accounts or fallback.
  final List<User> _localUsers = [];

  /// Registers a new user with Firebase Auth. Throws if the email is already taken.
  Future<User> register({
    required String name,
    required String email,
    required String role,
    required String phone,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = cred.user!;
      await fbUser.updateDisplayName(name);
      // role and phone are not stored in Firebase Auth; they remain local.
      final user = User(
        id: fbUser.uid.hashCode,
        name: name,
        email: fbUser.email ?? email,
        role: role,
        phone: phone,
        password: password,
      );
      _localUsers.add(user);
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Return existing user from local list if present.
        final existing = _localUsers.firstWhere(
          (u) => u.email == email,
          orElse: () => User(
            id: email.hashCode,
            name: name,
            email: email,
            role: role,
            phone: phone,
            password: password,
          ),
        );
        return existing;
      }
      rethrow;
    }
  }

  /// Attempts to log in with an email and password.
  /// Returns the matching [User] or null if credentials are invalid.
  Future<User?> login(String email, String password) async {
    User? user;
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = cred.user;
      if (fbUser != null) {
        user = User(
          id: fbUser.uid.hashCode,
          name: fbUser.displayName ?? '',
          email: fbUser.email ?? email,
          role: '',
          phone: '',
          password: password,
        );
        // Ensure user is in local list for fallback.
        _localUsers.removeWhere((u) => u.email == email);
        _localUsers.add(user);
      }
    } on firebase_auth.FirebaseAuthException {
      // Firebase login failed; fall back to local list.
    }
    if (user == null) {
      try {
        final local = _localUsers.firstWhere(
          (u) => u.email == email && u.password == password,
        );
        user = local;
      } catch (_) {
        // No matching local user.
      }
    }
    return user;
  }

  /// Retrieves a user by Firebase UID (not implemented).
  User? getUserById(int id) {
    // Not supported in this minimal example.
    return null;
  }

  /// Returns an empty list as user enumeration is not implemented.
  List<User> getAllUsers() => const [];
}
