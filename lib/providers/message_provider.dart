import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/realtime_client.dart';
import '../models/message_model.dart';
import '../models/chat_room_model.dart';

class MessageProvider extends ChangeNotifier {
  final List<MessageModel> _messages = [];
  final List<ChatRoomModel> _chatRooms = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _typingChannel;
  final List<RealtimeChannel> _channels = []; // List to store additional realtime channels

  // Getters
  List<MessageModel> get messages => _messages;
  List<ChatRoomModel> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize the provider
  bool _isInitialized = false;
  
  /// Explicitly refresh the chat rooms list to get the latest messages
  Future<void> refreshChatRooms() async {
    try {
      debugPrint('Refreshing chat rooms and direct messages');
      await _fetchChatRooms();
      // Explicitly fetch direct messages to ensure we have the latest
      await _fetchDirectMessages();
      // Ensure realtime subscriptions are active
      refreshMessageSubscriptions();
      notifyListeners();
      debugPrint('Chat rooms refreshed successfully');
    } catch (e) {
      debugPrint('Error refreshing chat rooms: $e');
    }
  }
  
  /// Test method to verify realtime subscriptions are active
  Future<void> testRealtimeSubscriptions() async {
    debugPrint('Testing realtime subscriptions...');
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('Cannot test subscriptions: User is null');
      return;
    }
    
    debugPrint('Current user ID: ${user.id}');
    debugPrint('Messages channel status: ${_messagesChannel?.socket.isConnected}');
    debugPrint('Number of active channels: ${_channels.length}');
    
    // Force a refresh of chat rooms
    await refreshChatRooms();
    
    // Check for recent messages that should have triggered realtime
    await testCheckRecentMessages();
    
    // Test sending a message to trigger realtime
    debugPrint('🔥 TEST: Sending test message to trigger realtime...');
    await testSendDirectMessage('2c911795-329a-4f5b-8799-e7d215f524d6', 'Test message from Flutter app at ${DateTime.now()}');
    
    // Wait a moment for the message to be processed
    await Future.delayed(Duration(seconds: 2));
    
    // Test manual query for inbound messages
    debugPrint('🔥 TEST: Manually querying for inbound messages from Apple Tester...');
    await testQueryInboundMessages();
    
    // Test creating an inbound message from Apple Tester to Erik
    await testCreateInboundMessage();
    
    // Test querying for specific inbound messages we know exist from web version
    await testQuerySpecificInboundMessages();
    
    debugPrint('Realtime subscription test completed');
  }
  
  /// Test method to create an INBOUND message (from Apple Tester to Erik)
  Future<void> testCreateInboundMessage() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('🔥 TEST INBOUND: Cannot create test message: User is null');
      return;
    }

    try {
      debugPrint('🔥 TEST INBOUND: Creating test message FROM Apple Tester TO Erik...');
      
      // Create a message FROM Apple Tester TO Erik (inbound for Erik)
      final response = await Supabase.instance.client
          .from('messages')
          .insert({
            'sender_id': '2c911795-329a-4f5b-8799-e7d215f524d6', // Apple Tester
            'recipient_id': user.id, // Erik (current user)
            'content': 'Test INBOUND message from Apple Tester to Erik at ${DateTime.now()}',
            'created_at': DateTime.now().toIso8601String(),
            'room_id': null, // Direct message
            'read': false,
          })
          .select();
      
      debugPrint('🔥 TEST INBOUND: Successfully created inbound message: $response');
      debugPrint('🔥 TEST INBOUND: This should trigger the realtime subscription!');
      
    } catch (e) {
      debugPrint('🔥 TEST INBOUND: Error creating inbound message: $e');
    }
  }
  
  /// Test method to query for specific inbound messages that should exist based on web version
  Future<void> testQuerySpecificInboundMessages() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('🔥 TEST SPECIFIC: Cannot query: User is null');
      return;
    }

    try {
      debugPrint('🔥 TEST SPECIFIC: Querying for messages containing "AT to EV" or "Apple tester to Erik"...');
      
      // Query for messages with content that matches what we see in web version
      final atToEvMessages = await Supabase.instance.client
          .from('messages')
          .select('id, sender_id, recipient_id, content, created_at, read')
          .or('content.ilike.%AT to EV%,content.ilike.%Apple tester to Erik%,content.ilike.%test from AT to EV%')
          .filter('room_id', 'is', null)
          .order('created_at', ascending: false);
      
      debugPrint('🔥 TEST SPECIFIC: Found ${atToEvMessages.length} messages with AT to EV content:');
      for (var message in atToEvMessages) {
        debugPrint('🔥 TEST SPECIFIC: - "${message['content']}" from ${message['sender_id']} to ${message['recipient_id']} at ${message['created_at']}');
        if (message['recipient_id'] == user.id) {
          debugPrint('🔥 TEST SPECIFIC:   ^^^ This is an INBOUND message to Erik!');
        } else {
          debugPrint('🔥 TEST SPECIFIC:   ^^^ This is an OUTBOUND message from Erik');
        }
      }
      
      // Also try a broader search for any messages from Apple Tester to Erik
      final broadSearch = await Supabase.instance.client
          .from('messages')
          .select('id, sender_id, recipient_id, content, created_at, read')
          .eq('sender_id', '2c911795-329a-4f5b-8799-e7d215f524d6') // Apple Tester
          .eq('recipient_id', user.id) // Erik
          .filter('room_id', 'is', null)
          .order('created_at', ascending: false);
      
      debugPrint('🔥 TEST SPECIFIC: Broad search found ${broadSearch.length} messages from Apple Tester to Erik:');
      for (var message in broadSearch) {
        debugPrint('🔥 TEST SPECIFIC: - "${message['content']}" at ${message['created_at']}');
      }
      
      // Check if the issue is with the main query in _fetchDirectMessages
      debugPrint('🔥 TEST SPECIFIC: Now testing the EXACT same query used in _fetchDirectMessages...');
      final mainQuery = await Supabase.instance.client
          .from('messages')
          .select('id, sender_id, recipient_id, content, created_at, updated_at, read, room_id, file_url, file_type, file_name, status, read_at')
          .or('sender_id.eq.${user.id},recipient_id.eq.${user.id}')
          .filter('room_id', 'is', null)
          .order('created_at', ascending: false);
      
      debugPrint('🔥 TEST SPECIFIC: Main query found ${mainQuery.length} total messages:');
      for (var message in mainQuery) {
        if (message['sender_id'] == '2c911795-329a-4f5b-8799-e7d215f524d6' || message['recipient_id'] == '2c911795-329a-4f5b-8799-e7d215f524d6') {
          debugPrint('🔥 TEST SPECIFIC: APPLE TESTER MESSAGE: "${message['content']}" from ${message['sender_id']} to ${message['recipient_id']}');
          if (message['recipient_id'] == user.id) {
            debugPrint('🔥 TEST SPECIFIC:   ^^^ This should be INBOUND to Erik but might not be showing in UI!');
          }
        }
      }
      
    } catch (e) {
      debugPrint('🔥 TEST SPECIFIC: Error querying specific messages: $e');
    }
  }
  
  /// Test method to send a direct message to verify realtime functionality
  Future<void> testSendDirectMessage(String recipientId, String content) async {
    debugPrint('🔥 TEST: Sending test direct message to $recipientId');
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('🔥 TEST: Cannot send message: User is null');
      return;
    }
    
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .insert({
            'sender_id': user.id,
            'recipient_id': recipientId,
            'content': content,
            'room_id': null, // Direct message
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      debugPrint('🔥 TEST: Message sent successfully: $response');
    } catch (e) {
      debugPrint('🔥 TEST: Error sending message: $e');
    }
  }
  
  /// Test method to check for recent messages that should have triggered realtime
  Future<void> testCheckRecentMessages() async {
    debugPrint('🔥 TEST: Checking for recent messages...');
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('🔥 TEST: Cannot check messages: User is null');
      return;
    }
    
    try {
      debugPrint('🔥 TEST: Querying for messages where recipient_id = ${user.id}');
      
      // Check for messages where current user is recipient (inbound)
      final inboundMessages = await Supabase.instance.client
          .from('messages')
          .select('id, sender_id, recipient_id, content, created_at, read')
          .eq('recipient_id', user.id)
          .filter('room_id', 'is', null)
          .order('created_at', ascending: false)
          .limit(5);
      
      debugPrint('🔥 TEST: Found ${inboundMessages.length} recent inbound messages:');
      for (var msg in inboundMessages) {
        debugPrint('🔥 TEST: - ${msg['content']} from ${msg['sender_id']} at ${msg['created_at']}');
      }
      
      // Also check ALL direct messages to see what's in the database
      final allDirectMessages = await Supabase.instance.client
          .from('messages')
          .select('id, sender_id, recipient_id, content, created_at, read')
          .filter('room_id', 'is', null)
          .order('created_at', ascending: false)
          .limit(10);
      
      debugPrint('🔥 TEST: Found ${allDirectMessages.length} total direct messages in database:');
      for (var msg in allDirectMessages) {
        debugPrint('🔥 TEST: - "${msg['content']}" from ${msg['sender_id']} to ${msg['recipient_id']} at ${msg['created_at']}');
        if (msg['recipient_id'] == user.id) {
          debugPrint('🔥 TEST:   ^^^ This should be an INBOUND message for current user!');
        }
        if (msg['sender_id'] == user.id) {
          debugPrint('🔥 TEST:   ^^^ This is an OUTBOUND message from current user');
        }
      }
      
      // Check for messages where current user is sender (outbound)
      final outboundMessages = await Supabase.instance.client
          .from('messages')
          .select('id, sender_id, recipient_id, content, created_at, read')
          .eq('sender_id', user.id)
          .filter('room_id', 'is', null)
          .order('created_at', ascending: false)
          .limit(5);
      
      debugPrint('🔥 TEST: Found ${outboundMessages.length} recent outbound messages:');
      for (var msg in outboundMessages) {
        debugPrint('🔥 TEST: - ${msg['content']} to ${msg['recipient_id']} at ${msg['created_at']}');
      }
      
    } catch (e) {
      debugPrint('🔥 TEST: Error checking messages: $e');
    }
  }
  
  /// Test method to manually query for inbound messages from Apple Tester
  Future<void> testQueryInboundMessages() async {
    debugPrint('🔥 TEST: Testing manual query for inbound messages...');
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('🔥 TEST: Cannot query: User is null');
      return;
    }
    
    try {
      // Query specifically for messages from Apple Tester to current user
      final appleToErikMessages = await Supabase.instance.client
          .from('messages')
          .select('id, sender_id, recipient_id, content, created_at, read')
          .eq('sender_id', '2c911795-329a-4f5b-8799-e7d215f524d6') // Apple Tester
          .eq('recipient_id', user.id) // Current user (Erik)
          .filter('room_id', 'is', null)
          .order('created_at', ascending: false);
      
      debugPrint('🔥 TEST: Found ${appleToErikMessages.length} messages from Apple Tester to Erik:');
      for (var msg in appleToErikMessages) {
        debugPrint('🔥 TEST: - "${msg['content']}" at ${msg['created_at']} (read: ${msg['read']})');
      }
      
      if (appleToErikMessages.isEmpty) {
        debugPrint('🔥 TEST: No inbound messages found - this explains why realtime isn\'t triggering!');
        
        // Let's check what messages DO exist in the database
        debugPrint('🔥 TEST: Checking what messages actually exist in the database...');
        
        // Check all messages involving Apple Tester
        final allAppleMessages = await Supabase.instance.client
            .from('messages')
            .select('id, sender_id, recipient_id, content, created_at, read')
            .or('sender_id.eq.2c911795-329a-4f5b-8799-e7d215f524d6,recipient_id.eq.2c911795-329a-4f5b-8799-e7d215f524d6')
            .filter('room_id', 'is', null)
            .order('created_at', ascending: false)
            .limit(10);
        
        debugPrint('🔥 TEST: Found ${allAppleMessages.length} messages involving Apple Tester:');
        for (var msg in allAppleMessages) {
          debugPrint('🔥 TEST: - "${msg['content']}" from ${msg['sender_id']} to ${msg['recipient_id']} at ${msg['created_at']}');
          if (msg['sender_id'] == '2c911795-329a-4f5b-8799-e7d215f524d6') {
            debugPrint('🔥 TEST:   ^^^ Apple Tester is SENDER');
          }
          if (msg['recipient_id'] == '2c911795-329a-4f5b-8799-e7d215f524d6') {
            debugPrint('🔥 TEST:   ^^^ Apple Tester is RECIPIENT');
          }
        }
        
        // Check if there are any messages where Erik is recipient (from anyone)
        final erikAsRecipient = await Supabase.instance.client
            .from('messages')
            .select('id, sender_id, recipient_id, content, created_at, read')
            .eq('recipient_id', user.id)
            .filter('room_id', 'is', null)
            .order('created_at', ascending: false)
            .limit(5);
        
        debugPrint('🔥 TEST: Found ${erikAsRecipient.length} messages where Erik is recipient:');
        for (var msg in erikAsRecipient) {
          debugPrint('🔥 TEST: - "${msg['content']}" from ${msg['sender_id']} at ${msg['created_at']}');
        }
        
        // Check authentication status
        debugPrint('🔥 TEST: Checking authentication status...');
        debugPrint('🔥 TEST: Current user ID: ${user.id}');
        debugPrint('🔥 TEST: Current user email: ${user.email}');
        debugPrint('🔥 TEST: User metadata: ${user.userMetadata}');
        
        // Check session info
        final session = Supabase.instance.client.auth.currentSession;
        debugPrint('🔥 TEST: Session exists: ${session != null}');
        if (session != null) {
          debugPrint('🔥 TEST: Access token exists: ${session.accessToken.isNotEmpty}');
          debugPrint('🔥 TEST: Token expires at: ${session.expiresAt}');
        }
        
        // Try to read ALL messages (ignoring RLS temporarily)
        debugPrint('🔥 TEST: Attempting to read ALL messages in the table...');
        try {
          final allMessages = await Supabase.instance.client
              .from('messages')
              .select('id, sender_id, recipient_id, content, created_at, room_id, read')
              .order('created_at', ascending: false)
              .limit(10);
          
          debugPrint('🔥 TEST: Successfully read ${allMessages.length} total messages from database:');
          for (var msg in allMessages) {
            debugPrint('🔥 TEST: - "${msg['content']}" from ${msg['sender_id']} to ${msg['recipient_id']} (room: ${msg['room_id']})');
          }
        } catch (e) {
          debugPrint('🔥 TEST: ERROR reading all messages: $e');
          debugPrint('🔥 TEST: The error suggests there might be invalid data in the database');
          
          // Try a simpler query to see if we can read anything at all
          debugPrint('🔥 TEST: Trying a simpler query without room_id...');
          try {
            final simpleMessages = await Supabase.instance.client
                .from('messages')
                .select('id, content, created_at')
                .limit(5);
            
            debugPrint('🔥 TEST: Simple query succeeded! Found ${simpleMessages.length} messages:');
            for (var msg in simpleMessages) {
              debugPrint('🔥 TEST: - "${msg['content']}" at ${msg['created_at']}');
            }
          } catch (e2) {
            debugPrint('🔥 TEST: Even simple query failed: $e2');
            debugPrint('🔥 TEST: This confirms RLS policies are blocking access!');
          }
        }
        
      } else {
        debugPrint('🔥 TEST: Inbound messages exist but realtime subscription is not triggering!');
      }
      
    } catch (e) {
      debugPrint('🔥 TEST: Error querying inbound messages: $e');
    }
  }
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _fetchChatRooms();
      await _fetchDirectMessages();
      _subscribeToMessages();
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing MessageProvider: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch chat rooms for the current user
  Future<void> _fetchChatRooms() async {
    _error = null;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _error = 'User not authenticated';
        return;
      }

      // First, get all unique room_ids from messages where the user is either sender or recipient
      final messagesResponse = await Supabase.instance.client
          .from('messages')
          .select('room_id')
          .or('sender_id.eq.${user.id},recipient_id.eq.${user.id}')
          .not('room_id', 'is', null)
          .order('created_at', ascending: false);
      
      // Extract unique room IDs
      final Set<String> uniqueRoomIds = {};
      for (var item in messagesResponse) {
        if (item['room_id'] != null) {
          uniqueRoomIds.add(item['room_id']);
        }
      }
      
      // If we have room IDs, fetch the chat rooms
      List<dynamic> data = [];
      if (uniqueRoomIds.isNotEmpty) {
        // Fetch chat rooms from Supabase
        // For multiple room IDs, we need to use multiple eq filters with or
        var query = Supabase.instance.client
            .from('chat_rooms')
            .select('*');
            
        // Add filters for each room ID with OR
        // Make sure each room ID is a valid UUID and properly quoted
        List<String> validRoomIds = [];
        for (var roomId in uniqueRoomIds) {
          // Basic UUID validation to avoid the 'private' error
          if (roomId.length == 36 && roomId.contains('-')) {
            validRoomIds.add(roomId);
          } else {
            debugPrint('Skipping invalid room_id: $roomId');
          }
        }
        
        if (validRoomIds.isNotEmpty) {
          String orCondition = validRoomIds.map((roomId) => "room_id.eq.$roomId").join(',');
          query = query.or(orCondition);
        }
        
        final response = await query.order('updated_at', ascending: false);
        data = response;
      }
      
      _chatRooms.clear();
      
      // Convert each room data to ChatRoomModel
      for (var roomData in data) {
        final room = ChatRoomModel.fromJson(roomData);
        _chatRooms.add(room);
        
        // Fetch last message for each room
        await _fetchLastMessage(room.roomId);
        
        // Fetch unread count for each room
        await _fetchUnreadCount(room.roomId);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching chat rooms: $_error');
    }
    // notifyListeners is called by the initialize method
  }

  // Fetch the last message for a chat room
  Future<void> _fetchLastMessage(String roomId) async {
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('*')
                    .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .limit(1)
          ;

      if (response.isNotEmpty) {
        final lastMessageData = response[0];
        final lastMessage = MessageModel.fromJson(lastMessageData);
        
        // Update the chat room with the last message info
        final index = _chatRooms.indexWhere((room) => room.roomId == roomId);
        if (index != -1) {
          final updatedRoom = ChatRoomModel(
            id: _chatRooms[index].id,
            roomId: _chatRooms[index].roomId,
            createdAt: _chatRooms[index].createdAt,
            updatedAt: _chatRooms[index].updatedAt,
            name: _chatRooms[index].name,
            lastMessage: lastMessage.content,
            lastMessageTime: lastMessage.createdAt,
            unreadCount: _chatRooms[index].unreadCount,
            participantIds: _chatRooms[index].participantIds,
            isStarred: _chatRooms[index].isStarred,
            avatarUrl: _chatRooms[index].avatarUrl,
          );
          _chatRooms[index] = updatedRoom;
        }
      }
    } catch (e) {
      debugPrint('Error fetching last message for room $roomId: $e');
    }
  }

  // Fetch unread message count for a chat room
  Future<void> _fetchUnreadCount(String roomId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final countResponse = await Supabase.instance.client
          .from('messages')
          .count()
                    .eq('room_id', roomId)
                    .eq('read', false)
          .neq('sender_id', user.id);

      // The count() method returns a CountResponse object with a count property
      int unreadCount = countResponse ?? 0;
      final index = _chatRooms.indexWhere((room) => room.roomId == roomId);
      if (index != -1) {
        final updatedRoom = ChatRoomModel(
          id: _chatRooms[index].id,
          roomId: _chatRooms[index].roomId,
          createdAt: _chatRooms[index].createdAt,
          updatedAt: _chatRooms[index].updatedAt,
          name: _chatRooms[index].name,
          lastMessage: _chatRooms[index].lastMessage,
          lastMessageTime: _chatRooms[index].lastMessageTime,
          unreadCount: unreadCount,
          participantIds: _chatRooms[index].participantIds,
          isStarred: _chatRooms[index].isStarred,
        );
        _chatRooms[index] = updatedRoom;
      }
    } catch (e) {
      debugPrint('Error fetching unread count for room $roomId: $e');
    }
  }

  // Fetch messages for a specific chat room or direct conversation
  Future<List<MessageModel>> fetchMessages(String roomId, {int limit = 20, int offset = 0}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _error = 'User not authenticated';
        return [];
      }

      List<dynamic> data;
      
      // Check if this is a virtual room ID for direct messages
      if (roomId.startsWith('dm_')) {
        // Extract user IDs from the virtual room ID
        final userIds = roomId.replaceFirst('dm_', '').split('_');
        
        if (userIds.length != 2) {
          _error = 'Invalid room ID format';
          return [];
        }
        
        // Get messages between these two users (where room_id is null)
        debugPrint('🔍 FETCH: Getting direct messages between users ${userIds[0]} and ${userIds[1]}');
        
        // Use the current user ID and partner ID directly to ensure we get all messages
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        String partnerId;
        
        // Determine which user ID is the partner (not the current user)
        if (userIds[0] == currentUserId) {
          partnerId = userIds[1];
        } else if (userIds[1] == currentUserId) {
          partnerId = userIds[0];
        } else {
          // If neither ID matches current user, use the original IDs
          partnerId = userIds[1];
        }
        
        debugPrint('🔍 FETCH: Current user: $currentUserId, Partner: $partnerId');
        
        // Query messages where current user is either sender or recipient AND partner is the other party
        // Use explicit partner ID for Apple Tester conversations to ensure we get all messages
        final bool isAppleTesterConversation = (partnerId == '2c911795-329a-4f5b-8799-e7d215f524d6');
        
        debugPrint('🔍 FETCH: Is Apple Tester conversation? $isAppleTesterConversation');
        
        // Special handling for Apple Tester conversations to ensure we get all messages
        final response = await Supabase.instance.client
            .from('messages')
            .select('*')
            .or(
              'and(sender_id.eq.$currentUserId,recipient_id.eq.$partnerId),' +
              'and(sender_id.eq.$partnerId,recipient_id.eq.$currentUserId)'
            )
            .filter('room_id', 'is', null)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
            
        debugPrint('🔍 FETCH: Found ${response.length} direct messages');
        for (var i = 0; i < response.length && i < 10; i++) {
          debugPrint('🔍 FETCH: Message $i: ${response[i]["content"]} - From: ${response[i]["sender_id"]} To: ${response[i]["recipient_id"]}');
        }
        
        // Double-check if we're missing any messages from Apple Tester
        if (isAppleTesterConversation && response.length < 10) {
          debugPrint('🔍 FETCH: Performing additional check for Apple Tester messages...');
          
          // Try a direct query for messages from Apple Tester to current user
          final additionalCheck = await Supabase.instance.client
              .from('messages')
              .select('*')
              .eq('sender_id', partnerId)
              .eq('recipient_id', currentUserId)
              .filter('room_id', 'is', null)
              .order('created_at', ascending: false);
              
          debugPrint('🔍 FETCH: Additional check found ${additionalCheck.length} messages');
          
          // Add any messages that weren't in the original response
          for (var newMsg in additionalCheck) {
            bool isDuplicate = false;
            for (var existingMsg in response) {
              if (existingMsg['id'] == newMsg['id']) {
                isDuplicate = true;
                break;
              }
            }
            
            if (!isDuplicate) {
              debugPrint('🔍 FETCH: Adding missing message: ${newMsg["content"]}');
              response.add(newMsg);
            }
          }
          
          // Re-sort messages by created_at in descending order
          response.sort((a, b) {
            final DateTime aTime = DateTime.parse(a['created_at']);
            final DateTime bTime = DateTime.parse(b['created_at']);
            return bTime.compareTo(aTime); // Descending order
          });
        }
            
        data = response;
      } else {
        // Regular room-based messages
        final response = await Supabase.instance.client
            .from('messages')
            .select('*')
            .eq('room_id', roomId)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
            
        data = response;
      }

      // Fetch user details for senders and recipients
      final Map<String, Map<String, dynamic>> userDetailsCache = {};
      
      // Convert the response to MessageModel objects
      final List<MessageModel> messages = [];
      
      // Process each message and fetch user details
      for (var item in data) {
        String senderName = 'Unknown User';
        String? senderAvatarUrl;
        
        // Fetch sender details if not in cache
        final senderId = item['sender_id'];
        if (senderId != null) {
          debugPrint('Fetching details for sender: $senderId');
          
          if (!userDetailsCache.containsKey(senderId)) {
            final senderDetails = await _fetchUserDetails(senderId);
            debugPrint('Fetched sender details: $senderDetails');
            if (senderDetails != null) {
              userDetailsCache[senderId] = senderDetails;
            }
          }
          
          // Use sender details from cache if available
          if (userDetailsCache.containsKey(senderId)) {
            final details = userDetailsCache[senderId]!;
            senderName = details['username'] ?? 'User $senderId';
            senderAvatarUrl = details['avatar_url'];
            debugPrint('Using sender name: $senderName, avatar: $senderAvatarUrl');
          }
        }
        
        // Create message model with user details
        final Map<String, dynamic> messageWithDetails = Map<String, dynamic>.from(item);
        messageWithDetails['sender_name'] = senderName;
        messageWithDetails['sender_avatar_url'] = senderAvatarUrl;
        
        debugPrint('Creating message with sender name: $senderName');
        messages.add(MessageModel.fromJson(messageWithDetails));
      }
      
      if (offset == 0) {
        _messages.clear();
        _messages.addAll(messages);
      } else {
        _messages.addAll(messages);
      }
      notifyListeners();
      return messages;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching messages: $_error');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a new message
  Future<MessageModel?> sendMessage({
    required String roomId,
    required String content,
    String? topic,
    Map<String, dynamic>? payload,
    String? fileUrl,
    String? fileType,
    String? fileName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _error = 'User not authenticated';
        return null;
      }

      final messageData = {
        'sender_id': user.id,
        'content': content,
        'read': false,
        'status': 'sent',
      };
      
      // Handle direct messages vs. room messages
      if (roomId.startsWith('dm_')) {
        // For direct messages, set room_id to null and extract recipient_id from the virtual room ID
        final userIds = roomId.replaceFirst('dm_', '').split('_');
        final recipientId = userIds[0] == user.id ? userIds[1] : userIds[0];
        messageData['recipient_id'] = recipientId;
        // room_id is intentionally left null for direct messages
      } else {
        // For room messages, include the room_id
        messageData['room_id'] = roomId;
      }

      if (payload != null) messageData['payload'] = payload;
      if (fileUrl != null) messageData['file_url'] = fileUrl;
      if (fileType != null) messageData['file_type'] = fileType;
      if (fileName != null) messageData['file_name'] = fileName;

      final response = await Supabase.instance.client
          .from('messages')
          .insert(messageData)
          .select();

      final newMessage = MessageModel.fromJson(response[0]);
      _messages.insert(0, newMessage);
      
      // Update the chat room's last message
      final index = _chatRooms.indexWhere((room) => room.roomId == roomId);
      if (index != -1) {
        final updatedRoom = ChatRoomModel(
          id: _chatRooms[index].id,
          roomId: _chatRooms[index].roomId,
          createdAt: _chatRooms[index].createdAt,
          updatedAt: DateTime.now(),
          name: _chatRooms[index].name,
          lastMessage: content,
          lastMessageTime: DateTime.now(),
          unreadCount: _chatRooms[index].unreadCount,
          participantIds: _chatRooms[index].participantIds,
          isStarred: _chatRooms[index].isStarred,
        );
        _chatRooms[index] = updatedRoom;
        
        // Move this chat room to the top of the list
        if (index > 0) {
          final room = _chatRooms.removeAt(index);
          _chatRooms.insert(0, room);
        }
      }
      
      notifyListeners();
      return newMessage;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending message: $_error');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String roomId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('messages')
          .update({
            'read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
                    .eq('room_id', roomId)
          .neq('sender_id', user.id)
                    .eq('read', false)
          ;

      // Update the unread count for this room to 0
      final index = _chatRooms.indexWhere((room) => room.roomId == roomId);
      if (index != -1) {
        final updatedRoom = ChatRoomModel(
          id: _chatRooms[index].id,
          roomId: _chatRooms[index].roomId,
          createdAt: _chatRooms[index].createdAt,
          updatedAt: _chatRooms[index].updatedAt,
          name: _chatRooms[index].name,
          lastMessage: _chatRooms[index].lastMessage,
          lastMessageTime: _chatRooms[index].lastMessageTime,
          unreadCount: 0,
          participantIds: _chatRooms[index].participantIds,
          isStarred: _chatRooms[index].isStarred,
          avatarUrl: _chatRooms[index].avatarUrl,
        );
        _chatRooms[index] = updatedRoom;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Subscribe to real-time message updates
  // Public method to refresh message subscriptions
  void refreshMessageSubscriptions() {
    _subscribeToMessages();
  }
  
  void _subscribeToMessages() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('Cannot subscribe to messages: User is null');
      return;
    }
    
    debugPrint('Setting up realtime subscriptions for user: ${user.id}');

    // Unsubscribe from any existing channels
    for (final channel in _channels) {
      debugPrint('Removing existing channel');
      Supabase.instance.client.removeChannel(channel);
    }
    _channels.clear();
    
    if (_messagesChannel != null) {
      debugPrint('Removing existing messages channel');
      Supabase.instance.client.removeChannel(_messagesChannel!);
    }

    // Subscribe to the messages table for real-time updates
    // We need to create separate subscriptions since OR filters aren't supported
    
    // Subscribe to direct messages where the user is the recipient (INBOUND)
    debugPrint('Setting up realtime subscription for user: ${user.id}');
    debugPrint('Creating separate channels for inbound and outbound messages');
    
    // INBOUND MESSAGES - where current user is recipient
    _messagesChannel = Supabase.instance.client
        .channel('inbound_messages_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: user.id,
          ),
          callback: (payload) async {
            debugPrint('🔥 REALTIME INBOUND: Received message as RECIPIENT: $payload');
            debugPrint('🔥 REALTIME INBOUND: New record: ${payload.newRecord}');
            try {
              await _handleNewMessage(payload.newRecord);
              await refreshChatRooms();
              debugPrint('🔥 REALTIME INBOUND: Successfully processed inbound message');
            } catch (e) {
              debugPrint('🔥 REALTIME INBOUND: Error handling inbound message: $e');
            }
          },
        )
        .subscribe((status, error) {
          if (error != null) {
            debugPrint('❌ INBOUND: Error subscribing: $error');
          } else {
            debugPrint('✅ INBOUND: Subscription status: $status');
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('🔥 REALTIME INBOUND: Successfully subscribed!');
              debugPrint('🔥 REALTIME INBOUND: Listening for recipient_id = ${user.id}');
            }
          }
        });
    
    // OUTBOUND MESSAGES - where current user is sender
    final outboundChannel = Supabase.instance.client
        .channel('outbound_messages_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sender_id',
            value: user.id,
          ),
          callback: (payload) async {
            debugPrint('🔥 REALTIME OUTBOUND: Received message as SENDER: $payload');
            debugPrint('🔥 REALTIME OUTBOUND: New record: ${payload.newRecord}');
            try {
              await _handleNewMessage(payload.newRecord);
              await refreshChatRooms();
              debugPrint('🔥 REALTIME OUTBOUND: Successfully processed outbound message');
            } catch (e) {
              debugPrint('🔥 REALTIME OUTBOUND: Error handling outbound message: $e');
            }
          },
        )
        .subscribe((status, error) {
          if (error != null) {
            debugPrint('❌ OUTBOUND: Error subscribing: $error');
          } else {
            debugPrint('✅ OUTBOUND: Subscription status: $status');
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('🔥 REALTIME OUTBOUND: Successfully subscribed!');
              debugPrint('🔥 REALTIME OUTBOUND: Listening for sender_id = ${user.id}');
            }
          }
        });
    
    // Store both channels for cleanup
    _channels.add(outboundChannel);
    
    // Store the direct messages channel for later cleanup
    _channels.add(_messagesChannel!);
    
    // 2. Subscribe to room messages for rooms the user is in
    // Only create this subscription if we have chat rooms
    if (_chatRooms.isNotEmpty) {
      // Since we can't use 'in_' filter, we'll create individual subscriptions for each room
      // This is not ideal but will work with the current SDK limitations
      for (final room in _chatRooms) {
        if (room.roomId == null) continue;
        
        final roomId = room.roomId!;
        final channelName = 'room_${roomId}_messages';
        
        debugPrint('Creating subscription for room: $roomId');
        
        // Create a subscription for this specific room
        final roomChannel = Supabase.instance.client
            .channel(channelName)
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'room_id',
                value: roomId,
              ),
              callback: (payload) async {
                debugPrint('New message in room $roomId: ${payload.newRecord}');
                try {
                  await _handleNewMessage(payload.newRecord);
                  // Force a refresh of chat rooms to ensure the UI updates
                  await refreshChatRooms();
                  debugPrint('Successfully processed room message');
                } catch (e) {
                  debugPrint('Error handling room message: $e');
                }
              },
            )
            .subscribe();
        
        // Store the channel for later cleanup
        _channels.add(roomChannel);
      }
    }
    
    debugPrint('Subscribed to messages for user ${user.id} and ${_chatRooms.length} rooms');
  }

  // Handle a new message received via real-time subscription
  // This method processes incoming messages from Supabase realtime API
  // Simple function to fetch user details from profiles table
  Future<Map<String, dynamic>> _fetchUserDetails(String userId) async {
    try {
      debugPrint('Fetching user details for $userId');
      
      // Try to fetch from profiles table with specific columns
      final response = await Supabase.instance.client
          .from('profiles')
          .select('first_name, last_name, avatar_url, email')
          .eq('id', userId)
          .maybeSingle();
      
      debugPrint('Profile response: $response');
      
      if (response != null) {
        // Construct name from first_name and last_name
        String firstName = response['first_name'] ?? '';
        String lastName = response['last_name'] ?? '';
        String displayName;
        
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          displayName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
        } else {
          // Fallback to email if name isn't available
          displayName = response['email'] ?? 'User $userId';
        }
        
        debugPrint('Constructed display name: $displayName');
        
        // Return with a clear display name
        return {
          'username': displayName.isNotEmpty ? displayName : 'User $userId',
          'avatar_url': response['avatar_url']
        };
      } else {
        debugPrint('No profile found for user $userId');
      }
    } catch (e) {
      debugPrint('Error fetching profile for $userId: $e');
    }
    
    // Return a placeholder if we couldn't get the profile
    debugPrint('Returning placeholder for user $userId');
    return {
      'username': 'User $userId', 
      'avatar_url': null
    };
  }

  // Fetch direct messages (private messages) for the current user
  Future<void> _fetchDirectMessages() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('Cannot fetch direct messages: User is null');
      return;
    }
    
    try {
      debugPrint('Fetching direct messages for user ${user.id}');
      
      // Fetch all direct messages where the current user is either sender or recipient
      final response = await Supabase.instance.client
          .from('messages')
          .select('id, sender_id, recipient_id, content, created_at, updated_at, read, room_id, file_url, file_type, file_name, status, read_at')
          .or('sender_id.eq.${user.id},recipient_id.eq.${user.id}')
          .filter('room_id', 'is', null)
          .order('created_at', ascending: false);
      
      debugPrint('Fetched ${response.length} direct messages');
      
      // Group messages by conversation partner using virtual room IDs
      final Map<String, List<dynamic>> conversationsByPartner = {};
      final Map<String, Map<String, dynamic>> userDetailsCache = {};
      
      // Process each message
      // Debug: Print all messages to help diagnose issues
      for (var i = 0; i < response.length && i < 5; i++) {
        debugPrint('Message $i: ${response[i]}');
      }
      
      for (var message in response) {
        // Verify message has required fields
        if (message['sender_id'] == null || message['recipient_id'] == null) {
          debugPrint('Skipping message with missing sender or recipient: ${message['id']}');
          continue;
        }
        
        // Determine the partner ID (the other user in the conversation)
        String partnerId;
        if (message['sender_id'] == user.id) {
          partnerId = message['recipient_id'];
          debugPrint('Message sent by current user to $partnerId');
        } else {
          partnerId = message['sender_id'];
          debugPrint('Message received from $partnerId to current user');
        }
        
        debugPrint('Processing message ID: ${message['id']} - Content: ${message['content']}');
        debugPrint('Message details - From: ${message['sender_id']}, To: ${message['recipient_id']}, Time: ${message['created_at']}');
        
        // Fetch user details if not already in cache
        if (!userDetailsCache.containsKey(partnerId)) {
          final userDetails = await _fetchUserDetails(partnerId);
          if (userDetails != null) {
            userDetailsCache[partnerId] = userDetails;
          }
        }
        
        // Create a virtual room ID for direct messages
        final List<String> userIds = [user.id, partnerId];
        userIds.sort(); // Sort to ensure consistent order regardless of sender/recipient
        final virtualRoomId = 'dm_${userIds.join('_')}';
        
        // Add message to the appropriate conversation group
        if (!conversationsByPartner.containsKey(virtualRoomId)) {
          conversationsByPartner[virtualRoomId] = [];
        }
        conversationsByPartner[virtualRoomId]!.add(message);
      }
      
      debugPrint('Grouped into ${conversationsByPartner.length} conversations');
      
      // Process each conversation and create virtual chat rooms
      for (var entry in conversationsByPartner.entries) {
        final String virtualRoomId = entry.key;
        final List<dynamic> messages = entry.value;
        
        // Get the most recent message
        final latestMessage = messages.first;
        
        // Determine partner info
        String partnerId;
        if (latestMessage['sender_id'] == user.id) {
          partnerId = latestMessage['recipient_id'];
        } else {
          partnerId = latestMessage['sender_id'];
        }
        
        // Get partner name from cache
        String partnerName = 'Unknown User';
        if (userDetailsCache.containsKey(partnerId)) {
          final details = userDetailsCache[partnerId]!;
          partnerName = details['username'] ?? 
                      details['email'] ?? 
                      'User $partnerId';
        }
        
        debugPrint('Creating virtual room for conversation with $partnerName ($partnerId)');
        
        // Count unread messages
        int unreadCount = 0;
        for (var msg in messages) {
          if (msg['sender_id'] != user.id && (msg['read'] == false || msg['read'] == null)) {
            unreadCount++;
          }
        }
        
        // Get avatar URL from user details cache
        String? avatarUrl;
        if (userDetailsCache.containsKey(partnerId)) {
          avatarUrl = userDetailsCache[partnerId]!['avatar_url'];
        }
        
        debugPrint('Creating virtual chat room with ID: $virtualRoomId for partner: $partnerName');
        debugPrint('Last message: ${latestMessage['content']} at ${latestMessage['created_at']}');
        debugPrint('Unread count: $unreadCount');
        
        // Create a virtual chat room for this conversation
        final chatRoom = ChatRoomModel(
          id: virtualRoomId, // Use the virtual ID as both id and roomId
          roomId: virtualRoomId,
          createdAt: latestMessage['created_at'] != null
              ? DateTime.parse(latestMessage['created_at'])
              : DateTime.now(),
          updatedAt: latestMessage['created_at'] != null
              ? DateTime.parse(latestMessage['created_at'])
              : DateTime.now(),
          name: partnerName,
          lastMessage: latestMessage['content'],
          lastMessageTime: latestMessage['created_at'] != null
              ? DateTime.parse(latestMessage['created_at'])
              : DateTime.now(),
          unreadCount: unreadCount,
          participantIds: [user.id, partnerId],
          isStarred: false,
          avatarUrl: avatarUrl,
        );
        
        // Check if this room already exists in our list
        final existingRoomIndex = _chatRooms.indexWhere((room) => room.roomId == virtualRoomId);
        
        if (existingRoomIndex >= 0) {
          // Update the existing room with new information
          debugPrint('Updating existing virtual room: $virtualRoomId');
          _chatRooms[existingRoomIndex] = chatRoom;
        } else {
          // Add as a new room
          debugPrint('Adding new virtual room: $virtualRoomId');
          _chatRooms.add(chatRoom);
        }
      }
      
      // Sort all chat rooms by last message time
      _chatRooms.sort((a, b) => 
        (b.lastMessageTime ?? DateTime(1970)).compareTo(a.lastMessageTime ?? DateTime(1970)));
        
      // Notify listeners to update the UI
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error fetching direct messages: $e');
    }
  }

  // Handle a new message from the realtime subscription
  Future<void> _handleNewMessage(Map<String, dynamic> payload) async {
    try {
      debugPrint('🔥 HANDLE_MESSAGE: Starting to handle new message: $payload');
      
      // Extract the new message data from the payload
      final newMessage = MessageModel.fromJson(payload);
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) {
        debugPrint('🔥 HANDLE_MESSAGE: Cannot handle new message: User is null');
        return;
      }
      
      debugPrint('🔥 HANDLE_MESSAGE: Current user ID: ${user.id}');
      debugPrint('🔥 HANDLE_MESSAGE: Message sender ID: ${newMessage.senderId}');
      debugPrint('🔥 HANDLE_MESSAGE: Message recipient ID: ${newMessage.recipientId}');
      debugPrint('🔥 HANDLE_MESSAGE: Is this an inbound message? ${newMessage.senderId != user.id}');
    
      debugPrint('New message received - ID: ${newMessage.id}');
      debugPrint('Content: ${newMessage.content}');
      debugPrint('From: ${newMessage.senderId}');
      debugPrint('To: ${newMessage.recipientId}');
      debugPrint('Room ID: ${newMessage.roomId}');
      debugPrint('Created at: ${newMessage.createdAt}');
      
      // Handle direct messages (messages with no room_id)
      if (newMessage.roomId == null) {
        debugPrint('Processing as direct message');
        
        // Determine the other user ID (conversation partner)
        final String otherUserId = newMessage.senderId == user.id 
            ? newMessage.recipientId! 
            : newMessage.senderId!;
        
        // Create a virtual room ID for direct messages
        final List<String> userIds = [user.id, otherUserId];
        userIds.sort(); // Sort to ensure consistent order regardless of sender/recipient
        final String roomId = 'dm_${userIds.join('_')}';
        debugPrint('Constructed virtual room ID for direct message: $roomId');
        
        // Find the room index
        final roomIndex = _chatRooms.indexWhere((room) => room.roomId == roomId);
      
        // If this is a new room we don't have yet, create a virtual chat room
        if (roomIndex == -1) {
          debugPrint('New message for unknown room, creating virtual chat room');
          
          // For direct messages, we need to create a virtual chat room
          if (newMessage.roomId == null) {
            debugPrint('Creating virtual chat room for direct message with user: $otherUserId');
            
            // Fetch user details for the other user
            final userDetails = await _fetchUserDetails(otherUserId);
            final otherUserName = userDetails?['username'] ?? 
                                userDetails?['email'] ?? 
                                'User $otherUserId';
            
            debugPrint('Got user details for $otherUserId: $otherUserName');
            
            // Create a virtual chat room for this direct message
            final newRoom = ChatRoomModel(
              id: roomId, // Using the virtual room ID we constructed
              roomId: roomId,
              name: otherUserName,
              lastMessage: newMessage.content,
              lastMessageTime: newMessage.createdAt,
              unreadCount: newMessage.senderId != user.id ? 1 : 0,
              participantIds: [user.id, otherUserId],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            debugPrint('Created virtual chat room: ${newRoom.name} with ID: ${newRoom.roomId}');
            
            // Add to the beginning of the chat rooms list
            _chatRooms.insert(0, newRoom);
            
            // If we're viewing this room, add the message to the messages list
            if (_messages.isNotEmpty && _messages[0].roomId == roomId) {
              _messages.insert(0, newMessage);
            }
            
            // Force a refresh of direct messages to ensure we have all messages
            await _fetchDirectMessages();
            
            // Notify listeners to update the UI
            notifyListeners();
            return;
          }
          
          // For room messages, fetch chat rooms again
          await _fetchChatRooms();
          notifyListeners();
          return;
        }

        // Add to messages list if we're already viewing this room
        if (_messages.isNotEmpty && _messages[0].roomId == roomId) {
          // Check if the message is already in our list to avoid duplicates
          if (!_messages.any((m) => m.id == newMessage.id)) {
            _messages.insert(0, newMessage);
            debugPrint('Added new message to active conversation');
            notifyListeners();
          }
        }
        
        debugPrint('Updating existing chat room at index $roomIndex with new message');
        
        // Update the chat room with the latest message
        final room = _chatRooms[roomIndex];
        
        // Only increment unread count if the message is from someone else and not already read
        int newUnreadCount = room.unreadCount ?? 0;
        if (newMessage.senderId != user.id && newMessage.read != true) {
          newUnreadCount += 1;
          debugPrint('Incrementing unread count to $newUnreadCount');
        }
        
        _chatRooms[roomIndex] = room.copyWith(
          lastMessage: newMessage.content,
          lastMessageTime: newMessage.createdAt,
          unreadCount: newUnreadCount,
          updatedAt: DateTime.now(),
        );
        
        // Move this room to the top of the list
        if (roomIndex > 0) {
          final room = _chatRooms.removeAt(roomIndex);
          _chatRooms.insert(0, room);
          debugPrint('Moved chat room to top of list');
        }
        
        // Force a refresh of direct messages if this is a direct message
        if (newMessage.roomId == null) {
          debugPrint('Refreshing direct messages after receiving a new one');
          await _fetchDirectMessages();
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }

  // Create a new chat room
  Future<ChatRoomModel?> createChatRoom({
    required String name,
    required List<String> participantIds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _error = 'User not authenticated';
        return null;
      }

      // Ensure the current user is included in participants
      if (!participantIds.contains(user.id)) {
        participantIds.add(user.id);
      }

      // Generate a unique room ID
      final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}_${user.id.substring(0, 8)}';
      
      final roomData = {
        'room_id': roomId,
      };

      final response = await Supabase.instance.client
          .from('chat_rooms')
          .insert(roomData)
          .select();

      final newRoomData = response[0];
      
      // Create a ChatRoomModel with additional UI fields
      final newRoom = ChatRoomModel(
        id: newRoomData['id'],
        roomId: newRoomData['room_id'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: name,
        unreadCount: 0,
        participantIds: participantIds,
      );
      
      _chatRooms.insert(0, newRoom);
      notifyListeners();
      return newRoom;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating chat room: $_error');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Star/unstar a conversation
  Future<void> toggleStarredConversation(String roomId, bool isStarred) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      if (isStarred) {
        // Add to starred conversations
        await Supabase.instance.client
            .from('starred_conversations')
            .insert({
              'user_id': user.id,
              'conversation_id': roomId,
            })
            ;
      } else {
        // Remove from starred conversations
        await Supabase.instance.client
            .from('starred_conversations')
            .delete()
                      .eq('user_id', user.id)
                      .eq('conversation_id', roomId)
            ;
      }

      // Update local state
      final index = _chatRooms.indexWhere((room) => room.roomId == roomId);
      if (index != -1) {
        final updatedRoom = ChatRoomModel(
          id: _chatRooms[index].id,
          roomId: _chatRooms[index].roomId,
          createdAt: _chatRooms[index].createdAt,
          updatedAt: _chatRooms[index].updatedAt,
          name: _chatRooms[index].name,
          lastMessage: _chatRooms[index].lastMessage,
          lastMessageTime: _chatRooms[index].lastMessageTime,
          unreadCount: _chatRooms[index].unreadCount,
          participantIds: _chatRooms[index].participantIds,
          isStarred: isStarred,
        );
        _chatRooms[index] = updatedRoom;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling starred conversation: $e');
    }
  }

  // Subscribe to messages for a specific room
  RealtimeChannel? _activeRoomChannel;
  String? _activeRoomId;
  
  void subscribeToRoom(String roomId) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    // If we're already subscribed to this room, do nothing
    if (_activeRoomId == roomId && _activeRoomChannel != null) {
      debugPrint('Already subscribed to room $roomId');
      return;
    }
    
    // Unsubscribe from any previous room
    unsubscribeFromRoom();
    
    _activeRoomId = roomId;
    debugPrint('Subscribing to messages for room $roomId');
    
    // Create a channel specific to this room
    _activeRoomChannel = Supabase.instance.client
        .channel('room:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) async {
            debugPrint('New message in room $roomId: ${payload.newRecord}');
            await _handleNewMessage(payload.newRecord);
          },
        )
        .subscribe();
  }
  
  void unsubscribeFromRoom() {
    if (_activeRoomChannel != null) {
      debugPrint('Unsubscribing from room $_activeRoomId');
      Supabase.instance.client.removeChannel(_activeRoomChannel!);
      _activeRoomChannel = null;
      _activeRoomId = null;
    }
  }
  
  // Clean up resources
  @override
  void dispose() {
    // Clean up main message channel
    if (_messagesChannel != null) {
      Supabase.instance.client.removeChannel(_messagesChannel!);
      _messagesChannel = null;
    }
    
    // Clean up typing channel
    if (_typingChannel != null) {
      Supabase.instance.client.removeChannel(_typingChannel!);
      _typingChannel = null;
    }
    
    // Clean up active room subscription
    unsubscribeFromRoom();
    
    // Clean up any additional channels
    for (final channel in _channels) {
      debugPrint('Cleaning up additional channel');
      Supabase.instance.client.removeChannel(channel);
    }
    _channels.clear();
    
    super.dispose();
  }
}
