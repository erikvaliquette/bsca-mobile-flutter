import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  static SubscriptionService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user's subscription
  Future<SubscriptionModel?> getCurrentSubscription() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        // User has no subscription record, return default free tier
        return SubscriptionModel.defaultFree(user.id);
      }

      return SubscriptionModel.fromJson(response);
    } catch (e) {
      print('Error fetching subscription: $e');
      return null;
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    final subscription = await getCurrentSubscription();
    return subscription?.isActive ?? false;
  }

  /// Get user's current service level
  Future<ServiceLevel> getCurrentServiceLevel() async {
    final subscription = await getCurrentSubscription();
    return subscription?.serviceLevel ?? ServiceLevel.free;
  }

  /// Check if user can access a specific feature
  Future<bool> canAccessFeature(String featureKey) async {
    final serviceLevel = await getCurrentServiceLevel();
    return _checkFeatureAccess(serviceLevel, featureKey);
  }

  /// Get feature limits for current user
  Future<Map<String, dynamic>> getFeatureLimits() async {
    final serviceLevel = await getCurrentServiceLevel();
    return _getServiceLevelLimits(serviceLevel);
  }

  /// Check if subscription is expired or expiring soon
  Future<bool> isSubscriptionExpiringSoon({int daysThreshold = 7}) async {
    final subscription = await getCurrentSubscription();
    if (subscription == null || !subscription.isActive) return false;

    if (subscription.currentPeriodEnd == null) return false;

    final now = DateTime.now();
    final expiryDate = subscription.currentPeriodEnd!;
    final daysUntilExpiry = expiryDate.difference(now).inDays;

    return daysUntilExpiry <= daysThreshold;
  }

  /// Create or update subscription record (for when user subscribes)
  Future<SubscriptionModel?> createOrUpdateSubscription({
    required String userId,
    required ServiceLevel serviceLevel,
    required String status,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    DateTime? currentPeriodEnd,
    Map<String, dynamic>? billingHistory,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'service_level': serviceLevel.name.toUpperCase(),
        'status': status,
        'stripe_customer_id': stripeCustomerId,
        'stripe_subscription_id': stripeSubscriptionId,
        'current_period_end': currentPeriodEnd?.toIso8601String(),
        'billing_history': billingHistory ?? [],
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('subscriptions')
          .upsert(data)
          .select()
          .single();

      return SubscriptionModel.fromJson(response);
    } catch (e) {
      print('Error creating/updating subscription: $e');
      return null;
    }
  }

  /// Private method to check feature access based on service level
  bool _checkFeatureAccess(ServiceLevel serviceLevel, String featureKey) {
    final limits = _getServiceLevelLimits(serviceLevel);
    
    switch (featureKey) {
      case 'unlimited_connections':
        return limits['max_connections'] == -1; // -1 means unlimited
      case 'business_trip_attribution':
        return limits['business_trip_attribution'] == true;
      case 'advanced_analytics':
        return limits['advanced_analytics'] == true;
      case 'team_management':
        return limits['team_management'] == true;
      case 'organization_admin':
        return limits['organization_admin'] == true;
      case 'custom_branding':
        return limits['custom_branding'] == true;
      case 'api_access':
        return limits['api_access'] == true;
      case 'priority_support':
        return limits['priority_support'] == true;
      default:
        return true; // Default to allowing access for unknown features
    }
  }

  /// Private method to get service level limits and features
  Map<String, dynamic> _getServiceLevelLimits(ServiceLevel serviceLevel) {
    switch (serviceLevel) {
      case ServiceLevel.free:
        return {
          'max_connections': 10,
          'business_trip_attribution': false,
          'advanced_analytics': false,
          'team_management': false,
          'organization_admin': false,
          'custom_branding': false,
          'api_access': false,
          'priority_support': false,
        };
      case ServiceLevel.basic:
        return {
          'max_connections': -1, // unlimited
          'business_trip_attribution': true,
          'advanced_analytics': false,
          'team_management': false,
          'organization_admin': false,
          'custom_branding': false,
          'api_access': false,
          'priority_support': false,
        };
      case ServiceLevel.advanced:
        return {
          'max_connections': -1, // unlimited
          'business_trip_attribution': true,
          'advanced_analytics': true,
          'team_management': true,
          'organization_admin': false,
          'custom_branding': false,
          'api_access': false,
          'priority_support': true,
        };
      case ServiceLevel.premium:
        return {
          'max_connections': -1, // unlimited
          'business_trip_attribution': true,
          'advanced_analytics': true,
          'team_management': true,
          'organization_admin': true,
          'custom_branding': true,
          'api_access': true,
          'priority_support': true,
        };
    }
  }
}

/// Enum for service levels
enum ServiceLevel {
  free,
  basic,
  advanced,
  premium;

  /// Convert from database string to enum
  static ServiceLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'genesis':
      case 'free':
        return ServiceLevel.free;
      case 'node':
      case 'basic':
        return ServiceLevel.basic;
      case 'smart chain':
      case 'smart_chain':
      case 'advanced':
        return ServiceLevel.advanced;
      case 'network':
      case 'premium':
        return ServiceLevel.premium;
      default:
        return ServiceLevel.free;
    }
  }

  /// Convert to database string (for backward compatibility)
  String get databaseValue {
    switch (this) {
      case ServiceLevel.free:
        return 'GENESIS'; // Keep existing database values for now
      case ServiceLevel.basic:
        return 'NODE';
      case ServiceLevel.advanced:
        return 'SMART CHAIN';
      case ServiceLevel.premium:
        return 'NETWORK';
    }
  }

  /// Get display name (will be customizable later)
  String get displayName {
    switch (this) {
      case ServiceLevel.free:
        return 'Free';
      case ServiceLevel.basic:
        return 'Basic';
      case ServiceLevel.advanced:
        return 'Advanced';
      case ServiceLevel.premium:
        return 'Premium';
    }
  }
}
