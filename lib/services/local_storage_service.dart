import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/local_trip_data.dart';
import '../models/local_business_connection.dart';

/// Service for managing local storage operations
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._();
  static const String _tripsBoxName = 'trips';
  static const String _locationsBoxName = 'locations';
  static const String _connectionsBoxName = 'connections';
  
  LocalStorageService._();
  
  static LocalStorageService get instance => _instance;
  
  Box<LocalTripData>? _tripsBox;
  Box<LocalLocationPoint>? _locationsBox;
  Box<LocalBusinessConnection>? _connectionsBox;
  
  /// Initialize Hive and open boxes
  Future<void> init() async {
    try {
      // Initialize Hive
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(LocalTripDataAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(LocalLocationPointAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(LocalBusinessConnectionAdapter());
      }
      
      // Force delete any lock files that might be preventing box opening
      await _forceDeleteLockFiles(appDocumentDir.path, _tripsBoxName);
      await _forceDeleteLockFiles(appDocumentDir.path, _locationsBoxName);
      await _forceDeleteLockFiles(appDocumentDir.path, _connectionsBoxName);
      
      // Open boxes with recovery options and retry mechanism
      _tripsBox = await _openBoxSafely<LocalTripData>(_tripsBoxName);
      _locationsBox = await _openBoxSafely<LocalLocationPoint>(_locationsBoxName);
      _connectionsBox = await _openBoxSafely<LocalBusinessConnection>(_connectionsBoxName);
      
      debugPrint('LocalStorageService initialized');
    } catch (e) {
      debugPrint('Error initializing LocalStorageService: $e');
      // Don't rethrow, just continue with limited functionality
    }
  }
  
  /// Helper method to safely open a Hive box with retries
  Future<Box<T>> _openBoxSafely<T>(String boxName) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        return await Hive.openBox<T>(boxName);
      } catch (e) {
        retryCount++;
        debugPrint('Error opening $boxName box (attempt $retryCount): $e');
        
        if (retryCount >= maxRetries) {
          // Last resort: delete the box and try again
          try {
            await Hive.deleteBoxFromDisk(boxName);
            return await Hive.openBox<T>(boxName);
          } catch (finalError) {
            debugPrint('Final attempt to open $boxName failed: $finalError');
            // Create an empty in-memory box as fallback
            return await Hive.openBox<T>(boxName, bytes: Uint8List(0));
          }
        }
        
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
    
    // This should never be reached due to the retry logic above
    throw Exception('Failed to open $boxName after multiple attempts');
  }
  
  /// Force delete lock files that might be preventing box opening
  Future<void> _forceDeleteLockFiles(String basePath, String boxName) async {
    try {
      final lockFile = File('$basePath/$boxName.lock');
      if (await lockFile.exists()) {
        await lockFile.delete();
        debugPrint('Deleted lock file for $boxName');
      }
    } catch (e) {
      debugPrint('Error deleting lock file for $boxName: $e');
      // Continue even if deletion fails
    }
  }
  
  /// Get all trips for a user
  List<LocalTripData> getUserTrips(String userId) {
    try {
      if (_tripsBox == null) {
        throw Exception('Trips box not initialized');
      }
      
      return _tripsBox!.values
          .where((trip) => trip.userId == userId)
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
    } catch (e) {
      debugPrint('Error getting user trips from local storage: $e');
      return [];
    }
  }
  
  /// Get a trip by ID
  LocalTripData? getTrip(String tripId) {
    try {
      if (_tripsBox == null) {
        throw Exception('Trips box not initialized');
      }
      
      return _tripsBox!.values.firstWhere((trip) => trip.id == tripId);
    } catch (e) {
      debugPrint('Error getting trip from local storage: $e');
      return null;
    }
  }
  
  /// Save a trip
  Future<LocalTripData?> saveTrip(LocalTripData trip) async {
    try {
      if (_tripsBox == null) {
        throw Exception('Trips box not initialized');
      }
      
      await _tripsBox!.put(trip.id, trip);
      return trip;
    } catch (e) {
      debugPrint('Error saving trip to local storage: $e');
      return null;
    }
  }
  
  /// Update a trip
  Future<LocalTripData?> updateTrip(String tripId, Map<String, dynamic> updates) async {
    try {
      if (_tripsBox == null) {
        throw Exception('Trips box not initialized');
      }
      
      final trip = getTrip(tripId);
      if (trip == null) {
        return null;
      }
      
      final updatedTrip = trip.copyWith(
        endTime: updates['end_time'] != null ? DateTime.parse(updates['end_time']) : trip.endTime,
        distance: updates['distance'] ?? trip.distance,
        emissions: updates['emissions'] ?? trip.emissions,
        isActive: updates['is_active'] ?? trip.isActive,
        purpose: updates['purpose'] ?? trip.purpose,
        fuelType: updates['fuel_type'] ?? trip.fuelType,
        isSynced: false, // Mark as not synced
      );
      
      await _tripsBox!.put(tripId, updatedTrip);
      return updatedTrip;
    } catch (e) {
      debugPrint('Error updating trip in local storage: $e');
      return null;
    }
  }
  
  /// Delete a trip
  Future<bool> deleteTrip(String tripId) async {
    try {
      if (_tripsBox == null) {
        throw Exception('Trips box not initialized');
      }
      
      await _tripsBox!.delete(tripId);
      
      // Delete associated location points
      if (_locationsBox != null) {
        final locationPoints = _locationsBox!.values.where((point) => point.tripId == tripId).toList();
        for (final point in locationPoints) {
          await _locationsBox!.delete(point.id);
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error deleting trip from local storage: $e');
      return false;
    }
  }
  
  /// Mark a trip as synced
  Future<bool> markTripSynced(String tripId) async {
    try {
      if (_tripsBox == null) {
        throw Exception('Trips box not initialized');
      }
      
      final trip = getTrip(tripId);
      if (trip == null) {
        return false;
      }
      
      final syncedTrip = trip.copyWith(isSynced: true);
      await _tripsBox!.put(tripId, syncedTrip);
      return true;
    } catch (e) {
      debugPrint('Error marking trip as synced in local storage: $e');
      return false;
    }
  }
  
  /// Get all unsynced trips
  List<LocalTripData> getUnsyncedTrips() {
    try {
      if (_tripsBox == null) {
        throw Exception('Trips box not initialized');
      }
      
      return _tripsBox!.values.where((trip) => !trip.isSynced).toList();
    } catch (e) {
      debugPrint('Error getting unsynced trips from local storage: $e');
      return [];
    }
  }
  
  /// Save a location point
  Future<LocalLocationPoint?> saveLocationPoint(LocalLocationPoint point) async {
    try {
      if (_locationsBox == null) {
        throw Exception('Locations box not initialized');
      }
      
      await _locationsBox!.put(point.id, point);
      return point;
    } catch (e) {
      debugPrint('Error saving location point to local storage: $e');
      return null;
    }
  }
  
  /// Get location points for a trip
  List<LocalLocationPoint> getTripLocationPoints(String tripId) {
    try {
      if (_locationsBox == null) {
        throw Exception('Locations box not initialized');
      }
      
      return _locationsBox!.values
          .where((point) => point.tripId == tripId)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      debugPrint('Error getting trip location points from local storage: $e');
      return [];
    }
  }
  
  /// Get all unsynced location points
  List<LocalLocationPoint> getUnsyncedLocationPoints() {
    try {
      if (_locationsBox == null) {
        throw Exception('Locations box not initialized');
      }
      
      return _locationsBox!.values.where((point) => !point.isSynced).toList();
    } catch (e) {
      debugPrint('Error getting unsynced location points from local storage: $e');
      return [];
    }
  }
  
  /// Get unsynced location points for a specific trip
  List<LocalLocationPoint> getUnsyncedLocationPointsForTrip(String tripId) {
    try {
      if (_locationsBox == null) {
        throw Exception('Locations box not initialized');
      }
      
      return _locationsBox!.values
          .where((point) => point.tripId == tripId && !point.isSynced)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      debugPrint('Error getting unsynced location points for trip from local storage: $e');
      return [];
    }
  }
  
  /// Mark a location point as synced
  Future<bool> markLocationPointSynced(String pointId) async {
    try {
      if (_locationsBox == null) {
        throw Exception('Locations box not initialized');
      }
      
      final point = _locationsBox!.values.firstWhere((p) => p.id == pointId);
      final syncedPoint = LocalLocationPoint(
        id: point.id,
        tripId: point.tripId,
        latitude: point.latitude,
        longitude: point.longitude,
        timestamp: point.timestamp,
        altitude: point.altitude,
        speed: point.speed,
        isSynced: true,
      );
      
      await _locationsBox!.put(pointId, syncedPoint);
      return true;
    } catch (e) {
      debugPrint('Error marking location point as synced in local storage: $e');
      return false;
    }
  }
  
  // ===== CONNECTION CACHING METHODS =====
  
  /// Cache connections for a user
  Future<bool> cacheConnections(List<LocalBusinessConnection> connections, String userId) async {
    try {
      if (_connectionsBox == null) {
        throw Exception('Connections box not initialized');
      }
      
      // Clear existing connections for this user
      await clearConnectionsForUser(userId);
      
      // Save new connections
      for (final connection in connections) {
        await _connectionsBox!.put('${userId}_${connection.id}', connection);
      }
      
      debugPrint('Cached ${connections.length} connections for user $userId');
      return true;
    } catch (e) {
      debugPrint('Error caching connections: $e');
      return false;
    }
  }
  
  /// Get cached connections for a user
  List<LocalBusinessConnection> getCachedConnections(String userId, {Duration maxAge = const Duration(minutes: 5)}) {
    try {
      if (_connectionsBox == null) {
        throw Exception('Connections box not initialized');
      }
      
      final allConnections = _connectionsBox!.values
          .where((connection) => connection.isForUser(userId))
          .where((connection) => connection.isCacheValid(maxAge: maxAge))
          .toList();
      
      debugPrint('Retrieved ${allConnections.length} cached connections for user $userId');
      return allConnections;
    } catch (e) {
      debugPrint('Error getting cached connections: $e');
      return [];
    }
  }
  
  /// Check if connections cache is valid for a user
  bool isConnectionsCacheValid(String userId, {Duration maxAge = const Duration(minutes: 5)}) {
    try {
      if (_connectionsBox == null) return false;
      
      final connections = _connectionsBox!.values
          .where((connection) => connection.isForUser(userId))
          .toList();
      
      if (connections.isEmpty) return false;
      
      // Check if all connections are still valid
      return connections.every((connection) => connection.isCacheValid(maxAge: maxAge));
    } catch (e) {
      debugPrint('Error checking connections cache validity: $e');
      return false;
    }
  }
  
  /// Clear cached connections for a specific user
  Future<bool> clearConnectionsForUser(String userId) async {
    try {
      if (_connectionsBox == null) {
        throw Exception('Connections box not initialized');
      }
      
      final keysToDelete = _connectionsBox!.keys
          .where((key) => key.toString().startsWith('${userId}_'))
          .toList();
      
      for (final key in keysToDelete) {
        await _connectionsBox!.delete(key);
      }
      
      debugPrint('Cleared ${keysToDelete.length} cached connections for user $userId');
      return true;
    } catch (e) {
      debugPrint('Error clearing connections cache: $e');
      return false;
    }
  }
  
  /// Clear all expired connections from cache
  Future<bool> clearExpiredConnections({Duration maxAge = const Duration(minutes: 5)}) async {
    try {
      if (_connectionsBox == null) {
        throw Exception('Connections box not initialized');
      }
      
      final expiredKeys = <dynamic>[];
      
      for (final entry in _connectionsBox!.toMap().entries) {
        if (!entry.value.isCacheValid(maxAge: maxAge)) {
          expiredKeys.add(entry.key);
        }
      }
      
      for (final key in expiredKeys) {
        await _connectionsBox!.delete(key);
      }
      
      debugPrint('Cleared ${expiredKeys.length} expired connections from cache');
      return true;
    } catch (e) {
      debugPrint('Error clearing expired connections: $e');
      return false;
    }
  }
  
  /// Get cache statistics
  Map<String, int> getConnectionsCacheStats() {
    try {
      if (_connectionsBox == null) {
        return {'total': 0, 'valid': 0, 'expired': 0};
      }
      
      final total = _connectionsBox!.length;
      final valid = _connectionsBox!.values
          .where((connection) => connection.isCacheValid())
          .length;
      final expired = total - valid;
      
      return {
        'total': total,
        'valid': valid,
        'expired': expired,
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {'total': 0, 'valid': 0, 'expired': 0};
    }
  }
  
  /// Close Hive boxes
  Future<void> close() async {
    await _tripsBox?.close();
    await _locationsBox?.close();
    await _connectionsBox?.close();
  }
}
