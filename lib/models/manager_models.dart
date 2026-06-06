class ManagerStall {
  final String id;
  final String name;
  final int queueCount;
  final int activeOrders;
  final int weeklyOrders;
  final double weeklyRevenue;
  final double rating;
  final bool isOpen;

  ManagerStall({
    required this.id,
    required this.name,
    required this.queueCount,
    required this.activeOrders,
    required this.weeklyOrders,
    required this.weeklyRevenue,
    required this.rating,
    required this.isOpen,
  });

  int get waitMinutes => queueCount * 2;

  String get congestionLevel {
    if (queueCount >= 20) return 'High';
    if (queueCount >= 10) return 'Medium';
    return 'Low';
  }
}

class ManagerComplaint {
  final String id;
  final String stallName;
  final String type;
  final String description;
  final String submittedAt;
  String status;
  String resolutionNotes;

  ManagerComplaint({
    required this.id,
    required this.stallName,
    required this.type,
    required this.description,
    required this.submittedAt,
    required this.status,
    required this.resolutionNotes,
  });

  factory ManagerComplaint.fromMap(
    String id,
    Map<dynamic, dynamic> map,
  ) {
    var status = map['status']?.toString() ?? 'New';
    if (status.toLowerCase() == 'open') status = 'New';
    if (status.toLowerCase() == 'in progress') status = 'In Review';

    return ManagerComplaint(
      id: id,
      stallName: map['stallName']?.toString() ?? 'Unknown Stall',
      type: map['type']?.toString() ?? 'General',
      description: map['description']?.toString() ??
          map['issue']?.toString() ??
          'No description',
      submittedAt: map['submittedAt']?.toString() ?? '',
      status: status,
      resolutionNotes: map['resolutionNotes']?.toString() ?? '',
    );
  }
}

class ManagerAlert {
  final String title;
  final String message;
  final String level;

  ManagerAlert({
    required this.title,
    required this.message,
    required this.level,
  });
}
