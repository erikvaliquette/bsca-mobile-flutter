import 'package:bsca_mobile_flutter/models/sdg_target_data.dart';
import 'package:bsca_mobile_flutter/services/supabase/supabase_client.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SdgTargetDataService {
  final String _tableName = 'sdg_target_data';

  // We don't need to store the SupabaseService instance since we'll use the static client
  SdgTargetDataService();

  Future<List<SdgTargetData>> getTargetDataByTargetId(String targetId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('target_id', targetId)
          .order('year', ascending: true)
          .order('month', ascending: true);

      return (response as List)
          .map((data) => SdgTargetData.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching target data: $e');
      return [];
    }
  }

  Future<SdgTargetData?> getTargetDataByMonthYear(
      String targetId, Month month, int year) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('target_id', targetId)
          .eq('month', month.name)
          .eq('year', year)
          .single();

      return SdgTargetData.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching target data for month/year: $e');
      return null;
    }
  }

  Future<SdgTargetData?> createTargetData(SdgTargetData data) async {
    try {
      final response = await SupabaseService.client.from(_tableName).insert(
            data.toJson(),
          ).select().single();

      return SdgTargetData.fromJson(response);
    } catch (e) {
      debugPrint('Error creating target data: $e');
      return null;
    }
  }

  Future<SdgTargetData?> updateTargetData(SdgTargetData data) async {
    if (data.id == null) {
      debugPrint('Cannot update target data without id');
      return null;
    }

    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .update(data.toJson())
          .eq('id', data.id)
          .select()
          .single();

      return SdgTargetData.fromJson(response);
    } catch (e) {
      debugPrint('Error updating target data: $e');
      return null;
    }
  }

  Future<bool> deleteTargetData(String id) async {
    try {
      await SupabaseService.client.from(_tableName).delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting target data: $e');
      return false;
    }
  }

  Future<bool> deleteAllTargetDataForTarget(String targetId) async {
    try {
      await SupabaseService.client
          .from(_tableName)
          .delete()
          .eq('target_id', targetId);
      return true;
    } catch (e) {
      debugPrint('Error deleting all target data for target: $e');
      return false;
    }
  }

  // Helper method to create or update target data
  Future<SdgTargetData?> saveTargetData(SdgTargetData data) async {
    // Check if data already exists for this target, month, and year
    final existingData = await getTargetDataByMonthYear(
      data.targetId!,
      data.month,
      data.year,
    );

    if (existingData != null) {
      // Update existing data
      return updateTargetData(data.copyWith(id: existingData.id));
    } else {
      // Create new data
      return createTargetData(data);
    }
  }
}
