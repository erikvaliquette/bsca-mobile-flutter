import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_service.dart';

class UpgradePromptWidget extends StatelessWidget {
  final String featureKey;
  final String? customMessage;
  final bool isDialog;
  final VoidCallback? onUpgradePressed;

  const UpgradePromptWidget({
    super.key,
    required this.featureKey,
    this.customMessage,
    this.isDialog = false,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, _) {
        final minimumTier = subscriptionProvider.getMinimumTierForFeature(featureKey);
        final currentTier = subscriptionProvider.currentServiceLevel;
        
        if (isDialog) {
          return _buildDialog(context, subscriptionProvider, minimumTier, currentTier);
        }
        
        return _buildInlinePrompt(context, subscriptionProvider, minimumTier, currentTier);
      },
    );
  }

  Widget _buildDialog(
    BuildContext context,
    SubscriptionProvider subscriptionProvider,
    ServiceLevel? minimumTier,
    ServiceLevel currentTier,
  ) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.orange.shade600,
          ),
          const SizedBox(width: 8),
          const Text('Upgrade Required'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customMessage ?? _getDefaultMessage(featureKey, minimumTier),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildFeatureComparison(currentTier, minimumTier),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _handleUpgrade(context, subscriptionProvider, minimumTier);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Upgrade Now'),
        ),
      ],
    );
  }

  Widget _buildInlinePrompt(
    BuildContext context,
    SubscriptionProvider subscriptionProvider,
    ServiceLevel? minimumTier,
    ServiceLevel currentTier,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.blue.shade600,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Upgrade Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            customMessage ?? _getDefaultMessage(featureKey, minimumTier),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 20),
          _buildFeatureComparison(currentTier, minimumTier),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showAllPlans(context, subscriptionProvider),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue.shade600),
                  ),
                  child: const Text('View All Plans'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleUpgrade(context, subscriptionProvider, minimumTier),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Upgrade to ${minimumTier?.displayName ?? 'Premium'}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparison(ServiceLevel currentTier, ServiceLevel? minimumTier) {
    if (minimumTier == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current tier
          Text(
            'Current: ${currentTier.displayName}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.close, color: Colors.red.shade600, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getFeatureName(featureKey),
                  style: TextStyle(color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          // Divider between tiers
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              height: 1,
              color: Colors.grey.shade300,
            ),
          ),
          
          // Upgraded tier
          Text(
            'With ${minimumTier.displayName}:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.check, color: Colors.green.shade600, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getFeatureName(featureKey),
                  style: TextStyle(color: Colors.green.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDefaultMessage(String featureKey, ServiceLevel? minimumTier) {
    final featureName = _getFeatureName(featureKey);
    final tierName = minimumTier?.displayName ?? 'a higher plan';
    
    return 'To access $featureName, you need to upgrade to $tierName.';
  }

  String _getFeatureName(String featureKey) {
    switch (featureKey) {
      case 'unlimited_connections':
        return 'unlimited connections';
      case 'business_trip_attribution':
        return 'business trip attribution';
      case 'advanced_analytics':
        return 'advanced analytics';
      case 'team_management':
        return 'team management';
      case 'organization_admin':
        return 'organization admin features';
      case 'custom_branding':
        return 'custom branding';
      case 'api_access':
        return 'API access';
      case 'priority_support':
        return 'priority support';
      default:
        return 'this feature';
    }
  }

  void _handleUpgrade(
    BuildContext context,
    SubscriptionProvider subscriptionProvider,
    ServiceLevel? targetTier,
  ) {
    if (onUpgradePressed != null) {
      onUpgradePressed!();
      return;
    }

    // Default upgrade handling - navigate to subscription screen
    _navigateToSubscriptionScreen(context, targetTier);
  }

  void _showAllPlans(BuildContext context, SubscriptionProvider subscriptionProvider) {
    _navigateToSubscriptionScreen(context, null);
  }

  void _navigateToSubscriptionScreen(BuildContext context, ServiceLevel? targetTier) {
    // TODO: Navigate to subscription management screen
    // This will be implemented when we create the subscription management UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          targetTier != null 
            ? 'Upgrade to ${targetTier.displayName} - Subscription screen coming soon!'
            : 'View all plans - Subscription screen coming soon!',
        ),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }
}

/// Widget to show subscription benefits for a specific tier
class SubscriptionBenefitsWidget extends StatelessWidget {
  final ServiceLevel serviceLevel;
  final bool isCurrentPlan;
  final VoidCallback? onSelectPlan;

  const SubscriptionBenefitsWidget({
    super.key,
    required this.serviceLevel,
    this.isCurrentPlan = false,
    this.onSelectPlan,
  });

  @override
  Widget build(BuildContext context) {
    final benefits = _getBenefits(serviceLevel);
    
    return Card(
      elevation: isCurrentPlan ? 4 : 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isCurrentPlan 
            ? Border.all(color: Colors.blue, width: 2)
            : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTierIcon(serviceLevel),
                  color: _getTierColor(serviceLevel),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  serviceLevel.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isCurrentPlan) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            ...benefits.map((benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
            if (!isCurrentPlan && onSelectPlan != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSelectPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getTierColor(serviceLevel),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Upgrade to ${serviceLevel.displayName}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _getBenefits(ServiceLevel level) {
    switch (level) {
      case ServiceLevel.free:
        return [
          'Basic profile creation',
          'Up to 10 network connections',
          'Personal carbon tracking',
          'View public content',
        ];
      case ServiceLevel.professional:
        return [
          'Everything in Free',
          'Unlimited network connections',
          'Business trip attribution',
          'Basic analytics',
          'Organization membership',
        ];
      case ServiceLevel.enterprise:
        return [
          'Everything in Professional',
          'Advanced analytics',
          'Team management',
          'Priority support',
          'Enhanced reporting',
        ];
      case ServiceLevel.impactPartner:
        return [
          'Everything in Enterprise',
          'Admin features',
          'Custom branding',
          'API access',
          'Advanced reporting',
          'Dedicated support',
        ];
    }
  }

  IconData _getTierIcon(ServiceLevel level) {
    switch (level) {
      case ServiceLevel.free:
        return Icons.person_outline;
      case ServiceLevel.professional:
        return Icons.verified_user;
      case ServiceLevel.enterprise:
        return Icons.business;
      case ServiceLevel.impactPartner:
        return Icons.verified;
    }
  }

  Color _getTierColor(ServiceLevel level) {
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
}
