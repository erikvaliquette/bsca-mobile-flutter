import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/fuel_types.dart';
import 'location_service.dart';
import 'travel_emissions_service.dart';

/// Service for managing background trip tracking that persists beyond widget lifecycle
class BackgroundTripTrackingService {
  static final BackgroundTripTrackingService _instance = BackgroundTripTrackingService._internal();
  static BackgroundTripTrackingService get instance => _instance;
  
  BackgroundTripTrackingService._internal();
  
  // Current tracking state
  TripData? _currentTrip;
  Position? _lastPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;
  
  // Tracking parameters
  String _selectedMode = 'car';
  String? _selectedFuelType;
  String _selectedPurpose = 'commute';
  
  // Stream controllers for UI updates
  final StreamController<TripData?> _currentTripController = StreamController<TripData?>.broadcast();
  final StreamController<bool> _isTrackingController = StreamController<bool>.broadcast();
  final StreamController<Position?> _lastPositionController = StreamController<Position?>.broadcast();
  
  // Getters for current state
  TripData? get currentTrip => _currentTrip;
  bool get isTracking => _isTracking;
  Position? get lastPosition => _lastPosition;
  
  // Streams for UI to listen to
  Stream<TripData?> get currentTripStream => _currentTripController.stream;
  Stream<bool> get isTrackingStream => _isTrackingController.stream;
  Stream<Position?> get lastPositionStream => _lastPositionController.stream;
  
  /// Start tracking a new trip
  Future<bool> startTracking({
    required String userId,
    required String mode,
    String? fuelType,
    required String purpose,
  }) async {
    if (_isTracking) {
      debugPrint('⚠️ Trip tracking already in progress');
      return false;
    }
    
    try {
      debugPrint('🚀 Starting background trip tracking');
      
      // Store tracking parameters
      _selectedMode = mode;
      _selectedFuelType = fuelType;
      _selectedPurpose = purpose;
      
      // Get current position
      final position = await LocationService.instance.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _lastPosition = position;
      _lastPositionController.add(position);
      
      // Create a new trip with start location
      final startLocationString = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      
      final newTrip = TripData(
        userId: userId,
        startTime: DateTime.now(),
        distance: 0.0,
        mode: mode,
        fuelType: fuelType,
        emissions: 0.0,
        isActive: true,
        purpose: purpose,
        startLocation: startLocationString,
      );
      
      // Keep trip in memory with a temporary local ID until we have meaningful movement
      _currentTrip = newTrip.copyWith(id: 'temp_${const Uuid().v4()}');
      _currentTripController.add(_currentTrip);
      
      // Start position stream
      final positionStream = LocationService.instance.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
      
      // Listen to position updates
      _positionStreamSubscription = positionStream.listen(
        (Position position) {
          _updateTripWithNewPosition(position);
        },
        onError: (error) {
          debugPrint('❌ Error in position stream: $error');
        },
      );
      
      _isTracking = true;
      _isTrackingController.add(_isTracking);
      
      debugPrint('✅ Background trip tracking started successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting background trip tracking: $e');
      return false;
    }
  }
  
  /// Stop tracking the current trip
  Future<TripData?> stopTracking({String? selectedOrganizationId}) async {
    if (!_isTracking || _currentTrip == null) {
      debugPrint('⚠️ No trip tracking in progress');
      return null;
    }
    
    try {
      debugPrint('🛑 Stopping background trip tracking');
      
      // Cancel position stream
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      
      final endTime = DateTime.now();
      
      // Add end location if we have a last position
      String? endLocationString;
      if (_lastPosition != null) {
        endLocationString = '${_lastPosition!.latitude.toStringAsFixed(6)}, ${_lastPosition!.longitude.toStringAsFixed(6)}';
      }
      
      // Finalize the trip
      final finalTrip = _currentTrip!.copyWith(
        endTime: endTime,
        isActive: false,
        endLocation: endLocationString,
        organizationId: selectedOrganizationId,
      );
      
      // Save or update trip in database
      TripData? savedTrip;
      if (_currentTrip!.id!.startsWith('temp_')) {
        // Trip was never saved to database, create it now
        final tripToSave = finalTrip.copyWith(id: null); // Remove temp ID
        savedTrip = await TravelEmissionsService.instance.createTrip(tripToSave);
      } else {
        // Trip exists in database, update it
        final updates = {
          'end_time': endTime.toIso8601String(),
          'distance': finalTrip.distance,
          'emissions': finalTrip.emissions,
          'is_active': false,
          'fuel_type': finalTrip.fuelType,
          if (endLocationString != null) 'end_location': endLocationString,
          if (selectedOrganizationId != null) 'organization_id': selectedOrganizationId,
        };
        
        await TravelEmissionsService.instance.updateTrip(_currentTrip!.id!, updates);
        savedTrip = finalTrip;
      }
      
      // Handle organization attribution for business trips
      if (selectedOrganizationId != null && finalTrip.emissions > 0) {
        debugPrint('🏢 Attempting to attribute ${finalTrip.emissions} kg CO2e to organization $selectedOrganizationId');
        try {
          final attributionSuccess = await TravelEmissionsService.instance.attributeEmissionsToOrganization(
            selectedOrganizationId,
            finalTrip.emissions,
            savedTrip?.id ?? finalTrip.id!,
          );
          if (attributionSuccess) {
            debugPrint('✅ Successfully attributed emissions to organization');
          } else {
            debugPrint('⚠️ Failed to attribute emissions to organization');
          }
        } catch (error) {
          debugPrint('❌ Exception during emission attribution: $error');
        }
      }
      
      // Sync location points if trip was saved in database
      if (savedTrip?.id != null && !savedTrip!.id!.startsWith('temp_')) {
        TravelEmissionsService.instance.syncTripLocationPoints(savedTrip!.id!).catchError((error) {
          debugPrint('Error syncing location points: $error');
          return false;
        });
      }
      
      // Reset tracking state
      _currentTrip = null;
      _lastPosition = null;
      _isTracking = false;
      
      // Notify UI
      _currentTripController.add(_currentTrip);
      _lastPositionController.add(_lastPosition);
      _isTrackingController.add(_isTracking);
      
      debugPrint('✅ Background trip tracking stopped successfully');
      return savedTrip ?? finalTrip;
    } catch (e) {
      debugPrint('❌ Error stopping background trip tracking: $e');
      return null;
    }
  }
  
  /// Update trip with new position data
  void _updateTripWithNewPosition(Position position) {
    if (_lastPosition == null || _currentTrip == null) return;
    
    // Calculate distance between last position and current position
    final distanceInMeters = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );
    
    // Convert to kilometers
    final distanceInKm = distanceInMeters / 1000;
    
    // Update trip distance
    final newDistance = _currentTrip!.distance + distanceInKm;
    
    // Calculate emissions based on mode and distance
    final emissionFactor = FuelTypes.getEmissionFactor(_selectedMode, _selectedFuelType);
    final newEmissions = newDistance * emissionFactor;
    
    // Check if this is the first meaningful movement (save trip to database)
    final isTemporaryTrip = _currentTrip!.id!.startsWith('temp_');
    final hasMinimumDistance = newDistance >= 0.01; // 10 meters
    
    if (isTemporaryTrip && hasMinimumDistance) {
      // Save trip to database now that we have meaningful movement
      final tripToSave = _currentTrip!.copyWith(
        id: null, // Remove temp ID so database can generate real ID
        distance: newDistance,
        emissions: newEmissions,
      );
      
      TravelEmissionsService.instance.createTrip(tripToSave).then((savedTrip) {
        if (savedTrip != null) {
          // Update current trip with real database ID
          _currentTrip = savedTrip.copyWith(
            distance: newDistance,
            emissions: newEmissions,
          );
          _currentTripController.add(_currentTrip);
          debugPrint('Trip saved to database with ID: ${savedTrip.id}');
        }
      }).catchError((error) {
        debugPrint('Error saving trip to database: $error');
      });
    } else if (!isTemporaryTrip) {
      // Update existing trip in database
      TravelEmissionsService.instance.updateTrip(
        _currentTrip!.id!,
        {
          'distance': newDistance,
          'emissions': newEmissions,
        },
      ).catchError((error) {
        debugPrint('Error updating trip: $error');
      });
    }
    
    // Save location points if trip is saved in database (not temporary)
    if (!_currentTrip!.id!.startsWith('temp_')) {
      TravelEmissionsService.instance.addLocationPoint(
        LocationPoint(
          tripId: _currentTrip!.id!,
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now().toIso8601String(),
          altitude: position.altitude,
          speed: position.speed,
        ),
      ).catchError((error) {
        debugPrint('Error adding location point: $error');
      });
    }
    
    // Update current trip state
    _currentTrip = TripData(
      id: _currentTrip!.id,
      userId: _currentTrip!.userId,
      startTime: _currentTrip!.startTime,
      endTime: _currentTrip!.endTime,
      distance: newDistance,
      mode: _currentTrip!.mode,
      fuelType: _currentTrip!.fuelType,
      emissions: newEmissions,
      isActive: true,
      purpose: _currentTrip!.purpose,
      startLocation: _currentTrip!.startLocation,
      endLocation: _currentTrip!.endLocation,
      organizationId: _currentTrip!.organizationId,
    );
    
    _lastPosition = position;
    
    // Notify UI of updates
    _currentTripController.add(_currentTrip);
    _lastPositionController.add(_lastPosition);
  }
  
  /// Dispose of the service and clean up resources
  void dispose() {
    _positionStreamSubscription?.cancel();
    _currentTripController.close();
    _isTrackingController.close();
    _lastPositionController.close();
  }
}
