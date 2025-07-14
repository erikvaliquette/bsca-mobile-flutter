import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  
  ConnectivityService._();
  
  static ConnectivityService get instance => _instance;
  
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool _isConnected = true;
  
  /// Initialize the connectivity service
  Future<void> init() async {
    try {
      // Get initial connection status
      final connectivityResults = await _connectivity.checkConnectivity();
      _updateConnectionStatus(connectivityResults);
      
      // Listen for connectivity changes
      _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
      
      debugPrint('ConnectivityService initialized');
    } catch (e) {
      debugPrint('Error initializing ConnectivityService: $e');
      _isConnected = false;
    }
  }
  
  /// Update connection status based on connectivity results
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Consider connected if any result is not 'none'
    _isConnected = results.any((result) => result != ConnectivityResult.none);
    _connectionStatusController.add(_isConnected);
    debugPrint('Connection status: ${_isConnected ? 'Online' : 'Offline'}');
  }
  
  /// Check if device is currently connected to the internet
  bool get isConnected => _isConnected;
  
  /// Dispose of resources
  void dispose() {
    _connectionStatusController.close();
  }
}
