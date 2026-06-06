import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/canteen_service.dart';
import '../../services/auth_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Order? _order;
  bool _loading = true;
  Timer? _pollTimer;

  static const _steps = [
    _Step('Order Received', Icons.check_circle_outline),
    _Step('Preparing', Icons.soup_kitchen_outlined),
    _Step('Ready for Pickup', Icons.storefront_outlined),
    _Step('Completed', Icons.done_all),
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrder();
    // Poll every 5 seconds for status updates
    _pollTimer = Timer.periodic(
        const Duration(seconds: 5), (_) => _fetchOrder(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrder({bool silent = false}) async {
    final auth = AuthService();
    await auth.loadSession();
    try {
      final order = await CanteenService()
          .getOrder(auth.currentUserId!, widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
      // Stop polling once completed
      if (order?.status == 'completed') _pollTimer?.cancel();
    } catch (_) {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmPickup() async {
    final auth = AuthService();
    await auth.loadSession();
    await CanteenService()
        .confirmPickup(auth.currentUserId!, widget.orderId);
    await _fetchOrder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        // Prevent going back to cart
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Home'),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final o = _order!;
    final currentStep = o.statusIndex;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order ID
          Text('Order ID: #${o.id}',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Text(o.stallName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),

          // Timeline stepper
          ...List.generate(_steps.length, (i) {
            final done = i < currentStep;
            final active = i == currentStep;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dot + line
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done || active
                            ? Colors.orange
                            : Colors.grey.shade300,
                      ),
                      child: Icon(
                        done ? Icons.check : _steps[i].icon,
                        size: 14,
                        color: done || active
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                    if (i < _steps.length - 1)
                      Container(
                        width: 2,
                        height: 48,
                        color: done
                            ? Colors.orange
                            : Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _steps[i].label,
                          style: TextStyle(
                            fontWeight: active || done
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: active
                                ? Colors.orange
                                : done
                                    ? Colors.black87
                                    : Colors.grey,
                          ),
                        ),
                        if (i == 2 && (done || active))
                          const Text('Please collect at the stall',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        if (i == 3 && done)
                          const Text('Thanks for your order!',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),

          // Pickup code box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('Pickup Code',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  o.pickupCode,
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8),
                ),
                const SizedBox(height: 4),
                Text('Pickup at: ${o.pickupTime}',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // "I've Picked Up" button — shown when ready
          if (o.status == 'ready')
            FilledButton(
              onPressed: _confirmPickup,
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text("I've Picked Up",
                  style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
  }
}

class _Step {
  final String label;
  final IconData icon;
  const _Step(this.label, this.icon);
}
