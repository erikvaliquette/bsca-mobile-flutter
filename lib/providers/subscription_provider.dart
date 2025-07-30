import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionModel? _subscription;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  SubscriptionModel? get subscription => _subscription;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  
  // Convenience getters
  ServiceLevel get currentServiceLevel => _subscription?.serviceLevel ?? ServiceLevel.free;
  bool get hasActiveSubscription => _subscription?.isActive ?? false;
  bool get isSubscriptionExpiringSoon => _subscription?.isExpiringSoon() ?? false;
  Map<String, dynamic> get displayInfo => _subscription?.displayInfo ?? {};

  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  SubscriptionProvider() {
    _initialize();
  }

  /// Initialize subscription data
  Future<void> _initialize() async {
    await loadSubscription();
    _isInitialized = true;
    notifyListeners();
  }

  /// Load current user's subscription
  Future<void> loadSubscription() async {
    _setLoading(true);
    _error = null;

    try {
      _subscription = await _subscriptionService.getCurrentSubscription();
    } catch (e) {
      _error = 'Failed to load subscription: $e';
      print('Error loading subscription: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh subscription data
  Future<void> refreshSubscription() async {
    await loadSubscription();
  }

  /// Check if user can access a specific feature
  Future<bool> canAccessFeature(String featureKey) async {
    try {
      return await _subscriptionService.canAccessFeature(featureKey);
    } catch (e) {
      print('Error checking feature access: $e');
      return false; // Default to denying access on error
    }
  }

  /// Get feature limits for current user
  Future<Map<String, dynamic>> getFeatureLimits() async {
    try {
      return await _subscriptionService.getFeatureLimits();
    } catch (e) {
      print('Error getting feature limits: $e');
      return {}; // Return empty map on error
    }
  }

  /// Check specific feature access (synchronous versions for UI)
  bool get canAccessUnlimitedConnections => _checkFeatureSync('unlimited_connections');
  bool get canAccessBusinessTripAttribution => _checkFeatureSync('business_trip_attribution');
  bool get canAccessAdvancedAnalytics => _checkFeatureSync('advanced_analytics');
  bool get canAccessTeamManagement => _checkFeatureSync('team_management');
  bool get canAccessOrganizationAdmin => _checkFeatureSync('organization_admin');
  bool get canAccessCustomBranding => _checkFeatureSync('custom_branding');
  bool get canAccessApiAccess => _checkFeatureSync('api_access');
  bool get canAccessPrioritySupport => _checkFeatureSync('priority_support');

  /// Get connection limit for current user
  int get connectionLimit {
    final limits = _getFeatureLimitsSync();
    return limits['max_connections'] ?? 10;
  }

  /// Check if user has unlimited connections
  bool get hasUnlimitedConnections => connectionLimit == -1;

  /// Update subscription (when user subscribes/unsubscribes)
  Future<bool> updateSubscription({
    required ServiceLevel serviceLevel,
    required String status,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    DateTime? currentPeriodEnd,
    Map<String, dynamic>? billingHistory,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final userId = _subscription?.userId;
      if (userId == null) {
        throw Exception('No user ID available');
      }

      final updatedSubscription = await _subscriptionService.createOrUpdateSubscription(
        userId: userId,
        serviceLevel: serviceLevel,
        status: status,
        stripeCustomerId: stripeCustomerId,
        stripeSubscriptionId: stripeSubscriptionId,
        currentPeriodEnd: currentPeriodEnd,
        billingHistory: billingHistory,
      );

      if (updatedSubscription != null) {
        _subscription = updatedSubscription;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update subscription';
        return false;
      }
    } catch (e) {
      _error = 'Failed to update subscription: $e';
      print('Error updating subscription: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Upgrade subscription to a higher tier
  Future<bool> upgradeSubscription(ServiceLevel newServiceLevel) async {
    return await updateSubscription(
      serviceLevel: newServiceLevel,
      status: 'active',
      currentPeriodEnd: DateTime.now().add(const Duration(days: 30)), // Default 30 days
    );
  }

  /// Cancel subscription (downgrade to free)
  Future<bool> cancelSubscription() async {
    return await updateSubscription(
      serviceLevel: ServiceLevel.free,
      status: 'cancelled',
    );
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Synchronous feature check (uses cached subscription data)
  bool _checkFeatureSync(String featureKey) {
    if (_subscription == null) return false;
    
    final limits = _getFeatureLimitsSync();
    
    switch (featureKey) {
      case 'unlimited_connections':
        return limits['max_connections'] == -1;
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
        return true;
    }
  }

  /// Get feature limits synchronously (uses cached subscription data)
  Map<String, dynamic> _getFeatureLimitsSync() {
    final serviceLevel = _subscription?.serviceLevel ?? ServiceLevel.free;
    
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
          'max_connections': -1,
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
          'max_connections': -1,
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
          'max_connections': -1,
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

  /// Clear subscription data (for logout)
  void clearSubscription() {
    _subscription = null;
    _error = null;
    _isLoading = false;
    _isInitialized = false;
    notifyListeners();
  }

  /// Get upgrade suggestions based on current tier
  List<ServiceLevel> getUpgradeOptions() {
    final current = currentServiceLevel;
    switch (current) {
      case ServiceLevel.free:
        return [ServiceLevel.basic, ServiceLevel.advanced, ServiceLevel.premium];
      case ServiceLevel.basic:
        return [ServiceLevel.advanced, ServiceLevel.premium];
      case ServiceLevel.advanced:
        return [ServiceLevel.premium];
      case ServiceLevel.premium:
        return []; // Already at highest tier
    }
  }

  /// Check if user needs to upgrade for a feature
  bool needsUpgradeForFeature(String featureKey) {
    return !_checkFeatureSync(featureKey);
  }

  /// Get minimum tier required for a feature
  ServiceLevel? getMinimumTierForFeature(String featureKey) {
    for (final tier in ServiceLevel.values) {
      final limits = _getFeatureLimitsForTier(tier);
      if (_checkFeatureAccessForTier(tier, featureKey, limits)) {
        return tier;
      }
    }
    return null;
  }

  /// Helper method to get limits for a specific tier
  Map<String, dynamic> _getFeatureLimitsForTier(ServiceLevel tier) {
    switch (tier) {
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
          'max_connections': -1,
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
          'max_connections': -1,
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
          'max_connections': -1,
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

  /// Helper method to check feature access for a specific tier
  bool _checkFeatureAccessForTier(ServiceLevel tier, String featureKey, Map<String, dynamic> limits) {
    switch (featureKey) {
      case 'unlimited_connections':
        return limits['max_connections'] == -1;
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
        return true;
    }
  }
}
