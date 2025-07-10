import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClient {
  static SupabaseClient? _instance;
  late final SupabaseClient _client;

  SupabaseClient._();

  static Future<SupabaseClient> get instance async {
    _instance ??= SupabaseClient._();
    return _instance!;
  }

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
