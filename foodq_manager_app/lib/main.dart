import 'package:flutter/material.dart';

void main() {
  runApp(const FoodQManagerApp());
}

class FoodQManagerApp extends StatelessWidget {
  const FoodQManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FoodQ Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E8F6A)),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      ),
      home: const ManagerHomePage(),
    );
  }
}

class Stall {
  Stall({
    required this.name,
    required this.queueCount,
    required this.waitMinutes,
    required this.activeOrders,
    required this.sales,
    required this.rating,
  });

  final String name;
  int queueCount;
  int waitMinutes;
  int activeOrders;
  double sales;
  double rating;

  String get congestionLevel {
    if (queueCount >= 20 || waitMinutes >= 20) return 'High';
    if (queueCount >= 10 || waitMinutes >= 10) return 'Medium';
    return 'Low';
  }
}

class Complaint {
  Complaint({
    required this.id,
    required this.stallName,
    required this.issue,
    required this.status,
  });

  final String id;
  final String stallName;
  final String issue;
  String status;
}

class ManagerAlert {
  ManagerAlert({
    required this.title,
    required this.message,
    required this.level,
    required this.resolved,
  });

  final String title;
  final String message;
  final String level;
  bool resolved;
}

class ManagerHomePage extends StatefulWidget {
  const ManagerHomePage({super.key});

  @override
  State<ManagerHomePage> createState() => _ManagerHomePageState();
}

class _ManagerHomePageState extends State<ManagerHomePage> {
  int selectedIndex = 0;

  final stalls = <Stall>[
    Stall(
      name: 'Nasi Lemak Corner',
      queueCount: 8,
      waitMinutes: 7,
      activeOrders: 12,
      sales: 860,
      rating: 4.6,
    ),
    Stall(
      name: 'Wok Noodle Bar',
      queueCount: 23,
      waitMinutes: 22,
      activeOrders: 18,
      sales: 1240,
      rating: 4.1,
    ),
    Stall(
      name: 'Thosai House',
      queueCount: 13,
      waitMinutes: 12,
      activeOrders: 9,
      sales: 680,
      rating: 4.4,
    ),
    Stall(
      name: 'Campus Drinks',
      queueCount: 5,
      waitMinutes: 4,
      activeOrders: 6,
      sales: 420,
      rating: 4.7,
    ),
  ];

  final complaints = <Complaint>[
    Complaint(
      id: 'CMP-001',
      stallName: 'Wok Noodle Bar',
      issue: 'Order delayed beyond pickup time.',
      status: 'Open',
    ),
    Complaint(
      id: 'CMP-002',
      stallName: 'Nasi Lemak Corner',
      issue: 'Wrong item received by customer.',
      status: 'In Progress',
    ),
    Complaint(
      id: 'CMP-003',
      stallName: 'Campus Drinks',
      issue: 'Sold-out drink still shown as available.',
      status: 'Resolved',
    ),
  ];

  final alerts = <ManagerAlert>[
    ManagerAlert(
      title: 'High Congestion',
      message: 'Wok Noodle Bar queue is above the threshold.',
      level: 'Critical',
      resolved: false,
    ),
    ManagerAlert(
      title: 'Open Complaint',
      message: 'A customer complaint is waiting for manager action.',
      level: 'Warning',
      resolved: false,
    ),
    ManagerAlert(
      title: 'Report Ready',
      message: 'Daily stall performance report is ready.',
      level: 'Info',
      resolved: true,
    ),
  ];

  int get totalOrders =>
      stalls.fold(0, (total, stall) => total + stall.activeOrders);

  int get totalQueue =>
      stalls.fold(0, (total, stall) => total + stall.queueCount);

  double get totalSales =>
      stalls.fold(0, (total, stall) => total + stall.sales);

  int get openComplaints =>
      complaints.where((complaint) => complaint.status != 'Resolved').length;

  int get activeAlerts => alerts.where((alert) => !alert.resolved).length;

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildDashboard(),
      buildCongestion(),
      buildComplaints(),
      buildReports(),
      buildAlerts(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FoodQ Manager'),
            Text(
              'Canteen management module',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'Congestion',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback_outlined),
            activeIcon: Icon(Icons.feedback),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }

  Widget buildDashboard() {
    return AppPage(
      children: [
        const SectionHeader(
          icon: Icons.dashboard,
          title: 'Admin Dashboard',
        ),
        MetricGrid(
          children: [
            MetricCard(
              title: 'Active Orders',
              value: '$totalOrders',
              icon: Icons.receipt_long,
              color: Colors.blue,
            ),
            MetricCard(
              title: 'Queue Count',
              value: '$totalQueue',
              icon: Icons.people,
              color: Colors.orange,
            ),
            MetricCard(
              title: 'Open Complaints',
              value: '$openComplaints',
              icon: Icons.feedback,
              color: Colors.red,
            ),
            MetricCard(
              title: 'Active Alerts',
              value: '$activeAlerts',
              icon: Icons.warning,
              color: Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SectionHeader(
          icon: Icons.store,
          title: 'Stall Overview',
        ),
        ...stalls.map(
          (stall) => InfoCard(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: congestionColor(stall.congestionLevel),
                child: const Icon(Icons.store, color: Colors.white),
              ),
              title: Text(stall.name),
              subtitle: Text(
                '${stall.activeOrders} active orders - ${stall.waitMinutes} min wait',
              ),
              trailing: StatusChip(
                text: stall.congestionLevel,
                color: congestionColor(stall.congestionLevel),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCongestion() {
    return AppPage(
      children: [
        const SectionHeader(
          icon: Icons.groups,
          title: 'Stall Congestion Levels',
        ),
        ...stalls.map(
          (stall) => InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stall.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StatusChip(
                      text: stall.congestionLevel,
                      color: congestionColor(stall.congestionLevel),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (stall.queueCount / 30).clamp(0.0, 1.0).toDouble(),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                  color: congestionColor(stall.congestionLevel),
                  backgroundColor: Colors.grey.shade200,
                ),
                const SizedBox(height: 8),
                Text(
                  'Queue: ${stall.queueCount} people | Wait: ${stall.waitMinutes} minutes',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => showMessage(
                    'Manager notified customers to use less crowded stalls.',
                  ),
                  icon: const Icon(Icons.campaign),
                  label: const Text('Send Redirect Notice'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildComplaints() {
    return AppPage(
      children: [
        const SectionHeader(
          icon: Icons.feedback,
          title: 'Complaint Tracking',
        ),
        ...complaints.map(
          (complaint) => InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${complaint.id} - ${complaint.stallName}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StatusChip(
                      text: complaint.status,
                      color: complaintColor(complaint.status),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(complaint.issue),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: complaint.status == 'Resolved'
                          ? null
                          : () {
                              setState(() {
                                complaint.status = 'In Progress';
                              });
                              showMessage('Complaint marked as in progress.');
                            },
                      icon: const Icon(Icons.sync),
                      label: const Text('In Progress'),
                    ),
                    FilledButton.icon(
                      onPressed: complaint.status == 'Resolved'
                          ? null
                          : () {
                              setState(() {
                                complaint.status = 'Resolved';
                              });
                              showMessage('Complaint resolved.');
                            },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Resolve'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildReports() {
    final topStall = [...stalls]..sort((a, b) => b.sales.compareTo(a.sales));

    return AppPage(
      children: [
        const SectionHeader(
          icon: Icons.bar_chart,
          title: 'Performance Reports',
        ),
        MetricGrid(
          children: [
            MetricCard(
              title: 'Total Sales',
              value: 'RM ${totalSales.toStringAsFixed(0)}',
              icon: Icons.payments,
              color: Colors.green,
            ),
            MetricCard(
              title: 'Total Orders',
              value: '$totalOrders',
              icon: Icons.shopping_bag,
              color: Colors.blue,
            ),
            MetricCard(
              title: 'Top Stall',
              value: topStall.first.name,
              icon: Icons.star,
              color: Colors.orange,
            ),
            MetricCard(
              title: 'Avg Rating',
              value: averageRating().toStringAsFixed(1),
              icon: Icons.rate_review,
              color: Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SectionHeader(
          icon: Icons.leaderboard,
          title: 'Stall Performance',
        ),
        ...topStall.map(
          (stall) => InfoCard(
            child: ListTile(
              leading: const Icon(Icons.store),
              title: Text(stall.name),
              subtitle: Text(
                'Sales: RM ${stall.sales.toStringAsFixed(0)} | Rating: ${stall.rating}',
              ),
              trailing: Text('${stall.activeOrders} orders'),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildAlerts() {
    return AppPage(
      children: [
        const SectionHeader(
          icon: Icons.notifications,
          title: 'Automated Alerts',
        ),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Basic Alert Rules',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Queue count above 20 creates a high congestion alert.'),
              const Text('2. New open complaint creates a manager alert.'),
              const Text('3. Daily report ready creates an information alert.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: generateBasicAlerts,
                icon: const Icon(Icons.sensors),
                label: const Text('Run Alert Check'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...alerts.map(
          (alert) => InfoCard(
            child: ListTile(
              leading: Icon(
                alert.resolved ? Icons.check_circle : Icons.warning,
                color: alert.resolved ? Colors.green : alertColor(alert.level),
              ),
              title: Text(alert.title),
              subtitle: Text(alert.message),
              trailing: alert.resolved
                  ? const Text('Resolved')
                  : TextButton(
                      onPressed: () {
                        setState(() {
                          alert.resolved = true;
                        });
                        showMessage('Alert resolved.');
                      },
                      child: const Text('Resolve'),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void generateBasicAlerts() {
    final highCongestion = stalls.any((stall) => stall.congestionLevel == 'High');
    final hasOpenComplaint =
        complaints.any((complaint) => complaint.status == 'Open');

    setState(() {
      if (highCongestion) {
        alerts.insert(
          0,
          ManagerAlert(
            title: 'High Congestion',
            message: 'One or more stalls have high congestion.',
            level: 'Critical',
            resolved: false,
          ),
        );
      }
      if (hasOpenComplaint) {
        alerts.insert(
          0,
          ManagerAlert(
            title: 'Open Complaint',
            message: 'There is an unresolved customer complaint.',
            level: 'Warning',
            resolved: false,
          ),
        );
      }
    });

    showMessage('Alert check completed.');
  }

  double averageRating() {
    final total = stalls.fold(0.0, (sum, stall) => sum + stall.rating);
    return total / stalls.length;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.icon,
    required this.title,
    super.key,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: children,
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.text,
    required this.color,
    super.key,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      side: BorderSide.none,
    );
  }
}

Color congestionColor(String level) {
  if (level == 'High') return Colors.red;
  if (level == 'Medium') return Colors.orange;
  return Colors.green;
}

Color complaintColor(String status) {
  if (status == 'Open') return Colors.red;
  if (status == 'In Progress') return Colors.orange;
  return Colors.green;
}

Color alertColor(String level) {
  if (level == 'Critical') return Colors.red;
  if (level == 'Warning') return Colors.orange;
  return Colors.blue;
}
