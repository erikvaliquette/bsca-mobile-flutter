import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/message_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/business_connection_provider.dart';
import 'services/supabase/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with windsurf-project credentials
  await SupabaseService.initialize(
    url: 'https://vufeuaoosussspqyskdw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ1ZmV1YW9vc3Vzc3NwcXlza2R3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI5MTI3NTAsImV4cCI6MjA0ODQ4ODc1MH0.DLmnF-g3Eo9Z1gsOSOHt97ljmGyV5K25ScPHTckkB9U',
    debug: true,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => BusinessConnectionProvider()),
      ],
      child: const BscaApp(),
    ),
  );
}
