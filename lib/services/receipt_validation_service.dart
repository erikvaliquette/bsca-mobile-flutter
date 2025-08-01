import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

class ReceiptValidationService {
  static final ReceiptValidationService _instance = ReceiptValidationService._internal();
  factory ReceiptValidationService() => _instance;
  ReceiptValidationService._internal();

  static ReceiptValidationService get instance => _instance;

  // Apple receipt validation endpoints
  static const String _appleSandboxUrl = 'https://sandbox.itunes.apple.com/verifyReceipt';
  static const String _appleProductionUrl = 'https://buy.itunes.apple.com/verifyReceipt';
  
  // Google Play receipt validation - typically done via your own backend
  // For security reasons, Google Play verification should be done server-side
  static const String _googlePlayVerificationEndpoint = 'https://api.bsca.app/verify-android-purchase';
  
  // Your app's shared secret from App Store Connect
  // In production, this should be stored securely, not hardcoded
  static const String _appleSharedSecret = ''; // TODO: Add your shared secret

  /// Validate iOS receipt with Apple servers
  Future<bool> validateIosReceipt(String receiptData) async {
    if (receiptData.isEmpty) {
      debugPrint('Empty receipt data');
      return false;
    }

    try {
      // First try production environment
      final bool productionValid = await _verifyWithApple(
        receiptData, 
        _appleProductionUrl,
      );
      
      // If production verification fails with specific error, try sandbox
      if (!productionValid) {
        return await _verifyWithApple(receiptData, _appleSandboxUrl);
      }
      
      return productionValid;
    } catch (e) {
      debugPrint('iOS receipt validation error: $e');
      return false;
    }
  }

  /// Verify receipt with Apple servers
  Future<bool> _verifyWithApple(String receiptData, String endpoint) async {
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        body: jsonEncode({
          'receipt-data': receiptData,
          'password': _appleSharedSecret, // Your shared secret from App Store Connect
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final int status = responseData['status'] ?? 21000;
        
        // Status 0 means successful validation
        if (status == 0) {
          // Parse receipt data and verify subscription status
          return _verifySubscriptionStatus(responseData);
        } else if (status == 21007) {
          // This receipt is from the test environment, but we're validating against production
          // Caller should retry with sandbox URL
          return false;
        } else if (status == 21008) {
          // This receipt is from the production environment, but we're validating against sandbox
          // Caller should retry with production URL
          return false;
        } else {
          debugPrint('Apple receipt validation failed with status: $status');
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error verifying with Apple: $e');
      return false;
    }
  }

  /// Verify subscription status from Apple receipt
  bool _verifySubscriptionStatus(Map<String, dynamic> receiptData) {
    try {
      // Check latest receipt info for subscription details
      final List<dynamic> latestReceiptInfo = receiptData['latest_receipt_info'] ?? [];
      
      if (latestReceiptInfo.isEmpty) {
        return false;
      }
      
      // Sort by expiration date to get the latest one
      latestReceiptInfo.sort((a, b) {
        final DateTime aExpires = DateTime.fromMillisecondsSinceEpoch(
          int.parse(a['expires_date_ms'] ?? '0')
        );
        final DateTime bExpires = DateTime.fromMillisecondsSinceEpoch(
          int.parse(b['expires_date_ms'] ?? '0')
        );
        return bExpires.compareTo(aExpires);
      });
      
      // Get the most recent subscription period
      final latestSubscription = latestReceiptInfo.first;
      
      // Check if subscription is still valid
      final expiresDateMs = latestSubscription['expires_date_ms'];
      if (expiresDateMs != null) {
        final DateTime expiryDate = DateTime.fromMillisecondsSinceEpoch(
          int.parse(expiresDateMs)
        );
        
        // Check if subscription is still active
        return DateTime.now().isBefore(expiryDate);
      }
      
      return false;
    } catch (e) {
      debugPrint('Error verifying subscription status: $e');
      return false;
    }
  }

  /// Validate Android purchase with Google Play
  Future<bool> validateAndroidReceipt(dynamic purchase) async {
    try {
      // In a production app, this verification should be done server-side
      // for security reasons. This is a simplified example.
      
      // For this example, we'll assume we're sending the purchase data to our backend
      // We'll use a simplified approach to avoid property access issues
      final Map<String, dynamic> requestData = {
        'rawData': purchase.toString(),
      };
      
      final response = await http.post(
        Uri.parse(_googlePlayVerificationEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['isValid'] == true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Android receipt validation error: $e');
      return false;
    }
  }

  /// Validate Android purchase locally (for development/testing)
  /// This should NOT be used in production - always verify with Google's servers
  bool validateAndroidPurchaseLocally(GooglePlayPurchaseDetails purchase) {
    // Check if purchase is acknowledged and not consumed (for subscriptions)
    if (purchase.billingClientPurchase.isAcknowledged == true) {
      // Check if it's a valid subscription
      if (purchase.billingClientPurchase.purchaseState == PurchaseStateWrapper.purchased) {
        return true;
      }
    }
    return false;
  }
}
