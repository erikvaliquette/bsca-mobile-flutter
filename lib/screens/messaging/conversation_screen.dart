import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/message_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/message_model.dart';

class ConversationScreen extends StatefulWidget {
  final String roomId;

  const ConversationScreen({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentOffset = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markMessagesAsRead();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMessages() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    await messageProvider.fetchMessages(widget.roomId, limit: _pageSize, offset: 0);
    _currentOffset = messageProvider.messages.length;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoading || _isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    final messages = await messageProvider.fetchMessages(
      widget.roomId,
      limit: _pageSize,
      offset: _currentOffset,
    );
    
    if (messages.isNotEmpty) {
      _currentOffset += messages.length;
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _markMessagesAsRead() async {
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    await messageProvider.markMessagesAsRead(widget.roomId);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    await messageProvider.sendMessage(
      roomId: widget.roomId,
      content: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: Consumer<MessageProvider>(
          builder: (context, messageProvider, child) {
            final room = messageProvider.chatRooms
                .firstWhere((room) => room.roomId == widget.roomId, 
                           orElse: () => throw Exception('Room not found'));
            return Text(room.name ?? 'Conversation');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show conversation options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, messageProvider, child) {
                if (_isLoading && messageProvider.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messageProvider.error != null && messageProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error loading messages',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(messageProvider.error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMessages,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = messageProvider.messages;
                
                if (messages.isEmpty) {
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
                        const Text('No messages yet'),
                        const SizedBox(height: 8),
                        const Text('Send a message to start the conversation'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.5),
              child: Text(
                message.senderName?.isNotEmpty == true
                    ? message.senderName![0].toUpperCase()
                    : 'U',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.createdAt != null
                            ? timeago.format(message.createdAt!, locale: 'en_short')
                            : '',
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isMe)
                        Icon(
                          message.read == true ? Icons.done_all : Icons.done,
                          size: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isMe)
            const SizedBox(width: 32), // Balance the avatar on the other side
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {
                // TODO: Implement file attachment
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              color: Theme.of(context).primaryColor,
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
