import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import 'receipt_validation_service.dart';
import 'subscription_sync_service.dart';

class InAppPurchaseService {
  static final InAppPurchaseService _instance = InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  static InAppPurchaseService get instance => _instance;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final ReceiptValidationService _receiptValidator = ReceiptValidationService.instance;
  final SubscriptionSyncService _subscriptionSync = SubscriptionSyncService.instance;
  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  
  // Product IDs for each tier
  // These should match the IDs configured in App Store Connect and Google Play Console
  static const Map<ServiceLevel, String> _productIds = {
    ServiceLevel.professional: 'com.bsca.mobile.subscription.professional',
    ServiceLevel.enterprise: 'com.bsca.mobile.subscription.enterprise',
    ServiceLevel.impactPartner: 'com.bsca.mobile.subscription.impactpartner',
  };

  // Getters
  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  
  /// Initialize the in-app purchase service
  Future<void> initialize() async {
    final isAvailable = await _inAppPurchase.isAvailable();
    _isAvailable = isAvailable;

    if (!isAvailable) {
      debugPrint('In-app purchases not available on this device');
      return;
    }

    // Set up purchase stream listener
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );

    // Load product details
    await loadProducts();
  }

  /// Load available products from the stores
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    try {
      final productIds = _productIds.values.toSet();
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      debugPrint('Products loaded: ${_products.length}');
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  /// Get product details for a specific service level
  ProductDetails? getProductForServiceLevel(ServiceLevel serviceLevel) {
    if (serviceLevel == ServiceLevel.free) return null;
    
    final productId = _productIds[serviceLevel];
    if (productId == null) return null;
    
    return _products.firstWhere(
      (product) => product.id == productId,
      orElse: () => null as ProductDetails, // This will throw if not found
    );
  }

  /// Purchase a subscription for a specific service level
  Future<bool> purchaseSubscription(ServiceLevel serviceLevel) async {
    if (!_isAvailable) return false;
    if (serviceLevel == ServiceLevel.free) return false;

    final product = getProductForServiceLevel(serviceLevel);
    if (product == null) {
      debugPrint('Product not found for service level: ${serviceLevel.name}');
      return false;
    }

    try {
      // Create purchase parameters
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: null, // Optional user identifier
      );

      // Start the purchase flow
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      return success;
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    if (!_isAvailable) return false;

    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  /// Handle purchase updates from the store
  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
  }

  /// Handle a single purchase
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      // Purchase is pending, wait for completion
      debugPrint('Purchase pending: ${purchaseDetails.productID}');
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      // Purchase failed
      debugPrint('Purchase error: ${purchaseDetails.error?.message}');
      await _completePurchase(purchaseDetails, success: false);
    } else if (purchaseDetails.status == PurchaseStatus.purchased || 
               purchaseDetails.status == PurchaseStatus.restored) {
      // Purchase completed or restored
      debugPrint('Purchase completed: ${purchaseDetails.productID}');
      
      // Validate receipt
      final bool isValid = await _validateReceipt(purchaseDetails);
      
      if (isValid) {
        // Sync with backend
        final success = await _syncPurchaseWithBackend(purchaseDetails);
        await _completePurchase(purchaseDetails, success: success);
      } else {
        debugPrint('Receipt validation failed for: ${purchaseDetails.productID}');
        await _completePurchase(purchaseDetails, success: false);
      }
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      // Purchase canceled by user
      debugPrint('Purchase canceled: ${purchaseDetails.productID}');
      await _completePurchase(purchaseDetails, success: false);
    }
  }

  /// Validate purchase receipt with Apple/Google
  Future<bool> _validateReceipt(PurchaseDetails purchaseDetails) async {
    if (Platform.isIOS) {
      final receiptData = await _getIosReceiptData(purchaseDetails);
      return await _receiptValidator.validateIosReceipt(receiptData);
    } else if (Platform.isAndroid) {
      final androidPurchase = purchaseDetails as GooglePlayPurchaseDetails;
      return await _receiptValidator.validateAndroidReceipt(
        androidPurchase.billingClientPurchase,
      );
    }
    return false;
  }

  /// Get iOS receipt data
  Future<String> _getIosReceiptData(PurchaseDetails purchaseDetails) async {
    if (Platform.isIOS) {
      final iosPurchase = purchaseDetails as AppStorePurchaseDetails;
      // For iOS, we can use the transaction receipt directly from the purchase details
      // This is a base64 encoded receipt data that can be sent to Apple for validation
      return iosPurchase.verificationData.serverVerificationData;
    }
    return '';
  }

  /// Sync purchase with backend (Supabase)
  Future<bool> _syncPurchaseWithBackend(PurchaseDetails purchaseDetails) async {
    final serviceLevel = _getServiceLevelFromProductId(purchaseDetails.productID);
    if (serviceLevel == null) return false;

    // Extract subscription details
    final subscriptionInfo = await _extractSubscriptionInfo(purchaseDetails);
    
    // Sync with backend
    return await _subscriptionSync.syncPurchaseWithSupabase(
      serviceLevel: serviceLevel,
      purchaseDetails: purchaseDetails,
      subscriptionInfo: subscriptionInfo,
    );
  }

  /// Extract subscription information from purchase details
  Future<Map<String, dynamic>> _extractSubscriptionInfo(PurchaseDetails purchaseDetails) async {
    final Map<String, dynamic> info = {
      'productId': purchaseDetails.productID,
      'purchaseId': purchaseDetails.purchaseID,
      'transactionDate': DateTime.now().toIso8601String(),
      'verificationData': purchaseDetails.verificationData.serverVerificationData,
      'source': Platform.isIOS ? 'ios' : 'android',
    };

    // Add platform-specific details
    if (Platform.isIOS) {
      final iosPurchase = purchaseDetails as AppStorePurchaseDetails;
      // Add iOS-specific details if available
      // This would require parsing the receipt data
    } else if (Platform.isAndroid) {
      final androidPurchase = purchaseDetails as GooglePlayPurchaseDetails;
      final purchase = androidPurchase.billingClientPurchase;
      
      // Add Android-specific details
      info['orderId'] = purchase.orderId;
      info['packageName'] = purchase.packageName;
      info['purchaseTime'] = purchase.purchaseTime;
      info['purchaseToken'] = purchase.purchaseToken;
      
      // Add subscription-specific details
      if (purchase.isAutoRenewing != null) {
        info['isAutoRenewing'] = purchase.isAutoRenewing;
      }
      
      // Calculate expiry date based on purchase time and subscription period
      // This is a simplified approach - in production, you'd parse the actual expiry date
      final purchaseTime = DateTime.fromMillisecondsSinceEpoch(purchase.purchaseTime ?? 0);
      info['expiryDate'] = purchaseTime.add(const Duration(days: 30)).toIso8601String();
    }

    return info;
  }

  /// Complete the purchase process
  Future<void> _completePurchase(PurchaseDetails purchaseDetails, {required bool success}) async {
    // Mark transaction as complete in the store
    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  /// Map product ID to service level
  ServiceLevel? _getServiceLevelFromProductId(String productId) {
    for (final entry in _productIds.entries) {
      if (entry.value == productId) {
        return entry.key;
      }
    }
    return null;
  }

  /// Clean up resources
  void dispose() {
    _purchaseSubscription?.cancel();
  }

  /// Handle subscription stream completion
  void _updateStreamOnDone() {
    _purchaseSubscription = null;
  }

  /// Handle subscription stream errors
  void _updateStreamOnError(dynamic error) {
    debugPrint('Purchase stream error: $error');
  }
}
