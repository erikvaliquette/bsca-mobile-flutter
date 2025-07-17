import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  
  // Store channels instead of subscriptions
  List<RealtimeChannel> _channels = [];
  
  // Badge counts
  int get messageCount => _notificationService.messageCount;
  int get contactRequestCount => _notificationService.contactRequestCount;
  int get organizationCount => _notificationService.organizationCount;
  int get totalCount => _notificationService.totalCount;
  
  // Initialize the notification provider
  Future<void> initialize() async {
    // Initialize the notification service
    await _notificationService.init();
    
    // Check if user has enabled push notifications
    await _checkNotificationPreferences();
    
    // Subscribe to Supabase realtime channels
    _subscribeToMessages();
    _subscribeToContactRequests();
    _subscribeToOrganizationUpdates();
    
    // Notify listeners to update UI
    notifyListeners();
  }
  
  // Check user notification preferences
  bool _pushNotificationsEnabled = true; // Default to true until we check
  
  Future<void> _checkNotificationPreferences() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        debugPrint('User not authenticated, using default notification preferences');
        return;
      }
      
      // Get user settings from the user_settings table
      final response = await _supabaseClient
          .from('user_settings')
          .select('push_notifications')
          .eq('id', user.id)
          .maybeSingle();
      
      if (response != null) {
        _pushNotificationsEnabled = response['push_notifications'] ?? true;
        debugPrint('User push notification preference: $_pushNotificationsEnabled');
      } else {
        debugPrint('No user settings found, using default notification preferences');
      }
    } catch (e) {
      debugPrint('Error fetching notification preferences: $e');
      // Default to true if there's an error
      _pushNotificationsEnabled = true;
    }
  }
  
  // Subscribe to messages table for real-time updates
  void _subscribeToMessages() {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) return;
    
    final channel = _supabaseClient
        .channel('messages_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            _handleNewMessage(payload.newRecord);
          },
        )
        .subscribe();
    
    _channels.add(channel);
  }
  
  // Subscribe to contact_requests table for real-time updates
  void _subscribeToContactRequests() {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) return;
    
    final channel = _supabaseClient
        .channel('contact_requests_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'contact_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId,
          ),
          callback: (payload) {
            _handleNewContactRequest(payload.newRecord);
          },
        )
        .subscribe();
    
    _channels.add(channel);
  }
  
  // Subscribe to organization_updates table for real-time updates
  void _subscribeToOrganizationUpdates() {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) return;
    
    // Get user's organization ID from profiles table
    _supabaseClient
        .from('profiles')
        .select('organization_id')
        .eq('id', userId)
        .single()
        .then((data) {
          final organizationId = data['organization_id'];
          if (organizationId != null) {
            final channel = _supabaseClient
                .channel('organization_updates_channel')
                .onPostgresChanges(
                  event: PostgresChangeEvent.insert,
                  schema: 'public',
                  table: 'organization_updates',
                  filter: PostgresChangeFilter(
                    type: PostgresChangeFilterType.eq,
                    column: 'organization_id',
                    value: organizationId,
                  ),
                  callback: (payload) {
                    _handleNewOrganizationUpdate(payload.newRecord);
                  },
                )
                .subscribe();
            
            _channels.add(channel);
          }
        });
  }
  
  // Handle new message
  void _handleNewMessage(Map<String, dynamic> message) {
    // If push notifications are disabled, just update the badge count without showing a notification
    if (!_pushNotificationsEnabled && message['sender_id'] != 'test-user-id') {
      _notificationService.incrementMessageCount();
      notifyListeners();
      return;
    }
    
    final senderId = message['sender_id'];
    final content = message['content'];
    
    // For testing purposes, if this is a test message, show it directly
    if (senderId == 'test-user-id') {
      _notificationService.showMessageNotification(
        title: 'New Message',
        body: content,
        payload: 'message:${message['id']}',
      );
      notifyListeners();
      return;
    }
    
    // Get sender name from Supabase
    _supabaseClient
        .from('user_settings')
        .select('first_name, last_name')
        .eq('id', senderId)
        .single()
        .then((data) {
          final senderName = '${data['first_name']} ${data['last_name']}';
          
          // Show notification
          _notificationService.showMessageNotification(
            title: 'New Message from $senderName',
            body: content,
            payload: 'message:${message['id']}',
          );
          
          // Notify listeners to update UI
          notifyListeners();
        });
  }
  
  // Handle new contact request
  void _handleNewContactRequest(Map<String, dynamic> contactRequest) {
    // If push notifications are disabled, just update the badge count without showing a notification
    if (!_pushNotificationsEnabled && contactRequest['sender_id'] != 'test-user-id') {
      _notificationService.incrementContactRequestCount();
      notifyListeners();
      return;
    }
    
    final senderId = contactRequest['sender_id'];
    
    // For testing purposes, if this is a test contact request, show it directly
    if (senderId == 'test-user-id') {
      _notificationService.showContactRequestNotification(
        title: 'New Contact Request',
        body: 'Someone wants to connect with you',
        payload: 'contact_request:${contactRequest['id']}',
      );
      notifyListeners();
      return;
    }
    
    // Get sender name from Supabase
    _supabaseClient
        .from('user_settings')
        .select('first_name, last_name')
        .eq('id', senderId)
        .single()
        .then((data) {
          final senderName = '${data['first_name']} ${data['last_name']}';
          
          // Show notification
          _notificationService.showContactRequestNotification(
            title: 'New Contact Request',
            body: '$senderName wants to connect with you',
            payload: 'contact_request:${contactRequest['id']}',
          );
          
          // Notify listeners to update UI
          notifyListeners();
        });
  }
  
  // Handle new organization update
  void _handleNewOrganizationUpdate(Map<String, dynamic> update) {
    // If push notifications are disabled, just update the badge count without showing a notification
    if (!_pushNotificationsEnabled && update['organization_id'] != 'test-org-id') {
      _notificationService.incrementOrganizationCount();
      notifyListeners();
      return;
    }
    
    final organizationId = update['organization_id'];
    final title = update['title'];
    final description = update['description'];
    
    // For testing purposes, if this is a test organization update, show it directly
    if (organizationId == 'test-org-id') {
      _notificationService.showOrganizationNotification(
        title: 'Organization Update',
        body: title ?? description ?? 'New organization update',
        payload: 'organization_update:${update['id']}',
      );
      notifyListeners();
      return;
    }
    
    // Get organization name from Supabase
    _supabaseClient
        .from('organizations')
        .select('name')
        .eq('id', organizationId)
        .single()
        .then((data) {
          final organizationName = data['name'];
          
          // Show notification
          _notificationService.showOrganizationNotification(
            title: 'Update from $organizationName',
            body: title,
            payload: 'organization_update:${update['id']}',
          );
          
          // Notify listeners to update UI
          notifyListeners();
        });
  }
  
  // Clear message notifications
  Future<void> clearMessageNotifications() async {
    await _notificationService.clearMessageNotifications();
    notifyListeners();
  }
  
  // Clear contact request notifications
  Future<void> clearContactRequestNotifications() async {
    await _notificationService.clearContactRequestNotifications();
    notifyListeners();
  }
  
  // Clear organization notifications
  Future<void> clearOrganizationNotifications() async {
    await _notificationService.clearOrganizationNotifications();
    notifyListeners();
  }
  
  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _notificationService.clearAllNotifications();
    notifyListeners();
  }
  
  // Public methods for testing notifications
  void testMessageNotification() {
    final mockMessage = {
      'id': '123',
      'sender_id': 'test-user-id',
      'content': 'You have received a new message from John Doe',
    };
    _handleNewMessage(mockMessage);
  }
  
  void testContactRequestNotification() {
    final mockContactRequest = {
      'id': '456',
      'sender_id': 'test-user-id',
    };
    _handleNewContactRequest(mockContactRequest);
  }
  
  void testOrganizationNotification() {
    final mockOrgUpdate = {
      'id': '789',
      'organization_id': 'test-org-id',
      'title': 'New Goal Achieved',
      'description': 'New sustainability goal achieved by your organization',
    };
    _handleNewOrganizationUpdate(mockOrgUpdate);
  }
  
  @override
  void dispose() {
    // Remove all channels
    for (var channel in _channels) {
      _supabaseClient.removeChannel(channel);
    }
    _channels.clear();
    super.dispose();
  }
}
