import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_prompt_widget.dart';

/// Helper class for subscription-related functionality
class SubscriptionHelper {
  static final SubscriptionService _subscriptionService = SubscriptionService();
  
  /// Show upgrade prompt dialog for a specific feature
  static Future<bool> showUpgradePromptIfNeeded(
    BuildContext context, 
    String featureKey,
    {String? customMessage}
  ) async {
    final canAccess = await _subscriptionService.canAccessFeature(featureKey);
    
    if (!canAccess) {
      // Show upgrade dialog
      await showDialog(
        context: context,
        builder: (context) => UpgradePromptWidget(
          featureKey: featureKey,
          customMessage: customMessage,
          isDialog: true,
        ),
      );
      return false;
    }
    
    return true;
  }
  
  /// Check if user can access a specific feature
  static Future<bool> canAccessFeature(String featureKey) async {
    return await _subscriptionService.canAccessFeature(featureKey);
  }
  
  /// Get current service level
  static Future<ServiceLevel> getCurrentServiceLevel() async {
    return await _subscriptionService.getCurrentServiceLevel();
  }
  
  /// Constants for feature keys
  static const String FEATURE_BUSINESS_TRIP_ATTRIBUTION = 'business_trip_attribution';
  static const String FEATURE_ORGANIZATION_ACCESS = 'organization_access';
  static const String FEATURE_UNLIMITED_CONNECTIONS = 'unlimited_connections';
  static const String FEATURE_ANALYTICS = 'analytics';
  static const String FEATURE_TEAM_MANAGEMENT = 'team_management';
  static const String FEATURE_ADMIN_FEATURES = 'admin_features';
  static const String FEATURE_CUSTOM_BRANDING = 'custom_branding';
  static const String FEATURE_API_ACCESS = 'api_access';
}
