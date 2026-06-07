import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../shared/models/order_model.dart';
import '../../orders/repository/order_repository.dart';

class LiveQueueScreen extends StatefulWidget {
  final String stallId;
  const LiveQueueScreen({super.key, required this.stallId});

  @override
  State<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends State<LiveQueueScreen>
    with SingleTickerProviderStateMixin {
  final _repo = OrderRepository();
  StreamSubscription<List<OrderModel>>? _sub;
  List<OrderModel> _orders = [];
  bool _loading = true;
  late TabController _tabController;

  static const _tabs = ['All', 'Pending', 'Preparing', 'Ready'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _sub = _repo.watchOrders(widget.stallId).listen((orders) {
      if (mounted) setState(() { _orders = orders; _loading = false; });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  List<OrderModel> _filtered(String tab) {
    switch (tab) {
      case 'Pending': return _orders.where((o) => o.status == OrderStatus.pending).toList();
      case 'Preparing': return _orders.where((o) => o.status == OrderStatus.preparing).toList();
      case 'Ready': return _orders.where((o) => o.status == OrderStatus.ready).toList();
      default: return _orders;
    }
  }

  Future<void> _updateStatus(OrderModel order, OrderStatus status) async {
    setState(() {
      final idx = _orders.indexWhere((o) => o.orderId == order.orderId);
      if (idx != -1) _orders[idx] = order.copyWith(status: status);
    });
    try {
      await _repo.updateOrderStatus(order.orderId, status);
    } catch (_) {
      setState(() {
        final idx = _orders.indexWhere((o) => o.orderId == order.orderId);
        if (idx != -1) _orders[idx] = order;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Queue'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) {
            final count = t == 'All' ? _orders.length : _filtered(t).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((t) => _QueueList(orders: _filtered(t), onUpdateStatus: _updateStatus))
                  .toList(),
            ),
    );
  }
}

class _QueueList extends StatelessWidget {
  final List<OrderModel> orders;
  final Future<void> Function(OrderModel, OrderStatus) onUpdateStatus;
  const _QueueList({required this.orders, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No orders here', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _QueueRow(order: orders[i], onUpdateStatus: onUpdateStatus),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final OrderModel order;
  final Future<void> Function(OrderModel, OrderStatus) onUpdateStatus;
  const _QueueRow({required this.order, required this.onUpdateStatus});

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
    final itemSummary = order.items.map((i) => '${i.quantity}x ${i.name}').join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('#$shortId',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(itemSummary,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('Pickup: ${order.pickupTime}  •  RM ${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _QuickActionButton(order: order, onUpdateStatus: onUpdateStatus),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final OrderModel order;
  final Future<void> Function(OrderModel, OrderStatus) onUpdateStatus;
  const _QuickActionButton({required this.order, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    switch (order.status) {
      case OrderStatus.pending:
        return FilledButton(
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36)),
          onPressed: () => onUpdateStatus(order, OrderStatus.preparing),
          child: const Text('Accept', style: TextStyle(fontSize: 13)),
        );
      case OrderStatus.preparing:
        return FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36)),
          onPressed: () => onUpdateStatus(order, OrderStatus.ready),
          child: const Text('Ready', style: TextStyle(fontSize: 13)),
        );
      case OrderStatus.ready:
        return FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36)),
          onPressed: () => onUpdateStatus(order, OrderStatus.completed),
          child: const Text('Collected', style: TextStyle(fontSize: 13)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
