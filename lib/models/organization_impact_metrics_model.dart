/// Data model for organization impact metrics
/// Tracks aggregated sustainability data for organizations
class OrganizationImpactMetricsModel {
  final String id;
  final String organizationId;
  final int year;
  final int sdgTargetsCount;
  final int actionsCount;
  final int activitiesCount;
  final int completedActionsCount;
  final double totalImpactValue;
  final String impactUnit;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrganizationImpactMetricsModel({
    required this.id,
    required this.organizationId,
    required this.year,
    required this.sdgTargetsCount,
    required this.actionsCount,
    required this.activitiesCount,
    required this.completedActionsCount,
    required this.totalImpactValue,
    required this.impactUnit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrganizationImpactMetricsModel.fromJson(Map<String, dynamic> json) {
    return OrganizationImpactMetricsModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      year: json['year'] as int,
      sdgTargetsCount: json['sdg_targets_count'] as int,
      actionsCount: json['actions_count'] as int,
      activitiesCount: json['activities_count'] as int,
      completedActionsCount: json['completed_actions_count'] as int,
      totalImpactValue: double.parse(json['total_impact_value'].toString()),
      impactUnit: json['impact_unit'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'year': year,
      'sdg_targets_count': sdgTargetsCount,
      'actions_count': actionsCount,
      'activities_count': activitiesCount,
      'completed_actions_count': completedActionsCount,
      'total_impact_value': totalImpactValue,
      'impact_unit': impactUnit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  OrganizationImpactMetricsModel copyWith({
    String? id,
    String? organizationId,
    int? year,
    int? sdgTargetsCount,
    int? actionsCount,
    int? activitiesCount,
    int? completedActionsCount,
    double? totalImpactValue,
    String? impactUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganizationImpactMetricsModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      year: year ?? this.year,
      sdgTargetsCount: sdgTargetsCount ?? this.sdgTargetsCount,
      actionsCount: actionsCount ?? this.actionsCount,
      activitiesCount: activitiesCount ?? this.activitiesCount,
      completedActionsCount: completedActionsCount ?? this.completedActionsCount,
      totalImpactValue: totalImpactValue ?? this.totalImpactValue,
      impactUnit: impactUnit ?? this.impactUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate completion rate as a percentage
  double get completionRate {
    if (actionsCount == 0) return 0.0;
    return (completedActionsCount / actionsCount) * 100;
  }

  /// Get a formatted string for total impact
  String get formattedTotalImpact {
    if (totalImpactValue == 0) return '0';
    
    if (totalImpactValue >= 1000000) {
      return '${(totalImpactValue / 1000000).toStringAsFixed(1)}M';
    } else if (totalImpactValue >= 1000) {
      return '${(totalImpactValue / 1000).toStringAsFixed(1)}K';
    } else if (totalImpactValue == totalImpactValue.toInt()) {
      return totalImpactValue.toInt().toString();
    } else {
      return totalImpactValue.toStringAsFixed(2);
    }
  }

  /// Check if the organization has any sustainability activity
  bool get hasActivity {
    return sdgTargetsCount > 0 || actionsCount > 0 || activitiesCount > 0;
  }

  /// Get a summary description of the organization's sustainability efforts
  String get summaryDescription {
    if (!hasActivity) {
      return 'No sustainability activities recorded for $year';
    }
    
    final parts = <String>[];
    
    if (sdgTargetsCount > 0) {
      parts.add('$sdgTargetsCount SDG target${sdgTargetsCount == 1 ? '' : 's'}');
    }
    
    if (actionsCount > 0) {
      parts.add('$actionsCount action${actionsCount == 1 ? '' : 's'}');
      if (completedActionsCount > 0) {
        parts.add('${completionRate.toStringAsFixed(0)}% completed');
      }
    }
    
    if (activitiesCount > 0) {
      parts.add('$activitiesCount activit${activitiesCount == 1 ? 'y' : 'ies'}');
    }
    
    if (totalImpactValue > 0) {
      parts.add('$formattedTotalImpact ${impactUnit == 'mixed' ? 'impact units' : impactUnit}');
    }
    
    return parts.join(', ');
  }

  @override
  String toString() {
    return 'OrganizationImpactMetricsModel(id: $id, organizationId: $organizationId, year: $year, actions: $actionsCount, completed: $completedActionsCount, impact: $formattedTotalImpact $impactUnit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrganizationImpactMetricsModel && 
           other.id == id &&
           other.organizationId == organizationId &&
           other.year == year;
  }

  @override
  int get hashCode => Object.hash(id, organizationId, year);
}
