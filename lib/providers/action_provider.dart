import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/action_item.dart';
import '../models/action_measurement.dart';
import '../services/action_service.dart';
import '../services/action_measurement_service.dart';

class ActionProvider with ChangeNotifier {
  List<ActionItem> _actions = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistics;

  List<ActionItem> get actions => _actions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get statistics => _statistics;

  /// Get actions for a specific SDG
  List<ActionItem> getActionsBySDG(int sdgId) {
    return _actions.where((action) => action.sdgId == sdgId).toList();
  }
  
  /// Get a specific action by ID
  ActionItem? getActionById(String id) {
    try {
      return _actions.firstWhere((action) => action.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get personal actions (not attributed to any organization)
  List<ActionItem> getPersonalActions() {
    return _actions.where((action) => action.organizationId == null).toList();
  }

  /// Get organization actions
  List<ActionItem> getOrganizationActions(String organizationId) {
    return _actions.where((action) => action.organizationId == organizationId).toList();
  }

  /// Get completed actions
  List<ActionItem> getCompletedActions() {
    return _actions.where((action) => action.isCompleted).toList();
  }

  /// Get in-progress actions
  List<ActionItem> getInProgressActions() {
    return _actions.where((action) => !action.isCompleted && action.progress > 0).toList();
  }

  /// Get not started actions
  List<ActionItem> getNotStartedActions() {
    return _actions.where((action) => action.progress == 0).toList();
  }

  /// Load all actions for a user
  Future<void> loadUserActions(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final actions = await ActionService.getUserActions(userId);
      _actions = actions;
      
      // Load statistics
      final stats = await ActionService.getActionStatistics(userId);
      _statistics = stats;
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Create a new action
  Future<ActionItem?> createAction({
    required String userId,
    required int sdgId,
    required String title,
    required String description,
    required String category,
    String? organizationId,
    DateTime? dueDate,
    String priority = 'medium',
    Map<String, dynamic>? metadata,
    String? sdgTargetId,
  }) async {
    try {
      print('ActionProvider.createAction called with title: $title, sdgId: $sdgId');
      final now = DateTime.now();
      
      // Create a map directly instead of using ActionItem constructor
      final actionData = {
        'user_id': userId,
        'organization_id': organizationId,
        'sdg_id': sdgId,
        'title': title,
        'description': description,
        'category': category,
        'progress': 0.0,
        'is_completed': false,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'priority': priority,
      };
      
      // Only add sdg_target_id if it's provided and not null
      if (sdgTargetId != null && sdgTargetId.isNotEmpty) {
        actionData['sdg_target_id'] = sdgTargetId;
      }
      
      // Remove null values to avoid database errors
      actionData.removeWhere((key, value) => value == null);
      
      // Only add optional fields if they're not null
      if (dueDate != null) {
        actionData['due_date'] = dueDate.toIso8601String();
      }
      
      if (metadata != null) {
        actionData['metadata'] = metadata;
      }
      
      print('Sending action data: $actionData');
      
      
      // Insert directly using Supabase client
      Map<String, dynamic> responseData;
      try {
        final response = await Supabase.instance.client
            .from('user_actions')
            .insert(actionData)
            .select()
            .maybeSingle();
        
        if (response == null) {
          throw Exception('No response returned from insert operation');
        }
        
        print('Supabase response: $response');
        responseData = response;
      } catch (insertError) {
        print('Insert error in ActionProvider: $insertError');
        throw Exception('Failed to create action: $insertError');
      }
      
      final createdAction = ActionItem.fromJson(responseData);
      _actions.insert(0, createdAction); // Add to beginning of list
      
      // Refresh statistics
      await _refreshStatistics(userId);
      
      notifyListeners();
      return createdAction;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Update an existing action
  Future<bool> updateAction(ActionItem action) async {
    try {
      final updatedAction = await ActionService.updateAction(action);
      
      final index = _actions.indexWhere((a) => a.id == action.id);
      if (index != -1) {
        _actions[index] = updatedAction;
        
        // Refresh statistics
        await _refreshStatistics(action.userId);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Update action progress
  Future<bool> updateActionProgress(String actionId, double progress) async {
    try {
      final updatedAction = await ActionService.updateActionProgress(actionId, progress);
      
      final index = _actions.indexWhere((a) => a.id == actionId);
      if (index != -1) {
        _actions[index] = updatedAction;
        
        // Refresh statistics
        await _refreshStatistics(updatedAction.userId);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Complete an action
  Future<bool> completeAction(String actionId) async {
    try {
      final updatedAction = await ActionService.completeAction(actionId);
      
      final index = _actions.indexWhere((a) => a.id == actionId);
      if (index != -1) {
        _actions[index] = updatedAction;
        
        // Refresh statistics
        await _refreshStatistics(updatedAction.userId);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Delete an action
  Future<bool> deleteAction(String actionId) async {
    try {
      final actionToDelete = _actions.firstWhere((a) => a.id == actionId);
      
      await ActionService.deleteAction(actionId);
      _actions.removeWhere((a) => a.id == actionId);
      
      // Refresh statistics
      await _refreshStatistics(actionToDelete.userId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Attribute action to organization
  Future<bool> attributeActionToOrganization(String actionId, String organizationId) async {
    try {
      final updatedAction = await ActionService.attributeActionToOrganization(actionId, organizationId);
      
      final index = _actions.indexWhere((a) => a.id == actionId);
      if (index != -1) {
        _actions[index] = updatedAction;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Remove organization attribution
  Future<bool> removeOrganizationAttribution(String actionId) async {
    try {
      final updatedAction = await ActionService.removeOrganizationAttribution(actionId);
      
      final index = _actions.indexWhere((a) => a.id == actionId);
      if (index != -1) {
        _actions[index] = updatedAction;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Refresh statistics
  Future<void> _refreshStatistics(String userId) async {
    try {
      final stats = await ActionService.getActionStatistics(userId);
      _statistics = stats;
    } catch (e) {
      debugPrint('Failed to refresh statistics: $e');
    }
  }

  /// Add a measurement to an action and update progress
  Future<bool> addMeasurement(ActionMeasurement measurement) async {
    try {
      // Save the measurement
      final savedMeasurement = await ActionMeasurementService.createMeasurement(measurement);
      
      // Find the action
      final index = _actions.indexWhere((a) => a.id == measurement.actionId);
      if (index == -1) return false;
      
      // Update action progress based on measurements
      final updatedAction = await ActionMeasurementService.updateActionProgress(_actions[index]);
      
      // Update local action with new progress
      _actions[index] = updatedAction;
      
      // If the action has measurements list, add the new measurement
      if (_actions[index].measurements != null) {
        final updatedMeasurements = List<ActionMeasurement>.from(_actions[index].measurements!);
        updatedMeasurements.add(savedMeasurement);
        _actions[index] = _actions[index].copyWith(measurements: updatedMeasurements);
      } else {
        _actions[index] = _actions[index].copyWith(measurements: [savedMeasurement]);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Load measurements for an action
  Future<List<ActionMeasurement>> loadMeasurements(String actionId) async {
    try {
      final measurements = await ActionMeasurementService.getMeasurementsForAction(actionId);
      
      // Update the action with measurements
      final index = _actions.indexWhere((a) => a.id == actionId);
      if (index != -1) {
        _actions[index] = _actions[index].copyWith(measurements: measurements);
        notifyListeners();
      }
      
      return measurements;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return [];
    }
  }

  /// Set baseline data for an action
  Future<bool> setBaseline(ActionItem action, double value, String unit, DateTime date, String? methodology) async {
    try {
      final updatedAction = action.copyWith(
        baselineValue: value,
        baselineUnit: unit,
        baselineDate: date,
        baselineMethodology: methodology,
        updatedAt: DateTime.now(),
      );
      
      return await updateAction(updatedAction);
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Set target data for an action
  Future<bool> setTarget(ActionItem action, double value, DateTime date, String? verificationMethod) async {
    try {
      final updatedAction = action.copyWith(
        targetValue: value,
        targetDate: date,
        verificationMethod: verificationMethod,
        updatedAt: DateTime.now(),
      );
      
      return await updateAction(updatedAction);
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }
  
  /// Clear all data
  void clear() {
    _actions.clear();
    _statistics = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String? error) {
    _error = error;
  }
}
