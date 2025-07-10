import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for managing Supabase initialization and access
class SupabaseService {
  static SupabaseService? _instance;
  static bool _isInitialized = false;

  SupabaseService._();

  static Future<SupabaseService> get instance async {
    if (!_isInitialized) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Initialize Supabase client with the provided URL and anonymous key
  static Future<void> initialize({
    required String url,
    required String anonKey,
    bool debug = true,
  }) async {
    if (_isInitialized) {
      debugPrint('SupabaseService already initialized');
      return;
    }
    
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: debug,
      );
      _isInitialized = true;
      debugPrint('SupabaseService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing SupabaseService: $e');
      rethrow;
    }
  }

  /// Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;
}
