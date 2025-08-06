import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/action_activity.dart';

class ActionActivityService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new activity for an action
  static Future<ActionActivity> createActivity(ActionActivity activity) async {
    try {
      final response = await _supabase
          .from('action_activities')
          .insert(activity.toJson())
          .select()
          .single();

      return ActionActivity.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create activity: $e');
    }
  }

  /// Get all activities for a specific action
  static Future<List<ActionActivity>> getActivitiesForAction(String actionId) async {
    try {
      final response = await _supabase
          .from('action_activities')
          .select()
          .eq('action_id', actionId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ActionActivity.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load activities: $e');
    }
  }

  /// Get activities for a specific user
  static Future<List<ActionActivity>> getActivitiesForUser(String userId) async {
    try {
      final response = await _supabase
          .from('action_activities')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ActionActivity.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load user activities: $e');
    }
  }

  /// Get activities for an organization
  static Future<List<ActionActivity>> getActivitiesForOrganization(String organizationId) async {
    try {
      final response = await _supabase
          .from('action_activities')
          .select()
          .eq('organization_id', organizationId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ActionActivity.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load organization activities: $e');
    }
  }

  /// Update an existing activity
  static Future<ActionActivity> updateActivity(ActionActivity activity) async {
    try {
      final response = await _supabase
          .from('action_activities')
          .update(activity.toJson())
          .eq('id', activity.id)
          .select()
          .single();

      return ActionActivity.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update activity: $e');
    }
  }

  /// Delete an activity
  static Future<void> deleteActivity(String activityId) async {
    try {
      await _supabase
          .from('action_activities')
          .delete()
          .eq('id', activityId);
    } catch (e) {
      throw Exception('Failed to delete activity: $e');
    }
  }

  /// Mark activity as completed
  static Future<ActionActivity> completeActivity(String activityId) async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from('action_activities')
          .update({
            'status': 'completed',
            'completed_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', activityId)
          .select()
          .single();

      return ActionActivity.fromJson(response);
    } catch (e) {
      throw Exception('Failed to complete activity: $e');
    }
  }

  /// Update activity verification status
  static Future<ActionActivity> updateVerificationStatus(
    String activityId,
    String status, {
    String? verifiedBy,
  }) async {
    try {
      final now = DateTime.now();
      final updateData = {
        'verification_status': status,
        'updated_at': now.toIso8601String(),
      };

      if (status == 'verified' && verifiedBy != null) {
        updateData['verified_by'] = verifiedBy;
        updateData['verified_at'] = now.toIso8601String();
      }

      final response = await _supabase
          .from('action_activities')
          .update(updateData)
          .eq('id', activityId)
          .select()
          .single();

      return ActionActivity.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update verification status: $e');
    }
  }

  /// Add evidence to an activity
  static Future<ActionActivity> addEvidence(String activityId, List<String> evidenceUrls) async {
    try {
      final response = await _supabase
          .from('action_activities')
          .update({
            'evidence_urls': evidenceUrls,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', activityId)
          .select()
          .single();

      return ActionActivity.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add evidence: $e');
    }
  }

  /// Get activities that need verification (for admins/verifiers)
  static Future<List<ActionActivity>> getActivitiesForVerification({
    String? organizationId,
  }) async {
    try {
      var query = _supabase
          .from('action_activities')
          .select()
          .eq('verification_status', 'pending')
          .not('evidence_urls', 'is', null);

      if (organizationId != null) {
        query = query.eq('organization_id', organizationId);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => ActionActivity.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load activities for verification: $e');
    }
  }

  /// Get activity statistics for an action
  static Future<Map<String, dynamic>> getActivityStats(String actionId) async {
    try {
      final activities = await getActivitiesForAction(actionId);
      
      final totalActivities = activities.length;
      final completedActivities = activities.where((a) => a.isCompleted).length;
      final verifiedActivities = activities.where((a) => a.isVerified).length;
      final totalImpact = activities
          .where((a) => a.impactValue != null)
          .fold(0.0, (sum, a) => sum + a.impactValue!);

      return {
        'total_activities': totalActivities,
        'completed_activities': completedActivities,
        'verified_activities': verifiedActivities,
        'completion_rate': totalActivities > 0 ? completedActivities / totalActivities : 0.0,
        'verification_rate': totalActivities > 0 ? verifiedActivities / totalActivities : 0.0,
        'total_impact': totalImpact,
        'impact_unit': activities.firstWhere(
          (a) => a.impactUnit != null,
          orElse: () => ActionActivity(
            id: '',
            actionId: '',
            title: '',
            description: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: '',
          ),
        ).impactUnit,
      };
    } catch (e) {
      throw Exception('Failed to get activity stats: $e');
    }
  }
}
