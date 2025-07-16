import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;

/// A service to handle location-related functionality
class LocationService {
  static final LocationService _instance = LocationService._internal();
  
  factory LocationService() {
    return _instance;
  }
  
  LocationService._internal();
  
  static LocationService get instance => _instance;
  
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
  
  /// Open app settings
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
  
  /// Check location permission
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }
  
  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }
  
  /// Get current position
  Future<Position> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
  }) async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: desiredAccuracy,
    );
  }
  
  /// Get position stream
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: locationSettings ?? 
        const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
    );
  }
  
  /// Handle location permission logic - completely revised to fix permission issues
  Future<bool> handleLocationPermission(BuildContext context) async {
    // First check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show dialog to enable location services
      final bool shouldOpenSettings = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Please enable location services in your device settings to track your travel emissions.'
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ) ?? false;
      
      if (shouldOpenSettings) {
        await openLocationSettings();
      }
      return false;
    }
    
    // Now check for location permission using Geolocator directly
    // This is more reliable than using permission_handler for location
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      // Request permission directly using Geolocator
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // User denied permission
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // User denied permission forever
      final bool shouldOpenSettings = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission has been permanently denied. '
            'Please enable it in app settings to track your travel emissions.'
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ) ?? false;
      
      if (shouldOpenSettings) {
        await Geolocator.openAppSettings();
      }
      return false;
    }
    
    // Permission is granted or limited - we can proceed
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }
}
