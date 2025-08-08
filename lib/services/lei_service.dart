import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/organization_model.dart';

class LEIService {
  static const String _leiApiBase = 'https://api.gleif.org/api/v1';
  
  /// Search for organization by LEI code
  static Future<LEIDetails?> searchByLEI(String leiCode) async {
    if (leiCode.length != 20) {
      throw ArgumentError('LEI code must be exactly 20 characters');
    }

    try {
      // Fetch LEI record
      final leiResponse = await http.get(
        Uri.parse('$_leiApiBase/lei-records?filter[lei]=$leiCode'),
        headers: {'Accept': 'application/vnd.api+json'},
      );

      if (!(leiResponse.statusCode >= 200 && leiResponse.statusCode < 300)) {
        throw Exception('LEI API error: ${leiResponse.statusCode} ${leiResponse.reasonPhrase}');
      }

      final leiData = jsonDecode(leiResponse.body);

      // Validate JSON API response structure
      if (leiData['data'] == null || 
          leiData['data'] is! List || 
          (leiData['data'] as List).isEmpty) {
        return null; // No organization found
      }

      final leiRecord = leiData['data'][0];
      if (leiRecord['attributes'] == null || 
          leiRecord['attributes']['entity'] == null) {
        throw Exception('Invalid LEI record format');
      }

      final entity = leiRecord['attributes']['entity'];

      // Check vLEI status separately
      Map<String, dynamic>? vLEICredentials;
      String vleiStatus = 'none';
      DateTime? vleiVerificationDate;

      try {
        final vLEIResponse = await http.get(
          Uri.parse('$_leiApiBase/vlei-credentials?filter[lei]=$leiCode'),
          headers: {'Accept': 'application/vnd.api+json'},
        );

        if (vLEIResponse.statusCode == 200) {
          final vLEIData = jsonDecode(vLEIResponse.body);
          if (vLEIData['data'] != null && 
              vLEIData['data'] is List && 
              (vLEIData['data'] as List).isNotEmpty) {
            final vLEIRecord = vLEIData['data'][0];
            vleiStatus = 'verified';
            vleiVerificationDate = DateTime.now();
            vLEICredentials = {
              'qvi': vLEIRecord['attributes']?['qvi'],
              'issuanceDate': vLEIRecord['attributes']?['issuanceDate'],
              'expirationDate': vLEIRecord['attributes']?['expirationDate'],
            };
          }
        }
      } catch (vLEIError) {
        debugPrint('Warning: Error checking vLEI status: $vLEIError');
        // Continue with LEI data even if vLEI check fails
      }

      // Extract address information
      OrganizationAddress? address;
      if (entity['legalAddress'] != null) {
        final legalAddress = entity['legalAddress'];
        address = OrganizationAddress(
          streetAddress: legalAddress['addressLines']?[0],
          city: legalAddress['city'],
          stateProvince: legalAddress['region'],
          country: legalAddress['country'],
          postalCode: legalAddress['postalCode'],
        );
      }

      return LEIDetails(
        name: entity['legalName']?['name'] ?? '',
        leiCode: leiCode,
        address: address,
        status: leiRecord['attributes']['status'] ?? 'UNKNOWN',
        registrationAuthority: entity['registrationAuthority']?['registrationAuthorityID'],
        lastUpdateDate: leiRecord['attributes']['lastUpdateDate'],
        vleiStatus: vleiStatus,
        vleiCredentials: vLEICredentials,
        vleiVerificationDate: vleiVerificationDate,
      );
    } catch (e) {
      debugPrint('Error looking up LEI: $e');
      rethrow;
    }
  }

  /// Check vLEI status for a given LEI code
  static Future<VLEIStatus?> checkVLEIStatus(String leiCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_leiApiBase/vlei-credentials?filter[lei]=$leiCode'),
        headers: {'Accept': 'application/vnd.api+json'},
      );

      if (!(response.statusCode >= 200 && response.statusCode < 300)) {
        throw Exception('vLEI API error: ${response.statusCode} ${response.reasonPhrase}');
      }

      final data = jsonDecode(response.body);

      if (data['data'] == null || 
          data['data'] is! List || 
          (data['data'] as List).isEmpty) {
        return null;
      }

      final vLEIRecord = data['data'][0];
      return VLEIStatus(
        credentials: {
          'qvi': vLEIRecord['attributes']?['qvi'],
          'issuanceDate': vLEIRecord['attributes']?['issuanceDate'],
          'expirationDate': vLEIRecord['attributes']?['expirationDate'],
        },
        verificationDate: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error checking vLEI status: $e');
      return null;
    }
  }
}

class LEIDetails {
  final String name;
  final String leiCode;
  final OrganizationAddress? address;
  final String status;
  final String? registrationAuthority;
  final String? lastUpdateDate;
  final String vleiStatus;
  final Map<String, dynamic>? vleiCredentials;
  final DateTime? vleiVerificationDate;

  LEIDetails({
    required this.name,
    required this.leiCode,
    this.address,
    required this.status,
    this.registrationAuthority,
    this.lastUpdateDate,
    required this.vleiStatus,
    this.vleiCredentials,
    this.vleiVerificationDate,
  });
}

class VLEIStatus {
  final Map<String, dynamic> credentials;
  final DateTime verificationDate;

  VLEIStatus({
    required this.credentials,
    required this.verificationDate,
  });
}

// Extension removed as we're using direct status code checks
