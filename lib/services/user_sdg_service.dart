import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bsca_mobile_flutter/services/supabase/supabase_client.dart';

/// Service for managing user SDG selections in Supabase
class UserSdgService {
  static const String _tableName = 'user_sdgs';

  /// Get all SDGs selected by the current user
  Future<List<int>> getUserSdgs() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('UserSdgService: No authenticated user');
        return [];
      }

      final response = await SupabaseService.client
          .from(_tableName)
          .select('sdg_id')
          .eq('user_id', userId);

      if (response is List) {
        return response.map<int>((item) => item['sdg_id'] as int).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching user SDGs: $e');
      return [];
    }
  }

  /// Save a user's SDG selection
  Future<bool> saveUserSdg(int sdgId) async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('UserSdgService: No authenticated user');
        return false;
      }

      await SupabaseService.client.from(_tableName).upsert({
        'user_id': userId,
        'sdg_id': sdgId,
      }, onConflict: 'user_id,sdg_id');

      return true;
    } catch (e) {
      debugPrint('Error saving user SDG: $e');
      return false;
    }
  }

  /// Remove a user's SDG selection
  Future<bool> removeUserSdg(int sdgId) async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('UserSdgService: No authenticated user');
        return false;
      }

      await SupabaseService.client
          .from(_tableName)
          .delete()
          .eq('user_id', userId)
          .eq('sdg_id', sdgId);

      return true;
    } catch (e) {
      debugPrint('Error removing user SDG: $e');
      return false;
    }
  }

  /// Check if a user has selected a specific SDG
  Future<bool> hasUserSelectedSdg(int sdgId) async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('UserSdgService: No authenticated user');
        return false;
      }

      final response = await SupabaseService.client
          .from(_tableName)
          .select('sdg_id')
          .eq('user_id', userId)
          .eq('sdg_id', sdgId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking user SDG selection: $e');
      return false;
    }
  }

  /// Toggle a user's SDG selection (add if not selected, remove if selected)
  Future<bool> toggleUserSdg(int sdgId) async {
    final isSelected = await hasUserSelectedSdg(sdgId);
    if (isSelected) {
      return await removeUserSdg(sdgId);
    } else {
      return await saveUserSdg(sdgId);
    }
  }

  /// Save multiple SDG selections for a user
  Future<bool> saveUserSdgs(List<int> sdgIds) async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('UserSdgService: No authenticated user');
        return false;
      }

      // Create records for batch insert
      final records = sdgIds.map((sdgId) => {
        'user_id': userId,
        'sdg_id': sdgId,
      }).toList();

      if (records.isEmpty) return true;

      await SupabaseService.client
          .from(_tableName)
          .upsert(records, onConflict: 'user_id,sdg_id');

      return true;
    } catch (e) {
      debugPrint('Error saving multiple user SDGs: $e');
      return false;
    }
  }

  /// Clear all SDG selections for a user
  Future<bool> clearUserSdgs() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('UserSdgService: No authenticated user');
        return false;
      }

      await SupabaseService.client
          .from(_tableName)
          .delete()
          .eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('Error clearing user SDGs: $e');
      return false;
    }
  }
}
