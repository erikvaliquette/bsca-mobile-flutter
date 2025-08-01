import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';

class SubscriptionSyncService {
  static final SubscriptionSyncService _instance = SubscriptionSyncService._internal();
  factory SubscriptionSyncService() => _instance;
  SubscriptionSyncService._internal();

  static SubscriptionSyncService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  /// Sync a purchase with Supabase
  Future<bool> syncPurchaseWithSupabase({
    required ServiceLevel serviceLevel,
    required PurchaseDetails purchaseDetails,
    required Map<String, dynamic> subscriptionInfo,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return false;
      }

      // Extract subscription details
      final DateTime? expiryDate = _extractExpiryDate(subscriptionInfo);
      final String purchaseSource = Platform.isIOS ? 'ios' : 'android';
      
      // Prepare billing history entry
      final Map<String, dynamic> billingEntry = {
        'transaction_id': purchaseDetails.purchaseID,
        'product_id': purchaseDetails.productID,
        'purchase_date': DateTime.now().toIso8601String(),
        'expiry_date': expiryDate?.toIso8601String(),
        'source': purchaseSource,
      };

      // Get current subscription to update billing history
      final currentSubscription = await _subscriptionService.getCurrentSubscription();
      final List<dynamic> billingHistory = currentSubscription?.billingHistory ?? [];
      billingHistory.add(billingEntry);

      // Update subscription in Supabase
      final updatedSubscription = await _subscriptionService.createOrUpdateSubscription(
        userId: user.id,
        serviceLevel: serviceLevel,
        status: 'active',
        stripeCustomerId: currentSubscription?.stripeCustomerId,
        stripeSubscriptionId: currentSubscription?.stripeSubscriptionId,
        currentPeriodEnd: expiryDate,
        billingHistory: billingHistory,
      );

      return updatedSubscription != null;
    } catch (e) {
      debugPrint('Error syncing purchase with Supabase: $e');
      return false;
    }
  }

  /// Extract expiry date from subscription info
  DateTime? _extractExpiryDate(Map<String, dynamic> subscriptionInfo) {
    try {
      if (subscriptionInfo.containsKey('expiryDate')) {
        return DateTime.parse(subscriptionInfo['expiryDate']);
      }
      
      // Default to 30 days from now if no expiry date is provided
      return DateTime.now().add(const Duration(days: 30));
    } catch (e) {
      debugPrint('Error extracting expiry date: $e');
      return null;
    }
  }

  /// Record a purchase failure in analytics
  Future<void> recordPurchaseFailure({
    required String productId,
    required String errorMessage,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('purchase_errors').insert({
        'user_id': user.id,
        'product_id': productId,
        'error_message': errorMessage,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error recording purchase failure: $e');
    }
  }

  /// Verify subscription status with platform stores and update Supabase
  Future<bool> verifyAndUpdateSubscriptionStatus() async {
    try {
      // This would typically involve checking with Apple/Google for current subscription status
      // and then updating the Supabase record accordingly
      
      // For now, this is a placeholder that assumes the local subscription data is accurate
      return true;
    } catch (e) {
      debugPrint('Error verifying subscription status: $e');
      return false;
    }
  }
}
