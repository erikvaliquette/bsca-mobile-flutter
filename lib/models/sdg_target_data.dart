import 'package:uuid/uuid.dart';

enum Month {
  january,
  february,
  march,
  april,
  may,
  june,
  july,
  august,
  september,
  october,
  november,
  december
}

extension MonthExtension on Month {
  String get name {
    return toString().split('.').last;
  }
  
  String get displayName {
    final name = toString().split('.').last;
    return name[0].toUpperCase() + name.substring(1);
  }
  
  static Month fromString(String value) {
    return Month.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => Month.january,
    );
  }
}

class SdgTargetData {
  final String? id;
  final String? targetId;
  final Month month;
  final int year;
  final double? baseline;
  final double? target;
  final double? actual;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SdgTargetData({
    this.id,
    required this.targetId,
    required this.month,
    required this.year,
    this.baseline,
    this.target,
    this.actual,
    this.createdAt,
    this.updatedAt,
  });

  factory SdgTargetData.fromJson(Map<String, dynamic> json) {
    return SdgTargetData(
      id: json['id'],
      targetId: json['target_id'],
      month: MonthExtension.fromString(json['month']),
      year: json['year'],
      baseline: json['baseline'] != null ? double.parse(json['baseline'].toString()) : null,
      target: json['target'] != null ? double.parse(json['target'].toString()) : null,
      actual: json['actual'] != null ? double.parse(json['actual'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'target_id': targetId,
      'month': month.name,
      'year': year,
      if (baseline != null) 'baseline': baseline,
      if (target != null) 'target': target,
      if (actual != null) 'actual': actual,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  SdgTargetData copyWith({
    String? id,
    String? targetId,
    Month? month,
    int? year,
    double? baseline,
    double? target,
    double? actual,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SdgTargetData(
      id: id ?? this.id,
      targetId: targetId ?? this.targetId,
      month: month ?? this.month,
      year: year ?? this.year,
      baseline: baseline ?? this.baseline,
      target: target ?? this.target,
      actual: actual ?? this.actual,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
