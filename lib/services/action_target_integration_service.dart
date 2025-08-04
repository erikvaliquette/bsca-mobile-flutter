import 'package:bsca_mobile_flutter/models/action_item.dart';
import 'package:bsca_mobile_flutter/models/action_measurement.dart';
import 'package:bsca_mobile_flutter/models/sdg_target.dart';
import 'package:bsca_mobile_flutter/models/sdg_target_data.dart';
import 'package:bsca_mobile_flutter/services/sdg_target_data_service.dart';
import 'package:bsca_mobile_flutter/services/sdg_target_service.dart';
import 'package:flutter/foundation.dart';

class ActionTargetIntegrationService {
  final SdgTargetService _targetService;
  final SdgTargetDataService _targetDataService;

  ActionTargetIntegrationService()
      : _targetService = SdgTargetService(),
        _targetDataService = SdgTargetDataService();

  /// Retrieves the SDG target associated with an action item
  Future<SdgTarget?> getTargetForAction(ActionItem action) async {
    if (action.sdgTargetId == null) {
      return null;
    }
    
    try {
      return await _targetService.getTargetById(action.sdgTargetId!);
    } catch (e) {
      debugPrint('Error fetching SDG target for action: $e');
      return null;
    }
  }

  /// Records a measurement for an action item to the SDG target data table
  Future<bool> recordActionMeasurement(
    ActionItem action,
    ActionMeasurement measurement,
  ) async {
    if (action.sdgTargetId == null) {
      debugPrint('Cannot record measurement: Action has no associated SDG target');
      return false;
    }

    // Extract month and year from the measurement date
    final date = measurement.date;
    final month = Month.values[date.month - 1]; // Convert 1-based month to 0-based enum
    final year = date.year;

    try {
      // Check if there's existing data for this month/year
      final existingData = await _targetDataService.getTargetDataByMonthYear(
        action.sdgTargetId!,
        month,
        year,
      );

      if (existingData != null) {
        // Update existing data with the new actual value
        final updatedData = existingData.copyWith(
          actual: measurement.value,
          updatedAt: DateTime.now(),
        );
        
        final result = await _targetDataService.updateTargetData(updatedData);
        return result != null;
      } else {
        // Create new data entry
        final newData = SdgTargetData(
          targetId: action.sdgTargetId,
          month: month,
          year: year,
          actual: measurement.value,
          // If action has baseline/target values, include them
          baseline: action.baselineValue,
          target: action.targetValue,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final result = await _targetDataService.createTargetData(newData);
        return result != null;
      }
    } catch (e) {
      debugPrint('Error recording action measurement to target data: $e');
      return false;
    }
  }

  /// Updates baseline and target values in the SDG target data table
  Future<bool> updateTargetBaseline(
    ActionItem action,
    double baselineValue,
    {DateTime? baselineDate}
  ) async {
    if (action.sdgTargetId == null) {
      debugPrint('Cannot update baseline: Action has no associated SDG target');
      return false;
    }

    final date = baselineDate ?? DateTime.now();
    final month = Month.values[date.month - 1];
    final year = date.year;

    try {
      // Check if there's existing data for this month/year
      final existingData = await _targetDataService.getTargetDataByMonthYear(
        action.sdgTargetId!,
        month,
        year,
      );

      if (existingData != null) {
        // Update existing data
        final updatedData = existingData.copyWith(
          baseline: baselineValue,
          updatedAt: DateTime.now(),
        );
        
        final result = await _targetDataService.updateTargetData(updatedData);
        return result != null;
      } else {
        // Create new data entry
        final newData = SdgTargetData(
          targetId: action.sdgTargetId,
          month: month,
          year: year,
          baseline: baselineValue,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final result = await _targetDataService.createTargetData(newData);
        return result != null;
      }
    } catch (e) {
      debugPrint('Error updating target baseline: $e');
      return false;
    }
  }

  /// Updates target value in the SDG target data table
  Future<bool> updateTargetValue(
    ActionItem action,
    double targetValue,
    {DateTime? targetDate}
  ) async {
    if (action.sdgTargetId == null) {
      debugPrint('Cannot update target value: Action has no associated SDG target');
      return false;
    }

    final date = targetDate ?? DateTime.now();
    final month = Month.values[date.month - 1];
    final year = date.year;

    try {
      // Check if there's existing data for this month/year
      final existingData = await _targetDataService.getTargetDataByMonthYear(
        action.sdgTargetId!,
        month,
        year,
      );

      if (existingData != null) {
        // Update existing data
        final updatedData = existingData.copyWith(
          target: targetValue,
          updatedAt: DateTime.now(),
        );
        
        final result = await _targetDataService.updateTargetData(updatedData);
        return result != null;
      } else {
        // Create new data entry
        final newData = SdgTargetData(
          targetId: action.sdgTargetId,
          month: month,
          year: year,
          target: targetValue,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final result = await _targetDataService.createTargetData(newData);
        return result != null;
      }
    } catch (e) {
      debugPrint('Error updating target value: $e');
      return false;
    }
  }

  /// Gets all target data for an action's associated SDG target
  Future<List<SdgTargetData>> getTargetDataForAction(ActionItem action) async {
    if (action.sdgTargetId == null) {
      return [];
    }
    
    try {
      return await _targetDataService.getTargetDataByTargetId(action.sdgTargetId!);
    } catch (e) {
      debugPrint('Error fetching target data for action: $e');
      return [];
    }
  }

  /// Synchronizes all action measurements with the SDG target data table
  Future<bool> syncActionMeasurementsWithTargetData(ActionItem action) async {
    if (action.sdgTargetId == null || action.measurements == null || action.measurements!.isEmpty) {
      return false;
    }

    bool allSucceeded = true;
    
    for (final measurement in action.measurements!) {
      final success = await recordActionMeasurement(action, measurement);
      if (!success) {
        allSucceeded = false;
      }
    }
    
    return allSucceeded;
  }
}
