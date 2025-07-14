import 'dart:async';
import 'package:flutter/foundation.dart';

import 'connectivity_service.dart';
import 'local_storage_service.dart';
import 'travel_emissions_service.dart';

/// Service for synchronizing local data with remote database
class SyncService {
  static final SyncService _instance = SyncService._();
  
  SyncService._();
  
  static SyncService get instance => _instance;
  
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final LocalStorageService _localStorageService = LocalStorageService.instance;
  final TravelEmissionsService _travelEmissionsService = TravelEmissionsService.instance;
  
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  /// Initialize the sync service
  Future<void> init() async {
    try {
      // Listen for connectivity changes
      _connectivitySubscription = _connectivityService.connectionStatus.listen((isConnected) {
        if (isConnected) {
          // Trigger sync when connection is restored
          syncData();
        }
      });
      
      // Set up periodic sync (every 5 minutes)
      _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        if (_connectivityService.isConnected) {
          syncData();
        }
      });
      
      debugPrint('SyncService initialized');
    } catch (e) {
      debugPrint('Error initializing SyncService: $e');
    }
  }
  
  /// Synchronize local data with remote database
  Future<void> syncData() async {
    if (_isSyncing || !_connectivityService.isConnected) {
      return;
    }
    
    try {
      _isSyncing = true;
      debugPrint('Starting data sync...');
      
      // Sync unsynced trips
      final unsyncedTrips = _localStorageService.getUnsyncedTrips();
      for (final localTrip in unsyncedTrips) {
        if (localTrip.id.startsWith('local_')) {
          // This is a new trip created locally, create it on the server
          final tripData = localTrip.toTripData();
          final savedTrip = await _travelEmissionsService.createTrip(tripData);
          if (savedTrip != null) {
            // Update local trip with server ID and mark as synced
            final updatedLocalTrip = localTrip.copyWith(
              id: savedTrip.id,
              isSynced: true,
            );
            await _localStorageService.saveTrip(updatedLocalTrip);
          }
        } else {
          // This is an existing trip, update it on the server
          final updates = {
            'end_time': localTrip.endTime?.toIso8601String(),
            'distance': localTrip.distance,
            'emissions': localTrip.emissions,
            'is_active': localTrip.isActive,
            'purpose': localTrip.purpose,
            'fuel_type': localTrip.fuelType,
          };
          
          // Remove null values
          updates.removeWhere((key, value) => value == null);
          
          final success = await _travelEmissionsService.updateTrip(localTrip.id, updates);
          if (success) {
            await _localStorageService.markTripSynced(localTrip.id);
          }
        }
      }
      
      // Sync unsynced location points
      final unsyncedPoints = _localStorageService.getUnsyncedLocationPoints();
      for (final localPoint in unsyncedPoints) {
        final locationPoint = localPoint.toLocationPoint();
        final success = await _travelEmissionsService.addLocationPoint(locationPoint);
        if (success) {
          await _localStorageService.markLocationPointSynced(localPoint.id);
        }
      }
      
      debugPrint('Data sync completed');
    } catch (e) {
      debugPrint('Error during data sync: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Force a sync operation
  Future<bool> forceSyncNow() async {
    if (!_connectivityService.isConnected) {
      return false;
    }
    
    try {
      await syncData();
      return true;
    } catch (e) {
      debugPrint('Error during forced sync: $e');
      return false;
    }
  }
  
  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}
