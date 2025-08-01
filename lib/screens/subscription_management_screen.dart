import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_model.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_prompt_widget.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  bool _restoreInProgress = false;

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final subscription = subscriptionProvider.subscription;
    final currentTier = subscriptionProvider.currentServiceLevel;
    final isActive = subscriptionProvider.hasActiveSubscription;
    final displayInfo = subscriptionProvider.displayInfo;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshSubscription(context),
            tooltip: 'Refresh subscription status',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCurrentSubscriptionCard(context, subscription, currentTier, isActive),
                const SizedBox(height: 24),
                _buildSubscriptionTiersSection(context, currentTier),
                const SizedBox(height: 24),
                _buildFeatureComparisonSection(context),
                const SizedBox(height: 24),
                _buildActionButtons(context),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildCurrentSubscriptionCard(
    BuildContext context, 
    SubscriptionModel? subscription, 
    ServiceLevel currentTier,
    bool isActive,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.error,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Subscription',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Chip(
                  label: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: isActive 
                    ? Colors.green 
                    : Theme.of(context).colorScheme.error,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currentTier.displayName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            if (subscription != null && subscription.currentPeriodEnd != null && currentTier != ServiceLevel.free)
              Text(
                'Expires: ${_formatDate(subscription.currentPeriodEnd!)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            if (subscription?.isExpiringSoon() == true)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Your subscription will expire soon!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTiersSection(BuildContext context, ServiceLevel currentTier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Subscription Tiers',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildTierCard(
          context, 
          ServiceLevel.free, 
          'Free', 
          'Basic features for individual users', 
          0.0,
          currentTier,
        ),
        _buildTierCard(
          context, 
          ServiceLevel.professional, 
          'Professional', 
          'For business professionals and consultants', 
          9.99,
          currentTier,
        ),
        _buildTierCard(
          context, 
          ServiceLevel.enterprise, 
          'Enterprise', 
          'For organizations and teams', 
          29.99,
          currentTier,
        ),
        _buildTierCard(
          context, 
          ServiceLevel.impactPartner, 
          'Impact Partner', 
          'Premium tier for sustainability leaders', 
          149.99,
          currentTier,
        ),
      ],
    );
  }

  Widget _buildTierCard(
    BuildContext context, 
    ServiceLevel tier, 
    String name, 
    String description, 
    double price,
    ServiceLevel currentTier,
  ) {
    final isCurrentTier = tier == currentTier;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isCurrentTier ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              price == 0 ? 'FREE' : '\$${price.toStringAsFixed(2)}/mo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 16),
            if (!isCurrentTier && tier != ServiceLevel.free)
              ElevatedButton(
                onPressed: () => _upgradeTier(context, tier),
                child: Text('Upgrade to ${name}'),
              )
            else if (isCurrentTier)
              OutlinedButton(
                onPressed: null,
                child: Text('Current Plan'),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildFeatureComparisonSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Comparison',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            horizontalMargin: 12,
            columns: const [
              DataColumn(label: Text('Feature')),
              DataColumn(label: Text('Free')),
              DataColumn(label: Text('Professional')),
              DataColumn(label: Text('Enterprise')),
              DataColumn(label: Text('Impact Partner')),
            ],
            rows: [
              _buildFeatureRow('Connections', '100', 'Unlimited', 'Unlimited', 'Unlimited'),
              _buildFeatureRow('Business Trip Attribution', '❌', '✅', '✅', '✅'),
              _buildFeatureRow('Advanced Analytics', '❌', '❌', '✅', '✅'),
              _buildFeatureRow('Team Management', '❌', '❌', '✅', '✅'),
              _buildFeatureRow('Organization Admin', '❌', '❌', '❌', '✅'),
              _buildFeatureRow('Custom Branding', '❌', '❌', '❌', '✅'),
              _buildFeatureRow('API Access', '❌', '❌', '❌', '✅'),
              _buildFeatureRow('Priority Support', '❌', '❌', '✅', '✅'),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _buildFeatureRow(String feature, String free, String professional, String enterprise, String impactPartner) {
    return DataRow(
      cells: [
        DataCell(Text(feature, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(free)),
        DataCell(Text(professional)),
        DataCell(Text(enterprise)),
        DataCell(Text(impactPartner)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          icon: _restoreInProgress 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.restore),
          label: Text(_restoreInProgress ? 'Restoring...' : 'Restore Purchases'),
          onPressed: _restoreInProgress ? null : () => _restorePurchases(context),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => _showTermsAndConditions(context),
          child: const Text('Terms & Conditions'),
        ),
        TextButton(
          onPressed: () => _showPrivacyPolicy(context),
          child: const Text('Privacy Policy'),
        ),
      ],
    );
  }

  Future<void> _refreshSubscription(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      await provider.refreshSubscription();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to refresh subscription: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _upgradeTier(BuildContext context, ServiceLevel tier) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      final success = await provider.purchaseSubscription(tier);
      
      if (!success && mounted) {
        setState(() {
          _errorMessage = 'Failed to initiate purchase';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error during purchase: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restorePurchases(BuildContext context) async {
    setState(() {
      _restoreInProgress = true;
      _errorMessage = null;
    });

    try {
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      final success = await provider.restorePurchases();
      
      if (!success && mounted) {
        setState(() {
          _errorMessage = 'Failed to restore purchases';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error restoring purchases: $e';
      });
    } finally {
      setState(() {
        _restoreInProgress = false;
      });
    }
  }

  void _showTermsAndConditions(BuildContext context) {
    // Navigate to terms and conditions page or show dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'By subscribing to BSCA services, you agree to our terms and conditions...\n\n'
            'Subscriptions will automatically renew unless canceled at least 24 hours before the end of the current period. '
            'You can cancel anytime through your App Store or Google Play account settings.\n\n'
            'For more information, please visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    // Navigate to privacy policy page or show dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'BSCA is committed to protecting your privacy...\n\n'
            'We collect and process subscription information to provide you with access to features '
            'appropriate for your subscription level. Payment information is processed securely by Apple or Google '
            'and is not stored on our servers.\n\n'
            'For more information, please visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
