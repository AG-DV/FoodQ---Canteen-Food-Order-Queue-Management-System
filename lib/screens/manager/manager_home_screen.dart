import 'package:flutter/material.dart';
import '../../models/manager_models.dart';
import '../../services/canteen_service.dart';
import '../../services/manager_service.dart';
import '../profile_screen.dart';
import 'manager_tabs.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  final ManagerService _service = ManagerService();
  int _selectedIndex = 0;
  bool _loading = true;
  String _canteenName = 'FoodQ Canteen';
  String _complaintFilter = 'All';
  List<ManagerStall> _stalls = [];
  List<ManagerComplaint> _complaints = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final canteens = await CanteenService().getCanteens();
      if (canteens.isEmpty) throw Exception('No canteen found');

      final canteen = canteens.first;
      final stalls = await _service.getStalls(canteen.id);
      final complaints = await _service.getComplaints();

      if (!mounted) return;
      setState(() {
        _canteenName = canteen.name;
        _stalls = stalls;
        _complaints = complaints;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(e.toString(), error: true);
    }
  }

  int get _activeOrders =>
      _stalls.fold(0, (sum, stall) => sum + stall.activeOrders);

  int get _queueCount =>
      _stalls.fold(0, (sum, stall) => sum + stall.queueCount);

  int get _openComplaints =>
      _complaints.where((item) => item.status != 'Resolved').length;

  List<ManagerAlert> get _alerts {
    final alerts = <ManagerAlert>[];

    for (final stall in _stalls) {
      if (stall.congestionLevel == 'High') {
        alerts.add(
          ManagerAlert(
            title: 'High Congestion',
            message: '${stall.name} has ${stall.queueCount} people in queue.',
            level: 'Critical',
          ),
        );
      }
    }

    if (_openComplaints > 0) {
      alerts.add(
        ManagerAlert(
          title: 'Open Complaints',
          message: '$_openComplaints complaint(s) need attention.',
          level: 'Warning',
        ),
      );
    }

    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      managerDashboard(
        stalls: _stalls,
        activeOrders: _activeOrders,
        queueCount: _queueCount,
        openComplaints: _openComplaints,
        alertCount: _alerts.length,
      ),
      managerQueues(_stalls, _sendNotice),
      managerComplaints(
        complaints: _complaints,
        filter: _complaintFilter,
        onFilterChanged: (value) {
          setState(() => _complaintFilter = value);
        },
        onUpdate: _updateComplaint,
      ),
      managerReports(_stalls),
      managerAlerts(_alerts),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_canteenName),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: pages[_selectedIndex],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            label: 'Queues',
          ),
          NavigationDestination(
            icon: Icon(Icons.feedback_outlined),
            label: 'Complaints',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }

  Future<void> _sendNotice(String stallName) async {
    try {
      await _service.sendRedirectNotice(stallName);
      _showMessage('Redirect notice sent.');
    } catch (e) {
      _showMessage(e.toString(), error: true);
    }
  }

  Future<void> _updateComplaint(
    ManagerComplaint complaint,
    String status,
  ) async {
    final controller = TextEditingController(text: complaint.resolutionNotes);
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as $status'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Resolution notes'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (notes == null) return;

    try {
      await _service.updateComplaint(
        complaintId: complaint.id,
        status: status,
        notes: notes,
      );
      setState(() {
        complaint.status = status;
        complaint.resolutionNotes = notes;
      });
      _showMessage('Complaint updated.');
    } catch (e) {
      _showMessage(e.toString(), error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }
}
