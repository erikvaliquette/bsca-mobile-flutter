import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase/supabase_client.dart';

/// Service for managing travel emissions data
class TravelEmissionsService {
  static final TravelEmissionsService _instance = TravelEmissionsService._();
  
  TravelEmissionsService._();
  
  static TravelEmissionsService get instance => _instance;
  
  /// Get the Supabase client
  SupabaseClient get _client => SupabaseService.client;
  
  /// Get all travel trips for a user
  Future<List<TripData>> getUserTrips(String userId) async {
    try {
      final response = await _client
          .from('travel_trips')
          .select()
          .eq('user_id', userId)
          .order('start_time', ascending: false);
      
      return (response as List).map((trip) => TripData.fromJson(trip)).toList();
    } catch (e) {
      debugPrint('Error getting user trips: $e');
      rethrow;
    }
  }
  
  /// Create a new trip
  Future<TripData?> createTrip(TripData trip) async {
    try {
      final response = await _client
          .from('travel_trips')
          .insert(trip.toJson())
          .select()
          .single();
      
      return TripData.fromJson(response);
    } catch (e) {
      debugPrint('Error creating trip: $e');
      return null;
    }
  }
  
  /// Update an existing trip
  Future<bool> updateTrip(String tripId, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('travel_trips')
          .update(updates)
          .eq('id', tripId);
      
      return true;
    } catch (e) {
      debugPrint('Error updating trip: $e');
      return false;
    }
  }
  
  /// Delete a trip
  Future<bool> deleteTrip(String tripId) async {
    try {
      await _client
          .from('travel_trips')
          .delete()
          .eq('id', tripId);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting trip: $e');
      return false;
    }
  }
  
  /// Add a location point for a trip
  Future<bool> addLocationPoint(LocationPoint point) async {
    try {
      await _client
          .from('travel_location_points')
          .insert(point.toJson());
      
      return true;
    } catch (e) {
      debugPrint('Error adding location point: $e');
      return false;
    }
  }
}

/// Data model for a travel trip
class TripData {
  final String? id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final double distance;
  final String mode;
  final double emissions;
  final String? startLocation;
  final String? endLocation;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? purpose;
  
  TripData({
    this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.distance,
    required this.mode,
    required this.emissions,
    this.startLocation,
    this.endLocation,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.purpose,
  });
  
  factory TripData.fromJson(Map<String, dynamic> json) {
    return TripData(
      id: json['id'],
      userId: json['user_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      distance: double.parse(json['distance'].toString()),
      mode: json['mode'],
      emissions: double.parse(json['emissions'].toString()),
      startLocation: json['start_location'],
      endLocation: json['end_location'],
      isActive: json['is_active'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      purpose: json['purpose'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      'distance': distance,
      'mode': mode,
      'emissions': emissions,
      if (startLocation != null) 'start_location': startLocation,
      if (endLocation != null) 'end_location': endLocation,
      'is_active': isActive,
      if (purpose != null) 'purpose': purpose,
    };
  }
}

/// Data model for a location point
class LocationPoint {
  final String? id;
  final String tripId;
  final double latitude;
  final double longitude;
  final String timestamp;
  final double? altitude;
  final double? speed;
  
  LocationPoint({
    this.id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.altitude,
    this.speed,
  });
  
  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      id: json['id'],
      tripId: json['trip_id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: json['timestamp'],
      altitude: json['altitude'],
      speed: json['speed'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'trip_id': tripId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
    };
  }
}
