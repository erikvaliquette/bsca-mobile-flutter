import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_service.dart';

class SubscriptionUpgradePrompt extends StatelessWidget {
  final String featureDescription;
  final ServiceLevel requiredTier;
  final VoidCallback? onClose;
  final bool showUpgradeButton;
  
  const SubscriptionUpgradePrompt({
    Key? key,
    required this.featureDescription,
    required this.requiredTier,
    this.onClose,
    this.showUpgradeButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final currentTier = subscriptionProvider.currentServiceLevel;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (onClose != null)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            
            Icon(
              _getTierIcon(requiredTier),
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Upgrade to ${requiredTier.displayName}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'To access: $featureDescription',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            _buildTierComparison(context, currentTier, requiredTier),
            
            const SizedBox(height: 16),
            
            if (showUpgradeButton)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/pricing');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View Pricing Options'),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTierComparison(BuildContext context, ServiceLevel currentTier, ServiceLevel requiredTier) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTierCard(
                context,
                'Current',
                currentTier.displayName,
                _getTierIcon(currentTier),
                Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTierCard(
                context,
                'Required',
                requiredTier.displayName,
                _getTierIcon(requiredTier),
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTierCard(
    BuildContext context,
    String label,
    String tierName,
    IconData icon,
    Color backgroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            tierName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  IconData _getTierIcon(ServiceLevel tier) {
    switch (tier) {
      case ServiceLevel.free:
        return Icons.star_border;
      case ServiceLevel.professional:
        return Icons.workspace_premium;
      case ServiceLevel.enterprise:
        return Icons.business;
      case ServiceLevel.impactPartner:
        return Icons.eco;
      default:
        return Icons.star_border;
    }
  }
}

// Convenience dialog to show the upgrade prompt
class SubscriptionUpgradeDialog {
  static Future<void> show({
    required BuildContext context,
    required String featureDescription,
    required ServiceLevel requiredTier,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SubscriptionUpgradePrompt(
            featureDescription: featureDescription,
            requiredTier: requiredTier,
            onClose: () => Navigator.of(context).pop(),
          ),
        );
      },
    );
  }
}

// Widget that wraps content that requires a specific subscription tier
class SubscriptionGatedWidget extends StatelessWidget {
  final Widget child;
  final ServiceLevel requiredTier;
  final String featureDescription;
  final Widget? alternativeWidget;
  
  const SubscriptionGatedWidget({
    Key? key,
    required this.child,
    required this.requiredTier,
    required this.featureDescription,
    this.alternativeWidget,
  }) : super(key: key);
  
  // Helper method to check if current tier has access to required tier
  bool _hasRequiredTierAccess(ServiceLevel currentLevel, ServiceLevel requiredTier) {
    // Define tier hierarchy
    final tierValues = {
      ServiceLevel.free: 0,
      ServiceLevel.professional: 1,
      ServiceLevel.enterprise: 2,
      ServiceLevel.impactPartner: 3,
    };
    
    // Compare tier levels
    return tierValues[currentLevel]! >= tierValues[requiredTier]!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, _) {
        // Check if current service level is equal to or higher than required tier
        final currentLevel = subscriptionProvider.currentServiceLevel;
        final hasAccess = _hasRequiredTierAccess(currentLevel, requiredTier);
        
        if (hasAccess) {
          return child;
        } else {
          return alternativeWidget ?? SubscriptionUpgradePrompt(
            featureDescription: featureDescription,
            requiredTier: requiredTier,
          );
        }
      },
    );
  }
}
