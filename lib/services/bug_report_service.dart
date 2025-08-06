import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bug_report.dart';

class BugReportService {
  static final BugReportService _instance = BugReportService._internal();
  factory BugReportService() => _instance;
  BugReportService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submit a new bug report
  Future<BugReport?> submitBugReport({
    required String title,
    required String description,
    String? stepsToReproduce,
    String? expectedBehavior,
    String? actualBehavior,
    String? errorLogs,
    String priority = 'medium',
  }) async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Collect device/app information
      final deviceInfo = await _collectDeviceInfo();

      final bugReport = BugReport(
        userId: user.id,
        title: title,
        description: description,
        stepsToReproduce: stepsToReproduce,
        expectedBehavior: expectedBehavior,
        actualBehavior: actualBehavior,
        browserInfo: deviceInfo,
        errorLogs: errorLogs,
        priority: priority,
        status: 'open',
      );

      final response = await _supabase
          .from('bug_reports')
          .insert(bugReport.toJson())
          .select()
          .single();

      return BugReport.fromJson(response);
    } catch (e) {
      debugPrint('Error submitting bug report: $e');
      rethrow;
    }
  }

  /// Get bug reports for the current user
  Future<List<BugReport>> getUserBugReports() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('bug_reports')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BugReport.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user bug reports: $e');
      return [];
    }
  }

  /// Get all bug reports (admin only)
  Future<List<BugReport>> getAllBugReports() async {
    try {
      final response = await _supabase
          .from('bug_reports')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BugReport.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all bug reports: $e');
      return [];
    }
  }

  /// Update bug report status (admin only)
  Future<BugReport?> updateBugReportStatus(String id, String status) async {
    try {
      final response = await _supabase
          .from('bug_reports')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return BugReport.fromJson(response);
    } catch (e) {
      debugPrint('Error updating bug report status: $e');
      rethrow;
    }
  }

  /// Collect device and app information for debugging
  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      Map<String, dynamic> deviceInfo = {
        'app_name': packageInfo.appName,
        'app_version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
        'package_name': packageInfo.packageName,
      };

      // Handle different platforms
      if (kIsWeb) {
        // Web platform
        try {
          final webInfo = await deviceInfoPlugin.webBrowserInfo;
          deviceInfo.addAll({
            'platform': 'Web',
            'browser_name': webInfo.browserName.name,
            'app_name': webInfo.appName,
            'app_version': webInfo.appVersion,
            'user_agent': webInfo.userAgent,
            'platform': webInfo.platform,
          });
        } catch (e) {
          debugPrint('Error collecting web browser info: $e');
          deviceInfo['error'] = 'Could not collect web browser info: $e';
        }
      } else {
        // Mobile platforms - only execute this code on non-web platforms
        try {
          // We use a separate function to handle mobile platform code
          // This prevents the dart:io code from being executed on web
          await _collectMobilePlatformInfo(deviceInfoPlugin, deviceInfo);
        } catch (e) {
          debugPrint('Error collecting mobile device info: $e');
          deviceInfo['error'] = 'Could not collect mobile device info: $e';
        }
      }

      return deviceInfo;
    } catch (e) {
      debugPrint('Error collecting device info: $e');
      return {
        'platform': kIsWeb ? 'Web' : 'Unknown',
        'error': 'Could not collect device info: $e',
      };
    }
  }

  // This function is only called on mobile platforms
  Future<void> _collectMobilePlatformInfo(DeviceInfoPlugin deviceInfoPlugin, Map<String, dynamic> deviceInfo) async {
    // Skip entirely on web platform
    if (kIsWeb) return;
    
    try {
      // For mobile platforms, we'll just add a generic entry
      // This avoids using Platform.isAndroid/isIOS which causes issues on web
      deviceInfo.addAll({
        'platform': 'Mobile',
        'note': 'Detailed device info not available in web mode'
      });
      
      // On actual mobile builds, the androidInfo and iosInfo would be collected here
      // But we're skipping that for web compatibility
    } catch (e) {
      debugPrint('Error in _collectMobilePlatformInfo: $e');
      deviceInfo['error'] = 'Error in platform-specific code: $e';
    }
  }

  /// Get priority options
  static List<String> getPriorityOptions() {
    return ['low', 'medium', 'high', 'critical'];
  }

  /// Get status options
  static List<String> getStatusOptions() {
    return ['open', 'in_progress', 'resolved', 'closed', 'duplicate'];
  }

  /// Get priority color
  static String getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return '#4CAF50'; // Green
      case 'medium':
        return '#FF9800'; // Orange
      case 'high':
        return '#F44336'; // Red
      case 'critical':
        return '#9C27B0'; // Purple
      default:
        return '#757575'; // Grey
    }
  }

  /// Get status color
  static String getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return '#2196F3'; // Blue
      case 'in_progress':
        return '#FF9800'; // Orange
      case 'resolved':
        return '#4CAF50'; // Green
      case 'closed':
        return '#757575'; // Grey
      case 'duplicate':
        return '#9E9E9E'; // Light Grey
      default:
        return '#757575'; // Grey
    }
  }
}
