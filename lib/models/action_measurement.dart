class ActionMeasurement {
  final String id;
  final String actionId;
  final DateTime date;
  final double value;
  final String? unit;
  final String? notes;
  final String? evidenceUrl;

  const ActionMeasurement({
    required this.id,
    required this.actionId,
    required this.date,
    required this.value,
    this.unit,
    this.notes,
    this.evidenceUrl,
  });

  factory ActionMeasurement.fromJson(Map<String, dynamic> json) {
    return ActionMeasurement(
      id: json['id'] as String,
      actionId: json['action_id'] as String,
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String?,
      notes: json['notes'] as String?,
      evidenceUrl: json['evidence_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action_id': actionId,
      'date': date.toIso8601String(),
      'value': value,
      'unit': unit,
      'notes': notes,
      'evidence_url': evidenceUrl,
    };
  }

  ActionMeasurement copyWith({
    String? id,
    String? actionId,
    DateTime? date,
    double? value,
    String? unit,
    String? notes,
    String? evidenceUrl,
  }) {
    return ActionMeasurement(
      id: id ?? this.id,
      actionId: actionId ?? this.actionId,
      date: date ?? this.date,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
    );
  }
}
