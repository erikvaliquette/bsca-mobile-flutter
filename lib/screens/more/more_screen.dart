import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bsca_mobile_flutter/screens/profile/profile_screen.dart';
import 'package:bsca_mobile_flutter/screens/organization/organization_screen.dart';
import 'package:bsca_mobile_flutter/screens/carbon_calculator/carbon_calculator_screen.dart';
import 'package:bsca_mobile_flutter/screens/solutions/solutions_screen.dart';
import 'package:bsca_mobile_flutter/screens/sdg_marketplace/sdg_marketplace_screen.dart';
import 'package:bsca_mobile_flutter/screens/actions/actions_screen.dart';
import 'package:bsca_mobile_flutter/screens/travel_emissions/my_travel_emissions_screen.dart';

import 'package:bsca_mobile_flutter/screens/more/help_support_screen.dart';
import 'package:bsca_mobile_flutter/screens/more/about_screen.dart';
import 'package:bsca_mobile_flutter/services/notifications/notification_provider.dart';
import 'package:bsca_mobile_flutter/services/subscription_helper.dart';
import 'package:bsca_mobile_flutter/services/subscription_service.dart';
import 'package:bsca_mobile_flutter/widgets/notification_badge.dart';
import 'package:bsca_mobile_flutter/widgets/upgrade_prompt_widget.dart';
import 'package:bsca_mobile_flutter/providers/organization_provider.dart';

// Define the MoreMenuItem class outside of the widget classes
class MoreMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasNotificationBadge;
  final NotificationType? notificationType;

  MoreMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.hasNotificationBadge = false,
    this.notificationType,
  });
}

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();

}

class _MoreScreenState extends State<MoreScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch pending validation requests when screen loads
    Future.microtask(() {
      final organizationProvider = Provider.of<OrganizationProvider>(context, listen: false);
      organizationProvider.fetchPendingValidationRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServiceLevel>(
      future: SubscriptionHelper.getCurrentServiceLevel(),
      builder: (context, snapshot) {
        // Default to free tier if service level is not yet loaded
        final serviceLevel = snapshot.data ?? ServiceLevel.free;
        
        // List of menu items for the More tab
        final List<MoreMenuItem> menuItems = [
          MoreMenuItem(
            title: 'My Profile',
            icon: Icons.person,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
          MoreMenuItem(
            title: 'Actions',
            icon: Icons.play_arrow,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ActionsScreen()),
            ),
          ),
          MoreMenuItem(
            title: 'My Travel Emissions',
            icon: Icons.analytics,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyTravelEmissionsScreen()),
            ),
          ),
          
          // Only show Organization menu item for paid tiers
          if (serviceLevel != ServiceLevel.free)
            MoreMenuItem(
              title: 'Organization',
              icon: Icons.business,
              onTap: () {
                // Clear organization notifications when navigating to the Organization screen
                final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
                notificationProvider.clearOrganizationNotifications();
                
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrganizationScreen()),
                );
              },
              hasNotificationBadge: true,
              notificationType: NotificationType.organization,
            )
          else
            MoreMenuItem(
              title: 'Organization',
              icon: Icons.business,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => UpgradePromptWidget(
                    featureKey: SubscriptionHelper.FEATURE_ORGANIZATION_ACCESS,
                    customMessage: 'Organization access is available in Professional tier and above.',
                    isDialog: true,
                  ),
                );
              },
            ),
          
          MoreMenuItem(
            title: 'SDG Marketplace',
            icon: Icons.shopping_cart,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SDGMarketplaceScreen()),
            ),
          ),
          MoreMenuItem(
            title: 'Carbon Calculator',
            icon: Icons.calculate,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CarbonCalculatorScreen()),
            ),
          ),
          MoreMenuItem(
            title: 'Solutions',
            icon: Icons.lightbulb,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SolutionsScreen()),
            ),
          ),
          MoreMenuItem(
            title: 'Help & Support',
            icon: Icons.help_outline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
            ),
          ),
          MoreMenuItem(
            title: 'About',
            icon: Icons.info_outline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            ),
          ),
          // Notification Test button removed as notifications are now working properly
        ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          Widget listTile = ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            leading: Icon(
              item.icon,
              size: 28.0,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: item.onTap,
          );
          
          // Wrap with notification badge if needed
          if (item.hasNotificationBadge && item.notificationType != null) {
            // Apply the notification badge with the specified type
            listTile = NotificationBadge(
              type: item.notificationType!,
              child: listTile,
            );
          }
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 2.0,
            child: listTile,
          );
        },
      ),
    );
  });
}
}
