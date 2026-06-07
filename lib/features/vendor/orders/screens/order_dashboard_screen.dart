import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../shared/models/order_model.dart';
import '../repository/order_repository.dart';
import '../../notifications/notification_service.dart';
import '../../../../services/auth_service.dart';

class OrderDashboardScreen extends StatefulWidget {
  final String stallId;
  final String stallName;
  const OrderDashboardScreen({
    super.key,
    required this.stallId,
    this.stallName = 'our stall',
  });

  @override
  State<OrderDashboardScreen> createState() => _OrderDashboardScreenState();
}

class _OrderDashboardScreenState extends State<OrderDashboardScreen> {
  final _repo = OrderRepository();
  StreamSubscription<List<OrderModel>>? _sub;
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sub = _repo.watchOrders(widget.stallId).listen(
      (orders) {
        if (mounted) setState(() { _orders = orders; _loading = false; });
      },
      onError: (e) {
        if (mounted) setState(() { _error = e.toString(); _loading = false; });
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  int get _pendingCount => _orders.where((o) => o.status == OrderStatus.pending).length;
  int get _preparingCount => _orders.where((o) => o.status == OrderStatus.preparing).length;
  int get _readyCount => _orders.where((o) => o.status == OrderStatus.ready).length;

  Future<void> _updateStatus(OrderModel order, OrderStatus newStatus) async {
    setState(() {
      final idx = _orders.indexWhere((o) => o.orderId == order.orderId);
      if (idx != -1) _orders[idx] = order.copyWith(status: newStatus);
    });
    try {
      await _repo.updateOrderStatus(order.orderId, newStatus);
      final token = AuthService().idToken ?? '';
      if (newStatus == OrderStatus.preparing) {
        await NotificationService.notifyOrderAccepted(
          customerId: order.customerId,
          orderId: order.orderId,
          stallName: widget.stallName,
          idToken: token,
        );
      } else if (newStatus == OrderStatus.ready) {
        await NotificationService.notifyOrderReady(
          customerId: order.customerId,
          orderId: order.orderId,
          stallName: widget.stallName,
          idToken: token,
        );
      } else if (newStatus == OrderStatus.cancelled) {
        await NotificationService.notifyOrderCancelled(
          customerId: order.customerId,
          orderId: order.orderId,
          stallName: widget.stallName,
          idToken: token,
        );
      }
    } catch (_) {
      setState(() {
        final idx = _orders.indexWhere((o) => o.orderId == order.orderId);
        if (idx != -1) _orders[idx] = order;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update order.')),
        );
      }
    }
  }

  Future<void> _confirmReject(OrderModel order) async {
    final shortId = order.orderId.substring(0, 6).toUpperCase();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Order?'),
        content: Text('Reject order #$shortId?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _updateStatus(order, OrderStatus.cancelled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Dashboard'),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('${_orders.length} active',
                    style: Theme.of(context).textTheme.labelLarge),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!)
              : Column(
                  children: [
                    _StatusSummaryBar(
                      pending: _pendingCount,
                      preparing: _preparingCount,
                      ready: _readyCount,
                    ),
                    Expanded(child: _buildOrderList()),
                  ],
                ),
    );
  }

  Widget _buildOrderList() {
    if (_orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 12),
            Text('No active orders', style: TextStyle(fontSize: 18)),
            SizedBox(height: 4),
            Text('New orders will appear here automatically',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final pending = _orders.where((o) => o.status == OrderStatus.pending).toList();
    final preparing = _orders.where((o) => o.status == OrderStatus.preparing).toList();
    final ready = _orders.where((o) => o.status == OrderStatus.ready).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (pending.isNotEmpty) ...[
          _SectionHeader(title: 'New Orders', count: pending.length, color: Colors.orange),
          ...pending.map((o) => _OrderCard(
                order: o,
                onAccept: () => _updateStatus(o, OrderStatus.preparing),
                onReject: () => _confirmReject(o),
              )),
        ],
        if (preparing.isNotEmpty) ...[
          _SectionHeader(title: 'Preparing', count: preparing.length, color: Colors.blue),
          ...preparing.map((o) => _OrderCard(
                order: o,
                onMarkReady: () => _updateStatus(o, OrderStatus.ready),
              )),
        ],
        if (ready.isNotEmpty) ...[
          _SectionHeader(title: 'Ready for Pickup', count: ready.length, color: Colors.green),
          ...ready.map((o) => _OrderCard(
                order: o,
                onMarkCollected: () => _updateStatus(o, OrderStatus.completed),
              )),
        ],
      ],
    );
  }
}

class _StatusSummaryBar extends StatelessWidget {
  final int pending, preparing, ready;
  const _StatusSummaryBar({required this.pending, required this.preparing, required this.ready});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _StatChip(label: 'New', count: pending, color: Colors.orange),
          _StatChip(label: 'Preparing', count: preparing, color: Colors.blue),
          _StatChip(label: 'Ready', count: ready, color: Colors.green),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _SectionHeader({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onAccept, onReject, onMarkReady, onMarkCollected;

  const _OrderCard({
    required this.order,
    this.onAccept,
    this.onReject,
    this.onMarkReady,
    this.onMarkCollected,
  });

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.preparing: return Colors.blue;
      case OrderStatus.ready: return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortId = order.orderId.substring(0, 6).toUpperCase();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _statusColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('#$shortId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('Pickup: ${order.pickupTime}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 16),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('${item.quantity}x',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontSize: 14)),
                            if (item.customization.isNotEmpty)
                              Text('📝 ${item.customization}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text('RM ${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),
            const Divider(height: 16),
            Row(
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('RM ${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            if (onAccept != null || onReject != null || onMarkReady != null || onMarkCollected != null) ...[
              const SizedBox(height: 12),
              _buildActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (order.status == OrderStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: onReject,
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(onPressed: onAccept, child: const Text('Accept')),
          ),
        ],
      );
    }
    if (order.status == OrderStatus.preparing) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: onMarkReady,
          icon: const Icon(Icons.check),
          label: const Text('Mark as Ready'),
        ),
      );
    }
    if (order.status == OrderStatus.ready) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.green),
          onPressed: onMarkCollected,
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text('Mark as Collected'),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case OrderStatus.pending: color = Colors.orange; label = 'New'; break;
      case OrderStatus.preparing: color = Colors.blue; label = 'Preparing'; break;
      case OrderStatus.ready: color = Colors.green; label = 'Ready'; break;
      case OrderStatus.completed: color = Colors.grey; label = 'Completed'; break;
      case OrderStatus.cancelled: color = Colors.red; label = 'Cancelled'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Failed to load orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
