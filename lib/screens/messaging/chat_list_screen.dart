import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/message_provider.dart';
import '../../providers/business_connection_provider.dart';
import '../../models/chat_room_model.dart';
import '../../models/business_connection_model.dart';
import 'conversation_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to avoid calling setState during build
    Future.microtask(() => _initializeMessageProvider());
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures we refresh the chat list when returning to this screen
    if (_isInitialized) {
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      // Force a full refresh of chat rooms and subscriptions
      messageProvider.refreshChatRooms();
      debugPrint('ChatListScreen: Refreshed chat rooms and subscriptions');
    }
  }

  Future<void> _initializeMessageProvider() async {
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    // If already initialized, just refresh the chat rooms
    if (_isInitialized) {
      debugPrint('ChatListScreen: Refreshing chat rooms and subscriptions');
      // Force a refresh of chat rooms to get the latest messages
      await messageProvider.refreshChatRooms();
      // Ensure realtime subscriptions are active
      messageProvider.refreshMessageSubscriptions();
      return;
    }
    
    debugPrint('ChatListScreen: First time initialization');
    // First time initialization
    await messageProvider.initialize();
    // Ensure realtime subscriptions are active
    messageProvider.refreshMessageSubscriptions();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement new conversation flow
              _showNewConversationDialog();
            },
          ),
        ],
      ),
      body: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          if (messageProvider.isLoading && messageProvider.chatRooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (messageProvider.error != null && messageProvider.chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading conversations',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(messageProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeMessageProvider,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (messageProvider.chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Start a new conversation to begin messaging'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showNewConversationDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('New Conversation'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _initializeMessageProvider,
            child: ListView.builder(
              itemCount: messageProvider.chatRooms.length,
              itemBuilder: (context, index) {
                final room = messageProvider.chatRooms[index];
                return _buildChatRoomTile(room);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatRoomTile(ChatRoomModel room) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        backgroundImage: room.avatarUrl != null ? NetworkImage(room.avatarUrl!) : null,
        child: room.avatarUrl == null
            ? Text(
                (room.name?.isNotEmpty == true)
                    ? room.name![0].toUpperCase()
                    : 'C',
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      title: Text(
        room.name ?? 'Conversation',
        style: TextStyle(
          fontWeight: (room.unreadCount ?? 0) > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: room.lastMessage != null
          ? Text(
              room.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : const Text('No messages yet'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (room.lastMessageTime != null)
            Text(
              timeago.format(room.lastMessageTime!, locale: 'en_short'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          const SizedBox(height: 4),
          if ((room.unreadCount ?? 0) > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${room.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(roomId: room.roomId),
          ),
        );
      },
      onLongPress: () {
        _showChatOptions(room);
      },
    );
  }

  void _showChatOptions(ChatRoomModel room) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  room.isStarred == true ? Icons.star : Icons.star_border,
                ),
                title: Text(
                  room.isStarred == true ? 'Unstar' : 'Star',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleStarredStatus(room);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off),
                title: const Text('Mute'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement mute functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteConversation(room);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleStarredStatus(ChatRoomModel room) {
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    messageProvider.toggleStarredConversation(room.roomId, !(room.isStarred ?? false));
  }

  void _confirmDeleteConversation(ChatRoomModel room) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Conversation'),
          content: const Text(
            'Are you sure you want to delete this conversation? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement delete functionality
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }

  void _showNewConversationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'New Conversation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Contact list
                Expanded(
                  child: Consumer<BusinessConnectionProvider>(
                    builder: (context, connectionProvider, child) {
                      if (connectionProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (connectionProvider.connections.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No connections yet',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add connections in the Network tab to start messaging',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: connectionProvider.connections.length,
                        itemBuilder: (context, index) {
                          final connection = connectionProvider.connections[index];
                          return _buildContactTile(connection);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    
    // Load connections when dialog opens
    Future.microtask(() {
      final connectionProvider = Provider.of<BusinessConnectionProvider>(context, listen: false);
      connectionProvider.fetchConnections();
    });
  }
  
  Widget _buildContactTile(BusinessConnection connection) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        backgroundImage: connection.profileImageUrl != null 
            ? NetworkImage(connection.profileImageUrl!) 
            : null,
        child: connection.profileImageUrl == null
            ? Text(
                connection.initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        connection.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (connection.title != null) 
            Text(connection.title!),
          if (connection.organization != null)
            Text(
              connection.organization!,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
        ],
      ),
      onTap: () => _startConversationWithContact(connection),
    );
  }
  
  void _startConversationWithContact(BusinessConnection connection) {
    Navigator.pop(context); // Close the dialog
    
    // Create a virtual room ID for direct messages
    final currentUserId = Provider.of<MessageProvider>(context, listen: false)
        .getCurrentUserId();
    if (currentUserId == null) return;
    
    final userIds = [currentUserId, connection.counterpartyId];
    userIds.sort(); // Sort to ensure consistent order
    final virtualRoomId = 'dm_${userIds.join('_')}';
    
    // Navigate to conversation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationScreen(roomId: virtualRoomId),
      ),
    );
  }
}
