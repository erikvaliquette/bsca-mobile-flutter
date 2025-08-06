import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/action_item.dart';
import '../models/action_measurement.dart';
import '../models/sdg_target.dart';

class ActionService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new action item
  static Future<ActionItem> createAction(ActionItem action) async {
    try {
      // Print the action data for debugging
      print('Creating action with data: ${action.toJson()}');
      
      // Remove the ID field if it's empty to let Supabase generate it
      final actionData = action.toJson();
      if (actionData['id'] == '') {
        actionData.remove('id');
      }
      
      print('Sending to Supabase: $actionData');
      
      final response = await _supabase
          .from('user_actions')
          .insert(actionData)
          .select()
          .single();
      
      print('Supabase response: $response');
      return ActionItem.fromJson(response);
    } catch (e) {
      print('Error in createAction: $e');
      throw Exception('Failed to create action: $e');
    }
  }

  /// Get a single action by ID
  static Future<ActionItem?> getActionById(String actionId) async {
    try {
      final response = await _supabase
          .from('user_actions')
          .select('''
            *,
            sdg_targets!sdg_target_id (*)
          ''')
          .eq('id', actionId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      // Create the action item from the response
      final action = ActionItem.fromJson(response);
      
      // If there's SDG target data in the response, parse it
      if (response['sdg_targets'] != null) {
        try {
          // Create SdgTarget from the nested data
          final sdgTarget = SdgTarget.fromJson(response['sdg_targets']);
          
          // Return action with the SDG target
          return action.copyWith(sdgTarget: sdgTarget);
        } catch (e) {
          print('Error parsing SDG target data: $e');
        }
      }
      
      return action;
    } catch (e) {
      print('Error fetching action by ID $actionId: $e');
      throw Exception('Failed to fetch action: $e');
    }
  }

  /// Get all actions for a user
  static Future<List<ActionItem>> getUserActions(String userId) async {
    try {
      // Use a foreign table join to get the SDG target data along with the action
      final response = await _supabase
          .from('user_actions')
          .select('''
            *,
            sdg_targets!sdg_target_id (*)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('Fetched user actions with SDG targets: ${response.length} actions');
      
      return (response as List).map((json) {
        // Create the action item from the response
        final action = ActionItem.fromJson(json);
        
        // If there's SDG target data in the response, parse it
        if (json['sdg_targets'] != null) {
          try {
            // Create SdgTarget from the nested data
            final sdgTarget = SdgTarget.fromJson(json['sdg_targets']);
            
            // Return action with the SDG target
            return action.copyWith(sdgTarget: sdgTarget);
          } catch (e) {
            print('Error parsing SDG target data: $e');
          }
        }
        
        return action;
      }).toList();
    } catch (e) {
      print('Error fetching user actions: $e');
      throw Exception('Failed to fetch user actions: $e');
    }
  }

  /// Get actions for a specific SDG
  static Future<List<ActionItem>> getActionsBySDG(String userId, int sdgId) async {
    try {
      final response = await _supabase
          .from('user_actions')
          .select('''
            *,
            sdg_targets!sdg_target_id (*)
          ''')
          .eq('user_id', userId)
          .eq('sdg_id', sdgId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        // Create the action item from the response
        final action = ActionItem.fromJson(json);
        
        // If there's SDG target data in the response, parse it
        if (json['sdg_targets'] != null) {
          try {
            // Create SdgTarget from the nested data
            final sdgTarget = SdgTarget.fromJson(json['sdg_targets']);
            
            // Return action with the SDG target
            return action.copyWith(sdgTarget: sdgTarget);
          } catch (e) {
            print('Error parsing SDG target data: $e');
          }
        }
        
        return action;
      }).toList();
    } catch (e) {
      print('Error fetching actions for SDG $sdgId: $e');
      throw Exception('Failed to fetch actions for SDG $sdgId: $e');
    }
  }

  /// Get actions attributed to an organization
  static Future<List<ActionItem>> getOrganizationActions(String organizationId) async {
    try {
      final response = await _supabase
          .from('user_actions')
          .select('''
            *,
            sdg_targets!sdg_target_id (*)
          ''')
          .eq('organization_id', organizationId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        // Create the action item from the response
        final action = ActionItem.fromJson(json);
        
        // If there's SDG target data in the response, parse it
        if (json['sdg_targets'] != null) {
          try {
            // Create SdgTarget from the nested data
            final sdgTarget = SdgTarget.fromJson(json['sdg_targets']);
            
            // Return action with the SDG target
            return action.copyWith(sdgTarget: sdgTarget);
          } catch (e) {
            print('Error parsing SDG target data: $e');
          }
        }
        
        return action;
      }).toList();
    } catch (e) {
      print('Error fetching organization actions: $e');
      throw Exception('Failed to fetch organization actions: $e');
    }
  }

  /// Update an existing action
  static Future<ActionItem> updateAction(ActionItem action) async {
    try {
      final updatedAction = action.copyWith(
        updatedAt: DateTime.now(),
      );

      // Prepare the data to update
      final updateData = updatedAction.toJson();
      
      // Debug log
      print('Updating action with data: $updateData');

      final response = await _supabase
          .from('user_actions')
          .update(updateData)
          .eq('id', action.id)
          .select()
          .single();

      return ActionItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update action: $e');
    }
  }

  /// Update action progress
  static Future<ActionItem> updateActionProgress(String actionId, double progress) async {
    try {
      final now = DateTime.now();
      final isCompleted = progress >= 1.0;
      
      final updateData = {
        'progress': progress,
        'is_completed': isCompleted,
        'updated_at': now.toIso8601String(),
        if (isCompleted) 'completed_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('user_actions')
          .update(updateData)
          .eq('id', actionId)
          .select()
          .single();

      return ActionItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update action progress: $e');
    }
  }

  /// Mark action as completed
  static Future<ActionItem> completeAction(String actionId) async {
    try {
      final now = DateTime.now();
      
      final updateData = {
        'progress': 1.0,
        'is_completed': true,
        'completed_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('user_actions')
          .update(updateData)
          .eq('id', actionId)
          .select()
          .single();

      return ActionItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to complete action: $e');
    }
  }

  /// Delete an action
  static Future<void> deleteAction(String actionId) async {
    try {
      await _supabase
          .from('user_actions')
          .delete()
          .eq('id', actionId);
    } catch (e) {
      throw Exception('Failed to delete action: $e');
    }
  }

  /// Attribute action to organization (for Professional+ users)
  static Future<ActionItem> attributeActionToOrganization(
    String actionId, 
    String organizationId
  ) async {
    try {
      final updateData = {
        'organization_id': organizationId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('user_actions')
          .update(updateData)
          .eq('id', actionId)
          .select()
          .single();

      return ActionItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to attribute action to organization: $e');
    }
  }

  /// Remove organization attribution from action
  static Future<ActionItem> removeOrganizationAttribution(String actionId) async {
    try {
      final updateData = {
        'organization_id': null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('user_actions')
          .update(updateData)
          .eq('id', actionId)
          .select()
          .single();

      return ActionItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to remove organization attribution: $e');
    }
  }

  /// Get action statistics for a user
  static Future<Map<String, dynamic>> getActionStatistics(String userId) async {
    try {
      final actions = await getUserActions(userId);
      
      final totalActions = actions.length;
      final completedActions = actions.where((a) => a.isCompleted).length;
      final inProgressActions = actions.where((a) => !a.isCompleted && a.progress > 0).length;
      final notStartedActions = actions.where((a) => a.progress == 0).length;
      
      // Calculate average progress
      final totalProgress = actions.fold<double>(0, (sum, action) => sum + action.progress);
      final averageProgress = totalActions > 0 ? totalProgress / totalActions : 0.0;
      
      // Group by SDG
      final Map<int, int> actionsBySDG = {};
      for (final action in actions) {
        actionsBySDG[action.sdgId] = (actionsBySDG[action.sdgId] ?? 0) + 1;
      }
      
      return {
        'totalActions': totalActions,
        'completedActions': completedActions,
        'inProgressActions': inProgressActions,
        'notStartedActions': notStartedActions,
        'averageProgress': averageProgress,
        'completionRate': totalActions > 0 ? completedActions / totalActions : 0.0,
        'actionsBySDG': actionsBySDG,
      };
    } catch (e) {
      throw Exception('Failed to get action statistics: $e');
    }
  }

  /// Get organization action statistics
  static Future<Map<String, dynamic>> getOrganizationActionStatistics(String organizationId) async {
    try {
      final actions = await getOrganizationActions(organizationId);
      
      final totalActions = actions.length;
      final completedActions = actions.where((a) => a.isCompleted).length;
      final inProgressActions = actions.where((a) => !a.isCompleted && a.progress > 0).length;
      
      // Calculate average progress
      final totalProgress = actions.fold<double>(0, (sum, action) => sum + action.progress);
      final averageProgress = totalActions > 0 ? totalProgress / totalActions : 0.0;
      
      // Group by SDG
      final Map<int, int> actionsBySDG = {};
      for (final action in actions) {
        actionsBySDG[action.sdgId] = (actionsBySDG[action.sdgId] ?? 0) + 1;
      }
      
      // Group by user
      final Map<String, int> actionsByUser = {};
      for (final action in actions) {
        actionsByUser[action.userId] = (actionsByUser[action.userId] ?? 0) + 1;
      }
      
      return {
        'totalActions': totalActions,
        'completedActions': completedActions,
        'inProgressActions': inProgressActions,
        'averageProgress': averageProgress,
        'completionRate': totalActions > 0 ? completedActions / totalActions : 0.0,
        'actionsBySDG': actionsBySDG,
        'actionsByUser': actionsByUser,
      };
    } catch (e) {
      throw Exception('Failed to get organization action statistics: $e');
    }
  }
}
