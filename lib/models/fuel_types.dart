import 'package:flutter/material.dart';

/// Utility class to manage fuel types for different modes of transport
class FuelTypes {
  /// Fuel types for car
  static const List<Map<String, dynamic>> car = [
    {'id': 'petrol', 'name': 'Petrol', 'emissionFactor': 0.192},
    {'id': 'diesel', 'name': 'Diesel', 'emissionFactor': 0.171},
    {'id': 'electric', 'name': 'Electric', 'emissionFactor': 0.053},
    {'id': 'hybrid', 'name': 'Hybrid', 'emissionFactor': 0.130},
    {'id': 'natural_gas', 'name': 'Natural Gas', 'emissionFactor': 0.159},
    {'id': 'biofuel', 'name': 'Biofuel', 'emissionFactor': 0.090},
  ];

  /// Fuel types for motorcycle
  static const List<Map<String, dynamic>> motorcycle = [
    {'id': 'petrol', 'name': 'Petrol', 'emissionFactor': 0.113},
    {'id': 'electric', 'name': 'Electric', 'emissionFactor': 0.035},
  ];

  /// Fuel types for truck
  static const List<Map<String, dynamic>> truck = [
    {'id': 'diesel', 'name': 'Diesel', 'emissionFactor': 0.250},
    {'id': 'natural_gas', 'name': 'Natural Gas', 'emissionFactor': 0.210},
    {'id': 'electric', 'name': 'Electric', 'emissionFactor': 0.080},
    {'id': 'biofuel', 'name': 'Biofuel', 'emissionFactor': 0.180},
  ];

  /// Fuel types for bus
  static const List<Map<String, dynamic>> bus = [
    {'id': 'diesel', 'name': 'Diesel', 'emissionFactor': 0.105},
    {'id': 'natural_gas', 'name': 'Natural Gas', 'emissionFactor': 0.085},
    {'id': 'electric', 'name': 'Electric', 'emissionFactor': 0.040},
    {'id': 'hybrid', 'name': 'Hybrid', 'emissionFactor': 0.070},
    {'id': 'biofuel', 'name': 'Biofuel', 'emissionFactor': 0.060},
  ];

  /// Fuel types for train
  static const List<Map<String, dynamic>> train = [
    {'id': 'diesel', 'name': 'Diesel', 'emissionFactor': 0.060},
    {'id': 'electric', 'name': 'Electric', 'emissionFactor': 0.041},
  ];

  /// Fuel types for boat
  static const List<Map<String, dynamic>> boat = [
    {'id': 'diesel', 'name': 'Diesel', 'emissionFactor': 0.195},
    {'id': 'petrol', 'name': 'Petrol', 'emissionFactor': 0.210},
    {'id': 'electric', 'name': 'Electric', 'emissionFactor': 0.070},
    {'id': 'human_powered', 'name': 'Human Powered', 'emissionFactor': 0.0},
    {'id': 'wind_power', 'name': 'Wind Power', 'emissionFactor': 0.0},
  ];

  /// Fuel types for plane
  static const List<Map<String, dynamic>> plane = [
    {'id': 'jet_fuel', 'name': 'Jet Fuel', 'emissionFactor': 0.255},
    {'id': 'sustainable_aviation_fuel', 'name': 'Sustainable Aviation Fuel', 'emissionFactor': 0.180},
  ];

  /// Zero emission modes
  static const List<Map<String, dynamic>> bicycle = [
    {'id': 'human_powered', 'name': 'Human Powered', 'emissionFactor': 0.0},
    {'id': 'electric', 'name': 'Electric', 'emissionFactor': 0.005},
  ];

  /// Zero emission modes (only walk)
  static const List<String> zeroEmissionModes = ['walk'];

  /// Get fuel types for a specific mode
  static List<Map<String, dynamic>> getFuelTypesForMode(String mode) {
    switch (mode) {
      case 'car':
        return car;
      case 'motorcycle':
        return motorcycle;
      case 'truck':
        return truck;
      case 'bus':
        return bus;
      case 'train':
        return train;
      case 'boat':
        return boat;
      case 'plane':
        return plane;
      case 'bicycle':
        return bicycle;
      default:
        return [];
    }
  }

  /// Check if a mode requires fuel type selection
  static bool requiresFuelType(String mode) {
    return !zeroEmissionModes.contains(mode);
  }

  /// Get default fuel type for a mode
  static String? getDefaultFuelType(String mode) {
    final fuelTypes = getFuelTypesForMode(mode);
    return fuelTypes.isNotEmpty ? fuelTypes.first['id'] as String : null;
  }

  /// Get emission factor for a specific mode and fuel type
  static double getEmissionFactor(String mode, String? fuelType) {
    // For zero emission modes
    if (zeroEmissionModes.contains(mode)) {
      return 0.0;
    }
    
    // Get fuel types for the mode
    final fuelTypes = getFuelTypesForMode(mode);
    
    // If no fuel type specified, use the default
    if (fuelType == null || fuelType.isEmpty) {
      return fuelTypes.isNotEmpty ? fuelTypes.first['emissionFactor'] as double : 0.0;
    }
    
    // Find the specific fuel type
    final specificFuelType = fuelTypes.firstWhere(
      (f) => f['id'] == fuelType,
      orElse: () => fuelTypes.isNotEmpty ? fuelTypes.first : {'emissionFactor': 0.0},
    );
    
    return specificFuelType['emissionFactor'] as double;
  }
}
