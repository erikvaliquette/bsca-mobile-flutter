import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_service.dart';
import 'subscription_upgrade_prompt.dart';

class LimitedListWidget<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final String featureDescription;
  final Map<ServiceLevel, int> tierLimits;
  final bool showUpgradePrompt;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Widget? separator;
  final Widget? emptyWidget;
  
  const LimitedListWidget({
    Key? key,
    required this.items,
    required this.itemBuilder,
    required this.featureDescription,
    required this.tierLimits,
    this.showUpgradePrompt = true,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.separator,
    this.emptyWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, _) {
        final currentTier = subscriptionProvider.currentServiceLevel;
        final limit = _getLimitForTier(currentTier);
        final limitedItems = items.take(limit).toList();
        final hasMoreItems = items.length > limit;
        
        if (items.isEmpty && emptyWidget != null) {
          return emptyWidget!;
        }
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (separator == null)
              ListView.builder(
                padding: padding,
                physics: physics,
                shrinkWrap: shrinkWrap,
                itemCount: limitedItems.length,
                itemBuilder: (context, index) => itemBuilder(context, limitedItems[index]),
              )
            else
              ListView.separated(
                padding: padding,
                physics: physics,
                shrinkWrap: shrinkWrap,
                itemCount: limitedItems.length,
                separatorBuilder: (context, index) => separator!,
                itemBuilder: (context, index) => itemBuilder(context, limitedItems[index]),
              ),
              
            if (hasMoreItems && showUpgradePrompt)
              _buildUpgradePrompt(context, currentTier, items.length - limit),
          ],
        );
      },
    );
  }
  
  int _getLimitForTier(ServiceLevel tier) {
    // Return the limit for the current tier, or the highest available limit if the tier is not in the map
    return tierLimits[tier] ?? tierLimits.values.reduce((max, value) => max > value ? max : value);
  }
  
  Widget _buildUpgradePrompt(BuildContext context, ServiceLevel currentTier, int hiddenItemCount) {
    // Find the next tier that would show more items
    ServiceLevel? nextTier;
    int? nextLimit;
    
    for (final entry in tierLimits.entries) {
      if (entry.key.index > currentTier.index && (nextLimit == null || entry.value > nextLimit)) {
        nextTier = entry.key;
        nextLimit = entry.value;
      }
    }
    
    if (nextTier == null) {
      return const SizedBox.shrink(); // No higher tier available
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$hiddenItemCount more ${hiddenItemCount == 1 ? 'item' : 'items'} available with ${nextTier.displayName}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  SubscriptionUpgradeDialog.show(
                    context: context,
                    featureDescription: 'Access to all $featureDescription',
                    requiredTier: nextTier,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                child: const Text('Upgrade'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Example usage:
// LimitedListWidget<Connection>(
//   items: connections,
//   featureDescription: 'network connections',
//   tierLimits: {
//     ServiceLevel.free: 10,
//     ServiceLevel.professional: 50,
//     ServiceLevel.enterprise: 100,
//     ServiceLevel.impactPartner: 500,
//   },
//   itemBuilder: (context, connection) => ConnectionListItem(connection: connection),
//   shrinkWrap: true,
//   physics: NeverScrollableScrollPhysics(),
// )
