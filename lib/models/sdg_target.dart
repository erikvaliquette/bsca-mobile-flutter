class SdgTarget {
  final String id;
  final String description;
  final String? actionDescription; // Matches action_description in the database
  final int? sdgGoalNumber; // Keeping for backward compatibility
  final int? sdgId; // Added to match database schema
  final int? targetNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? organizationId;
  final String? userId;

  SdgTarget({
    required this.id,
    required this.description,
    this.actionDescription,
    this.sdgGoalNumber,
    this.sdgId,
    this.targetNumber,
    this.createdAt,
    this.updatedAt,
    this.organizationId,
    this.userId,
  });

  factory SdgTarget.fromJson(Map<String, dynamic> json) {
    return SdgTarget(
      id: json['id'],
      description: json['description'],
      actionDescription: json['action_description'],
      sdgGoalNumber: json['sdg_goal_number'],
      sdgId: json['sdg_id'], // Added to match database schema
      targetNumber: json['target_number'] is String ? int.tryParse(json['target_number']) : json['target_number'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      organizationId: json['organization_id'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'description': description,
      if (actionDescription != null) 'action_description': actionDescription,
      if (sdgId != null) 'sdg_id': sdgId, // Using sdg_id for database operations
      if (targetNumber != null) 'target_number': targetNumber,
      if (organizationId != null && organizationId!.isNotEmpty) 'organization_id': organizationId,
      if (userId != null) 'user_id': userId,
    };
    
    // Only include ID if it's not empty (for updates, not for inserts)
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }

  SdgTarget copyWith({
    String? id,
    String? description,
    String? actionDescription,
    int? sdgGoalNumber,
    int? sdgId,
    int? targetNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? organizationId,
    String? userId,
  }) {
    return SdgTarget(
      id: id ?? this.id,
      description: description ?? this.description,
      actionDescription: actionDescription ?? this.actionDescription,
      sdgGoalNumber: sdgGoalNumber ?? this.sdgGoalNumber,
      sdgId: sdgId ?? this.sdgId,
      targetNumber: targetNumber ?? this.targetNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
    );
  }
}
