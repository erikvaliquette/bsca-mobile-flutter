import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sdg_target_attribution_model.dart';
import '../services/supabase/supabase_client.dart';
import 'connectivity_service.dart';

/// Service for managing SDG Target organization attribution
/// Based on the travel emissions attribution pattern
class SdgTargetAttributionService {
  static final SdgTargetAttributionService _instance = SdgTargetAttributionService._();
  
  SdgTargetAttributionService._();
  
  static SdgTargetAttributionService get instance => _instance;
  
  /// Get the Supabase client
  SupabaseClient get _client => SupabaseService.client;
  
  /// Create attribution record for SDG target to organization
  Future<bool> createSdgTargetOrganizationAttribution(
    String sdgTargetId, 
    String organizationId, 
    String attributedBy
  ) async {
    try {
      debugPrint('🔄 Creating SDG target attribution: target $sdgTargetId to org $organizationId by user $attributedBy');
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - SDG target attribution will be synced later');
        return false;
      }
      
      // Check if an active attribution already exists
      final existingAttribution = await _client
          .from('sdg_target_organization_attribution')
          .select('id')
          .eq('sdg_target_id', sdgTargetId)
          .eq('organization_id', organizationId)
          .eq('is_active', true)
          .maybeSingle();
      
      if (existingAttribution != null) {
        debugPrint('⚠️ Active attribution already exists for this target-organization pair');
        return true; // Consider this a success since the attribution exists
      }
      
      // Create new attribution record
      final result = await _client
          .from('sdg_target_organization_attribution')
          .insert({
            'sdg_target_id': sdgTargetId,
            'organization_id': organizationId,
            'attributed_by': attributedBy,
            'attribution_date': DateTime.now().toIso8601String(),
            'is_active': true,
          })
          .select();
      
      debugPrint('✅ SDG target attribution created: $result');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating SDG target attribution: $e');
      return false;
    }
  }
  
  /// Deactivate attribution record for SDG target from organization
  Future<bool> deactivateSdgTargetOrganizationAttribution(
    String sdgTargetId, 
    String organizationId
  ) async {
    try {
      debugPrint('🔄 Deactivating SDG target attribution: target $sdgTargetId from org $organizationId');
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - SDG target de-attribution will be synced later');
        return false;
      }
      
      // Update existing active attributions to inactive
      final result = await _client
          .from('sdg_target_organization_attribution')
          .update({'is_active': false})
          .eq('sdg_target_id', sdgTargetId)
          .eq('organization_id', organizationId)
          .eq('is_active', true)
          .select();
      
      if (result.isEmpty) {
        debugPrint('⚠️ No active attribution found to deactivate');
        return false;
      }
      
      debugPrint('✅ SDG target attribution deactivated: $result');
      return true;
    } catch (e) {
      debugPrint('❌ Error deactivating SDG target attribution: $e');
      return false;
    }
  }
  
  /// Get all attributions for a specific SDG target
  Future<List<SdgTargetAttributionModel>> getSdgTargetAttributions(String sdgTargetId) async {
    try {
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - cannot fetch SDG target attributions');
        return [];
      }
      
      final response = await _client
          .from('sdg_target_organization_attribution')
          .select('''
            *,
            organizations!organization_id(id, name, description)
          ''')
          .eq('sdg_target_id', sdgTargetId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((data) => SdgTargetAttributionModel.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting SDG target attributions: $e');
      return [];
    }
  }
  
  /// Get all attributions for a specific organization
  Future<List<SdgTargetAttributionModel>> getOrganizationSdgTargetAttributions(String organizationId) async {
    try {
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - cannot fetch organization SDG target attributions');
        return [];
      }
      
      final response = await _client
          .from('sdg_target_organization_attribution')
          .select('''
            *,
            sdg_targets!sdg_target_id(id, target_number, description, target_value, current_value, unit)
          ''')
          .eq('organization_id', organizationId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((data) => SdgTargetAttributionModel.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting organization SDG target attributions: $e');
      return [];
    }
  }
  
  /// Check if a user can attribute SDG targets to an organization
  Future<bool> canUserAttributeToOrganization(String userId, String organizationId) async {
    try {
      if (!ConnectivityService.instance.isConnected) {
        return false;
      }
      
      final membership = await _client
          .from('organization_members')
          .select('role, status')
          .eq('user_id', userId)
          .eq('organization_id', organizationId)
          .eq('status', 'approved')
          .maybeSingle();
      
      return membership != null;
    } catch (e) {
      debugPrint('❌ Error checking user attribution permissions: $e');
      return false;
    }
  }
  
  /// Get user's organizations that they can attribute SDG targets to
  Future<List<Map<String, dynamic>>> getUserAttributableOrganizations(String userId) async {
    try {
      if (!ConnectivityService.instance.isConnected) {
        return [];
      }
      
      final response = await _client
          .from('organization_members')
          .select('''
            organizations!organization_id(id, name, description, logo_url)
          ''')
          .eq('user_id', userId)
          .eq('status', 'approved');
      
      return (response as List)
          .map((data) => data['organizations'] as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting user attributable organizations: $e');
      return [];
    }
  }
}
