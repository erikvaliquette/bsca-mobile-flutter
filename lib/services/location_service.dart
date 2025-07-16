import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;

import 'permission_service.dart';

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
  
  /// Handle location permission logic
  Future<bool> handleLocationPermission(BuildContext context) async {
    // Check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Please enable location services in your device settings to track your travel emissions.'
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                PermissionService.instance.openSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
      return false;
    }
    
    // First check if we already have permission using permission_handler
    final permissionStatus = await permission_handler.Permission.location.status;
    if (permissionStatus.isGranted || permissionStatus.isLimited) {
      // We already have permission, no need to request again
      return true;
    }
    
    // If we don't have permission, use the PermissionService to handle it
    final hasPermission = await PermissionService.instance.handlePermission(
      context,
      permission_handler.Permission.location,
      'Location',
      'This app needs location access to track your travel emissions. '
      'Please grant location permission to use this feature.',
    );
    
    return hasPermission;
  }
}
