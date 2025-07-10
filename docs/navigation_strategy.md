# Navigation Strategy for BSCA Mobile Flutter

This document outlines the navigation approach for the Flutter version of the BSCA Mobile application.

## Overview

After analyzing the existing React Native application's navigation structure, we've decided to use **go_router** for navigation in our Flutter application. This package provides a declarative, URL-based routing system that aligns well with Flutter's widget-based architecture and supports deep linking.

## Navigation Architecture

### Core Principles

1. **Declarative Routing**: Define routes in a central location
2. **Nested Navigation**: Support for tabs and nested navigation flows
3. **Deep Linking**: Support for deep linking to specific screens
4. **Type Safety**: Strongly typed route parameters
5. **Navigation Guards**: Authentication-based navigation protection

## Router Configuration

```dart
// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/messages/messages_list_screen.dart';
import '../screens/messages/conversation_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/marketplace/marketplace_screen.dart';
import '../screens/travel/travel_emissions_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../providers/auth_provider.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final router = GoRouter(
    refreshListenable: authProvider,
    debugLogDiagnostics: true,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final isAuthRoute = state.location.startsWith('/login') || 
                          state.location.startsWith('/register');

      // If not logged in and not on auth route, redirect to login
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // If logged in and on auth route, redirect to home
      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main app shell with tabs
      ShellRoute(
        builder: (context, state, child) {
          return HomeScreen(child: child);
        },
        routes: [
          // Home tab
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeContent(),
            routes: [
              // Nested routes within home tab
              GoRoute(
                path: 'notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),

          // Messages tab
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesListScreen(),
            routes: [
              GoRoute(
                path: ':conversationId',
                builder: (context, state) {
                  final conversationId = state.pathParameters['conversationId']!;
                  return ConversationScreen(conversationId: conversationId);
                },
              ),
            ],
          ),

          // Marketplace tab
          GoRoute(
            path: '/marketplace',
            builder: (context, state) => const MarketplaceScreen(),
            routes: [
              GoRoute(
                path: ':itemId',
                builder: (context, state) {
                  final itemId = state.pathParameters['itemId']!;
                  return MarketplaceItemDetailScreen(itemId: itemId);
                },
              ),
            ],
          ),

          // Travel tab
          GoRoute(
            path: '/travel',
            builder: (context, state) => const TravelEmissionsScreen(),
          ),

          // Profile tab
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'wallet',
                builder: (context, state) => const WalletScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.location}'),
      ),
    ),
  );
}
```

## Integration with State Management

To integrate our navigation with the state management system, we'll make the `AuthProvider` implement `Listenable` so that the router can listen for authentication state changes:

```dart
// lib/providers/auth_provider.dart (updated)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  // Existing code...

  // Make AuthProvider a Listenable for GoRouter
  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}
```

## Usage in App

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/messaging_provider.dart';
import 'providers/profile_provider.dart';
import 'router/app_router.dart';

void main() {
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

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BscaApp extends StatelessWidget {
  final GoRouter router;

  const BscaApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BSCA Mobile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
```

## Navigation in Widgets

```dart
// Example of navigation in a widget
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MessageListItem extends StatelessWidget {
  final String conversationId;
  final String title;

  const MessageListItem({
    super.key,
    required this.conversationId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      onTap: () => context.go('/messages/$conversationId'),
    );
  }
}
```

## Deep Linking Support

To support deep linking, we'll configure the app to handle specific URL schemes:

```dart
// In AndroidManifest.xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="bsca" android:host="app" />
</intent-filter>
```

```dart
// In Info.plist
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.bsca.mobile</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>bsca</string>
    </array>
  </dict>
</array>
```

## Conclusion

This navigation strategy provides a clean, maintainable, and feature-rich routing system for our Flutter application. By using go_router, we get:

1. **Declarative Routing**: All routes defined in one place
2. **Nested Navigation**: Support for complex navigation patterns
3. **Type Safety**: Strongly typed route parameters
4. **Deep Linking**: Built-in support for deep linking
5. **Integration with State**: Authentication-aware routing

This approach closely mirrors the navigation structure of the original React Native application while leveraging Flutter's strengths and best practices.
