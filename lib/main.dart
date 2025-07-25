import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/message_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/business_connection_provider.dart';
import 'providers/organization_provider.dart';
import 'services/connectivity_service.dart';
import 'services/local_storage_service.dart';
import 'services/notifications/notification_provider.dart';
import 'services/sdg_icon_service.dart';
import 'services/supabase/supabase_client.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local storage
  await LocalStorageService.instance.init();
  
  // Initialize connectivity service
  await ConnectivityService.instance.init();
  
  // Initialize Supabase with windsurf-project credentials
  await SupabaseService.initialize(
    url: 'https://vufeuaoosussspqyskdw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ1ZmV1YW9vc3Vzc3NwcXlza2R3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI5MTI3NTAsImV4cCI6MjA0ODQ4ODc1MH0.DLmnF-g3Eo9Z1gsOSOHt97ljmGyV5K25ScPHTckkB9U',
    debug: true,
  );
  
  // Initialize sync service
  await SyncService.instance.init();
  
  // Preload SDG icons for better performance
  await SDGIconService.instance.preloadAllSDGIcons();
  
  // Initialize notification provider
  final notificationProvider = NotificationProvider();
  await notificationProvider.initialize();
  
  // Initialize message provider and connect it to notification provider
  final messageProvider = MessageProvider();
  messageProvider.setNotificationProvider(notificationProvider);
  
  // Initialize business connection provider and connect it to notification provider
  final businessConnectionProvider = BusinessConnectionProvider();
  businessConnectionProvider.setNotificationProvider(notificationProvider);
  
  // Initialize organization provider and connect it to notification provider
  final organizationProvider = OrganizationProvider();
  organizationProvider.setNotificationProvider(notificationProvider);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: messageProvider),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider.value(value: businessConnectionProvider),
        ChangeNotifierProvider.value(value: organizationProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
      ],
      child: const BscaApp(),
    ),
  );
}
