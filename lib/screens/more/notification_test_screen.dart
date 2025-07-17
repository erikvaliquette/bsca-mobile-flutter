import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notifications/notification_provider.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  BuildContext? _context;

  @override
  Widget build(BuildContext context) {
    _context = context;
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Notifications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Message notification test
            ElevatedButton(
              onPressed: () {
                _showMessageNotification(notificationProvider);
              },
              child: const Text('Test Message Notification'),
            ),
            const SizedBox(height: 16),
            
            // Contact request notification test
            ElevatedButton(
              onPressed: () {
                _showContactRequestNotification(notificationProvider);
              },
              child: const Text('Test Contact Request Notification'),
            ),
            const SizedBox(height: 16),
            
            // Organization notification test
            ElevatedButton(
              onPressed: () {
                _showOrganizationNotification(notificationProvider);
              },
              child: const Text('Test Organization Notification'),
            ),
            const SizedBox(height: 24),
            
            // Clear all notifications
            OutlinedButton(
              onPressed: () {
                notificationProvider.clearAllNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications cleared'),
                  ),
                );
              },
              child: const Text('Clear All Notifications'),
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            
            // Current notification counts
            const Text(
              'Current Notification Counts:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildNotificationCountRow(
              'Messages',
              notificationProvider.messageCount,
              Icons.message,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            
            _buildNotificationCountRow(
              'Contact Requests',
              notificationProvider.contactRequestCount,
              Icons.people,
              Colors.green,
            ),
            const SizedBox(height: 8),
            
            _buildNotificationCountRow(
              'Organization Updates',
              notificationProvider.organizationCount,
              Icons.business,
              Colors.orange,
            ),
            const SizedBox(height: 8),
            
            _buildNotificationCountRow(
              'Total',
              notificationProvider.totalCount,
              Icons.notifications,
              Colors.red,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showMessageNotification(NotificationProvider provider) {
    provider.testMessageNotification();
    ScaffoldMessenger.of(_context!).showSnackBar(
      const SnackBar(
        content: Text('Message notification sent'),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  void _showContactRequestNotification(NotificationProvider provider) {
    provider.testContactRequestNotification();
    ScaffoldMessenger.of(_context!).showSnackBar(
      const SnackBar(
        content: Text('Contact request notification sent'),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  void _showOrganizationNotification(NotificationProvider provider) {
    provider.testOrganizationNotification();
    ScaffoldMessenger.of(_context!).showSnackBar(
      const SnackBar(
        content: Text('Organization notification sent'),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  Widget _buildNotificationCountRow(
    String title,
    int count,
    IconData icon,
    Color color, {
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
