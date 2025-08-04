class SdgTarget {
  final String id;
  final String name;
  final String? description;
  final int? sdgGoalNumber;
  final String? targetNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? organizationId;
  final String? userId;

  SdgTarget({
    required this.id,
    required this.name,
    this.description,
    this.sdgGoalNumber,
    this.targetNumber,
    this.createdAt,
    this.updatedAt,
    this.organizationId,
    this.userId,
  });

  factory SdgTarget.fromJson(Map<String, dynamic> json) {
    return SdgTarget(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      sdgGoalNumber: json['sdg_goal_number'],
      targetNumber: json['target_number'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      organizationId: json['organization_id'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (sdgGoalNumber != null) 'sdg_goal_number': sdgGoalNumber,
      if (targetNumber != null) 'target_number': targetNumber,
      if (organizationId != null) 'organization_id': organizationId,
      if (userId != null) 'user_id': userId,
    };
  }

  SdgTarget copyWith({
    String? id,
    String? name,
    String? description,
    int? sdgGoalNumber,
    String? targetNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? organizationId,
    String? userId,
  }) {
    return SdgTarget(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sdgGoalNumber: sdgGoalNumber ?? this.sdgGoalNumber,
      targetNumber: targetNumber ?? this.targetNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
    );
  }
}
