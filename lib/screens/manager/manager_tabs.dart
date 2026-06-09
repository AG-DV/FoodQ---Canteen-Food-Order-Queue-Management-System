import 'package:flutter/material.dart';
import '../../models/manager_models.dart';

// Defines the callback used to update a complaint.
typedef ComplaintUpdate = Future<void> Function(
  ManagerComplaint complaint,
  String status,
);

// Builds the dashboard summary, heatmap and registered stall list.
Widget managerDashboard({
  required List<ManagerStall> stalls,
  required int activeOrders,
  required int queueCount,
  required int openComplaints,
  required int alertCount,
}) {
  return _page([
    const _Title('Admin Dashboard'),
    GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _Metric('Active Orders', '$activeOrders', Icons.receipt_long),
        _Metric('Queue Count', '$queueCount', Icons.people),
        _Metric('Complaints', '$openComplaints', Icons.feedback),
        _Metric('Alerts', '$alertCount', Icons.warning),
      ],
    ),
    const _Title('People Flow Heatmap'),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stalls.map((stall) {
        final color = congestionColor(stall.congestionLevel);
        return Container(
          width: 145,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                stall.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('${stall.queueCount} people'),
            ],
          ),
        );
      }).toList(),
    ),
    const SizedBox(height: 20),
    const _Title('Registered Stalls'),
    ...stalls.map(
      (stall) => Card(
        child: ListTile(
          leading: const Icon(Icons.storefront),
          title: Text(stall.name),
          subtitle: Text('${stall.activeOrders} active orders'),
          trailing: _Status(stall.congestionLevel),
        ),
      ),
    ),
  ]);
}

// Builds the stall congestion page and redirect notice action.
Widget managerQueues(
  List<ManagerStall> stalls,
  Future<void> Function(String stallName) sendNotice,
) {
  return _page([
    const _Title('Stall Congestion Levels'),
    ...stalls.map(
      (stall) => Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: congestionColor(stall.congestionLevel),
            child: Text(
              '${stall.queueCount}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(stall.name),
          subtitle: Text(
            '${stall.activeOrders} orders | ${stall.waitMinutes} min wait',
          ),
          trailing: IconButton(
            onPressed: () => sendNotice(stall.name),
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Send redirect notice',
          ),
        ),
      ),
    ),
  ]);
}

// Builds the complaint list, filter and resolution actions.
Widget managerComplaints({
  required List<ManagerComplaint> complaints,
  required String filter,
  required ValueChanged<String> onFilterChanged,
  required ComplaintUpdate onUpdate,
}) {
  // Apply the selected complaint status filter.
  final filtered = filter == 'All'
      ? complaints
      : complaints.where((item) => item.status == filter).toList();

  return _page([
    const _Title('Complaint Tracking'),
    DropdownButton<String>(
      value: filter,
      isExpanded: true,
      items: const ['All', 'New', 'In Review', 'Resolved']
          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
          .toList(),
      onChanged: (value) {
        if (value != null) onFilterChanged(value);
      },
    ),
    if (filtered.isEmpty)
      const _Empty('No complaints found')
    else
      ...filtered.map(
        (complaint) => Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(complaint.stallName),
                  subtitle: Text(
                    '${complaint.type}\n${complaint.description}',
                  ),
                  trailing: _Status(complaint.status),
                ),
                if (complaint.resolutionNotes.isNotEmpty)
                  Text('Notes: ${complaint.resolutionNotes}'),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: complaint.status == 'Resolved'
                          ? null
                          : () => onUpdate(complaint, 'In Review'),
                      child: const Text('In Review'),
                    ),
                    FilledButton(
                      onPressed: complaint.status == 'Resolved'
                          ? null
                          : () => onUpdate(complaint, 'Resolved'),
                      child: const Text('Resolve'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
  ]);
}

// Builds the latest seven-day performance report.
Widget managerReports(List<ManagerStall> stalls) {
  // Calculate overall revenue, orders and average rating.
  final revenue = stalls.fold(0.0, (sum, stall) => sum + stall.weeklyRevenue);
  final orders = stalls.fold(0, (sum, stall) => sum + stall.weeklyOrders);
  final rating = stalls.isEmpty
      ? 0.0
      : stalls.fold(0.0, (sum, stall) => sum + stall.rating) / stalls.length;

  return _page([
    const _Title('Weekly Performance Report'),
    Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.payments),
            title: const Text('Total Revenue'),
            trailing: Text('RM ${revenue.toStringAsFixed(2)}'),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Total Orders'),
            trailing: Text('$orders'),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Average Rating'),
            trailing: Text(rating.toStringAsFixed(1)),
          ),
        ],
      ),
    ),
    const _Title('Stall Performance'),
    ...stalls.map(
      (stall) => Card(
        child: ListTile(
          title: Text(stall.name),
          subtitle: Text('Rating ${stall.rating.toStringAsFixed(1)}'),
          trailing: Text('${stall.weeklyOrders} orders'),
        ),
      ),
    ),
  ]);
}

// Builds the list of automatically generated alerts.
Widget managerAlerts(List<ManagerAlert> alerts) {
  return _page([
    const _Title('Automated Alerts'),
    if (alerts.isEmpty)
      const _Empty('No active alerts')
    else
      ...alerts.map(
        (alert) => Card(
          child: ListTile(
            leading: Icon(
              Icons.warning_amber,
              color: alert.level == 'Critical' ? Colors.red : Colors.orange,
            ),
            title: Text(alert.title),
            subtitle: Text(alert.message),
            trailing: Text(alert.level),
          ),
        ),
      ),
  ]);
}

// Provides the same scrollable layout for every Manager tab.
Widget _page(List<Widget> children) {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(16),
    children: children,
  );
}

// Reusable heading used by the Manager pages.
class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Reusable card used for Dashboard summary values.
class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _Metric(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            Text(value, style: const TextStyle(fontSize: 22)),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// Reusable coloured text for congestion and complaint status.
class _Status extends StatelessWidget {
  final String text;
  const _Status(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: text == 'High' || text == 'New'
            ? Colors.red
            : text == 'Medium' || text == 'In Review'
                ? Colors.orange
                : Colors.green,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// Reusable message shown when a page has no data.
class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(child: Text(text)),
    );
  }
}

// Returns a display colour for each congestion level.
Color congestionColor(String level) {
  if (level == 'High') return Colors.red;
  if (level == 'Medium') return Colors.orange;
  return Colors.green;
}
