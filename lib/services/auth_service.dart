import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A service class to handle authentication operations independently of the UI
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => _instance;

  // Global navigator key to enable navigation from anywhere
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Sign out the current user and handle all cleanup
  Future<void> signOut() async {
    debugPrint('AuthService: Starting sign-out process');
    
    try {
      // 1. Remove all realtime subscriptions first
      debugPrint('AuthService: Removing all realtime subscriptions');
      await Supabase.instance.client.removeAllChannels();
      
      // 2. Small delay to ensure subscriptions are properly closed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 3. Sign out with global scope
      debugPrint('AuthService: Executing sign-out with global scope');
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
      
      debugPrint('AuthService: Sign-out completed successfully');
      return;
    } catch (e) {
      debugPrint('AuthService: Error during sign-out: $e');
      rethrow;
    }
  }

  /// Navigate to login screen, clearing all previous routes
  void navigateToLogin() {
    if (navigatorKey.currentState != null) {
      debugPrint('AuthService: Navigating to login screen');
      navigatorKey.currentState!.pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      debugPrint('AuthService: Navigator key not available, cannot navigate');
    }
  }
}
