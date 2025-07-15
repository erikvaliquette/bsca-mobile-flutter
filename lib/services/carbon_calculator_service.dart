import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/organization_model.dart';

/// Service for handling carbon footprint calculations and data
class CarbonCalculatorService {
  static final CarbonCalculatorService instance = CarbonCalculatorService._();
  
  CarbonCalculatorService._();
  
  /// Get the Supabase client
  final _supabase = Supabase.instance.client;
  
  /// Save a carbon footprint calculation to the database
  Future<void> saveCarbonFootprint({
    required double scope1Emissions,
    required double scope2Emissions,
    required double scope3Emissions,
    required double totalEmissions,
    String? organizationId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    await _supabase.from('carbon_footprints').insert({
      'user_id': user.id,
      'organization_id': organizationId,
      'scope1_emissions': scope1Emissions,
      'scope2_emissions': scope2Emissions,
      'scope3_emissions': scope3Emissions,
      'total_emissions': totalEmissions,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  /// Get the latest carbon footprint calculation for the current user
  Future<Map<String, dynamic>?> getLatestCarbonFootprint() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await _supabase
        .from('carbon_footprints')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    
    return response;
  }
  
  /// Convert a carbon footprint calculation to the organization model format
  CarbonFootprint convertToCarbonFootprintModel(Map<String, dynamic> data) {
    // Create emission categories
    final List<EmissionCategory> categories = [
      EmissionCategory(
        name: 'Scope 1: Direct Emissions',
        value: data['scope1_emissions'] ?? 0.0,
        icon: 'local_fire_department',
        subcategories: [
          EmissionSubcategory(
            name: 'Stationary Combustion',
            value: (data['scope1_emissions'] ?? 0.0) * 0.6,
          ),
          EmissionSubcategory(
            name: 'Mobile Combustion',
            value: (data['scope1_emissions'] ?? 0.0) * 0.3,
          ),
          EmissionSubcategory(
            name: 'Fugitive Emissions',
            value: (data['scope1_emissions'] ?? 0.0) * 0.1,
          ),
        ],
      ),
      EmissionCategory(
        name: 'Scope 2: Indirect Emissions',
        value: data['scope2_emissions'] ?? 0.0,
        icon: 'electric_bolt',
        subcategories: [
          EmissionSubcategory(
            name: 'Purchased Electricity',
            value: (data['scope2_emissions'] ?? 0.0) * 0.8,
          ),
          EmissionSubcategory(
            name: 'Purchased Heating/Cooling',
            value: (data['scope2_emissions'] ?? 0.0) * 0.2,
          ),
        ],
      ),
      EmissionCategory(
        name: 'Scope 3: Value Chain Emissions',
        value: data['scope3_emissions'] ?? 0.0,
        icon: 'business',
        subcategories: [
          EmissionSubcategory(
            name: 'Business Travel',
            value: (data['scope3_emissions'] ?? 0.0) * 0.2,
          ),
          EmissionSubcategory(
            name: 'Employee Commuting',
            value: (data['scope3_emissions'] ?? 0.0) * 0.15,
            fuelType: 'Various',
          ),
          EmissionSubcategory(
            name: 'Purchased Goods & Services',
            value: (data['scope3_emissions'] ?? 0.0) * 0.4,
          ),
          EmissionSubcategory(
            name: 'Waste',
            value: (data['scope3_emissions'] ?? 0.0) * 0.1,
          ),
          EmissionSubcategory(
            name: 'Transportation & Distribution',
            value: (data['scope3_emissions'] ?? 0.0) * 0.15,
            fuelType: 'Various',
          ),
        ],
      ),
    ];
    
    return CarbonFootprint(
      totalEmissions: data['total_emissions'] ?? 0.0,
      unit: 'tCO₂e',
      year: DateTime.now().year,
      reductionGoal: 30.0, // Default 30% reduction goal
      reductionTarget: (data['total_emissions'] ?? 0.0) * 0.7, // 30% reduction
      categories: categories,
    );
  }
  
  /// Get the latest carbon footprint as a CarbonFootprint model
  Future<CarbonFootprint?> getLatestCarbonFootprintModel() async {
    try {
      final data = await getLatestCarbonFootprint();
      if (data != null) {
        return convertToCarbonFootprintModel(data);
      }
      return null;
    } catch (e) {
      print('Error getting latest carbon footprint: $e');
      return null;
    }
  }
}
