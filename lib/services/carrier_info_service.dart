import 'dart:io';
import 'package:flutter/services.dart';

/// A service to handle carrier information
class CarrierInfoService {
  static final CarrierInfoService _instance = CarrierInfoService._internal();
  
  factory CarrierInfoService() {
    return _instance;
  }
  
  CarrierInfoService._internal();
  
  static CarrierInfoService get instance => _instance;
  
  final MethodChannel _channel = const MethodChannel('com.bsca/carrier_info');
  
  /// Get carrier information
  /// 
  /// Returns a map with carrier information or null if not available
  /// Possible keys: carrierName, isoCountryCode, mobileCountryCode, mobileNetworkCode
  Future<Map<String, dynamic>?> getCarrierInfo() async {
    if (!Platform.isIOS) {
      return null;
    }
    
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getCarrierInfo');
      if (result == null) {
        return null;
      }
      
      // Convert the result to a Map<String, dynamic>
      return result.map((key, value) => MapEntry(key.toString(), value));
    } on PlatformException catch (_) {
      return null;
    }
  }
  
  /// Get carrier name
  Future<String?> getCarrierName() async {
    final info = await getCarrierInfo();
    return info?['carrierName'] as String?;
  }
  
  /// Get ISO country code
  Future<String?> getIsoCountryCode() async {
    final info = await getCarrierInfo();
    return info?['isoCountryCode'] as String?;
  }
  
  /// Get mobile country code
  Future<String?> getMobileCountryCode() async {
    final info = await getCarrierInfo();
    return info?['mobileCountryCode'] as String?;
  }
  
  /// Get mobile network code
  Future<String?> getMobileNetworkCode() async {
    final info = await getCarrierInfo();
    return info?['mobileNetworkCode'] as String?;
  }
}
