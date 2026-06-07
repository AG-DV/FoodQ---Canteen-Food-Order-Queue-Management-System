import 'dart:convert';
import 'package:http/http.dart' as http;

const String _dbUrl =
    'https://foodq-canteen-system-default-rtdb.asia-southeast1.firebasedatabase.app/';

class NotificationService {
  static Future<void> notifyOrderAccepted({
    required String customerId,
    required String orderId,
    required String stallName,
    required String idToken,
  }) async {
    final shortId = orderId.substring(0, 6).toUpperCase();
    await _write(
      customerId: customerId,
      idToken: idToken,
      payload: {
        'orderId': orderId,
        'title': 'Order Accepted 👨‍🍳',
        'body': 'Your order #$shortId from $stallName is being prepared.',
        'type': 'order_accepted',
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> notifyOrderReady({
    required String customerId,
    required String orderId,
    required String stallName,
    required String idToken,
  }) async {
    final shortId = orderId.substring(0, 6).toUpperCase();
    await _write(
      customerId: customerId,
      idToken: idToken,
      payload: {
        'orderId': orderId,
        'title': 'Order Ready! 🍽️',
        'body': 'Your order #$shortId from $stallName is ready for pickup.',
        'type': 'order_ready',
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> notifyOrderCancelled({
    required String customerId,
    required String orderId,
    required String stallName,
    required String idToken,
  }) async {
    final shortId = orderId.substring(0, 6).toUpperCase();
    await _write(
      customerId: customerId,
      idToken: idToken,
      payload: {
        'orderId': orderId,
        'title': 'Order Cancelled',
        'body': 'Your order #$shortId from $stallName has been cancelled.',
        'type': 'order_cancelled',
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> _write({
    required String customerId,
    required String idToken,
    required Map<String, dynamic> payload,
  }) async {
    await http.post(
      Uri.parse('$_dbUrl/notifications/$customerId.json?auth=$idToken'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }
}
