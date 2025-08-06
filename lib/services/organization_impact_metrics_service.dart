import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/organization_impact_metrics_model.dart';
import '../services/supabase/supabase_client.dart';
import 'connectivity_service.dart';

/// Service for managing organization impact metrics
/// Tracks aggregated sustainability data for organizations
class OrganizationImpactMetricsService {
  static final OrganizationImpactMetricsService _instance = OrganizationImpactMetricsService._();
  
  OrganizationImpactMetricsService._();
  
  static OrganizationImpactMetricsService get instance => _instance;
  
  /// Get the Supabase client
  SupabaseClient get _client => SupabaseService.client;
  
  /// Get or create organization impact metrics for current year
  Future<OrganizationImpactMetricsModel?> getOrCreateMetrics(String organizationId, {int? year}) async {
    try {
      final targetYear = year ?? DateTime.now().year;
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - cannot fetch organization impact metrics');
        return null;
      }
      
      // Try to get existing metrics
      final existingMetrics = await _client
          .from('organization_impact_metrics')
          .select()
          .eq('organization_id', organizationId)
          .eq('year', targetYear)
          .maybeSingle();
      
      if (existingMetrics != null) {
        return OrganizationImpactMetricsModel.fromJson(existingMetrics);
      }
      
      // Create new metrics record
      final newMetrics = await _client
          .from('organization_impact_metrics')
          .insert({
            'organization_id': organizationId,
            'year': targetYear,
            'sdg_targets_count': 0,
            'actions_count': 0,
            'activities_count': 0,
            'completed_actions_count': 0,
            'total_impact_value': 0,
            'impact_unit': 'mixed',
          })
          .select()
          .single();
      
      debugPrint('✅ Created new organization impact metrics for $organizationId');
      return OrganizationImpactMetricsModel.fromJson(newMetrics);
    } catch (e) {
      debugPrint('❌ Error getting/creating organization impact metrics: $e');
      return null;
    }
  }
  
  /// Update SDG targets count
  Future<bool> updateSdgTargetsCount(String organizationId, int delta, {int? year}) async {
    return _updateMetricField(organizationId, 'sdg_targets_count', delta, year: year);
  }
  
  /// Update actions count
  Future<bool> updateActionCount(String organizationId, int delta, {int? year}) async {
    return _updateMetricField(organizationId, 'actions_count', delta, year: year);
  }
  
  /// Update activities count
  Future<bool> updateActivityCount(String organizationId, int delta, {int? year}) async {
    return _updateMetricField(organizationId, 'activities_count', delta, year: year);
  }
  
  /// Update completed actions count
  Future<bool> updateCompletedActionsCount(String organizationId, int delta, {int? year}) async {
    return _updateMetricField(organizationId, 'completed_actions_count', delta, year: year);
  }
  
  /// Update total impact value
  Future<bool> updateTotalImpact(String organizationId, double delta, String unit, {int? year}) async {
    try {
      final targetYear = year ?? DateTime.now().year;
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - impact update will be synced later');
        return false;
      }
      
      // Get or create metrics
      final metrics = await getOrCreateMetrics(organizationId, year: targetYear);
      if (metrics == null) {
        debugPrint('❌ Could not get/create metrics for impact update');
        return false;
      }
      
      final newTotalImpact = (metrics.totalImpactValue + delta).clamp(0.0, double.infinity);
      final newUnit = metrics.impactUnit == 'mixed' || unit == 'mixed' ? 'mixed' : unit;
      
      debugPrint('📈 Updating total impact: ${metrics.totalImpactValue} + $delta = $newTotalImpact $newUnit');
      
      final result = await _client
          .from('organization_impact_metrics')
          .update({
            'total_impact_value': newTotalImpact,
            'impact_unit': newUnit,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', metrics.id)
          .select();
      
      debugPrint('✅ Total impact updated: $result');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating total impact: $e');
      return false;
    }
  }
  
  /// Get organization impact metrics for a specific year
  Future<OrganizationImpactMetricsModel?> getMetrics(String organizationId, {int? year}) async {
    try {
      final targetYear = year ?? DateTime.now().year;
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - cannot fetch organization impact metrics');
        return null;
      }
      
      final response = await _client
          .from('organization_impact_metrics')
          .select()
          .eq('organization_id', organizationId)
          .eq('year', targetYear)
          .maybeSingle();
      
      if (response == null) {
        return null;
      }
      
      return OrganizationImpactMetricsModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error getting organization impact metrics: $e');
      return null;
    }
  }
  
  /// Get organization impact metrics for multiple years
  Future<List<OrganizationImpactMetricsModel>> getMetricsHistory(String organizationId, {int? startYear, int? endYear}) async {
    try {
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - cannot fetch organization impact metrics history');
        return [];
      }
      
      var query = _client
          .from('organization_impact_metrics')
          .select()
          .eq('organization_id', organizationId);
      
      if (startYear != null) {
        query = query.gte('year', startYear);
      }
      
      if (endYear != null) {
        query = query.lte('year', endYear);
      }
      
      final response = await query.order('year', ascending: false);
      
      return (response as List)
          .map((data) => OrganizationImpactMetricsModel.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting organization impact metrics history: $e');
      return [];
    }
  }
  
  /// Recalculate all metrics for an organization (useful for data consistency)
  Future<bool> recalculateMetrics(String organizationId, {int? year}) async {
    try {
      final targetYear = year ?? DateTime.now().year;
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - cannot recalculate metrics');
        return false;
      }
      
      debugPrint('🔄 Recalculating metrics for organization $organizationId, year $targetYear');
      
      // Count SDG targets
      final sdgTargetsCount = await _client
          .from('sdg_target_organization_attribution')
          .count()
          .eq('organization_id', organizationId)
          .eq('is_active', true);
      
      // Count actions
      final actionsCount = await _client
          .from('action_organization_attribution')
          .count()
          .eq('organization_id', organizationId)
          .eq('is_active', true);
      
      // Count activities
      final activitiesCount = await _client
          .from('activity_organization_attribution')
          .count()
          .eq('organization_id', organizationId)
          .eq('is_active', true);
      
      // Count completed actions
      final completedActionsResponse = await _client
          .from('action_organization_attribution')
          .select('''
            actions!action_id(status)
          ''')
          .eq('organization_id', organizationId)
          .eq('is_active', true);
      
      final completedActionsCount = (completedActionsResponse as List)
          .where((item) => item['actions']?['status'] == 'completed')
          .length;
      
      // Calculate total impact
      final impactResponse = await _client
          .from('action_organization_attribution')
          .select('impact_value, impact_unit')
          .eq('organization_id', organizationId)
          .eq('is_active', true)
          .not('impact_value', 'is', null);
      
      double totalImpact = 0;
      for (final item in impactResponse as List) {
        if (item['impact_value'] != null) {
          totalImpact += double.parse(item['impact_value'].toString());
        }
      }
      
      // Update or create metrics
      final metrics = await getOrCreateMetrics(organizationId, year: targetYear);
      if (metrics == null) {
        debugPrint('❌ Could not get/create metrics for recalculation');
        return false;
      }
      
      final result = await _client
          .from('organization_impact_metrics')
          .update({
            'sdg_targets_count': sdgTargetsCount ?? 0,
            'actions_count': actionsCount ?? 0,
            'activities_count': activitiesCount ?? 0,
            'completed_actions_count': completedActionsCount,
            'total_impact_value': totalImpact,
            'impact_unit': totalImpact > 0 ? 'mixed' : 'mixed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', metrics.id)
          .select();
      
      debugPrint('✅ Metrics recalculated: $result');
      return true;
    } catch (e) {
      debugPrint('❌ Error recalculating metrics: $e');
      return false;
    }
  }
  
  /// Helper method to update a specific metric field
  Future<bool> _updateMetricField(String organizationId, String fieldName, int delta, {int? year}) async {
    try {
      final targetYear = year ?? DateTime.now().year;
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - metric update will be synced later');
        return false;
      }
      
      // Get or create metrics
      final metrics = await getOrCreateMetrics(organizationId, year: targetYear);
      if (metrics == null) {
        debugPrint('❌ Could not get/create metrics for field update');
        return false;
      }
      
      // Get current value
      final currentValue = _getFieldValue(metrics, fieldName);
      final newValue = (currentValue + delta).clamp(0, double.infinity).toInt();
      
      debugPrint('📈 Updating $fieldName: $currentValue + $delta = $newValue');
      
      final result = await _client
          .from('organization_impact_metrics')
          .update({
            fieldName: newValue,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', metrics.id)
          .select();
      
      debugPrint('✅ $fieldName updated: $result');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating $fieldName: $e');
      return false;
    }
  }
  
  /// Helper method to get field value from metrics model
  int _getFieldValue(OrganizationImpactMetricsModel metrics, String fieldName) {
    switch (fieldName) {
      case 'sdg_targets_count':
        return metrics.sdgTargetsCount;
      case 'actions_count':
        return metrics.actionsCount;
      case 'activities_count':
        return metrics.activitiesCount;
      case 'completed_actions_count':
        return metrics.completedActionsCount;
      default:
        return 0;
    }
  }
}
