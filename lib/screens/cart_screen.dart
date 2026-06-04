import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/canteen_service.dart';
import '../../services/auth_service.dart';
import 'order_tracking_screen.dart';

class CartScreen extends StatefulWidget {
  final String canteenId;
  final Stall stall;
  final List<CartItem> cartItems;

  const CartScreen({
    super.key,
    required this.canteenId,
    required this.stall,
    required this.cartItems,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _noteCtrl = TextEditingController();
  String _pickupTime = '';
  bool _placing = false;

  // Generate pickup time slots: every 15 min from now for the next 2 hours
  late final List<String> _timeSlots = _generateSlots();

  List<String> _generateSlots() {
    final slots = <String>[];
    var t = DateTime.now();
    // Round up to next 15-min mark
    final extra = 15 - (t.minute % 15);
    t = t.add(Duration(minutes: extra));
    for (int i = 0; i < 8; i++) {
      slots.add(
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
      t = t.add(const Duration(minutes: 15));
    }
    return slots;
  }

  @override
  void initState() {
    super.initState();
    _pickupTime = _timeSlots.first;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _total =>
      widget.cartItems.fold(0.0, (sum, c) => sum + c.subtotal);

  Future<void> _placeOrder() async {
    setState(() => _placing = true);
    try {
      final auth = AuthService();
      final orderId = await CanteenService().placeOrder(
        uid: auth.uid!,
        idToken: auth.idToken!,
        canteenId: widget.canteenId,
        stallId: widget.stall.id,
        stallName: widget.stall.name,
        cartItems: widget.cartItems,
        pickupTime: _pickupTime,
        note: _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customize Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order items
            ...widget.cartItems.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.lunch_dining,
                            color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text('RM ${c.item.price.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text('x${c.quantity}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),

            const Divider(height: 24),

            // Pickup time
            const Text('Pickup Time',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _pickupTime,
              decoration: const InputDecoration(),
              items: _timeSlots
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _pickupTime = v!),
            ),

            const SizedBox(height: 16),

            // Note / customisation
            const Text('Note / Customize',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Add notes or special requests...'),
            ),

            const SizedBox(height: 24),

            // Total + CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text('RM ${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _placing ? null : _placeOrder,
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _placing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Proceed to Pay',
                      style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
