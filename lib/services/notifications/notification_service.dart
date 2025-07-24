import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Notification channels
  static const String _messageChannelId = 'messages';
  static const String _messageChannelName = 'Messages';
  static const String _messageChannelDescription = 'Notifications for new messages';
  
  static const String _contactRequestChannelId = 'contact_requests';
  static const String _contactRequestChannelName = 'Contact Requests';
  static const String _contactRequestChannelDescription = 'Notifications for new contact requests';
  
  static const String _organizationChannelId = 'organization';
  static const String _organizationChannelName = 'Organization Updates';
  static const String _organizationChannelDescription = 'Notifications for organization updates';

  // Notification IDs
  static const int messageNotificationId = 1;
  static const int contactRequestNotificationId = 2;
  static const int organizationNotificationId = 3;

  // Badge counts
  int _messageCount = 0;
  int _contactRequestCount = 0;
  int _organizationCount = 0;

  // Getters for badge counts
  int get messageCount => _messageCount;
  int get contactRequestCount => _contactRequestCount;
  int get organizationCount => _organizationCount;
  int get totalCount => _messageCount + _contactRequestCount + _organizationCount;
  
  // Badge count increment methods
  void incrementMessageCount() {
    _messageCount++;
  }
  
  void incrementContactRequestCount() {
    _contactRequestCount++;
  }
  
  void incrementOrganizationCount() {
    _organizationCount++;
  }
  
  // Badge count decrement methods
  void decrementMessageCount() {
    if (_messageCount > 0) {
      _messageCount--;
    }
  }
  
  void decrementContactRequestCount() {
    if (_contactRequestCount > 0) {
      _contactRequestCount--;
    }
  }
  
  void decrementOrganizationCount() {
    if (_organizationCount > 0) {
      _organizationCount--;
    }
  }
  
  // Badge count reset methods
  void resetMessageCount() {
    _messageCount = 0;
  }
  
  void resetContactRequestCount() {
    _contactRequestCount = 0;
  }
  
  void resetOrganizationCount() {
    _organizationCount = 0;
  }
  
  // Clear all badge counts
  void clearAllBadges() {
    _messageCount = 0;
    _contactRequestCount = 0;
    _organizationCount = 0;
  }

  // Initialize notifications
  Future<void> init() async {
    tz_init.initializeTimeZones();
    
    // Initialize for Android
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Initialize for iOS
    final DarwinInitializationSettings iOSInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );
    
    // Initialize settings
    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iOSInitializationSettings,
    );
    
    // Initialize plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
    
    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
    
    // Request permissions for iOS
    if (Platform.isIOS) {
      await _requestIOSPermissions();
    }
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    // Messages channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _messageChannelId,
            _messageChannelName,
            description: _messageChannelDescription,
            importance: Importance.high,
          ),
        );
    
    // Contact requests channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _contactRequestChannelId,
            _contactRequestChannelName,
            description: _contactRequestChannelDescription,
            importance: Importance.high,
          ),
        );
    
    // Organization updates channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _organizationChannelId,
            _organizationChannelName,
            description: _organizationChannelDescription,
            importance: Importance.high,
          ),
        );
  }

  // Request permissions for iOS
  Future<void> _requestIOSPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Handle iOS notification when app is in foreground
  void _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    // Handle iOS foreground notification
    debugPrint('Received iOS notification: $title');
  }

  // Handle notification tap
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    // Handle notification tap
    final String? payload = response.payload;
    if (payload != null) {
      debugPrint('Notification payload: $payload');
      // Navigate to appropriate screen based on payload
    }
  }

  // Show a message notification
  Future<void> showMessageNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    _messageCount++;
    
    await _flutterLocalNotificationsPlugin.show(
      messageNotificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _messageChannelId,
          _messageChannelName,
          channelDescription: _messageChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          number: _messageCount,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        ),
      ),
      payload: payload,
    );
    
    // Update iOS badge
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await _updateIOSBadge();
    }
  }

  // Show a contact request notification
  Future<void> showContactRequestNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    _contactRequestCount++;
    
    await _flutterLocalNotificationsPlugin.show(
      contactRequestNotificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _contactRequestChannelId,
          _contactRequestChannelName,
          channelDescription: _contactRequestChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          number: _contactRequestCount,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        ),
      ),
      payload: payload,
    );
    
    // Update iOS badge
    if (Platform.isIOS) {
      await _updateIOSBadge();
    }
  }

  // Show an organization notification
  Future<void> showOrganizationNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    _organizationCount++;
    
    await _flutterLocalNotificationsPlugin.show(
      organizationNotificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _organizationChannelId,
          _organizationChannelName,
          channelDescription: _organizationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          number: _organizationCount,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        ),
      ),
      payload: payload,
    );
    
    // Update iOS badge
    if (Platform.isIOS) {
      await _updateIOSBadge();
    }
  }

  // Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String channelId = 'messages',
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == _messageChannelId
              ? _messageChannelName
              : channelId == _contactRequestChannelId
                  ? _contactRequestChannelName
                  : _organizationChannelName,
          channelDescription: channelId == _messageChannelId
              ? _messageChannelDescription
              : channelId == _contactRequestChannelId
                  ? _contactRequestChannelDescription
                  : _organizationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Clear message notifications
  Future<void> clearMessageNotifications() async {
    _messageCount = 0;
    await _flutterLocalNotificationsPlugin.cancel(messageNotificationId);
    
    // Update iOS badge
    if (Platform.isIOS) {
      await _updateIOSBadge();
    }
  }

  // Clear contact request notifications
  Future<void> clearContactRequestNotifications() async {
    _contactRequestCount = 0;
    await _flutterLocalNotificationsPlugin.cancel(contactRequestNotificationId);
    
    // Update iOS badge
    if (Platform.isIOS) {
      await _updateIOSBadge();
    }
  }

  // Clear organization notifications
  Future<void> clearOrganizationNotifications() async {
    _organizationCount = 0;
    await _flutterLocalNotificationsPlugin.cancel(organizationNotificationId);
    
    // Update iOS badge
    if (Platform.isIOS) {
      await _updateIOSBadge();
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    _messageCount = 0;
    _contactRequestCount = 0;
    _organizationCount = 0;
    await _flutterLocalNotificationsPlugin.cancelAll();
    
    // Update iOS badge
    if (Platform.isIOS) {
      await _updateIOSBadge();
    }
  }

  // Update iOS badge count
  Future<void> _updateIOSBadge() async {
    if (Platform.isIOS) {
      // Use iOS notification details with badge count
      final DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(badgeNumber: totalCount);
      
      // Create platform-specific notification details
      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(iOS: iOSPlatformChannelSpecifics);
      
      // Show a silent notification to update the badge
      if (totalCount > 0) {
        await _flutterLocalNotificationsPlugin.show(
          0, // Use a consistent ID for badge updates
          '', // Empty title for silent notification
          '', // Empty body for silent notification
          platformChannelSpecifics,
        );
      } else {
        // Clear all notifications when count is zero
        await _flutterLocalNotificationsPlugin.cancelAll();
      }
    }
  }
}
