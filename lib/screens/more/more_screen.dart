import 'package:flutter/material.dart';
import 'package:bsca_mobile_flutter/screens/profile/profile_screen.dart';
import 'package:bsca_mobile_flutter/screens/organization/organization_screen.dart';
import 'package:bsca_mobile_flutter/screens/carbon_calculator/carbon_calculator_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        onTap: () => _navigateToScreen(context, 'Actions'),
      ),
      MoreMenuItem(
        title: 'Organization',
        icon: Icons.business,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrganizationScreen()),
        ),
      ),
      MoreMenuItem(
        title: 'SDG Marketplace',
        icon: Icons.shopping_cart,
        onTap: () => _navigateToScreen(context, 'SDG Marketplace'),
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
        onTap: () => _navigateToScreen(context, 'Solutions'),
      ),
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
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 2.0,
            child: ListTile(
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
            ),
          );
        },
      ),
    );
  }

  void _navigateToScreen(BuildContext context, String screenName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceholderDetailScreen(title: screenName),
      ),
    );
  }
}

class MoreMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  MoreMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class PlaceholderDetailScreen extends StatelessWidget {
  final String title;

  const PlaceholderDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForTitle(title),
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '$title Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'This feature is currently being developed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Actions':
        return Icons.play_arrow;
      case 'Organization':
        return Icons.business;
      case 'SDG Marketplace':
        return Icons.shopping_cart;
      case 'Carbon Calculator':
        return Icons.calculate;
      case 'Solutions':
        return Icons.lightbulb;
      default:
        return Icons.info;
    }
  }
}
