import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:collection';

import '../models/local_trip_data.dart';
import '../models/trip_organization_attribution_model.dart';
import '../services/trip_attribution_service.dart';
import '../services/organization_carbon_footprint_service.dart';
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
      
      // If online and tripId is not a temp ID, try to sync with Supabase
      if (ConnectivityService.instance.isConnected && !tripId.startsWith('temp_') && !tripId.startsWith('local_')) {
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
      debugPrint('🔄 Starting attribution: adding $emissions kg CO2e to organization $organizationId for trip $tripId');
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - organization emissions attribution will be synced later');
        return false;
      }
      
      // First, create or update the attribution record in the junction table
      final attributionResult = await TripAttributionService.instance.createTripOrganizationAttribution(
        tripId, 
        organizationId, 
        emissions
      );
      
      if (!attributionResult) {
        debugPrint('❌ Failed to create attribution record in junction table');
        return false;
      }
      
      debugPrint('🔍 Checking for existing organization carbon footprint record...');
      final existingRecord = await _client
          .from('organization_carbon_footprint')
          .select('id, scope3_business_travel, scope3_total, total_emissions')
          .eq('organization_id', organizationId)
          .maybeSingle();
      
      debugPrint('📊 Existing record found: ${existingRecord != null}');
      
      if (existingRecord != null) {
        // Update existing record
        final currentBusinessTravel = double.parse(existingRecord['scope3_business_travel']?.toString() ?? '0');
        final currentScope3Total = double.parse(existingRecord['scope3_total']?.toString() ?? '0');
        final currentTotalEmissions = double.parse(existingRecord['total_emissions']?.toString() ?? '0');
        
        final newBusinessTravel = currentBusinessTravel + emissions;
        final newScope3Total = currentScope3Total + emissions;
        final newTotalEmissions = currentTotalEmissions + emissions;
        
        debugPrint('📈 Updating existing record:');
        debugPrint('   Business Travel: $currentBusinessTravel + $emissions = $newBusinessTravel kg CO2e');
        debugPrint('   Scope 3 Total: $currentScope3Total + $emissions = $newScope3Total kg CO2e');
        debugPrint('   Total Emissions: $currentTotalEmissions + $emissions = $newTotalEmissions kg CO2e');
        
        final updateResult = await _client
            .from('organization_carbon_footprint')
            .update({
              'scope3_business_travel': newBusinessTravel,
              'scope3_total': newScope3Total,
              'total_emissions': newTotalEmissions,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingRecord['id'])
            .select();
            
        debugPrint('✅ Update result: $updateResult');
      } else {
        // Create new record
        debugPrint('🆕 Creating new organization carbon footprint record');
        
        final insertResult = await _client
            .from('organization_carbon_footprint')
            .insert({
              'organization_id': organizationId,
              'year': DateTime.now().year,
              'scope1_total': 0,
              'scope2_total': 0,
              'scope3_total': emissions,
              'scope3_business_travel': emissions,
              'total_emissions': emissions,
              'unit': 'tCO2e',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select();
            
        debugPrint('✅ Insert result: $insertResult');
      }
      
      debugPrint('🎉 Successfully attributed $emissions kg CO2e to organization $organizationId');
      return true;
    } catch (e) {
      debugPrint('❌ Error attributing emissions to organization: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// De-attribute emissions from an organization's carbon footprint
  /// This subtracts emissions when a trip changes from business to personal or changes organizations
  Future<bool> deAttributeEmissionsFromOrganization(String organizationId, double emissions, String tripId) async {
    try {
      debugPrint('🔄 Starting de-attribution: removing $emissions kg CO2e from organization $organizationId for trip $tripId');
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - organization emissions de-attribution will be synced later');
        return false;
      }
      
      // First, mark any attribution records for this trip and organization as inactive
      final deactivateResult = await TripAttributionService.instance.deactivateTripOrganizationAttribution(
        tripId, 
        organizationId
      );
      
      if (!deactivateResult) {
        debugPrint('⚠️ No attribution record found to deactivate or deactivation failed');
        // Continue anyway as we still want to update the organization carbon footprint
      }
      
      debugPrint('🔍 Checking for existing organization carbon footprint record...');
      final existingRecord = await _client
          .from('organization_carbon_footprint')
          .select('id, scope3_business_travel, scope3_total, total_emissions')
          .eq('organization_id', organizationId)
          .maybeSingle();
      
      debugPrint('📊 Existing record found: ${existingRecord != null}');
      
      if (existingRecord != null) {
        // Update existing record by subtracting emissions
        final currentBusinessTravel = double.parse(existingRecord['scope3_business_travel']?.toString() ?? '0');
        final currentScope3Total = double.parse(existingRecord['scope3_total']?.toString() ?? '0');
        final currentTotalEmissions = double.parse(existingRecord['total_emissions']?.toString() ?? '0');
        
        // Calculate new values (ensure they don't go below zero)
        final newBusinessTravel = (currentBusinessTravel - emissions).clamp(0.0, double.infinity);
        final newScope3Total = (currentScope3Total - emissions).clamp(0.0, double.infinity);
        final newTotalEmissions = (currentTotalEmissions - emissions).clamp(0.0, double.infinity);
        
        debugPrint('📉 De-attributing from existing record:');
        debugPrint('   Business Travel: $currentBusinessTravel - $emissions = $newBusinessTravel kg CO2e');
        debugPrint('   Scope 3 Total: $currentScope3Total - $emissions = $newScope3Total kg CO2e');
        debugPrint('   Total Emissions: $currentTotalEmissions - $emissions = $newTotalEmissions kg CO2e');
        
        final updateResult = await _client
            .from('organization_carbon_footprint')
            .update({
              'scope3_business_travel': newBusinessTravel,
              'scope3_total': newScope3Total,
              'total_emissions': newTotalEmissions,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingRecord['id'])
            .select();
          
        debugPrint('✅ De-attribution result: $updateResult');
      } else {
        debugPrint('⚠️ No existing carbon footprint record found for organization $organizationId - nothing to de-attribute');
        return false;
      }
      
      debugPrint('🎉 Successfully de-attributed $emissions kg CO2e from organization $organizationId');
      return true;
    } catch (e) {
      debugPrint('❌ Error de-attributing emissions from organization: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Get all active attribution records for a trip
  Future<List<TripOrganizationAttribution>> getTripAttributions(String tripId) async {
    return await TripAttributionService.instance.getTripAttributions(tripId);
  }

  /// Reconcile orphaned business trips
  /// This finds business trips without attribution records and creates them
  /// Returns the number of trips that were successfully reconciled
  Future<int> reconcileOrphanedBusinessTrips(String userId, String defaultOrganizationId) async {
    try {
      debugPrint('🔄 Starting reconciliation of orphaned business trips');
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - reconciliation will be performed later');
        return 0;
      }
      
      // Use the TripAttributionService to find and reconcile orphaned trips
      final reconciled = await TripAttributionService.instance.reconcileOrphanedBusinessTrips(
        userId,
        defaultOrganizationId,
      );
      
      if (reconciled > 0) {
        debugPrint('✅ Successfully reconciled $reconciled orphaned trips');
        
        // Note: Organization carbon footprint is updated through the attribution process
        debugPrint('✅ Reconciled $reconciled trips - carbon footprint updated through attribution records');
      }
      
      return reconciled;
    } catch (e) {
      debugPrint('❌ Error reconciling orphaned business trips: $e');
      return 0;
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
    // Filter out temp IDs to prevent UUID errors in Supabase
    final jsonMap = <String, dynamic>{
      'user_id': userId,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'distance': distance,
      'mode': mode,
      'emissions': emissions,
      'start_location': startLocation,
      'end_location': endLocation,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'purpose': purpose,
      'fuel_type': fuelType,
      // Note: organizationId is excluded because travel_trips table doesn't have this column
      // Organization attribution is handled separately via organization_carbon_footprint table
    };
    
    // Only include ID if it's not a temp ID
    if (id != null && !id!.startsWith('temp_') && !id!.startsWith('local_')) {
      jsonMap['id'] = id;
    }
    
    return jsonMap;
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
