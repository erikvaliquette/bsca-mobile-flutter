import 'dart:io';
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

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceInfo.addAll({
          'platform': 'Android',
          'device_model': androidInfo.model,
          'device_brand': androidInfo.brand,
          'device_manufacturer': androidInfo.manufacturer,
          'android_version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'device_id': androidInfo.id,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceInfo.addAll({
          'platform': 'iOS',
          'device_model': iosInfo.model,
          'device_name': iosInfo.name,
          'system_name': iosInfo.systemName,
          'system_version': iosInfo.systemVersion,
          'device_id': iosInfo.identifierForVendor,
        });
      }

      return deviceInfo;
    } catch (e) {
      debugPrint('Error collecting device info: $e');
      return {
        'platform': Platform.operatingSystem,
        'error': 'Could not collect device info: $e',
      };
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
