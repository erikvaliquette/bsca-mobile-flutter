# State Management Strategy for BSCA Mobile Flutter

This document outlines the state management approach for the Flutter version of the BSCA Mobile application.

## Overview

After evaluating the requirements of the application and analyzing the existing React Native implementation, we've decided to use a combination of **Provider** and **Riverpod** for state management in our Flutter application.

## State Management Architecture

### Core Principles

1. **Separation of Concerns**: Each feature will have its own dedicated state management
2. **Testability**: All state logic should be easily testable
3. **Reactivity**: UI should automatically update when state changes
4. **Scalability**: State management should scale with application complexity

### Provider Structure

We'll organize our providers into the following categories:

1. **Service Providers**: For low-level services like API clients, database access
2. **Repository Providers**: For data access and manipulation
3. **State Providers**: For UI state management

## Implementation Details

### Authentication State

```dart
// auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = response.user;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _user = null;
    notifyListeners();
  }
}
```

### Messaging State (Equivalent to UnreadContext)

```dart
// messaging_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

class MessagingProvider extends ChangeNotifier {
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _subscription;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use the ultra-safe function to avoid UUID parsing issues
      final response = await Supabase.instance.client
          .rpc('get_messages_ultra_safe', params: {
        'p_user_id': Supabase.instance.client.auth.currentUser!.id,
      });

      _messages = (response as List)
          .map((message) => MessageModel.fromJson(message))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      // Optimistic update
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        final updatedMessage = MessageModel(
          id: _messages[index].id,
          senderId: _messages[index].senderId,
          receiverId: _messages[index].receiverId,
          roomId: _messages[index].roomId,
          content: _messages[index].content,
          createdAt: _messages[index].createdAt,
          updatedAt: _messages[index].updatedAt,
          readAt: DateTime.now(),
          senderName: _messages[index].senderName,
          senderAvatarUrl: _messages[index].senderAvatarUrl,
        );
        
        _messages[index] = updatedMessage;
        notifyListeners();
      }

      // Update in database
      await Supabase.instance.client.from('messages').update({
        'read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      // Refresh messages to revert optimistic update if it failed
      await fetchMessages();
    }
  }

  void setupRealtimeSubscription() {
    _subscription = Supabase.instance.client
        .channel('public:messages')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'messages',
          ),
          (payload, [ref]) {
            final newMessage = MessageModel.fromJson(payload['new']);
            _messages.add(newMessage);
            notifyListeners();
          },
        )
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'UPDATE',
            schema: 'public',
            table: 'messages',
          ),
          (payload, [ref]) {
            final updatedMessage = MessageModel.fromJson(payload['new']);
            final index = _messages.indexWhere((msg) => msg.id == updatedMessage.id);
            if (index != -1) {
              _messages[index] = updatedMessage;
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
```

### Profile State

```dart
// profile_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class ProfileProvider extends ChangeNotifier {
  UserModel? _profile;
  bool _isLoading = false;
  String? _error;

  UserModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      _profile = UserModel.fromJson(response);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserModel updatedProfile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Supabase.instance.client
          .from('profiles')
          .update(updatedProfile.toJson())
          .eq('id', updatedProfile.id);

      _profile = updatedProfile;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

## Provider Registration

We'll register our providers at the application root using `MultiProvider`:

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/messaging_provider.dart';
import 'providers/profile_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MessagingProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const BscaApp(),
    ),
  );
}
```

## Accessing State in Widgets

```dart
// Example usage in a widget
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/messaging_provider.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch messages when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagingProvider>().fetchMessages();
      context.read<MessagingProvider>().setupRealtimeSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagingProvider = context.watch<MessagingProvider>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: messagingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : messagingProvider.error != null
              ? Center(child: Text('Error: ${messagingProvider.error}'))
              : ListView.builder(
                  itemCount: messagingProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = messagingProvider.messages[index];
                    return ListTile(
                      title: Text(message.content),
                      subtitle: Text(message.senderName ?? 'Unknown'),
                      trailing: message.readAt != null
                          ? const Icon(Icons.done_all)
                          : const Icon(Icons.done),
                    );
                  },
                ),
    );
  }
}
```

## Conclusion

This state management approach provides a clean, maintainable, and testable architecture for our Flutter application. By using Provider, we get:

1. **Dependency Injection**: Easy access to services and state throughout the app
2. **Reactivity**: Automatic UI updates when state changes
3. **Testability**: Easy to mock providers for testing
4. **Separation of Concerns**: Clear separation between UI and business logic

As the application grows, we can consider migrating to Riverpod for more advanced features like provider overrides, family providers, and automatic disposal of providers.
