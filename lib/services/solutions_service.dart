import 'package:bsca_mobile_flutter/models/solution.dart';
import 'package:bsca_mobile_flutter/services/supabase/supabase_client.dart';
import 'package:flutter/foundation.dart';

class SolutionsService {
  /// Fetch all solutions from the database
  static Future<List<Solution>> getSolutions() async {
    try {
      final response = await SupabaseService.client
          .from('solutions')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Solution.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching solutions: $e');
      return [];
    }
  }

  /// Fetch solutions filtered by SDG goals
  static Future<List<Solution>> getSolutionsBySDG(List<int> sdgGoals) async {
    try {
      final response = await SupabaseService.client
          .from('solutions')
          .select()
          .eq('is_active', true)
          .contains('sdg_goals', sdgGoals)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Solution.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching solutions by SDG: $e');
      return [];
    }
  }

  /// Fetch solutions by category
  static Future<List<Solution>> getSolutionsByCategory(String category) async {
    try {
      final response = await SupabaseService.client
          .from('solutions')
          .select()
          .eq('is_active', true)
          .eq('category', category)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Solution.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching solutions by category: $e');
      return [];
    }
  }

  /// Search solutions by name or description
  static Future<List<Solution>> searchSolutions(String query) async {
    try {
      final response = await SupabaseService.client
          .from('solutions')
          .select()
          .eq('is_active', true)
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List).map((json) => Solution.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error searching solutions: $e');
      return [];
    }
  }
}
