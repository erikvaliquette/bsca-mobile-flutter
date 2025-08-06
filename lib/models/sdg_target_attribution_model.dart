/// Data model for SDG Target organization attribution
/// Based on the travel emissions attribution pattern
class SdgTargetAttributionModel {
  final String id;
  final String sdgTargetId;
  final String organizationId;
  final String attributedBy;
  final DateTime attributionDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Related data (populated via joins)
  final Map<String, dynamic>? organization;
  final Map<String, dynamic>? sdgTarget;

  SdgTargetAttributionModel({
    required this.id,
    required this.sdgTargetId,
    required this.organizationId,
    required this.attributedBy,
    required this.attributionDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.organization,
    this.sdgTarget,
  });

  factory SdgTargetAttributionModel.fromJson(Map<String, dynamic> json) {
    return SdgTargetAttributionModel(
      id: json['id'] as String,
      sdgTargetId: json['sdg_target_id'] as String,
      organizationId: json['organization_id'] as String,
      attributedBy: json['attributed_by'] as String,
      attributionDate: DateTime.parse(json['attribution_date'] as String),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      organization: json['organizations'] as Map<String, dynamic>?,
      sdgTarget: json['sdg_targets'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sdg_target_id': sdgTargetId,
      'organization_id': organizationId,
      'attributed_by': attributedBy,
      'attribution_date': attributionDate.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SdgTargetAttributionModel copyWith({
    String? id,
    String? sdgTargetId,
    String? organizationId,
    String? attributedBy,
    DateTime? attributionDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? organization,
    Map<String, dynamic>? sdgTarget,
  }) {
    return SdgTargetAttributionModel(
      id: id ?? this.id,
      sdgTargetId: sdgTargetId ?? this.sdgTargetId,
      organizationId: organizationId ?? this.organizationId,
      attributedBy: attributedBy ?? this.attributedBy,
      attributionDate: attributionDate ?? this.attributionDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organization: organization ?? this.organization,
      sdgTarget: sdgTarget ?? this.sdgTarget,
    );
  }

  @override
  String toString() {
    return 'SdgTargetAttributionModel(id: $id, sdgTargetId: $sdgTargetId, organizationId: $organizationId, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SdgTargetAttributionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
