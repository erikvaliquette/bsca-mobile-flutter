import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_model.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_service.dart';
import 'subscription_management_screen.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({Key? key}) : super(key: key);

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final currentTier = subscriptionProvider.currentServiceLevel;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionManagementScreen(),
                ),
              );
            },
            child: const Text('Manage'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
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
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildPricingCards(context, currentTier),
                  const SizedBox(height: 32),
                  _buildFeatureComparison(context),
                  const SizedBox(height: 24),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildFooter(context),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Unlock the Full Potential',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the plan that best fits your sustainability journey',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPricingCards(BuildContext context, ServiceLevel currentTier) {
    return Column(
      children: [
        _buildPricingCard(
          context,
          ServiceLevel.free,
          'Free',
          0.0,
          'FREE',
          'Basic features for individual users',
          [
            '10 network connections',
            'Personal carbon tracking',
            'Basic profile',
            'Community access',
          ],
          currentTier,
        ),
        const SizedBox(height: 16),
        _buildPricingCard(
          context,
          ServiceLevel.professional,
          'Professional',
          9.99,
          'CAD\$ 9.99/month',
          'For business professionals and consultants',
          [
            'Unlimited connections',
            'Business trip attribution',
            'Organization membership',
            'Enhanced reporting',
          ],
          currentTier,
        ),
        const SizedBox(height: 16),
        _buildPricingCard(
          context,
          ServiceLevel.enterprise,
          'Enterprise',
          29.99,
          'CAD\$ 29.99/month',
          'For organizations and teams',
          [
            'Everything in Professional',
            'Advanced analytics',
            'Team management',
            'Priority support',
          ],
          currentTier,
        ),
        const SizedBox(height: 16),
        _buildPricingCard(
          context,
          ServiceLevel.impactPartner,
          'Impact Partner',
          149.99,
          'CAD\$ 149.99/month',
          'Premium tier for sustainability leaders',
          [
            'Everything in Enterprise',
            'Admin features',
            'Custom branding',
            'API access',
          ],
          currentTier,
        ),
      ],
    );
  }

  Widget _buildPricingCard(
    BuildContext context,
    ServiceLevel tier,
    String name,
    double price,
    String priceDisplay,
    String description,
    List<String> features,
    ServiceLevel currentTier,
  ) {
    final isCurrentTier = tier == currentTier;
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCurrentTier ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (isCurrentTier)
                  Chip(
                    label: const Text(
                      'CURRENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price == 0 ? 'FREE' : priceDisplay,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(feature),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isCurrentTier
                  ? null
                  : () => _handleSubscriptionAction(context, tier),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isCurrentTier ? 'Current Plan' : (tier == ServiceLevel.free ? 'Downgrade' : 'Subscribe'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureComparison(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compare Features',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
              _buildFeatureRow('Connections', '10', 'Unlimited', 'Unlimited', 'Unlimited'),
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

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Subscriptions will automatically renew unless canceled at least 24 hours before the end of the current period. You can cancel anytime through your App Store or Google Play account settings.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _showTermsAndConditions(context),
              child: const Text('Terms & Conditions'),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => _showPrivacyPolicy(context),
              child: const Text('Privacy Policy'),
            ),
          ],
        ),
        TextButton(
          onPressed: () => _restorePurchases(context),
          child: const Text('Restore Purchases'),
        ),
      ],
    );
  }

  Future<void> _handleSubscriptionAction(BuildContext context, ServiceLevel tier) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      
      if (tier == ServiceLevel.free) {
        // Downgrade to free tier
        final success = await provider.cancelSubscription();
        if (!success && mounted) {
          setState(() {
            _errorMessage = 'Failed to downgrade subscription';
          });
        }
      } else {
        // Upgrade to paid tier
        final success = await provider.purchaseSubscription(tier);
        if (!success && mounted) {
          setState(() {
            _errorMessage = 'Failed to initiate purchase';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing subscription: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restorePurchases(BuildContext context) async {
    setState(() {
      _isLoading = true;
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
        _isLoading = false;
      });
    }
  }

  void _showTermsAndConditions(BuildContext context) {
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
}
