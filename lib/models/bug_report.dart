class BugReport {
  final String? id;
  final String? userId;
  final String title;
  final String description;
  final String? stepsToReproduce;
  final String? expectedBehavior;
  final String? actualBehavior;
  final Map<String, dynamic>? browserInfo;
  final String? errorLogs;
  final String status;
  final String priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BugReport({
    this.id,
    this.userId,
    required this.title,
    required this.description,
    this.stepsToReproduce,
    this.expectedBehavior,
    this.actualBehavior,
    this.browserInfo,
    this.errorLogs,
    this.status = 'open',
    this.priority = 'medium',
    this.createdAt,
    this.updatedAt,
  });

  factory BugReport.fromJson(Map<String, dynamic> json) {
    return BugReport(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      stepsToReproduce: json['steps_to_reproduce'],
      expectedBehavior: json['expected_behavior'],
      actualBehavior: json['actual_behavior'],
      browserInfo: json['browser_info'],
      errorLogs: json['error_logs'],
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'medium',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'title': title,
      'description': description,
      if (stepsToReproduce != null) 'steps_to_reproduce': stepsToReproduce,
      if (expectedBehavior != null) 'expected_behavior': expectedBehavior,
      if (actualBehavior != null) 'actual_behavior': actualBehavior,
      if (browserInfo != null) 'browser_info': browserInfo,
      if (errorLogs != null) 'error_logs': errorLogs,
      'status': status,
      'priority': priority,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  BugReport copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? stepsToReproduce,
    String? expectedBehavior,
    String? actualBehavior,
    Map<String, dynamic>? browserInfo,
    String? errorLogs,
    String? status,
    String? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BugReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      stepsToReproduce: stepsToReproduce ?? this.stepsToReproduce,
      expectedBehavior: expectedBehavior ?? this.expectedBehavior,
      actualBehavior: actualBehavior ?? this.actualBehavior,
      browserInfo: browserInfo ?? this.browserInfo,
      errorLogs: errorLogs ?? this.errorLogs,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
