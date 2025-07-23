import 'package:uuid/uuid.dart';

/// Model for trip organization attribution data from Supabase
class TripOrganizationAttribution {
  final String id;
  final String tripId;
  final String organizationId;
  final double emissionsAmount;
  final DateTime attributionDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TripOrganizationAttribution({
    required this.id,
    required this.tripId,
    required this.organizationId,
    required this.emissionsAmount,
    required this.attributionDate,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory TripOrganizationAttribution.fromJson(Map<String, dynamic> json) {
    return TripOrganizationAttribution(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      organizationId: json['organization_id'] as String,
      emissionsAmount: double.parse(json['emissions_amount']?.toString() ?? '0'),
      attributionDate: DateTime.parse(json['attribution_date']),
      isActive: json['is_active'] as bool,
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
      'id': id,
      'trip_id': tripId,
      'organization_id': organizationId,
      'emissions_amount': emissionsAmount,
      'attribution_date': attributionDate.toIso8601String(),
      'is_active': isActive,
      // createdAt and updatedAt are managed by the database
    };
  }

  /// Create a new attribution record
  factory TripOrganizationAttribution.create({
    required String tripId,
    required String organizationId,
    required double emissionsAmount,
  }) {
    return TripOrganizationAttribution(
      id: const Uuid().v4(),
      tripId: tripId,
      organizationId: organizationId,
      emissionsAmount: emissionsAmount,
      attributionDate: DateTime.now(),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy of this attribution with updated fields
  TripOrganizationAttribution copyWith({
    String? id,
    String? tripId,
    String? organizationId,
    double? emissionsAmount,
    DateTime? attributionDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripOrganizationAttribution(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      organizationId: organizationId ?? this.organizationId,
      emissionsAmount: emissionsAmount ?? this.emissionsAmount,
      attributionDate: attributionDate ?? this.attributionDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
