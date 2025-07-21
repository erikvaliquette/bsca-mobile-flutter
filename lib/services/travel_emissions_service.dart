import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:collection';

import '../models/local_trip_data.dart';
import '../services/supabase/supabase_client.dart';
import 'connectivity_service.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';

/// Service for managing travel emissions data
class TravelEmissionsService {
  static final TravelEmissionsService _instance = TravelEmissionsService._();
  
  TravelEmissionsService._();
  
  static TravelEmissionsService get instance => _instance;
  
  /// Get the Supabase client
  SupabaseClient get _client => SupabaseService.client;
  
  // Cache for trips by user ID
  final Map<String, _CachedData<List<TripData>>> _tripCache = {};
  
  // Cache for location points by trip ID
  final Map<String, _CachedData<List<LocationPoint>>> _locationPointCache = {};
  
  // Cache expiration time (5 minutes)
  static const _cacheExpirationMs = 300000; // 5 minutes in milliseconds
  
  /// Get all travel trips for a user
  Future<List<TripData>> getUserTrips(String userId) async {
    try {
      // Check cache first
      if (_tripCache.containsKey(userId) && !_tripCache[userId]!.isExpired) {
        return _tripCache[userId]!.data;
      }
      
      List<TripData> trips = [];
      bool isSynced = false;
      
      // Check if we're online
      if (ConnectivityService.instance.isConnected) {
        try {
          // Try to get trips from Supabase
          final response = await _client
              .from('travel_trips')
              .select()
              .eq('user_id', userId)
              .order('start_time', ascending: false);
          
          trips = (response as List).map((trip) => TripData.fromJson(trip)).toList();
          isSynced = true;
          
          // Save trips to local storage in batch
          await Future.wait(
            trips.map((trip) => LocalStorageService.instance.saveTrip(
              LocalTripData.fromTripData(trip, isSynced: true)
            ))
          );
        } catch (e) {
          debugPrint('Error getting user trips from Supabase: $e');
          // Fall back to local storage
        }
      }
      
      // If we couldn't get from Supabase, get from local storage
      if (trips.isEmpty) {
        final localTrips = LocalStorageService.instance.getUserTrips(userId);
        trips = localTrips.map((localTrip) => localTrip.toTripData()).toList();
      }
      
      // Update cache
      _tripCache[userId] = _CachedData<List<TripData>>(trips);
      
      return trips;
    } catch (e) {
      debugPrint('Error getting user trips: $e');
      return [];
    }
  }
  
  /// Create a new trip
  Future<TripData?> createTrip(TripData trip) async {
    try {
      // Generate a local ID if none provided
      final tripId = trip.id == null || trip.id!.isEmpty ? 'local_${const Uuid().v4()}' : trip.id;
      final tripWithId = trip.copyWith(id: tripId);
      
      // Save to local storage first
      final localTrip = LocalTripData.fromTripData(tripWithId, isSynced: false);
      await LocalStorageService.instance.saveTrip(localTrip);
      
      // If online, try to sync with Supabase
      if (ConnectivityService.instance.isConnected) {
        try {
          final response = await _client
              .from('travel_trips')
              .insert(tripWithId.toJson())
              .select()
              .single();
          
          final savedTrip = TripData.fromJson(response);
          
          // Update local storage with server ID
          final updatedLocalTrip = localTrip.copyWith(
            id: savedTrip.id,
            isSynced: true,
          );
          await LocalStorageService.instance.saveTrip(updatedLocalTrip);
          
          // Invalidate user trips cache
          _invalidateUserTripsCache(trip.userId);
          
          return savedTrip;
        } catch (e) {
          debugPrint('Error creating trip in Supabase: $e');
          // Schedule sync for later
          SyncService.instance.syncData();
        }
      }
      
      // Return the local trip data
      return tripWithId;
    } catch (e) {
      debugPrint('Error creating trip: $e');
      return null;
    }
  }
  
  /// Update an existing trip
  Future<bool> updateTrip(String tripId, Map<String, dynamic> updates) async {
    try {
      // Update in local storage first
      final updatedLocalTrip = await LocalStorageService.instance.updateTrip(tripId, updates);
      
      // If online, try to sync with Supabase
      if (ConnectivityService.instance.isConnected) {
        try {
          await _client
              .from('travel_trips')
              .update(updates)
              .eq('id', tripId);
          
          // Mark as synced in local storage
          if (updatedLocalTrip != null) {
            await LocalStorageService.instance.markTripSynced(tripId);
          }
          
          // Invalidate caches
          if (updatedLocalTrip != null) {
            _invalidateUserTripsCache(updatedLocalTrip.userId);
          }
          
          return true;
        } catch (e) {
          debugPrint('Error updating trip in Supabase: $e');
          // Schedule sync for later
          SyncService.instance.syncData();
        }
      }
      
      // Return true if local update was successful
      return updatedLocalTrip != null;
    } catch (e) {
      debugPrint('Error updating trip: $e');
      return false;
    }
  }
  
  /// Delete a trip
  Future<bool> deleteTrip(String tripId) async {
    try {
      // Get trip data first to know user ID for cache invalidation
      final trip = await _getTripById(tripId);
      
      // Delete from local storage first
      final localSuccess = await LocalStorageService.instance.deleteTrip(tripId);
      
      // If online, try to delete from Supabase
      if (ConnectivityService.instance.isConnected) {
        try {
          await _client
              .from('travel_trips')
              .delete()
              .eq('id', tripId);
          
          // Invalidate caches
          if (trip != null) {
            _invalidateUserTripsCache(trip.userId);
          }
          _locationPointCache.remove(tripId);
          
          return true;
        } catch (e) {
          debugPrint('Error deleting trip from Supabase: $e');
          // Return local result
          return localSuccess;
        }
      }
      
      // Invalidate location points cache
      _locationPointCache.remove(tripId);
      
      return localSuccess;
    } catch (e) {
      debugPrint('Error deleting trip: $e');
      return false;
    }
  }
  
  /// Add a location point to a trip
  Future<bool> addLocationPoint(LocationPoint point) async {
    try {
      // Only save to local storage during tracking
      // Location points will be synced to Supabase when the trip is completed
      final localPoint = LocalLocationPoint.fromLocationPoint(point, isSynced: false);
      final savedPoint = await LocalStorageService.instance.saveLocationPoint(localPoint);
      
      // Invalidate location points cache for this trip
      _locationPointCache.remove(point.tripId);
      
      // Return true if local save was successful
      return savedPoint != null;
    } catch (e) {
      debugPrint('Error adding location point: $e');
      return false;
    }
  }
  
  /// Get all location points for a trip
  Future<List<LocationPoint>> getTripLocationPoints(String tripId) async {
    try {
      // Check cache first
      if (_locationPointCache.containsKey(tripId) && !_locationPointCache[tripId]!.isExpired) {
        return _locationPointCache[tripId]!.data;
      }
      
      List<LocationPoint> points = [];
      
      // Check if we're online
      if (ConnectivityService.instance.isConnected) {
        try {
          // Try to get location points from Supabase
          final response = await _client
              .from('location_points')
              .select()
              .eq('trip_id', tripId)
              .order('timestamp');
          
          points = (response as List).map((point) => LocationPoint.fromJson(point)).toList();
          
          // Save points to local storage in batch
          await Future.wait(
            points.map((point) => LocalStorageService.instance.saveLocationPoint(
              LocalLocationPoint.fromLocationPoint(point, isSynced: true)
            ))
          );
        } catch (e) {
          debugPrint('Error getting trip location points from Supabase: $e');
          // Fall back to local storage
        }
      }
      
      // If we couldn't get from Supabase, get from local storage
      if (points.isEmpty) {
        final localPoints = LocalStorageService.instance.getTripLocationPoints(tripId);
        points = localPoints.map((localPoint) => localPoint.toLocationPoint()).toList();
      }
      
      // Update cache
      _locationPointCache[tripId] = _CachedData<List<LocationPoint>>(points);
      
      return points;
    } catch (e) {
      debugPrint('Error getting trip location points: $e');
      return [];
    }
  }
  
  /// Batch sync location points for a trip to Supabase
  Future<bool> syncTripLocationPoints(String tripId) async {
    try {
      if (!ConnectivityService.instance.isConnected) {
        return false;
      }
      
      // Get unsynced location points for this trip
      final unsyncedPoints = LocalStorageService.instance.getUnsyncedLocationPointsForTrip(tripId);
      
      if (unsyncedPoints.isEmpty) {
        debugPrint('No unsynced location points for trip $tripId');
        return true;
      }
      
      // Convert to JSON format for Supabase
      final pointsJson = unsyncedPoints
          .map((localPoint) => localPoint.toLocationPoint().toJson())
          .toList();
      
      await _client
          .from('travel_locations')
          .insert(pointsJson);
      
      // Mark all points as synced
      await Future.wait(
        unsyncedPoints.map((point) => 
          LocalStorageService.instance.markLocationPointSynced(point.id)
        )
      );
      
      debugPrint('Synced ${unsyncedPoints.length} location points for trip $tripId');
      return true;
    } catch (e) {
      debugPrint('Error syncing location points for trip $tripId: $e');
      return false;
    }
  }
  
  /// Attribute trip emissions to organization's carbon footprint
  Future<bool> attributeEmissionsToOrganization(String organizationId, double emissions, String tripId) async {
    try {
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('Offline - organization emissions attribution will be synced later');
        return false;
      }
      
      // Check if organization carbon footprint record exists
      final existingRecord = await _client
          .from('organization_carbon_footprint')
          .select('id, travel_emissions')
          .eq('organization_id', organizationId)
          .maybeSingle();
      
      if (existingRecord != null) {
        // Update existing record
        final currentEmissions = double.parse(existingRecord['travel_emissions']?.toString() ?? '0');
        final newTotalEmissions = currentEmissions + emissions;
        
        await _client
            .from('organization_carbon_footprint')
            .update({
              'travel_emissions': newTotalEmissions,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingRecord['id']);
      } else {
        // Create new record
        await _client
            .from('organization_carbon_footprint')
            .insert({
              'organization_id': organizationId,
              'travel_emissions': emissions,
              'total_emissions': emissions, // Initialize with travel emissions
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
      
      debugPrint('Successfully attributed $emissions kg CO2e to organization $organizationId');
      return true;
    } catch (e) {
      debugPrint('Error attributing emissions to organization: $e');
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
  final String? fuelType;
  final double emissions;
  final String? startLocation;
  final String? endLocation;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? purpose;
  final String? organizationId;
  
  TripData({
    this.id,
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
    this.createdAt,
    this.updatedAt,
    this.purpose,
    this.organizationId,
  });
  
  factory TripData.fromJson(Map<String, dynamic> json) {
    return TripData(
      id: json['id'],
      userId: json['user_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      distance: double.parse(json['distance'].toString()),
      mode: json['mode'],
      fuelType: json['fuel_type'],
      emissions: double.parse(json['emissions'].toString()),
      startLocation: json['start_location'],
      endLocation: json['end_location'],
      isActive: json['is_active'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      purpose: json['purpose'],
      organizationId: json['organization_id'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      // Only include ID if it's not a local or temp ID (these should not be sent to Supabase)
      if (id != null && !id!.startsWith('local_') && !id!.startsWith('temp_')) 'id': id,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      'distance': distance,
      'mode': mode,
      if (fuelType != null) 'fuel_type': fuelType,
      'emissions': emissions,
      if (startLocation != null) 'start_location': startLocation,
      if (endLocation != null) 'end_location': endLocation,
      'is_active': isActive,
      if (purpose != null) 'purpose': purpose,
      if (organizationId != null) 'organization_id': organizationId,
    };
  }
  
  /// Create a copy of this TripData with optional field updates
  TripData copyWith({
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
    DateTime? createdAt,
    DateTime? updatedAt,
    String? purpose,
    String? organizationId,
  }) {
    return TripData(
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      purpose: purpose ?? this.purpose,
      organizationId: organizationId ?? this.organizationId,
    );
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

/// Helper class for caching data with expiration
class _CachedData<T> {
  final T data;
  final DateTime timestamp;
  
  _CachedData(this.data) : timestamp = DateTime.now();
  
  bool get isExpired => 
      DateTime.now().difference(timestamp).inMilliseconds > 
      TravelEmissionsService._cacheExpirationMs;
}

extension TravelEmissionsServiceExtension on TravelEmissionsService {
  /// Helper method to invalidate user trips cache
  void _invalidateUserTripsCache(String userId) {
    _tripCache.remove(userId);
  }
  
  /// Helper method to get a trip by ID
  Future<TripData?> _getTripById(String tripId) async {
    try {
      if (ConnectivityService.instance.isConnected) {
        try {
          final response = await _client
              .from('travel_trips')
              .select()
              .eq('id', tripId)
              .single();
          
          return TripData.fromJson(response);
        } catch (e) {
          debugPrint('Error getting trip by ID from Supabase: $e');
        }
      }
      
      // Try local storage
      final localTrip = LocalStorageService.instance.getTrip(tripId);
      return localTrip?.toTripData();
    } catch (e) {
      debugPrint('Error getting trip by ID: $e');
      return null;
    }
  }
}
