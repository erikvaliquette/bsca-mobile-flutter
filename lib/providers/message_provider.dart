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

  // Getters
  List<MessageModel> get messages => _messages;
  List<ChatRoomModel> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize the provider
  bool _isInitialized = false;
  
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
          .or('sender_id          .eq.${user.id},recipient_id.eq.${user.id}')
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
        final response = await Supabase.instance.client
            .from('messages')
            .select('*')
            .or(
              'and(sender_id.eq.${userIds[0]},recipient_id.eq.${userIds[1]}),' +
              'and(sender_id.eq.${userIds[1]},recipient_id.eq.${userIds[0]})'
            )
            .filter('room_id', 'is', null)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
            
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
        'extension': 'text',
        'topic': topic ?? 'message',
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
  void _subscribeToMessages() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Unsubscribe from any existing channels
    _messagesChannel?.unsubscribe();

    // Subscribe to the messages table for real-time updates
    _messagesChannel = Supabase.instance.client
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            _handleNewMessage(payload.newRecord as Map<String, dynamic>);
          },
        )
        .subscribe();
  }

  // Handle a new message received via real-time subscription
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
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Fetch all direct messages where the current user is either sender or recipient
      // and room_id is null
      final response = await Supabase.instance.client
          .from('messages')
          .select('*')
          .or('sender_id.eq.${user.id},recipient_id.eq.${user.id}')
          .filter('room_id', 'is', null)
          .order('created_at', ascending: false);

      // Group messages by conversation partner
      final Map<String, List<dynamic>> conversationsByPartner = {};
      final Map<String, Map<String, dynamic>> userDetailsCache = {};
      
      for (var message in response) {
        String partnerId;
        String partnerName = 'Unknown User';
        
        // Determine the conversation partner (the other person)
        if (message['sender_id'] == user.id) {
          partnerId = message['recipient_id'];
          
          // Fetch user details if not already in cache
          if (!userDetailsCache.containsKey(partnerId)) {
            final userDetails = await _fetchUserDetails(partnerId);
            if (userDetails != null) {
              userDetailsCache[partnerId] = userDetails;
            }
          }
          
          // Use user details from cache if available
          if (userDetailsCache.containsKey(partnerId)) {
            final details = userDetailsCache[partnerId]!;
            partnerName = details['username'] ?? 
                         details['email'] ?? 
                         'User $partnerId';
          }
        } else {
          partnerId = message['sender_id'];
          
          // Fetch user details if not already in cache
          if (!userDetailsCache.containsKey(partnerId)) {
            final userDetails = await _fetchUserDetails(partnerId);
            if (userDetails != null) {
              userDetailsCache[partnerId] = userDetails;
            }
          }
          
          // Use user details from cache if available
          if (userDetailsCache.containsKey(partnerId)) {
            final details = userDetailsCache[partnerId]!;
            partnerName = details['username'] ?? 
                         details['email'] ?? 
                         'User $partnerId';
          }
        }
        
        // Create a virtual room ID for direct messages - use a different format that won't be confused with actual room_id
        // Instead of using room_id, we'll use a special format for the ID property
        final virtualRoomId = 'dm_${user.id}_${partnerId}';
        
        // Add message to the appropriate conversation group
        if (!conversationsByPartner.containsKey(virtualRoomId)) {
          conversationsByPartner[virtualRoomId] = [];
        }
        conversationsByPartner[virtualRoomId]!.add(message);
      }
      
      // Create virtual chat rooms for direct messages
      for (var entry in conversationsByPartner.entries) {
        final String virtualRoomId = entry.key;
        final List<dynamic> messages = entry.value;
        
        // Skip if we already have this room
        if (_chatRooms.any((room) => room.roomId == virtualRoomId)) {
          continue;
        }
        
        // Get the most recent message
        final latestMessage = messages.first;
        
        // Determine partner info
        String partnerId;
        String partnerName = 'Unknown User';
        
        if (latestMessage['sender_id'] == user.id) {
          partnerId = latestMessage['recipient_id'];
          
          // Use cached user details if available
          if (userDetailsCache.containsKey(partnerId)) {
            final details = userDetailsCache[partnerId]!;
            partnerName = details['username'] ?? 'User $partnerId';
          }
        } else {
          partnerId = latestMessage['sender_id'];
          
          // Use cached user details if available
          if (userDetailsCache.containsKey(partnerId)) {
            final details = userDetailsCache[partnerId]!;
            partnerName = details['username'] ?? 'User $partnerId';
          }
        }
        
        // Count unread messages
        int unreadCount = 0;
        for (var msg in messages) {
          if (msg['sender_id'] != user.id && msg['read'] == false) {
            unreadCount++;
          }
        }
        
        // Get avatar URL from user details cache
        String? avatarUrl;
        if (userDetailsCache.containsKey(partnerId)) {
          avatarUrl = userDetailsCache[partnerId]!['avatar_url'];
        }
        
        // Create a virtual chat room for this conversation
        final chatRoom = ChatRoomModel(
          id: virtualRoomId, // Use the virtual ID as both id and roomId
          roomId: virtualRoomId,
          createdAt: latestMessage['created_at'] != null
              ? DateTime.parse(latestMessage['created_at'])
              : null,
          updatedAt: latestMessage['created_at'] != null
              ? DateTime.parse(latestMessage['created_at'])
              : null,
          name: partnerName,
          lastMessage: latestMessage['content'],
          lastMessageTime: latestMessage['created_at'] != null
              ? DateTime.parse(latestMessage['created_at'])
              : null,
          unreadCount: messages.where((m) => 
              m['recipient_id'] == user.id && 
              m['read'] == false).length,
          participantIds: [user.id, partnerId],
          isStarred: false,
          avatarUrl: avatarUrl,
        );
        
        _chatRooms.add(chatRoom);
      }
      
      // Sort all chat rooms by last message time
      _chatRooms.sort((a, b) => 
        (b.lastMessageTime ?? DateTime(1970)).compareTo(a.lastMessageTime ?? DateTime(1970)));
      
    } catch (e) {
      debugPrint('Error fetching direct messages: $e');
    }
  }

  void _handleNewMessage(Map<String, dynamic> payload) {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final newMessage = MessageModel.fromJson(payload['new']);
      
      // Only process if this is a message for a room we're tracking
      final roomIndex = _chatRooms.indexWhere((room) => room.roomId == newMessage.roomId);
      if (roomIndex == -1) return;

      // If this is a message from someone else to a room we're viewing
      if (newMessage.senderId != user.id) {
        // Add to messages list if we're already viewing this room
        if (_messages.isNotEmpty && _messages[0].roomId == newMessage.roomId) {
          _messages.insert(0, newMessage);
        }
        
        // Update unread count for the room
        final updatedRoom = ChatRoomModel(
          id: _chatRooms[roomIndex].id,
          roomId: _chatRooms[roomIndex].roomId,
          createdAt: _chatRooms[roomIndex].createdAt,
          updatedAt: DateTime.now(),
          name: _chatRooms[roomIndex].name,
          lastMessage: newMessage.content,
          lastMessageTime: newMessage.createdAt,
          unreadCount: (_chatRooms[roomIndex].unreadCount ?? 0) + 1,
          participantIds: _chatRooms[roomIndex].participantIds,
          isStarred: _chatRooms[roomIndex].isStarred,
        );
        
        // Update the room and move it to the top
        _chatRooms[roomIndex] = updatedRoom;
        if (roomIndex > 0) {
          final room = _chatRooms.removeAt(roomIndex);
          _chatRooms.insert(0, room);
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

  // Clean up resources
  void dispose() {
    _messagesChannel?.unsubscribe();
    _typingChannel?.unsubscribe();
    super.dispose();
  }
}
