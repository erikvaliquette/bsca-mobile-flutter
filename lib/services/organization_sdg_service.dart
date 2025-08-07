import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bsca_mobile_flutter/services/supabase/supabase_client.dart';

/// Service for managing organization SDG focus areas in Supabase
class OrganizationSdgService {
  static final OrganizationSdgService instance = OrganizationSdgService._();
  OrganizationSdgService._();

  final _client = Supabase.instance.client;
  static const String _tableName = 'organization_sdgs';

  /// Get all SDG focus areas for an organization
  Future<List<String>> getOrganizationSdgFocusAreas(String organizationId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('sdg_id')
          .eq('organization_id', organizationId);

      if (response != null) {
        return List<String>.from(response.map((item) => item['sdg_id']));
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching organization SDG focus areas: $e');
      return [];
    }
  }

  /// Update SDG focus areas for an organization
  Future<bool> updateOrganizationSdgFocusAreas(String organizationId, List<String> sdgFocusAreas) async {
    try {
      // First, delete all existing SDG associations for this organization
      await _client
          .from(_tableName)
          .delete()
          .eq('organization_id', organizationId);
      
      // Then add all the selected SDGs
      if (sdgFocusAreas.isNotEmpty) {
        final newEntries = sdgFocusAreas.map((sdgId) => {
          'organization_id': organizationId,
          'sdg_id': sdgId,
        }).toList();
        
        await _client.from(_tableName).insert(newEntries);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating organization SDG focus areas: $e');
      return false;
    }
  }

  /// Check if a user is an admin of the organization
  Future<bool> isUserOrganizationAdmin(String userId, String organizationId) async {
    debugPrint('Checking if user $userId is admin of organization $organizationId');
    try {
      // Check new organization_members table
      debugPrint('Checking organization_members table...');
      final membershipResponse = await _client
          .from('organization_members')
          .select('role')
          .eq('user_id', userId)
          .eq('organization_id', organizationId)
          .eq('status', 'approved')
          .maybeSingle();

      debugPrint('Membership response: $membershipResponse');
      if (membershipResponse != null && membershipResponse['role'] == 'admin') {
        debugPrint('User is admin based on organization_members table');
        return true;
      }

      // BACKWARD COMPATIBILITY: Check legacy admin_ids array in organizations table
      debugPrint('Checking organizations table admin_ids array...');
      final adminResponse = await _client
          .from('organizations')
          .select('admin_ids')
          .eq('id', organizationId)
          .single();

      debugPrint('Admin response: $adminResponse');
      if (adminResponse != null && 
          adminResponse['admin_ids'] != null && 
          List<String>.from(adminResponse['admin_ids']).contains(userId)) {
        debugPrint('User is admin based on legacy admin_ids array');
        return true;
      }

      debugPrint('User is not an admin of this organization');
      return false;
    } catch (e) {
      debugPrint('Error checking if user is organization admin: $e');
      return false;
    }
  }
}
