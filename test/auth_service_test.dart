import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:canteen_food_ordering_and_queue_management_system/services/auth_service.dart';

// ─── Helper ───────────────────────────────────────────────────────────────────

http.Client mockClient(int statusCode, String body) {
  return MockClient((request) async => http.Response(body, statusCode));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ─── register ─────────────────────────────────────────────────────────────

  group('register', () {
    test('sets currentUserId to the Firebase push key on success', () async {
      final service = AuthService.withClient(
        mockClient(200, '{"name": "-abc123"}'),
      );

      await service.register(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
      );

      expect(service.currentUserId, equals('-abc123'));
    });

    test(' is true after successful register', () async {
      final service = AuthService.withClient(
        mockClient(200, '{"name": "-abc123"}'),
      );

      await service.register(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
      );

      expect(service.isLoggedIn, isTrue);
    });

    test('throws exception when status >= 400', () async {
      final service = AuthService.withClient(
        mockClient(400, '{"error": "Permission denied"}'),
      );

      expect(
        () => service.register(
          name: 'Test User',
          email: 'test@example.com',
          password: 'password123',
        ),
        throwsException,
      );
    });
  });

  // ─── login ────────────────────────────────────────────────────────────────

  group('login', () {
    const fakeDb = '''
      {
        "-user1": {
          "email": "alice@example.com",
          "password": "pass1234",
          "name": "Alice",
          "role": "customer"
        }
      }
    ''';

    test('returns true and sets currentUserId when credentials match', () async {
      final service = AuthService.withClient(mockClient(200, fakeDb));

      final result = await service.login(
        email: 'alice@example.com',
        password: 'pass1234',
      );

      expect(result, isTrue);
      expect(service.currentUserId, equals('-user1'));
    });

    test('persists currentUserId to SharedPreferences on success', () async {
      final service = AuthService.withClient(mockClient(200, fakeDb));

      await service.login(email: 'alice@example.com', password: 'pass1234');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('currentUserId'), equals('-user1'));
    });

    test('returns false when email does not match any record', () async {
      final service = AuthService.withClient(mockClient(200, fakeDb));

      final result = await service.login(
        email: 'wrong@example.com',
        password: 'pass1234',
      );

      expect(result, isFalse);
      expect(service.currentUserId, isNull);
    });

    test('returns false when password is incorrect', () async {
      final service = AuthService.withClient(mockClient(200, fakeDb));

      final result = await service.login(
        email: 'alice@example.com',
        password: 'wrongpassword',
      );

      expect(result, isFalse);
    });

    test('returns false when database is empty', () async {
      final service = AuthService.withClient(mockClient(200, 'null'));

      final result = await service.login(
        email: 'alice@example.com',
        password: 'pass1234',
      );

      expect(result, isFalse);
    });

    test('throws exception when status >= 400', () async {
      final service = AuthService.withClient(
        mockClient(400, '{"error": "Permission denied"}'),
      );

      expect(
        () => service.login(email: 'a@b.com', password: '123'),
        throwsException,
      );
    });
  });

  // ─── getProfile ───────────────────────────────────────────────────────────

  group('getProfile', () {
    test('returns correct profile map on success', () async {
      const fakeProfile = '''
        {
          "name": "Alice",
          "email": "alice@example.com",
          "role": "customer",
          "createdAt": "2026-01-01T00:00:00.000"
        }
      ''';

      final service = AuthService.withClient(mockClient(200, fakeProfile));

      final profile = await service.getProfile('-user1');

      expect(profile['name'], equals('Alice'));
      expect(profile['email'], equals('alice@example.com'));
      expect(profile['role'], equals('customer'));
    });

    test('throws exception when status >= 400', () async {
      final service = AuthService.withClient(
        mockClient(404, '{"error": "Not found"}'),
      );

      expect(() => service.getProfile('-nonexistent'), throwsException);
    });
  });

  // ─── updateProfile ────────────────────────────────────────────────────────

  group('updateProfile', () {
    test('completes without throwing on success', () async {
      final service = AuthService.withClient(
        mockClient(200, '{"name": "New Name"}'),
      );

      await expectLater(
        service.updateProfile(userId: '-user1', name: 'New Name'),
        completes,
      );
    });

    test('throws exception when status >= 400', () async {
      final service = AuthService.withClient(
        mockClient(400, '{"error": "Permission denied"}'),
      );

      expect(
        () => service.updateProfile(userId: '-user1', name: 'New Name'),
        throwsException,
      );
    });
  });

  // ─── deleteUser ───────────────────────────────────────────────────────────

  group('deleteUser', () {
    test('completes without throwing on success', () async {
      final service = AuthService.withClient(mockClient(200, 'null'));

      await expectLater(service.deleteUser('-user1'), completes);
    });

    test('throws exception when status >= 400', () async {
      final service = AuthService.withClient(
        mockClient(403, '{"error": "Permission denied"}'),
      );

      expect(() => service.deleteUser('-user1'), throwsException);
    });
  });

  // ─── logout ───────────────────────────────────────────────────────────────

  group('logout', () {
    test('sets currentUserId to null', () async {
      final service = AuthService.withClient(mockClient(200, 'null'));
      service.currentUserId = '-user1';

      await service.logout();

      expect(service.currentUserId, isNull);
    });

    test('isL is false after logout', () async {
      final service = AuthService.withClient(mockClient(200, 'null'));
      service.currentUserId = '-user1';

      await service.logout();

      expect(service.isLoggedIn, isFalse);
    });

    test('removes currentUserId key from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'currentUserId': '-user1'});
      final service = AuthService.withClient(mockClient(200, 'null'));

      await service.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('currentUserId'), isNull);
    });
  });

  // ─── loadSession ──────────────────────────────────────────────────────────

  group('loadSession', () {
    test('restores currentUserId from SharedPreferences when a session exists', () async {
      SharedPreferences.setMockInitialValues({'currentUserId': '-user1'});
      final service = AuthService.withClient(mockClient(200, 'null'));

      await service.loadSession();

      expect(service.currentUserId, equals('-user1'));
      expect(service.isLoggedIn, isTrue);
    });

    test('currentUserId stays null when no session is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AuthService.withClient(mockClient(200, 'null'));

      await service.loadSession();

      expect(service.currentUserId, isNull);
      expect(service.isLoggedIn, isFalse);
    });
  });

  // ─── isLoggedIn ───────────────────────────────────────────────────────────

  group('isLoggedIn', () {
    test('returns false when currentUserId is null', () {
      final service = AuthService.withClient(mockClient(200, 'null'));
      expect(service.isLoggedIn, isFalse);
    });

    test('returns true when currentUserId is set', () {
      final service = AuthService.withClient(mockClient(200, 'null'));
      service.currentUserId = '-user1';
      expect(service.isLoggedIn, isTrue);
    });
  });
}
