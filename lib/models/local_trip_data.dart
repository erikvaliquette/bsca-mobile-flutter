import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../services/travel_emissions_service.dart';

part 'local_trip_data.g.dart';

/// Local storage model for trip data
@HiveType(typeId: 0)
class LocalTripData {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final DateTime startTime;

  @HiveField(3)
  final DateTime? endTime;

  @HiveField(4)
  final double distance;

  @HiveField(5)
  final String mode;

  @HiveField(6)
  final String? fuelType;

  @HiveField(7)
  final double emissions;

  @HiveField(8)
  final String? startLocation;

  @HiveField(9)
  final String? endLocation;

  @HiveField(10)
  final bool isActive;

  @HiveField(11)
  final String? purpose;

  @HiveField(12)
  final bool isSynced;

  LocalTripData({
    String? id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.distance,
    required this.mode,
    this.fuelType,
    required this.emissions,
    this.startLocation,
    this.endLocation,
    required this.isActive,
    this.purpose,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4();

  /// Convert to TripData model
  TripData toTripData() {
    return TripData(
      id: id,
      userId: userId,
      startTime: startTime,
      endTime: endTime,
      distance: distance,
      mode: mode,
      fuelType: fuelType,
      emissions: emissions,
      startLocation: startLocation,
      endLocation: endLocation,
      isActive: isActive,
      purpose: purpose,
    );
  }

  /// Create from TripData model
  factory LocalTripData.fromTripData(TripData tripData, {bool isSynced = true}) {
    return LocalTripData(
      id: tripData.id,
      userId: tripData.userId,
      startTime: tripData.startTime,
      endTime: tripData.endTime,
      distance: tripData.distance,
      mode: tripData.mode,
      fuelType: tripData.fuelType,
      emissions: tripData.emissions,
      startLocation: tripData.startLocation,
      endLocation: tripData.endLocation,
      isActive: tripData.isActive,
      purpose: tripData.purpose,
      isSynced: isSynced,
    );
  }

  /// Create a copy with updated fields
  LocalTripData copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    double? distance,
    String? mode,
    String? fuelType,
    double? emissions,
    String? startLocation,
    String? endLocation,
    bool? isActive,
    String? purpose,
    bool? isSynced,
  }) {
    return LocalTripData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distance: distance ?? this.distance,
      mode: mode ?? this.mode,
      fuelType: fuelType ?? this.fuelType,
      emissions: emissions ?? this.emissions,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      isActive: isActive ?? this.isActive,
      purpose: purpose ?? this.purpose,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

/// Local storage model for location points
@HiveType(typeId: 1)
class LocalLocationPoint {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tripId;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final String timestamp;

  @HiveField(5)
  final double? altitude;

  @HiveField(6)
  final double? speed;

  @HiveField(7)
  final bool isSynced;

  LocalLocationPoint({
    String? id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.altitude,
    this.speed,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4();

  /// Convert to LocationPoint model
  LocationPoint toLocationPoint() {
    return LocationPoint(
      id: id,
      tripId: tripId,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      altitude: altitude,
      speed: speed,
    );
  }

  /// Create from LocationPoint model
  factory LocalLocationPoint.fromLocationPoint(LocationPoint point, {bool isSynced = true}) {
    return LocalLocationPoint(
      id: point.id,
      tripId: point.tripId,
      latitude: point.latitude,
      longitude: point.longitude,
      timestamp: point.timestamp,
      altitude: point.altitude,
      speed: point.speed,
      isSynced: isSynced,
    );
  }
}
