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

      // Fetch chat rooms from Supabase
      final response = await Supabase.instance.client
          .from('chat_rooms')
          .select('*')
          .order('updated_at', ascending: false)
          ;

      final data = response as List<dynamic>;
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

  // Fetch messages for a specific chat room
  Future<List<MessageModel>> fetchMessages(String roomId, {int limit = 20, int offset = 0}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('*')
          .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1)
          ;

      final data = response as List<dynamic>;
      final messages = data.map((json) => MessageModel.fromJson(json)).toList();
      
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
        'room_id': roomId,
        'content': content,
        'extension': 'text',
        'topic': topic ?? 'message',
        'read': false,
        'status': 'sent',
      };

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
