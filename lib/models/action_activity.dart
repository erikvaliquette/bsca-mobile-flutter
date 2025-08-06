class ActionActivity {
  final String id;
  final String actionId; // Reference to parent Action
  final String title;
  final String description;
  final String status; // 'planned', 'in_progress', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startDate;
  final DateTime? completedAt;
  final DateTime? dueDate;
  
  // Impact tracking
  final double? impactValue;
  final String? impactUnit; // e.g., "metric tons CO₂e", "kWh saved", "people reached"
  final String? impactDescription;
  
  // Evidence and verification
  final List<String>? evidenceUrls; // URLs to supporting documents/photos
  final String? verificationMethod; // How this activity's impact is verified
  final String verificationStatus; // 'pending', 'verified', 'rejected'
  final String? verifiedBy; // User ID who verified this activity
  final DateTime? verifiedAt;
  
  // Organization and user tracking
  final String userId;
  final String? organizationId;
  
  // Tokenization placeholder (for future blockchain integration)
  final int? tokensAwarded;
  final String? tokenTransactionId;
  
  // Additional metadata
  final Map<String, dynamic>? metadata;

  const ActionActivity({
    required this.id,
    required this.actionId,
    required this.title,
    required this.description,
    this.status = 'planned',
    required this.createdAt,
    required this.updatedAt,
    this.startDate,
    this.completedAt,
    this.dueDate,
    this.impactValue,
    this.impactUnit,
    this.impactDescription,
    this.evidenceUrls,
    this.verificationMethod,
    this.verificationStatus = 'pending',
    this.verifiedBy,
    this.verifiedAt,
    required this.userId,
    this.organizationId,
    this.tokensAwarded,
    this.tokenTransactionId,
    this.metadata,
  });

  factory ActionActivity.fromJson(Map<String, dynamic> json) {
    return ActionActivity(
      id: json['id'] as String,
      actionId: json['action_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String? ?? 'planned',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      impactValue: json['impact_value'] != null ? (json['impact_value'] as num).toDouble() : null,
      impactUnit: json['impact_unit'] as String?,
      impactDescription: json['impact_description'] as String?,
      evidenceUrls: json['evidence_urls'] != null ? List<String>.from(json['evidence_urls']) : null,
      verificationMethod: json['verification_method'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at'] as String) : null,
      userId: json['user_id'] as String,
      organizationId: json['organization_id'] as String?,
      tokensAwarded: json['tokens_awarded'] as int?,
      tokenTransactionId: json['token_transaction_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'action_id': actionId,
      'title': title,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
    };

    // Add optional fields only if they have values
    if (startDate != null) json['start_date'] = startDate!.toIso8601String();
    if (completedAt != null) json['completed_at'] = completedAt!.toIso8601String();
    if (dueDate != null) json['due_date'] = dueDate!.toIso8601String();
    if (impactValue != null) json['impact_value'] = impactValue;
    if (impactUnit != null) json['impact_unit'] = impactUnit;
    if (impactDescription != null) json['impact_description'] = impactDescription;
    if (evidenceUrls != null) json['evidence_urls'] = evidenceUrls;
    if (verificationMethod != null) json['verification_method'] = verificationMethod;
    if (verificationStatus != 'pending') json['verification_status'] = verificationStatus;
    if (verifiedBy != null) json['verified_by'] = verifiedBy;
    if (verifiedAt != null) json['verified_at'] = verifiedAt!.toIso8601String();
    if (organizationId != null) json['organization_id'] = organizationId;
    if (tokensAwarded != null) json['tokens_awarded'] = tokensAwarded;
    if (tokenTransactionId != null) json['token_transaction_id'] = tokenTransactionId;
    if (metadata != null) json['metadata'] = metadata;

    return json;
  }

  ActionActivity copyWith({
    String? id,
    String? actionId,
    String? title,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? completedAt,
    DateTime? dueDate,
    double? impactValue,
    String? impactUnit,
    String? impactDescription,
    List<String>? evidenceUrls,
    String? verificationMethod,
    String? verificationStatus,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? userId,
    String? organizationId,
    int? tokensAwarded,
    String? tokenTransactionId,
    Map<String, dynamic>? metadata,
  }) {
    return ActionActivity(
      id: id ?? this.id,
      actionId: actionId ?? this.actionId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startDate: startDate ?? this.startDate,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      impactValue: impactValue ?? this.impactValue,
      impactUnit: impactUnit ?? this.impactUnit,
      impactDescription: impactDescription ?? this.impactDescription,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      tokensAwarded: tokensAwarded ?? this.tokensAwarded,
      tokenTransactionId: tokenTransactionId ?? this.tokenTransactionId,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isVerified => verificationStatus == 'verified';
  bool get hasImpact => impactValue != null && impactValue! > 0;
  bool get hasEvidence => evidenceUrls != null && evidenceUrls!.isNotEmpty;

  String get statusDisplayName {
    switch (status) {
      case 'planned':
        return 'Planned';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String get verificationStatusDisplayName {
    switch (verificationStatus) {
      case 'pending':
        return 'Pending Verification';
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Verification Rejected';
      default:
        return 'Unknown';
    }
  }
}
