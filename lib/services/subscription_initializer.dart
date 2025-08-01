import 'package:flutter/foundation.dart';
import 'in_app_purchase_service.dart';
import 'receipt_validation_service.dart';
import 'subscription_service.dart';
import 'subscription_sync_service.dart';

/// Initializes all subscription-related services at app startup
class SubscriptionInitializer {
  static final SubscriptionInitializer _instance = SubscriptionInitializer._internal();
  
  factory SubscriptionInitializer() {
    return _instance;
  }
  
  SubscriptionInitializer._internal();
  
  bool _isInitialized = false;
  
  /// Initialize all subscription services
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('Subscription services already initialized');
      return;
    }
    
    try {
      debugPrint('Initializing subscription services...');
      
      // Get singleton instances
      final receiptValidationService = ReceiptValidationService.instance;
      final subscriptionSyncService = SubscriptionSyncService.instance;
      final inAppPurchaseService = InAppPurchaseService.instance;
      
      // Initialize the in-app purchase system
      await inAppPurchaseService.initialize();
      
      // Load available products
      await inAppPurchaseService.loadProducts();
      
      _isInitialized = true;
      debugPrint('Subscription services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing subscription services: $e');
      // Don't set _isInitialized to true if initialization fails
      // This allows for retry attempts
    }
  }
  
  /// Check if subscription services are initialized
  bool get isInitialized => _isInitialized;
}
