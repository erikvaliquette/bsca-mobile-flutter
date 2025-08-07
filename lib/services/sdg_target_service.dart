import 'package:bsca_mobile_flutter/models/sdg_target.dart';
import 'package:bsca_mobile_flutter/services/supabase/supabase_client.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SdgTargetService {
  final String _tableName = 'sdg_targets';

  // We don't need to store the SupabaseService instance since we'll use the static client
  SdgTargetService();

  Future<List<SdgTarget>> getAllTargets() async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .order('target_number');

      return (response as List)
          .map((data) => SdgTarget.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching SDG targets: $e');
      return [];
    }
  }

  Future<List<SdgTarget>> getTargetsByOrganization(String organizationId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('organization_id', organizationId)
          .order('target_number');

      return (response as List)
          .map((data) => SdgTarget.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching organization SDG targets: $e');
      return [];
    }
  }

  Future<List<SdgTarget>> getTargetsByUser(String userId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('target_number');

      return (response as List)
          .map((data) => SdgTarget.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user SDG targets: $e');
      return [];
    }
  }
  
  Future<List<SdgTarget>> getTargetsBySDG(int sdgId) async {
    try {
      // Using 'sdg_id' instead of 'sdg_goal_number' to match the database schema
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('sdg_id', sdgId)
          .order('target_number', ascending: true);

      return (response as List)
          .map((data) => SdgTarget.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching SDG targets for SDG $sdgId: $e');
      return [];
    }
  }
  
  Future<List<SdgTarget>> getTargetsByOrganizationAndSDG(String organizationId, int sdgId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('organization_id', organizationId)
          .eq('sdg_id', sdgId)
          .order('target_number', ascending: true);

      return (response as List)
          .map((data) => SdgTarget.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching organization SDG targets for SDG $sdgId: $e');
      return [];
    }
  }

  Future<SdgTarget?> getTargetById(String id) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      return SdgTarget.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching SDG target: $e');
      return null;
    }
  }

  Future<SdgTarget?> createTarget(SdgTarget target) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .insert(target.toJson())
          .select()
          .single();

      return SdgTarget.fromJson(response);
    } catch (e) {
      debugPrint('Error creating SDG target: $e');
      return null;
    }
  }

  Future<SdgTarget?> updateTarget(SdgTarget target) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .update(target.toJson())
          .eq('id', target.id)
          .select()
          .single();

      return SdgTarget.fromJson(response);
    } catch (e) {
      debugPrint('Error updating SDG target: $e');
      return null;
    }
  }

  Future<bool> deleteTarget(String id) async {
    try {
      await SupabaseService.client
          .from(_tableName)
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting SDG target: $e');
      return false;
    }
  }
}
