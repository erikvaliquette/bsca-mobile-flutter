import 'dart:io';
import 'package:flutter/services.dart';

/// A service to handle phone-related permissions
class PhonePermissionService {
  static final PhonePermissionService _instance = PhonePermissionService._internal();
  
  factory PhonePermissionService() {
    return _instance;
  }
  
  PhonePermissionService._internal();
  
  static PhonePermissionService get instance => _instance;
  
  final MethodChannel _channel = const MethodChannel('com.bsca/phone_permission');
  
  /// Check if phone permission is granted
  /// 
  /// Returns true if permission is granted, false otherwise
  /// On non-iOS platforms, this always returns true
  Future<bool> checkPhonePermission() async {
    if (!Platform.isIOS) {
      return true;
    }
    
    try {
      final result = await _channel.invokeMethod<bool>('checkPhonePermission');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
