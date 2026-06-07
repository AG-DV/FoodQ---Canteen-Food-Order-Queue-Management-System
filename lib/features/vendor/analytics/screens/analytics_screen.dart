import 'package:flutter/material.dart';
import '../../../../shared/models/order_model.dart';
import '../../orders/repository/order_repository.dart';

class AnalyticsScreen extends StatefulWidget {
  final String stallId;
  const AnalyticsScreen({super.key, required this.stallId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _repo = OrderRepository();
  List<OrderModel> _orders = [];
  bool _loading = true;
  String _period = 'Today';
  static const _periods = ['Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await _repo.getCompletedOrdersToday(widget.stallId);
    if (mounted) setState(() { _orders = orders; _loading = false; });
  }

  int get _totalOrders => _orders.length;
  double get _totalRevenue => _orders.fold(0.0, (s, o) => s + o.totalAmount);
  double get _avgOrder => _totalOrders == 0 ? 0 : _totalRevenue / _totalOrders;

  List<MapEntry<String, int>> get _topItems {
    final counts = <String, int>{};
    for (final o in _orders) {
      for (final i in o.items) {
        counts[i.name] = (counts[i.name] ?? 0) + i.quantity;
      }
    }
    return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5).toList();
  }

  Map<int, int> get _byHour {
    final map = {for (var h = 6; h <= 22; h++) h: 0};
    for (final o in _orders) {
      try {
        final h = DateTime.parse(o.createdAt).hour;
        if (map.containsKey(h)) map[h] = map[h]! + 1;
      } catch (_) {}
    }
    return map;
  }

  int get _peakHour {
    final h = _byHour;
    if (h.isEmpty) return -1;
    return h.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _PeriodSelector(
                    periods: _periods,
                    selected: _period,
                    onChanged: (p) => setState(() => _period = p),
                  ),
                  const SizedBox(height: 16),
                  _SummaryRow(
                    totalOrders: _totalOrders,
                    totalRevenue: _totalRevenue,
                    avgOrderValue: _avgOrder,
                  ),
                  const SizedBox(height: 20),
                  if (_peakHour != -1) ...[
                    _PeakHourCard(peakHour: _peakHour),
                    const SizedBox(height: 20),
                  ],
                  const _SectionTitle(title: 'Orders by Hour'),
                  const SizedBox(height: 12),
                  _HourlyChart(byHour: _byHour),
                  const SizedBox(height: 20),
                  const _SectionTitle(title: 'Top Selling Items'),
                  const SizedBox(height: 12),
                  _topItems.isEmpty
                      ? const _Empty(msg: 'No sales data yet')
                      : _TopItems(items: _topItems),
                  const SizedBox(height: 20),
                  const _SectionTitle(title: 'Recent Completed Orders'),
                  const SizedBox(height: 12),
                  _orders.isEmpty
                      ? const _Empty(msg: 'No completed orders today')
                      : _RecentOrders(orders: _orders.reversed.take(10).toList()),
                ],
              ),
            ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final List<String> periods;
  final String selected;
  final ValueChanged<String> onChanged;
  const _PeriodSelector({required this.periods, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: periods.map((p) {
        final isSelected = p == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(p,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Theme.of(context).colorScheme.onPrimary : null)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int totalOrders;
  final double totalRevenue, avgOrderValue;
  const _SummaryRow({required this.totalOrders, required this.totalRevenue, required this.avgOrderValue});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(label: 'Orders', value: '$totalOrders', icon: Icons.receipt_long, color: Colors.orange),
        const SizedBox(width: 10),
        _StatCard(label: 'Revenue', value: 'RM ${totalRevenue.toStringAsFixed(2)}', icon: Icons.attach_money, color: Colors.green),
        const SizedBox(width: 10),
        _StatCard(label: 'Avg Order', value: 'RM ${avgOrderValue.toStringAsFixed(2)}', icon: Icons.bar_chart, color: Colors.blue),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _PeakHourCard extends StatelessWidget {
  final int peakHour;
  const _PeakHourCard({required this.peakHour});

  String _fmt(int h) {
    final s = h < 12 ? 'AM' : 'PM';
    final d = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$d:00 $s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Peak Hour Today',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              Text(_fmt(peakHour), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HourlyChart extends StatelessWidget {
  final Map<int, int> byHour;
  const _HourlyChart({required this.byHour});

  @override
  Widget build(BuildContext context) {
    if (byHour.isEmpty) return const _Empty(msg: 'No data');
    final max = byHour.values.reduce((a, b) => a > b ? a : b);
    final entries = byHour.entries.toList();

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((e) {
          final ratio = max == 0 ? 0.0 : e.value / max;
          final active = e.value > 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (active) Text('${e.value}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 80 * ratio + (active ? 4 : 2),
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(e.key % 3 == 0 ? '${e.key}' : '',
                      style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopItems extends StatelessWidget {
  final List<MapEntry<String, int>> items;
  const _TopItems({required this.items});

  static const _colors = [Colors.orange, Colors.blue, Colors.green, Colors.purple, Colors.red];

  @override
  Widget build(BuildContext context) {
    final max = items.first.value;
    return Column(
      children: items.asMap().entries.map((e) {
        final rank = e.key;
        final item = e.value;
        final ratio = max == 0 ? 0.0 : item.value / max;
        final color = _colors[rank % _colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Text('${rank + 1}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rank == 0 ? Colors.amber : Colors.grey)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(item.key,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
                        Text('${item.value} sold',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  final List<OrderModel> orders;
  const _RecentOrders({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: orders.map((o) {
        final shortId = o.orderId.substring(0, 6).toUpperCase();
        final items = o.items.map((i) => '${i.quantity}x ${i.name}').join(', ');
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text('#$shortId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 10),
              Expanded(child: Text(items,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text('RM ${o.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }
}

class _Empty extends StatelessWidget {
  final String msg;
  const _Empty({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ),
    );
  }
}
