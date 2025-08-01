import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_service.dart';
import 'upgrade_prompt_widget.dart';

/// Widget that controls access to features based on subscription level
class AccessControlWidget extends StatelessWidget {
  final String featureKey;
  final Widget child;
  final Widget? fallback;
  final bool showUpgradePrompt;
  final String? customUpgradeMessage;

  const AccessControlWidget({
    super.key,
    required this.featureKey,
    required this.child,
    this.fallback,
    this.showUpgradePrompt = true,
    this.customUpgradeMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, _) {
        // Check if user has access to this feature
        final hasAccess = _checkFeatureAccess(subscriptionProvider, featureKey);

        if (hasAccess) {
          return child;
        }

        // User doesn't have access - show fallback or upgrade prompt
        if (fallback != null) {
          return fallback!;
        }

        if (showUpgradePrompt) {
          return UpgradePromptWidget(
            featureKey: featureKey,
            customMessage: customUpgradeMessage,
          );
        }

        // Default: show nothing if no access and no fallback
        return const SizedBox.shrink();
      },
    );
  }

  bool _checkFeatureAccess(SubscriptionProvider provider, String featureKey) {
    switch (featureKey) {
      case 'unlimited_connections':
        return provider.canAccessUnlimitedConnections;
      case 'business_trip_attribution':
        return provider.canAccessBusinessTripAttribution;
      case 'advanced_analytics':
        return provider.canAccessAdvancedAnalytics;
      case 'team_management':
        return provider.canAccessTeamManagement;
      case 'organization_admin':
        return provider.canAccessOrganizationAdmin;
      case 'custom_branding':
        return provider.canAccessCustomBranding;
      case 'api_access':
        return provider.canAccessApiAccess;
      case 'priority_support':
        return provider.canAccessPrioritySupport;
      default:
        return true; // Default to allowing access for unknown features
    }
  }
}

/// Widget for limiting lists based on subscription
class LimitedListWidget extends StatelessWidget {
  final List<Widget> items;
  final String featureKey;
  final int? customLimit;
  final Widget? limitReachedWidget;

  const LimitedListWidget({
    super.key,
    required this.items,
    required this.featureKey,
    this.customLimit,
    this.limitReachedWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, _) {
        final limit = customLimit ?? _getLimit(subscriptionProvider, featureKey);
        
        // If unlimited (-1) or no limit, show all items
        if (limit == -1 || limit >= items.length) {
          return Column(children: items);
        }

        // Show limited items plus upgrade prompt
        final limitedItems = items.take(limit).toList();
        
        return Column(
          children: [
            ...limitedItems,
            if (limitReachedWidget != null)
              limitReachedWidget!
            else
              _buildDefaultLimitWidget(context, subscriptionProvider, featureKey, limit),
          ],
        );
      },
    );
  }

  int _getLimit(SubscriptionProvider provider, String featureKey) {
    switch (featureKey) {
      case 'connections':
        return provider.connectionLimit;
      default:
        return -1; // Unlimited by default
    }
  }

  Widget _buildDefaultLimitWidget(
    BuildContext context,
    SubscriptionProvider provider,
    String featureKey,
    int limit,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.orange.shade600,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Limit Reached',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You\'ve reached your limit of $limit ${_getFeatureName(featureKey)}.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange.shade700),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showUpgradeDialog(context, provider, featureKey),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade to Continue'),
          ),
        ],
      ),
    );
  }

  String _getFeatureName(String featureKey) {
    switch (featureKey) {
      case 'connections':
        return 'connections';
      default:
        return 'items';
    }
  }

  void _showUpgradeDialog(
    BuildContext context,
    SubscriptionProvider provider,
    String featureKey,
  ) {
    showDialog(
      context: context,
      builder: (context) => UpgradePromptWidget(
        featureKey: featureKey,
        isDialog: true,
      ),
    );
  }
}

/// Wrapper for buttons that require subscription access
class SubscriptionGatedButton extends StatelessWidget {
  final String featureKey;
  final Widget button;
  final VoidCallback? onPressed;
  final String? upgradeMessage;

  const SubscriptionGatedButton({
    super.key,
    required this.featureKey,
    required this.button,
    this.onPressed,
    this.upgradeMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, _) {
        final hasAccess = _checkFeatureAccess(subscriptionProvider, featureKey);

        if (hasAccess) {
          return button;
        }

        // Return disabled button that shows upgrade prompt when tapped
        return GestureDetector(
          onTap: () => _showUpgradePrompt(context, subscriptionProvider),
          child: Opacity(
            opacity: 0.6,
            child: IgnorePointer(child: button),
          ),
        );
      },
    );
  }

  bool _checkFeatureAccess(SubscriptionProvider provider, String featureKey) {
    switch (featureKey) {
      case 'unlimited_connections':
        return provider.canAccessUnlimitedConnections;
      case 'business_trip_attribution':
        return provider.canAccessBusinessTripAttribution;
      case 'advanced_analytics':
        return provider.canAccessAdvancedAnalytics;
      case 'team_management':
        return provider.canAccessTeamManagement;
      case 'organization_admin':
        return provider.canAccessOrganizationAdmin;
      case 'custom_branding':
        return provider.canAccessCustomBranding;
      case 'api_access':
        return provider.canAccessApiAccess;
      case 'priority_support':
        return provider.canAccessPrioritySupport;
      default:
        return true;
    }
  }

  void _showUpgradePrompt(BuildContext context, SubscriptionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => UpgradePromptWidget(
        featureKey: featureKey,
        customMessage: upgradeMessage,
        isDialog: true,
      ),
    );
  }
}

/// Helper widget for showing subscription status
class SubscriptionStatusWidget extends StatelessWidget {
  final bool showDetails;

  const SubscriptionStatusWidget({
    super.key,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, _) {
        final subscription = subscriptionProvider.subscription;
        
        if (subscription == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor(subscription.serviceLevel).withOpacity(0.1),
            border: Border.all(color: _getStatusColor(subscription.serviceLevel)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _getStatusIcon(subscription.serviceLevel),
                color: _getStatusColor(subscription.serviceLevel),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${subscription.serviceLevel.displayName} Plan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(subscription.serviceLevel),
                      ),
                    ),
                    if (showDetails && subscription.isExpiringSoon()) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Expires in ${subscription.daysUntilExpiration} days',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(ServiceLevel level) {
    switch (level) {
      case ServiceLevel.free:
        return Colors.grey;
      case ServiceLevel.professional:
        return Colors.blue;
      case ServiceLevel.enterprise:
        return Colors.purple;
      case ServiceLevel.impactPartner:
        return Colors.amber;
    }
  }

  IconData _getStatusIcon(ServiceLevel level) {
    switch (level) {
      case ServiceLevel.free:
        return Icons.person_outline;
      case ServiceLevel.professional:
        return Icons.star_border;
      case ServiceLevel.enterprise:
        return Icons.star_half;
      case ServiceLevel.impactPartner:
        return Icons.star;
    }
  }
}
