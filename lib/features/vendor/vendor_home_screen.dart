import 'package:flutter/material.dart';
import 'orders/screens/order_dashboard_screen.dart';
import 'queue/screens/live_queue_screen.dart';
import 'menu/screens/menu_management_screen.dart';
import 'analytics/screens/analytics_screen.dart';
import 'stall/repository/stall_repository.dart';
import '../../shared/models/stall_model.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  int _index = 0;
  StallModel? _stall;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStall();
  }

  Future<void> _loadStall() async {
    final stall = await StallRepository().getMyStall();
    setState(() { _stall = stall; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_stall == null) return const _NoStallScreen();

    final screens = [
      OrderDashboardScreen(stallId: _stall!.stallId, stallName: _stall!.name),
      LiveQueueScreen(stallId: _stall!.stallId),
      MenuManagementScreen(stallId: _stall!.stallId),
      AnalyticsScreen(stallId: _stall!.stallId),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.queue_outlined),
              selectedIcon: Icon(Icons.queue),
              label: 'Queue'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Menu'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Analytics'),
        ],
      ),
    );
  }
}

class _NoStallScreen extends StatelessWidget {
  const _NoStallScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FoodQ Vendor')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No stall found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                'Ask your canteen manager to create your stall in the system first.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
