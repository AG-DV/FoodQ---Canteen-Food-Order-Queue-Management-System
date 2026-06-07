import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:canteen_food_ordering_and_queue_management_system/services/canteen_service.dart';
import 'package:canteen_food_ordering_and_queue_management_system/models/models.dart';

// ─── Helper ───────────────────────────────────────────────────────────────────

http.Client mockClient(int statusCode, String body) {
  return MockClient((request) async => http.Response(body, statusCode));
}

void main() {

  // ─── getCanteens ──────────────────────────────────────────────────────────

  group('getCanteens', () {
    test('returns a list of Canteen objects on success', () async {
      const fakeBody = '''
        {
          "-c1": { "name": "Main Canteen", "location": "Block A" },
          "-c2": { "name": "Tech Canteen", "location": "Block B" }
        }
      ''';

      final service = CanteenService.withClient(mockClient(200, fakeBody));

      final canteens = await service.getCanteens();

      expect(canteens.length, equals(2));
      expect(canteens.map((c) => c.name), containsAll(['Main Canteen', 'Tech Canteen']));
    });

    test('returns empty list when database node is null', () async {
      final service = CanteenService.withClient(mockClient(200, 'null'));

      final canteens = await service.getCanteens();

      expect(canteens, isEmpty);
    });

    test('throws exception when status is not 200', () async {
      final service = CanteenService.withClient(
        mockClient(500, '{"error": "Internal Server Error"}'),
      );

      expect(() => service.getCanteens(), throwsException);
    });
  });

  // ─── getStalls ────────────────────────────────────────────────────────────

  group('getStalls', () {
    test('returns a list of Stall objects for a given canteenId', () async {
      const fakeBody = '''
        {
          "-s1": { "name": "Nasi Lemak Corner", "category": "Malaysian" },
          "-s2": { "name": "Western Grill", "category": "Western" }
        }
      ''';

      final service = CanteenService.withClient(mockClient(200, fakeBody));

      final stalls = await service.getStalls('-c1');

      expect(stalls.length, equals(2));
      expect(stalls.map((s) => s.name), containsAll(['Nasi Lemak Corner', 'Western Grill']));
    });

    test('returns empty list when no stalls exist for canteen', () async {
      final service = CanteenService.withClient(mockClient(200, 'null'));

      final stalls = await service.getStalls('-c1');

      expect(stalls, isEmpty);
    });

    test('throws exception when status is not 200', () async {
      final service = CanteenService.withClient(
        mockClient(400, '{"error": "Bad Request"}'),
      );

      expect(() => service.getStalls('-c1'), throwsException);
    });
  });

  // ─── getMenu ──────────────────────────────────────────────────────────────

  group('getMenu', () {
    test('returns a list of MenuItem objects for a given stall', () async {
      const fakeBody = '''
        {
          "-m1": { "name": "Nasi Lemak", "price": 5.50, "isAvailable": true },
          "-m2": { "name": "Milo Ais",   "price": 2.00, "isAvailable": true },
          "-m3": { "name": "Rendang",    "price": 7.00, "isAvailable": false }
        }
      ''';

      final service = CanteenService.withClient(mockClient(200, fakeBody));

      final menu = await service.getMenu('-c1', '-s1');

      expect(menu.length, equals(3));
      expect(menu.map((m) => m.name), containsAll(['Nasi Lemak', 'Milo Ais', 'Rendang']));
    });

    test('returns empty list when menu node is null', () async {
      final service = CanteenService.withClient(mockClient(200, 'null'));

      final menu = await service.getMenu('-c1', '-s1');

      expect(menu, isEmpty);
    });

    test('includes unavailable items in the returned list', () async {
      const fakeBody = '''
        {
          "-m1": { "name": "Nasi Lemak", "price": 5.50, "isAvailable": true },
          "-m2": { "name": "Rendang",    "price": 7.00, "isAvailable": false }
        }
      ''';

      final service = CanteenService.withClient(mockClient(200, fakeBody));

      final menu = await service.getMenu('-c1', '-s1');

      expect(menu.length, equals(2));
      expect(menu.where((m) => m.isAvailable == false).length, equals(1));
    });

    test('throws exception when status is not 200', () async {
      final service = CanteenService.withClient(
        mockClient(404, '{"error": "Not found"}'),
      );

      expect(() => service.getMenu('-c1', '-s1'), throwsException);
    });
  });

  // ─── placeOrder ───────────────────────────────────────────────────────────

  group('placeOrder', () {
    final fakeCartItems = [
      CartItem(
        item: MenuItem(id: '-m1', name: 'Nasi Lemak', price: 5.50, category: 'Malaysian', isAvailable: true),
        quantity: 2,
      ),
      CartItem(
        item: MenuItem(id: '-m2', name: 'Milo Ais', price: 2.00, category: 'Beverage', isAvailable: true),
        quantity: 1,
      ),
    ];

    test('returns an orderId string starting with ORD on success', () async {
      // placeOrder makes two PUT requests; both must return 200
      final service = CanteenService.withClient(
        MockClient((request) async => http.Response('{"status": "ok"}', 200)),
      );

      final orderId = await service.placeOrder(
        userId: '-user1',
        canteenId: '-c1',
        stallId: '-s1',
        stallName: 'Nasi Lemak Corner',
        cartItems: fakeCartItems,
        pickupTime: '12:30',
        note: '',
      );

      expect(orderId, startsWith('ORD'));
    });

    test('orderId contains current timestamp in milliseconds', () async {
      final before = DateTime.now().millisecondsSinceEpoch;

      final service = CanteenService.withClient(
        MockClient((request) async => http.Response('{}', 200)),
      );

      final orderId = await service.placeOrder(
        userId: '-user1',
        canteenId: '-c1',
        stallId: '-s1',
        stallName: 'Nasi Lemak Corner',
        cartItems: fakeCartItems,
        pickupTime: '12:30',
        note: '',
      );

      final after = DateTime.now().millisecondsSinceEpoch;
      final timestamp = int.parse(orderId.replaceFirst('ORD', ''));

      expect(timestamp, greaterThanOrEqualTo(before));
      expect(timestamp, lessThanOrEqualTo(after));
    });

    test('throws exception when first PUT returns non-200', () async {
      final service = CanteenService.withClient(
        MockClient((request) async => http.Response('{}', 500)),
      );

      expect(
        () => service.placeOrder(
          userId: '-user1',
          canteenId: '-c1',
          stallId: '-s1',
          stallName: 'Nasi Lemak Corner',
          cartItems: fakeCartItems,
          pickupTime: '12:30',
          note: '',
        ),
        throwsException,
      );
    });

    test('calculates correct total from cart items', () async {
      // 2 x 5.50 + 1 x 2.00 = 13.00
      String? capturedBody;

      final service = CanteenService.withClient(
        MockClient((request) async {
          capturedBody ??= request.body;
          return http.Response('{}', 200);
        }),
      );

      await service.placeOrder(
        userId: '-user1',
        canteenId: '-c1',
        stallId: '-s1',
        stallName: 'Nasi Lemak Corner',
        cartItems: fakeCartItems,
        pickupTime: '12:30',
        note: '',
      );

      expect(capturedBody, contains('"total":13.0'));
    });
  });

  // ─── getOrder ─────────────────────────────────────────────────────────────

  group('getOrder', () {
    test('returns an Order object when the order exists', () async {
      const fakeOrder = '''
        {
          "stallId": "-s1",
          "stallName": "Nasi Lemak Corner",
          "canteenId": "-c1",
          "total": 13.0,
          "status": "pending",
          "pickupCode": "4521",
          "pickupTime": "12:30",
          "note": "",
          "createdAt": "2026-01-01T12:00:00.000",
          "items": []
        }
      ''';

      final service = CanteenService.withClient(mockClient(200, fakeOrder));

      final order = await service.getOrder('-user1', 'ORD1234567890');

      expect(order, isNotNull);
      expect(order!.status, equals('pending'));
      expect(order.pickupCode, equals('4521'));
    });

    test('returns null when order document does not exist', () async {
      final service = CanteenService.withClient(mockClient(200, 'null'));

      final order = await service.getOrder('-user1', 'ORD9999999999');

      expect(order, isNull);
    });

    test('returns null when status is not 200', () async {
      final service = CanteenService.withClient(
        mockClient(404, '{"error": "Not found"}'),
      );

      final order = await service.getOrder('-user1', 'ORD9999');

      expect(order, isNull);
    });
  });

  // ─── getOrderHistory ──────────────────────────────────────────────────────

  group('getOrderHistory', () {
    test('returns all orders for a user sorted newest first', () async {
      const fakeOrders = '''
        {
          "ORD100": {
            "stallId": "-s1", "stallName": "Stall A", "canteenId": "-c1",
            "total": 5.50, "status": "completed", "pickupCode": "1111",
            "pickupTime": "11:00", "note": "", "items": [],
            "createdAt": "2026-01-01T11:00:00.000"
          },
          "ORD200": {
            "stallId": "-s1", "stallName": "Stall A", "canteenId": "-c1",
            "total": 8.00, "status": "pending", "pickupCode": "2222",
            "pickupTime": "13:00", "note": "", "items": [],
            "createdAt": "2026-01-02T13:00:00.000"
          }
        }
      ''';

      final service = CanteenService.withClient(mockClient(200, fakeOrders));

      final orders = await service.getOrderHistory('-user1');

      expect(orders.length, equals(2));
      // Newest (ORD200, 2 Jan) should be first
      expect(orders.first.id, equals('ORD200'));
      expect(orders.last.id, equals('ORD100'));
    });

    test('returns empty list when user has no orders', () async {
      final service = CanteenService.withClient(mockClient(200, 'null'));

      final orders = await service.getOrderHistory('-user1');

      expect(orders, isEmpty);
    });

    test('throws exception when status is not 200', () async {
      final service = CanteenService.withClient(
        mockClient(400, '{"error": "Bad Request"}'),
      );

      expect(() => service.getOrderHistory('-user1'), throwsException);
    });
  });

  // ─── confirmPickup ────────────────────────────────────────────────────────

  group('confirmPickup', () {
    test('completes without throwing on success', () async {
      final service = CanteenService.withClient(
        mockClient(200, '{"status": "completed"}'),
      );

      await expectLater(
        service.confirmPickup('-user1', 'ORD1234567890'),
        completes,
      );
    });

    test('sends a PATCH request to the correct order path', () async {
      Uri? capturedUri;
      String? capturedMethod;

      final service = CanteenService.withClient(
        MockClient((request) async {
          capturedUri = request.url;
          capturedMethod = request.method;
          return http.Response('{}', 200);
        }),
      );

      await service.confirmPickup('-user1', 'ORD1234567890');

      expect(capturedMethod, equals('PATCH'));
      expect(capturedUri.toString(), contains('/orders/-user1/ORD1234567890.json'));
    });

    test('sends status "completed" in the request body', () async {
      String? capturedBody;

      final service = CanteenService.withClient(
        MockClient((request) async {
          capturedBody = request.body;
          return http.Response('{}', 200);
        }),
      );

      await service.confirmPickup('-user1', 'ORD1234567890');

      expect(capturedBody, contains('"status":"completed"'));
    });
  });
}
