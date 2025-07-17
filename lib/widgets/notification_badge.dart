import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';
import '../services/notifications/notification_provider.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final NotificationType type;
  
  const NotificationBadge({
    Key? key,
    required this.child,
    required this.type,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final count = _getCount(notificationProvider);
        
        if (count <= 0) {
          return child;
        }
        
        return badges.Badge(
          position: badges.BadgePosition.topEnd(top: -5, end: -5),
          badgeAnimation: const badges.BadgeAnimation.scale(
            animationDuration: Duration(milliseconds: 300),
          ),
          badgeStyle: const badges.BadgeStyle(
            badgeColor: Colors.red,
          ),
          badgeContent: Text(
            count > 99 ? '99+' : count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: child,
        );
      },
    );
  }
  
  int _getCount(NotificationProvider provider) {
    switch (type) {
      case NotificationType.message:
        return provider.messageCount;
      case NotificationType.contactRequest:
        return provider.contactRequestCount;
      case NotificationType.organization:
        return provider.organizationCount;
      case NotificationType.all:
        return provider.totalCount;
    }
  }
}

enum NotificationType {
  message,
  contactRequest,
  organization,
  all,
}
