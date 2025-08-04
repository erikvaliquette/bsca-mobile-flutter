import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/action_measurement.dart';
import '../models/action_item.dart';

class ActionMeasurementService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'action_measurements';
  static const double _minMeaningfulChange = 0.01; // Minimum change to record (1%)

  /// Create a new measurement for an action
  static Future<ActionMeasurement> createMeasurement(ActionMeasurement measurement) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .insert(measurement.toJson())
          .select()
          .single();

      return ActionMeasurement.fromJson(response);
    } catch (e) {
      print('Error creating measurement: $e');
      throw Exception('Failed to create measurement: $e');
    }
  }

  /// Get all measurements for a specific action
  static Future<List<ActionMeasurement>> getMeasurementsForAction(String actionId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('action_id', actionId)
          .order('date', ascending: true);

      return (response as List)
          .map((data) => ActionMeasurement.fromJson(data))
          .toList();
    } catch (e) {
      print('Error getting measurements: $e');
      throw Exception('Failed to get measurements: $e');
    }
  }

  /// Update an action's progress based on measurements
  /// Returns the updated action with new progress value
  static Future<ActionItem> updateActionProgress(ActionItem action) async {
    try {
      // Get all measurements for this action
      final measurements = await getMeasurementsForAction(action.id);
      
      if (measurements.isEmpty) {
        return action; // No change if no measurements
      }

      // Calculate progress based on measurements, baseline, and target
      double progress = 0.0;
      
      if (action.baselineValue != null && action.targetValue != null) {
        // If we have baseline and target, calculate progress as percentage of target achieved
        final latestMeasurement = measurements.last;
        final totalChange = action.targetValue! - action.baselineValue!;
        
        if (totalChange != 0) {
          final achievedChange = latestMeasurement.value - action.baselineValue!;
          progress = (achievedChange / totalChange).clamp(0.0, 1.0);
        }
      } else {
        // Without baseline/target, use simple 0-1 scale based on number of measurements
        // More measurements = more progress, up to 5 measurements = 100%
        progress = (measurements.length / 5).clamp(0.0, 1.0);
      }
      
      // Update the action's progress in the database
      final response = await _supabase
          .from('user_actions')
          .update({'progress': progress})
          .eq('id', action.id)
          .select()
          .single();
      
      return ActionItem.fromJson(response);
    } catch (e) {
      print('Error updating action progress: $e');
      throw Exception('Failed to update action progress: $e');
    }
  }

  /// Check if a new measurement represents meaningful change
  /// This prevents recording trivial changes that don't represent real progress
  static bool isMeaningfulChange(ActionItem action, double newValue) {
    if (action.baselineValue == null) return true;
    
    // Get the range between baseline and target (or use baseline as reference if no target)
    final referenceValue = action.targetValue ?? action.baselineValue!;
    final range = (referenceValue - action.baselineValue!).abs();
    
    // Calculate the minimum meaningful change as a percentage of the range
    final minChange = range * _minMeaningfulChange;
    
    // Get the latest measurement value if available
    double? lastValue;
    if (action.measurements != null && action.measurements!.isNotEmpty) {
      lastValue = action.measurements!.last.value;
    } else {
      lastValue = action.baselineValue;
    }
    
    // Check if the change from the last value is meaningful
    return lastValue == null || (newValue - lastValue).abs() >= minChange;
  }
}
