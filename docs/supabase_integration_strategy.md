# Supabase Integration Strategy for BSCA Mobile Flutter

This document outlines the approach for integrating Supabase with the Flutter version of the BSCA Mobile application.

## Overview

Supabase provides a comprehensive backend-as-a-service solution that includes database, authentication, storage, and real-time capabilities. Our Flutter application will leverage the `supabase_flutter` package to interact with these services.

## Key Integration Points

### 1. Supabase Client Setup

We'll use a singleton pattern to manage the Supabase client instance throughout the application:

```dart
// lib/services/supabase/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() {
    return _instance;
  }
  
  SupabaseService._internal();
  
  late final SupabaseClient client;
  
  Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authCallbackUrlHostname: 'login-callback',
      debug: true,
    );
    
    client = Supabase.instance.client;
  }
  
  // Convenience getters
  GotrueClient get auth => client.auth;
  SupabaseQueryBuilder from(String table) => client.from(table);
  SupabaseStorageClient get storage => client.storage;
}
```

### 2. Authentication

```dart
// lib/services/supabase/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_client.dart';

class AuthService {
  final SupabaseService _supabase = SupabaseService();
  
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  Future<UserResponse> resetPassword(String email) async {
    return await _supabase.auth.resetPasswordForEmail(email);
  }
}
```

### 3. Database Access

We'll create repository classes for each data entity to encapsulate database operations:

```dart
// lib/repositories/message_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import '../services/supabase/supabase_client.dart';

class MessageRepository {
  final SupabaseService _supabase = SupabaseService();
  
  // Fetch messages with safe UUID handling
  Future<List<MessageModel>> getMessages() async {
    try {
      // Use RPC call to avoid UUID parsing issues
      final response = await _supabase.client.rpc(
        'get_messages_ultra_safe',
        params: {
          'p_user_id': _supabase.auth.currentUser!.id,
        },
      );
      
      return (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } catch (e) {
      // Log error and rethrow
      print('Error fetching messages: $e');
      rethrow;
    }
  }
  
  // Send a new message
  Future<MessageModel> sendMessage({
    required String receiverId,
    required String content,
    String? roomId,
  }) async {
    try {
      final senderId = _supabase.auth.currentUser!.id;
      
      // Generate a new roomId if not provided
      final actualRoomId = roomId ?? _generateRoomId(senderId, receiverId);
      
      final response = await _supabase.from('messages').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'room_id': actualRoomId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();
      
      return MessageModel.fromJson(response);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
  
  // Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      await _supabase.from('messages').update({
        'read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);
    } catch (e) {
      print('Error marking message as read: $e');
      rethrow;
    }
  }
  
  // Subscribe to new messages
  RealtimeChannel subscribeToMessages(
    void Function(MessageModel) onInsert,
    void Function(MessageModel) onUpdate,
  ) {
    final userId = _supabase.auth.currentUser!.id;
    
    return _supabase.client
      .channel('public:messages')
      .on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: 'receiver_id=eq.$userId',
        ),
        (payload, [ref]) {
          final message = MessageModel.fromJson(payload['new']);
          onInsert(message);
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
          final message = MessageModel.fromJson(payload['new']);
          onUpdate(message);
        },
      )
      .subscribe();
  }
  
  // Helper method to generate a room ID
  String _generateRoomId(String userId1, String userId2) {
    // Sort IDs to ensure consistency
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
}
```

### 4. Storage Integration

```dart
// lib/services/supabase/storage_service.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_client.dart';

class StorageService {
  final SupabaseService _supabase = SupabaseService();
  
  Future<String> uploadProfileImage(File file) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final fileExt = path.extension(file.path);
      final fileName = '$userId$fileExt';
      
      final response = await _supabase
          .storage
          .from('avatars')
          .upload(fileName, file);
      
      return _supabase
          .storage
          .from('avatars')
          .getPublicUrl(fileName);
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow;
    }
  }
  
  Future<String> uploadMessageAttachment(File file, String messageId) async {
    try {
      final fileExt = path.extension(file.path);
      final fileName = '$messageId$fileExt';
      
      final response = await _supabase
          .storage
          .from('attachments')
          .upload(fileName, file);
      
      return _supabase
          .storage
          .from('attachments')
          .getPublicUrl(fileName);
    } catch (e) {
      print('Error uploading message attachment: $e');
      rethrow;
    }
  }
}
```

### 5. Handling UUID Issues

The React Native app encountered issues with UUID parsing. We'll implement a solution in Flutter:

```dart
// lib/utils/uuid_helper.dart
import 'package:uuid/uuid.dart';

class UuidHelper {
  // Validate if a string is a valid UUID
  static bool isValidUuid(String? str) {
    if (str == null) return false;
    
    RegExp uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    
    return uuidRegex.hasMatch(str);
  }
  
  // Safely parse UUID from string
  static String? safeParseUuid(String? str) {
    if (isValidUuid(str)) {
      return str;
    }
    return null;
  }
  
  // Generate a new UUID
  static String generateUuid() {
    return const Uuid().v4();
  }
}
```

### 6. Database Functions

We'll need to create equivalent Supabase functions to handle the UUID issues:

```sql
-- Create ultra-safe function to get messages
CREATE OR REPLACE FUNCTION get_messages_ultra_safe(p_user_id UUID)
RETURNS SETOF messages AS $$
BEGIN
  RETURN QUERY
  SELECT m.*
  FROM messages m
  WHERE m.receiver_id = p_user_id OR m.sender_id = p_user_id
  ORDER BY m.created_at DESC;
END;
$$ LANGUAGE plpgsql;
```

### 7. Initialization in App

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/messaging_provider.dart';
import 'providers/profile_provider.dart';
import 'router/app_router.dart';
import 'services/supabase/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService().initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  final authProvider = AuthProvider();
  final appRouter = AppRouter(authProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => MessagingProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: BscaApp(router: appRouter.router),
    ),
  );
}
```

## Security Considerations

### 1. Row Level Security (RLS)

We'll ensure that all tables have proper RLS policies:

```sql
-- Example RLS policy for messages table
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own messages" 
ON messages FOR SELECT 
USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can insert their own messages" 
ON messages FOR INSERT 
WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update their own messages" 
ON messages FOR UPDATE 
USING (auth.uid() = sender_id);
```

### 2. Secure Storage

For sensitive information like tokens, we'll use `flutter_secure_storage` instead of regular shared preferences:

```dart
// lib/services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  
  factory SecureStorageService() {
    return _instance;
  }
  
  SecureStorageService._internal();
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }
  
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }
  
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }
}
```

## Error Handling

We'll implement a centralized error handling system for Supabase errors:

```dart
// lib/utils/supabase_error_handler.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseErrorHandler {
  static String handleError(dynamic error) {
    if (error is AuthException) {
      return _handleAuthError(error);
    } else if (error is PostgrestException) {
      return _handlePostgrestError(error);
    } else if (error is StorageException) {
      return _handleStorageError(error);
    } else {
      return 'An unexpected error occurred: ${error.toString()}';
    }
  }
  
  static String _handleAuthError(AuthException error) {
    switch (error.message) {
      case 'Invalid login credentials':
        return 'Invalid email or password';
      case 'Email not confirmed':
        return 'Please confirm your email before logging in';
      default:
        return 'Authentication error: ${error.message}';
    }
  }
  
  static String _handlePostgrestError(PostgrestException error) {
    if (error.code == '23505') {
      return 'This record already exists';
    } else if (error.code == '23503') {
      return 'Referenced record does not exist';
    } else {
      return 'Database error: ${error.message}';
    }
  }
  
  static String _handleStorageError(StorageException error) {
    return 'Storage error: ${error.message}';
  }
}
```

## Conclusion

This Supabase integration strategy provides a comprehensive approach to integrating Supabase with our Flutter application. By following these patterns and best practices, we'll ensure a robust, secure, and maintainable integration that addresses the specific requirements of the BSCA Mobile application, including the critical UUID handling issues encountered in the React Native version.
