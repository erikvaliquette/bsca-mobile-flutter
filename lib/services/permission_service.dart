import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;

/// A service to handle app permissions
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  
  factory PermissionService() {
    return _instance;
  }
  
  PermissionService._internal();
  
  static PermissionService get instance => _instance;
  
  /// Request a specific permission
  Future<permission_handler.PermissionStatus> requestPermission(permission_handler.Permission permission) async {
    return await permission.request();
  }
  
  /// Check if a specific permission is granted
  Future<bool> hasPermission(permission_handler.Permission permission) async {
    final status = await permission.status;
    // Consider both fully granted and limited (e.g., "While Using") as valid permissions
    return status.isGranted || status.isLimited;
  }
  
  /// Open app settings
  Future<bool> openSettings() async {
    return await permission_handler.openAppSettings();
  }
  
  /// Handle permission request with UI feedback
  Future<bool> handlePermission(
    BuildContext context,
    permission_handler.Permission permission,
    String permissionName,
    String rationaleMessage,
  ) async {
    // Check current status
    final status = await permission.status;
    
    // If already granted or limited (e.g., "While Using"), return true
    if (status.isGranted || status.isLimited) {
      return true;
    }
    
    // If denied but can request, show rationale and request
    if (status.isDenied) {
      // Show rationale dialog
      final shouldRequest = await _showRationaleDialog(
        context,
        permissionName,
        rationaleMessage,
      );
      
      if (shouldRequest) {
        final result = await permission.request();
        // Accept both granted and limited permissions as valid
        return result.isGranted || result.isLimited;
      }
      
      return false;
    }
    
    // If permanently denied, show settings dialog
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(
        context,
        permissionName,
      );
      return false;
    }
    
    // For other cases (restricted, etc.)
    return false;
  }
  
  /// Show a dialog explaining why the permission is needed
  Future<bool> _showRationaleDialog(
    BuildContext context,
    String permissionName,
    String rationaleMessage,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(rationaleMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('DENY'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  /// Show a dialog to direct the user to app settings
  Future<void> _showSettingsDialog(
    BuildContext context,
    String permissionName,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          'The $permissionName permission has been permanently denied. '
          'Please enable it in the app settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openSettings();
            },
            child: const Text('SETTINGS'),
          ),
        ],
      ),
    );
  }
}
