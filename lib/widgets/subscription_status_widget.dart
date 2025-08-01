import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_service.dart';

class SubscriptionStatusWidget extends StatelessWidget {
  final bool compact;
  
  const SubscriptionStatusWidget({
    Key? key,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final currentTier = subscriptionProvider.currentServiceLevel;
    final isActive = subscriptionProvider.hasActiveSubscription;
    final displayInfo = subscriptionProvider.displayInfo;
    final daysUntilExpiration = displayInfo['daysUntilExpiration'];
    final isExpiringSoon = subscriptionProvider.isSubscriptionExpiringSoon;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive 
              ? (isExpiringSoon ? Colors.orange : Theme.of(context).colorScheme.primary) 
              : Theme.of(context).colorScheme.error,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/account'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12.0 : 16.0),
          child: compact ? _buildCompactView(context, currentTier, isActive, isExpiringSoon, daysUntilExpiration) 
                         : _buildFullView(context, currentTier, isActive, isExpiringSoon, daysUntilExpiration),
        ),
      ),
    );
  }
  
  Widget _buildCompactView(
    BuildContext context, 
    ServiceLevel currentTier, 
    bool isActive,
    bool isExpiringSoon,
    int? daysUntilExpiration
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              _getTierIcon(currentTier),
              color: isActive 
                  ? (isExpiringSoon ? Colors.orange : Theme.of(context).colorScheme.primary)
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentTier.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive 
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
                if (isExpiringSoon && daysUntilExpiration != null)
                  Text(
                    'Renews in $daysUntilExpiration days',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
          ],
        ),
        const Icon(Icons.chevron_right),
      ],
    );
  }
  
  Widget _buildFullView(
    BuildContext context, 
    ServiceLevel currentTier, 
    bool isActive,
    bool isExpiringSoon,
    int? daysUntilExpiration
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subscription Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Chip(
              label: Text(
                isActive ? 'ACTIVE' : 'INACTIVE',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              backgroundColor: isActive ? Colors.green : Theme.of(context).colorScheme.error,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              _getTierIcon(currentTier),
              size: 32,
              color: isActive 
                  ? (isExpiringSoon ? Colors.orange : Theme.of(context).colorScheme.primary)
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTier.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isExpiringSoon && daysUntilExpiration != null)
                  Text(
                    'Renews in $daysUntilExpiration days',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/subscription'),
                child: const Text('Manage'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/pricing'),
                child: const Text('Upgrade'),
              ),
            ),
          ],
        ),
      ],
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
