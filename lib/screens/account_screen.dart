import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_service.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final user = authProvider.user;
    final currentTier = subscriptionProvider.currentServiceLevel;
    final isActive = subscriptionProvider.hasActiveSubscription;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(context, user?.email ?? 'No email'),
            const SizedBox(height: 24),
            _buildSubscriptionSection(context, currentTier, isActive, subscriptionProvider),
            const SizedBox(height: 24),
            _buildAccountActions(context, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, String email) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    email.isNotEmpty ? email[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Profile'),
                        onPressed: () {
                          // Navigate to profile edit screen
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection(
    BuildContext context,
    ServiceLevel currentTier,
    bool isActive,
    SubscriptionProvider subscriptionProvider,
  ) {
    final theme = Theme.of(context);
    final displayInfo = subscriptionProvider.displayInfo;
    final expirationDate = displayInfo['expirationDate'];
    final daysUntilExpiration = displayInfo['daysUntilExpiration'];
    final isExpiringSoon = subscriptionProvider.isSubscriptionExpiringSoon;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? theme.colorScheme.primary : theme.colorScheme.error,
          width: 1,
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
                  'Subscription',
                  style: theme.textTheme.titleLarge?.copyWith(
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
                  backgroundColor: isActive ? Colors.green : theme.colorScheme.error,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTier.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (currentTier != ServiceLevel.free && expirationDate != null)
                        Text(
                          'Expires: ${_formatDate(expirationDate)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      if (isExpiringSoon)
                        Text(
                          'Expiring soon! Renews in $daysUntilExpiration days',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/subscription');
                    },
                    child: const Text('Manage'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/pricing');
                    },
                    child: const Text('Upgrade'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context, AuthProvider authProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              context,
              'Notification Preferences',
              Icons.notifications_outlined,
              () {
                // Navigate to notification settings
              },
            ),
            const Divider(),
            _buildSettingItem(
              context,
              'Privacy Settings',
              Icons.privacy_tip_outlined,
              () {
                // Navigate to privacy settings
              },
            ),
            const Divider(),
            _buildSettingItem(
              context,
              'Help & Support',
              Icons.help_outline,
              () {
                // Navigate to help & support
              },
            ),
            const Divider(),
            _buildSettingItem(
              context,
              'About BSCA',
              Icons.info_outline,
              () {
                // Navigate to about screen
              },
            ),
            const Divider(),
            _buildSettingItem(
              context,
              'Log Out',
              Icons.logout,
              () async {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              },
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color ?? Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
