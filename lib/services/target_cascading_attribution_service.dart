import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/connectivity_service.dart';
import '../services/organization_impact_metrics_service.dart';

/// Service for handling cascading attribution from SDG Targets to Actions and Activities
/// When a target's organization attribution changes, all associated actions and activities
/// automatically inherit the same attribution
class TargetCascadingAttributionService {
  static final TargetCascadingAttributionService _instance = TargetCascadingAttributionService._internal();
  factory TargetCascadingAttributionService.instance() => _instance;
  TargetCascadingAttributionService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// Handle target attribution change with cascading to actions and activities
  /// This is the main method called when a target's organization attribution changes
  Future<bool> handleTargetAttributionChange({
    required String targetId,
    required String? oldOrganizationId,
    required String? newOrganizationId,
    required String attributedBy,
  }) async {
    try {
      debugPrint('🎯 Handling Target attribution change:');
      debugPrint('   Target: $targetId');
      debugPrint('   Old Org: $oldOrganizationId');
      debugPrint('   New Org: $newOrganizationId');
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - Target attribution change will be synced later');
        return false;
      }

      // Step 1: Handle target-level attribution
      await _handleTargetAttribution(targetId, oldOrganizationId, newOrganizationId, attributedBy);
      
      // Step 2: Cascade to actions
      await _cascadeToActions(targetId, oldOrganizationId, newOrganizationId, attributedBy);
      
      // Step 3: Cascade to activities (through actions)
      await _cascadeToActivities(targetId, oldOrganizationId, newOrganizationId, attributedBy);
      
      // Step 4: Update organization metrics
      await _updateOrganizationMetrics(oldOrganizationId, newOrganizationId, targetId);
      
      debugPrint('✅ Target attribution cascading completed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error handling target attribution change: $e');
      return false;
    }
  }

  /// Handle target-level attribution in the junction table
  Future<void> _handleTargetAttribution(
    String targetId, 
    String? oldOrganizationId, 
    String? newOrganizationId, 
    String attributedBy
  ) async {
    // Deactivate old attribution if exists
    if (oldOrganizationId != null) {
      await _client
          .from('sdg_target_organization_attribution')
          .update({'is_active': false})
          .eq('sdg_target_id', targetId)
          .eq('organization_id', oldOrganizationId)
          .eq('is_active', true);
      
      debugPrint('🔄 Deactivated old target attribution from org $oldOrganizationId');
    }
    
    // Create new attribution if needed
    if (newOrganizationId != null) {
      // Check if attribution already exists
      final existingAttribution = await _client
          .from('sdg_target_organization_attribution')
          .select('id')
          .eq('sdg_target_id', targetId)
          .eq('organization_id', newOrganizationId)
          .eq('is_active', true)
          .maybeSingle();
      
      if (existingAttribution == null) {
        await _client
            .from('sdg_target_organization_attribution')
            .insert({
              'sdg_target_id': targetId,
              'organization_id': newOrganizationId,
              'attributed_by': attributedBy,
              'attribution_date': DateTime.now().toIso8601String(),
              'is_active': true,
            });
        
        debugPrint('✅ Created new target attribution to org $newOrganizationId');
      }
    }
  }

  /// Cascade attribution changes to all actions under the target
  Future<void> _cascadeToActions(
    String targetId, 
    String? oldOrganizationId, 
    String? newOrganizationId, 
    String attributedBy
  ) async {
    try {
      // Get all actions for this target
      final actions = await _client
          .from('actions')
          .select('id')
          .eq('sdg_target_id', targetId);
      
      if (actions.isEmpty) {
        debugPrint('ℹ️ No actions found for target $targetId - no action cascading needed');
        return;
      }
      
      debugPrint('📋 Found ${actions.length} actions to cascade attribution to');
      
      for (final action in actions) {
        final actionId = action['id'] as String;
        
        // Deactivate old action attribution if exists
        if (oldOrganizationId != null) {
          await _client
              .from('action_organization_attribution')
              .update({'is_active': false})
              .eq('action_id', actionId)
              .eq('organization_id', oldOrganizationId)
              .eq('is_active', true);
        }
        
        // Create new action attribution if needed
        if (newOrganizationId != null) {
          final existingAttribution = await _client
              .from('action_organization_attribution')
              .select('id')
              .eq('action_id', actionId)
              .eq('organization_id', newOrganizationId)
              .eq('is_active', true)
              .maybeSingle();
          
          if (existingAttribution == null) {
            await _client
                .from('action_organization_attribution')
                .insert({
                  'action_id': actionId,
                  'organization_id': newOrganizationId,
                  'attributed_by': attributedBy,
                  'attribution_date': DateTime.now().toIso8601String(),
                  'is_active': true,
                });
          }
        }
      }
      
      debugPrint('✅ Cascaded attribution to ${actions.length} actions');
    } catch (e) {
      debugPrint('❌ Error cascading to actions: $e');
    }
  }

  /// Cascade attribution changes to all activities under the target's actions
  Future<void> _cascadeToActivities(
    String targetId, 
    String? oldOrganizationId, 
    String? newOrganizationId, 
    String attributedBy
  ) async {
    try {
      // Get all activities for actions under this target
      final activities = await _client
          .from('action_activities')
          .select('id')
          .inFilter('action_id', await _getActionIdsForTarget(targetId));
      
      if (activities.isEmpty) {
        debugPrint('ℹ️ No activities found for target $targetId - no activity cascading needed');
        return;
      }
      
      debugPrint('📋 Found ${activities.length} activities to cascade attribution to');
      
      for (final activity in activities) {
        final activityId = activity['id'] as String;
        
        // Deactivate old activity attribution if exists
        if (oldOrganizationId != null) {
          await _client
              .from('activity_organization_attribution')
              .update({'is_active': false})
              .eq('activity_id', activityId)
              .eq('organization_id', oldOrganizationId)
              .eq('is_active', true);
        }
        
        // Create new activity attribution if needed
        if (newOrganizationId != null) {
          final existingAttribution = await _client
              .from('activity_organization_attribution')
              .select('id')
              .eq('activity_id', activityId)
              .eq('organization_id', newOrganizationId)
              .eq('is_active', true)
              .maybeSingle();
          
          if (existingAttribution == null) {
            await _client
                .from('activity_organization_attribution')
                .insert({
                  'activity_id': activityId,
                  'organization_id': newOrganizationId,
                  'attributed_by': attributedBy,
                  'attribution_date': DateTime.now().toIso8601String(),
                  'is_active': true,
                });
          }
        }
      }
      
      debugPrint('✅ Cascaded attribution to ${activities.length} activities');
    } catch (e) {
      debugPrint('❌ Error cascading to activities: $e');
    }
  }

  /// Helper method to get action IDs for a target
  Future<List<String>> _getActionIdsForTarget(String targetId) async {
    final actions = await _client
        .from('actions')
        .select('id')
        .eq('sdg_target_id', targetId);
    
    return actions.map((a) => a['id'] as String).toList();
  }

  /// Update organization impact metrics after attribution changes
  Future<void> _updateOrganizationMetrics(
    String? oldOrganizationId, 
    String? newOrganizationId, 
    String targetId
  ) async {
    try {
      // Get counts for metric updates
      final actionCount = await _getActionCountForTarget(targetId);
      final activityCount = await _getActivityCountForTarget(targetId);
      
      // Update old organization metrics (subtract)
      if (oldOrganizationId != null) {
        await OrganizationImpactMetricsService.instance.updateSdgTargetsCount(oldOrganizationId, -1);
        await OrganizationImpactMetricsService.instance.updateActionCount(oldOrganizationId, -actionCount);
        await OrganizationImpactMetricsService.instance.updateActivityCount(oldOrganizationId, -activityCount);
        debugPrint('📉 Updated old organization metrics for org $oldOrganizationId');
      }
      
      // Update new organization metrics (add)
      if (newOrganizationId != null) {
        await OrganizationImpactMetricsService.instance.updateSdgTargetsCount(newOrganizationId, 1);
        await OrganizationImpactMetricsService.instance.updateActionCount(newOrganizationId, actionCount);
        await OrganizationImpactMetricsService.instance.updateActivityCount(newOrganizationId, activityCount);
        debugPrint('📈 Updated new organization metrics for org $newOrganizationId');
      }
    } catch (e) {
      debugPrint('❌ Error updating organization metrics: $e');
    }
  }

  /// Get action count for a target
  Future<int> _getActionCountForTarget(String targetId) async {
    final count = await _client
        .from('actions')
        .count()
        .eq('sdg_target_id', targetId);
    return count ?? 0;
  }

  /// Get activity count for a target (through actions)
  Future<int> _getActivityCountForTarget(String targetId) async {
    final actionIds = await _getActionIdsForTarget(targetId);
    if (actionIds.isEmpty) return 0;
    
    final count = await _client
        .from('action_activities')
        .count()
        .inFilter('action_id', actionIds);
    return count ?? 0;
  }

  /// Get current attribution for a target
  Future<String?> getTargetAttribution(String targetId) async {
    try {
      final attribution = await _client
          .from('sdg_target_organization_attribution')
          .select('organization_id')
          .eq('sdg_target_id', targetId)
          .eq('is_active', true)
          .maybeSingle();
      
      return attribution?['organization_id'] as String?;
    } catch (e) {
      debugPrint('❌ Error getting target attribution: $e');
      return null;
    }
  }

  /// Check if a target has organizational attribution
  Future<bool> isTargetAttributedToOrganization(String targetId) async {
    final attribution = await getTargetAttribution(targetId);
    return attribution != null;
  }
}
