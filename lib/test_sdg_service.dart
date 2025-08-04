import 'package:flutter/material.dart';
import 'package:bsca_mobile_flutter/services/sdg_target_service.dart';
import 'package:bsca_mobile_flutter/services/supabase/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize(
    url: 'https://your-supabase-url.supabase.co',
    anonKey: 'your-anon-key',
  );
  
  // Create the service
  final sdgTargetService = SdgTargetService();
  
  // Test if we can access the client
  try {
    print('Testing SdgTargetService...');
    print('Service created successfully!');
  } catch (e) {
    print('Error: $e');
  }
}
