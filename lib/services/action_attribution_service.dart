import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/action_attribution_model.dart';
import '../services/supabase/supabase_client.dart';
import 'connectivity_service.dart';
import 'organization_impact_metrics_service.dart';

/// Service for managing Action organization attribution
/// Based on the travel emissions attribution pattern
class ActionAttributionService {
  static final ActionAttributionService _instance = ActionAttributionService._();
  
  ActionAttributionService._();
  
  static ActionAttributionService get instance => _instance;
  
  /// Get the Supabase client
  SupabaseClient get _client => SupabaseService.client;
  
  /// Create attribution record for Action to organization
  Future<bool> createActionOrganizationAttribution(
    String actionId, 
    String organizationId, 
    String attributedBy,
    {double? impactValue, String? impactUnit}
  ) async {
    try {
      debugPrint('🔄 Creating Action attribution: action $actionId to org $organizationId by user $attributedBy');
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - Action attribution will be synced later');
        return false;
      }
      
      // Check if an active attribution already exists
      final existingAttribution = await _client
          .from('action_organization_attribution')
          .select('id')
          .eq('action_id', actionId)
          .eq('organization_id', organizationId)
          .eq('is_active', true)
          .maybeSingle();
      
      if (existingAttribution != null) {
        debugPrint('⚠️ Active attribution already exists for this action-organization pair');
        return true; // Consider this a success since the attribution exists
      }
      
      // Create new attribution record
      final result = await _client
          .from('action_organization_attribution')
          .insert({
            'action_id': actionId,
            'organization_id': organizationId,
            'attributed_by': attributedBy,
            'attribution_date': DateTime.now().toIso8601String(),
            'is_active': true,
            if (impactValue != null) 'impact_value': impactValue,
            if (impactUnit != null) 'impact_unit': impactUnit,
          })
          .select();
      
      debugPrint('✅ Action attribution created: $result');
      
      // Update organization impact metrics
      await OrganizationImpactMetricsService.instance.updateActionCount(organizationId, 1);
      if (impactValue != null) {
        await OrganizationImpactMetricsService.instance.updateTotalImpact(organizationId, impactValue, impactUnit ?? 'mixed');
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error creating Action attribution: $e');
      return false;
    }
  }
  
  /// Deactivate attribution record for Action from organization
  Future<bool> deactivateActionOrganizationAttribution(
    String actionId, 
    String organizationId
  ) async {
    try {
      debugPrint('🔄 Deactivating Action attribution: action $actionId from org $organizationId');
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - Action de-attribution will be synced later');
        return false;
      }
      
      // Get the attribution record before deactivating to update metrics
      final existingAttribution = await _client
          .from('action_organization_attribution')
          .select('impact_value, impact_unit')
          .eq('action_id', actionId)
          .eq('organization_id', organizationId)
          .eq('is_active', true)
          .maybeSingle();
      
      // Update existing active attributions to inactive
      final result = await _client
          .from('action_organization_attribution')
          .update({'is_active': false})
          .eq('action_id', actionId)
          .eq('organization_id', organizationId)
          .eq('is_active', true)
          .select();
      
      if (result.isEmpty) {
        debugPrint('⚠️ No active attribution found to deactivate');
        return false;
      }
      
      debugPrint('✅ Action attribution deactivated: $result');
      
      // Update organization impact metrics
      await OrganizationImpactMetricsService.instance.updateActionCount(organizationId, -1);
      if (existingAttribution != null && existingAttribution['impact_value'] != null) {
        final impactValue = double.parse(existingAttribution['impact_value'].toString());
        await OrganizationImpactMetricsService.instance.updateTotalImpact(organizationId, -impactValue, existingAttribution['impact_unit'] ?? 'mixed');
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error deactivating Action attribution: $e');
      return false;
    }
  }
  
  /// Get all attributions for a specific Action
  Future<List<ActionAttributionModel>> getActionAttributions(String actionId) async {
    try {
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - cannot fetch Action attributions');
        return [];
      }
      
      final response = await _client
          .from('action_organization_attribution')
          .select('''
            *,
            organizations!organization_id(id, name, description)
          ''')
          .eq('action_id', actionId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((data) => ActionAttributionModel.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting Action attributions: $e');
      return [];
    }
  }
  
  /// Get all attributions for a specific organization
  Future<List<ActionAttributionModel>> getOrganizationActionAttributions(String organizationId) async {
    try {
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - cannot fetch organization Action attributions');
        return [];
      }
      
      final response = await _client
          .from('action_organization_attribution')
          .select('''
            *,
            actions!action_id(id, title, description, status, impact_value, impact_unit)
          ''')
          .eq('organization_id', organizationId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((data) => ActionAttributionModel.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting organization Action attributions: $e');
      return [];
    }
  }
  
  /// Handle reattribution when action changes from personal to organizational or vice versa
  /// Similar to travel emissions reattribution logic
  Future<void> handleActionReattribution({
    required String actionId,
    required String? oldOrganizationId,
    required String? newOrganizationId,
    required String attributedBy,
    double? impactValue,
    String? impactUnit,
  }) async {
    debugPrint('🔄 Handling Action reattribution:');
    debugPrint('   Old Org: $oldOrganizationId');
    debugPrint('   New Org: $newOrganizationId');
    
    try {
      // Step 1: Handle old attribution
      if (oldOrganizationId != null) {
        debugPrint('➖ Removing old attribution from organization $oldOrganizationId');
        await deactivateActionOrganizationAttribution(actionId, oldOrganizationId);
      }
      
      // Step 2: Add new attribution if needed
      if (newOrganizationId != null) {
        debugPrint('➕ Adding new attribution to organization $newOrganizationId');
        await createActionOrganizationAttribution(
          actionId, 
          newOrganizationId, 
          attributedBy,
          impactValue: impactValue,
          impactUnit: impactUnit,
        );
      }
      
      // Log the final state
      if (oldOrganizationId == null && newOrganizationId == null) {
        debugPrint('ℹ️ No attribution changes needed (personal → personal)');
      } else if (oldOrganizationId != null && newOrganizationId == null) {
        debugPrint('🏠 Action changed from organizational to personal - attribution removed');
      } else if (oldOrganizationId == null && newOrganizationId != null) {
        debugPrint('🏢 Action changed from personal to organizational - attribution added');
      } else if (oldOrganizationId == newOrganizationId) {
        debugPrint('🔄 Same organization, impact updated');
      } else {
        debugPrint('🔄 Action moved from organization $oldOrganizationId to $newOrganizationId');
      }
    } catch (e) {
      debugPrint('❌ Error handling Action reattribution: $e');
    }
  }
  
  /// Check if a user can attribute Actions to an organization
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
}
