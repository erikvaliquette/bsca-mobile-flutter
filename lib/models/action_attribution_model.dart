/// Data model for Action organization attribution
/// Based on the travel emissions attribution pattern
class ActionAttributionModel {
  final String id;
  final String actionId;
  final String organizationId;
  final String attributedBy;
  final DateTime attributionDate;
  final bool isActive;
  final double? impactValue;
  final String? impactUnit;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Related data (populated via joins)
  final Map<String, dynamic>? organization;
  final Map<String, dynamic>? action;

  ActionAttributionModel({
    required this.id,
    required this.actionId,
    required this.organizationId,
    required this.attributedBy,
    required this.attributionDate,
    required this.isActive,
    this.impactValue,
    this.impactUnit,
    required this.createdAt,
    required this.updatedAt,
    this.organization,
    this.action,
  });

  factory ActionAttributionModel.fromJson(Map<String, dynamic> json) {
    return ActionAttributionModel(
      id: json['id'] as String,
      actionId: json['action_id'] as String,
      organizationId: json['organization_id'] as String,
      attributedBy: json['attributed_by'] as String,
      attributionDate: DateTime.parse(json['attribution_date'] as String),
      isActive: json['is_active'] as bool,
      impactValue: json['impact_value'] != null ? double.parse(json['impact_value'].toString()) : null,
      impactUnit: json['impact_unit'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      organization: json['organizations'] as Map<String, dynamic>?,
      action: json['actions'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action_id': actionId,
      'organization_id': organizationId,
      'attributed_by': attributedBy,
      'attribution_date': attributionDate.toIso8601String(),
      'is_active': isActive,
      'impact_value': impactValue,
      'impact_unit': impactUnit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ActionAttributionModel copyWith({
    String? id,
    String? actionId,
    String? organizationId,
    String? attributedBy,
    DateTime? attributionDate,
    bool? isActive,
    double? impactValue,
    String? impactUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? organization,
    Map<String, dynamic>? action,
  }) {
    return ActionAttributionModel(
      id: id ?? this.id,
      actionId: actionId ?? this.actionId,
      organizationId: organizationId ?? this.organizationId,
      attributedBy: attributedBy ?? this.attributedBy,
      attributionDate: attributionDate ?? this.attributionDate,
      isActive: isActive ?? this.isActive,
      impactValue: impactValue ?? this.impactValue,
      impactUnit: impactUnit ?? this.impactUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organization: organization ?? this.organization,
      action: action ?? this.action,
    );
  }

  @override
  String toString() {
    return 'ActionAttributionModel(id: $id, actionId: $actionId, organizationId: $organizationId, isActive: $isActive, impactValue: $impactValue $impactUnit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActionAttributionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
