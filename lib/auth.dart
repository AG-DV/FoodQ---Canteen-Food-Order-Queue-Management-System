// Simple authentication and account management module
// No external dependencies, no JSON serialization

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

/// Service that handles user registration, login, and lookup.
class AuthService {
  final List<User> _users = [];
  int _nextId = 1;

  /// Registers a new user. Throws if the email is already taken.
  User register({
    required String name,
    required String email,
    required String role,
    required String phone,
    required String password,
  }) {
    if (_users.any((u) => u.email == email)) {
      throw Exception('User with email $email already exists');
    }
    final user = User(
      id: _nextId++,
      name: name,
      email: email,
      role: role,
      phone: phone,
      password: password,
    );
    _users.add(user);
    return user;
  }

  /// Attempts to log in with an email and password.
  /// Returns the matching [User] or null if credentials are invalid.
  User? login(String email, String password) {
    try {
      return _users.firstWhere((u) => u.email == email && u.password == password);
    } catch (_) {
      return null;
    }
  }

  /// Retrieves a user by their numeric [id], or null if not found.
  User? getUserById(int id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Returns an unmodifiable view of all registered users.
  List<User> getAllUsers() => List.unmodifiable(_users);
}
