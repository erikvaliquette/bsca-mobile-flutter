import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../providers/business_connection_provider.dart';
import '../providers/organization_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/notifications/notification_provider.dart';
import '../widgets/notification_badge.dart';
import '../widgets/subscription_status_widget.dart';
import 'profile/profile_screen.dart';
import 'messaging/chat_list_screen.dart';
import 'more/more_screen.dart';
import 'network/network_screen.dart';
import 'travel_emissions/travel_emissions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const NetworkScreen(),
    const TravelEmissionsScreen(),
    const ChatListScreen(),
    const MoreScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    // Refresh notifications when home screen loads
    Future.microtask(() => _refreshNotifications());
  }
  
  // Refresh all notification badges
  Future<void> _refreshNotifications() async {
    try {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      final businessConnectionProvider = Provider.of<BusinessConnectionProvider>(context, listen: false);
      final organizationProvider = Provider.of<OrganizationProvider>(context, listen: false);
      
      // Re-initialize notification provider
      await notificationProvider.initialize();
      
      // Fetch unread messages
      await messageProvider.fetchUnreadMessages();
      
      // Fetch pending contact requests
      await businessConnectionProvider.fetchPendingRequests();
      
      // Fetch pending validation requests
      await organizationProvider.fetchPendingValidationRequests();
      
      debugPrint('📱 Refreshed all notifications on home screen load');
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, _) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              
              // Clear notifications when navigating to the respective tab
              if (index == 1 && notificationProvider.contactRequestCount > 0) {
                notificationProvider.clearContactRequestNotifications();
              } else if (index == 3 && notificationProvider.messageCount > 0) {
                notificationProvider.clearMessageNotifications();
              } else if (index == 4 && notificationProvider.organizationCount > 0) {
                notificationProvider.clearOrganizationNotifications();
              }
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: NotificationBadge(
                  type: NotificationType.contactRequest,
                  child: const Icon(Icons.people),
                ),
                label: 'Network',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.flight),
                label: 'Travel',
              ),
              BottomNavigationBarItem(
                icon: NotificationBadge(
                  type: NotificationType.message,
                  child: const Icon(Icons.message),
                ),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: NotificationBadge(
                  type: NotificationType.organization,
                  child: const Icon(Icons.more_horiz),
                ),
                label: 'More',
              ),
            ],
          );
        },
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          // Added top padding to avoid dynamic island on iPhone
          padding: const EdgeInsets.fromLTRB(16.0, 60.0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${authProvider.user?.email?.split('@').first ?? 'User'}!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Track your sustainability journey and impact on the environment.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24.0),
              
              // Subscription Status
              const SubscriptionStatusWidget(),
              
              const SizedBox(height: 24.0),
              
              // Your Impact Section
              Card(
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Impact',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      _buildImpactMetrics(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24.0),
              
              // Recent Activity Section
              Card(
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      _buildRecentActivity(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildImpactMetrics() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Carbon Reduction',
                '12.5 tons',
                Icons.eco,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _buildMetricCard(
                'Actions Completed',
                '24',
                Icons.check_circle,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Ongoing Initiatives',
                '3',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _buildMetricCard(
                'Impact Score',
                '78/100',
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8.0),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentActivity() {
    final activities = [
      {
        'title': 'Completed Travel Log',
        'description': 'Added a new sustainable travel entry',
        'time': '2 hours ago',
        'icon': Icons.flight,
        'color': Colors.blue,
      },
      {
        'title': 'SDG Progress Update',
        'description': 'Made progress on SDG 13: Climate Action',
        'time': '1 day ago',
        'icon': Icons.trending_up,
        'color': Colors.green,
      },
      {
        'title': 'New Team Member',
        'description': 'Sarah joined your organization',
        'time': '2 days ago',
        'icon': Icons.person_add,
        'color': Colors.purple,
      },
    ];
    
    return Column(
      children: activities.map((activity) => _buildActivityItem(activity)).toList(),
    );
  }
  
  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  activity['description'] as String,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  activity['time'] as String,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({super.key, required this.title});

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Network':
        return Icons.people;
      case 'Travel':
        return Icons.flight;
      case 'Messages':
        return Icons.message;
      case 'More':
        return Icons.more_horiz;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
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
            Text(
              'This feature is currently being migrated from React Native.',
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
}
