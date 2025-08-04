import 'action_measurement.dart';
import 'sdg_target.dart';

class ActionItem {
  final String id;
  final String userId;
  final String? organizationId; // For organization attribution (Professional+ tiers)
  final String? sdgTargetId; // Reference to SDG target
  final SdgTarget? sdgTarget; // The associated SDG target object
  final int sdgId; // Legacy field
  final String title;
  final String description;
  final String category; // e.g., 'personal', 'community', 'workplace', 'education'
  final double progress; // 0.0 to 1.0
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final String priority; // 'low', 'medium', 'high'
  final Map<String, dynamic>? metadata; // For additional data like notes, attachments, etc.
  
  // New sustainability tracking fields
  final double? baselineValue; // Starting measurement value
  final String? baselineUnit; // Unit of measurement (kg CO2e, kWh, etc.)
  final DateTime? baselineDate; // When baseline was established
  final String? baselineMethodology; // How baseline was calculated
  
  final double? targetValue; // Goal to achieve
  final DateTime? targetDate; // When you aim to achieve the target
  final String? verificationMethod; // How progress is verified
  
  final List<ActionMeasurement>? measurements; // Historical measurements

  const ActionItem({
    required this.id,
    required this.userId,
    this.organizationId,
    this.sdgTargetId,
    this.sdgTarget,
    required this.sdgId,
    required this.title,
    required this.description,
    required this.category,
    this.progress = 0.0,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.dueDate,
    this.priority = 'medium',
    this.metadata,
    // New sustainability tracking fields
    this.baselineValue,
    this.baselineUnit,
    this.baselineDate,
    this.baselineMethodology,
    this.targetValue,
    this.targetDate,
    this.verificationMethod,
    this.measurements,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    // Parse measurements if they exist
    List<ActionMeasurement>? measurements;
    if (json['measurements'] != null) {
      final measurementsList = json['measurements'] as List;
      measurements = measurementsList
          .map((m) => ActionMeasurement.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    
    // Parse SDG target if it exists
    SdgTarget? sdgTarget;
    if (json['sdg_target'] != null) {
      sdgTarget = SdgTarget.fromJson(json['sdg_target'] as Map<String, dynamic>);
    }
    
    return ActionItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      organizationId: json['organization_id'] as String?,
      sdgTargetId: json['sdg_target_id'] as String?,
      sdgTarget: sdgTarget,
      sdgId: json['sdg_id'] as int? ?? 0,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] as String)
          : null,
      priority: json['priority'] as String? ?? 'medium',
      metadata: json['metadata'] as Map<String, dynamic>?,
      // New sustainability tracking fields
      baselineValue: (json['baseline_value'] as num?)?.toDouble(),
      baselineUnit: json['baseline_unit'] as String?,
      baselineDate: json['baseline_date'] != null
          ? DateTime.parse(json['baseline_date'] as String)
          : null,
      baselineMethodology: json['baseline_methodology'] as String?,
      targetValue: (json['target_value'] as num?)?.toDouble(),
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      verificationMethod: json['verification_method'] as String?,
      measurements: measurements,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'user_id': userId,
      'organization_id': organizationId,
      'sdg_target_id': sdgTargetId,
      'sdg_id': sdgId,
      'title': title,
      'description': description,
      'category': category,
      'progress': progress,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'metadata': metadata,
    };
    
    // Add new sustainability tracking fields if they exist
    if (baselineValue != null) data['baseline_value'] = baselineValue;
    if (baselineUnit != null) data['baseline_unit'] = baselineUnit;
    if (baselineDate != null) data['baseline_date'] = baselineDate!.toIso8601String();
    if (baselineMethodology != null) data['baseline_methodology'] = baselineMethodology;
    
    if (targetValue != null) data['target_value'] = targetValue;
    if (targetDate != null) data['target_date'] = targetDate!.toIso8601String();
    if (verificationMethod != null) data['verification_method'] = verificationMethod;
    
    // Add measurements if they exist
    if (measurements != null && measurements!.isNotEmpty) {
      data['measurements'] = measurements!.map((m) => m.toJson()).toList();
    }
    
    return data;
  }

  ActionItem copyWith({
    String? id,
    String? userId,
    String? organizationId,
    String? sdgTargetId,
    SdgTarget? sdgTarget,
    int? sdgId,
    String? title,
    String? description,
    String? category,
    double? progress,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? dueDate,
    String? priority,
    Map<String, dynamic>? metadata,
    // New sustainability tracking fields
    double? baselineValue,
    String? baselineUnit,
    DateTime? baselineDate,
    String? baselineMethodology,
    double? targetValue,
    DateTime? targetDate,
    String? verificationMethod,
    List<ActionMeasurement>? measurements,
  }) {
    return ActionItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      sdgTargetId: sdgTargetId ?? this.sdgTargetId,
      sdgTarget: sdgTarget ?? this.sdgTarget,
      sdgId: sdgId ?? this.sdgId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      metadata: metadata ?? this.metadata,
      // New sustainability tracking fields
      baselineValue: baselineValue ?? this.baselineValue,
      baselineUnit: baselineUnit ?? this.baselineUnit,
      baselineDate: baselineDate ?? this.baselineDate,
      baselineMethodology: baselineMethodology ?? this.baselineMethodology,
      targetValue: targetValue ?? this.targetValue,
      targetDate: targetDate ?? this.targetDate,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      measurements: measurements ?? this.measurements,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActionItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ActionItem(id: $id, title: $title, sdgId: $sdgId, progress: $progress, isCompleted: $isCompleted)';
  }
}
