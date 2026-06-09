import 'package:flutter/material.dart';
import '../../models/manager_models.dart';
import '../../services/canteen_service.dart';
import '../../services/manager_service.dart';
import '../profile_screen.dart';
import 'manager_tabs.dart';

// Main screen that controls all Manager pages and data.
class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  // Service and state values used by the Manager interface.
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
    // Load Manager data when the screen first opens.
    _loadData();
  }

  // Loads the canteen, stall, order and complaint data.
  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final canteens = await CanteenService().getCanteens();
      if (canteens.isEmpty) throw Exception('No canteen found');

      // The prototype currently uses the first available canteen.
      final canteen = canteens.first;
      final stalls = await _service.getStalls(canteen.id);
      final complaints = await _service.getComplaints();

      // Save the loaded data and rebuild the interface.
      if (!mounted) return;
      setState(() {
        _canteenName = canteen.name;
        _stalls = stalls;
        _complaints = complaints;
        _loading = false;
      });
    } catch (e) {
      // Stop loading and show an error if a request fails.
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(e.toString(), error: true);
    }
  }

  // Calculates the total active orders from all stalls.
  int get _activeOrders =>
      _stalls.fold(0, (sum, stall) => sum + stall.activeOrders);

  // Calculates the total number of people in all queues.
  int get _queueCount =>
      _stalls.fold(0, (sum, stall) => sum + stall.queueCount);

  // Counts complaints that have not been resolved.
  int get _openComplaints =>
      _complaints.where((item) => item.status != 'Resolved').length;

  // Generates alerts from high congestion and open complaints.
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
    // Connect Manager data and callbacks to the five tab pages.
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

    // Build the app bar, selected page and bottom navigation.
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

  // Sends a redirect notice for a crowded stall.
  Future<void> _sendNotice(String stallName) async {
    try {
      await _service.sendRedirectNotice(stallName);
      _showMessage('Redirect notice sent.');
    } catch (e) {
      _showMessage(e.toString(), error: true);
    }
  }

  // Opens a notes dialog and updates the selected complaint.
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
    // Stop when the manager cancels the dialog.
    if (notes == null) return;

    try {
      // Update Firebase before changing the local screen data.
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

  // Shows a success or error message at the bottom of the screen.
  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }
}
