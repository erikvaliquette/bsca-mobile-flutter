import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/organization_carbon_footprint_model.dart';

/// Service for managing organization carbon footprint data
class OrganizationCarbonFootprintService {
  static final OrganizationCarbonFootprintService _instance = OrganizationCarbonFootprintService._();
  static OrganizationCarbonFootprintService get instance => _instance;
  
  OrganizationCarbonFootprintService._();
  
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch carbon footprint data for a specific organization
  Future<OrganizationCarbonFootprint?> getOrganizationCarbonFootprint(String organizationId) async {
    try {
      debugPrint('🔍 Fetching carbon footprint for organization: $organizationId');
      
      final response = await _client
          .from('organization_carbon_footprint')
          .select('*')
          .eq('organization_id', organizationId)
          .maybeSingle();
      
      if (response == null) {
        debugPrint('📊 No carbon footprint data found for organization: $organizationId');
        return null;
      }
      
      debugPrint('✅ Carbon footprint data retrieved: ${response['total_emissions']} ${response['unit']}');
      return OrganizationCarbonFootprint.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching organization carbon footprint: $e');
      return null;
    }
  }

  /// Fetch carbon footprint data for multiple organizations
  Future<List<OrganizationCarbonFootprint>> getMultipleOrganizationCarbonFootprints(List<String> organizationIds) async {
    try {
      debugPrint('🔍 Fetching carbon footprints for ${organizationIds.length} organizations');
      
      final response = await _client
          .from('organization_carbon_footprint')
          .select('*')
          .inFilter('organization_id', organizationIds);
      
      debugPrint('✅ Retrieved ${response.length} carbon footprint records');
      return response.map((json) => OrganizationCarbonFootprint.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching multiple organization carbon footprints: $e');
      return [];
    }
  }

  /// Get carbon footprint breakdown by scope for an organization
  Future<Map<String, double>> getCarbonFootprintBreakdown(String organizationId) async {
    try {
      final footprint = await getOrganizationCarbonFootprint(organizationId);
      if (footprint == null) return {};
      
      return {
        'Scope 1': footprint.scope1Total,
        'Scope 2': footprint.scope2Total,
        'Scope 3': footprint.scope3Total,
      };
    } catch (e) {
      debugPrint('❌ Error getting carbon footprint breakdown: $e');
      return {};
    }
  }

  /// Get detailed Scope 3 breakdown for an organization
  Future<Map<String, double>> getScope3Breakdown(String organizationId) async {
    try {
      final footprint = await getOrganizationCarbonFootprint(organizationId);
      if (footprint == null) return {};
      
      return {
        'Business Travel': footprint.scope3BusinessTravel ?? 0,
        'Transportation': footprint.scope3Transportation ?? 0,
        'Purchased Goods': footprint.scope3PurchasedGoods ?? 0,
        'Capital Goods': footprint.scope3CapitalGoods ?? 0,
        'Fuel & Energy': footprint.scope3FuelEnergy ?? 0,
        'Waste': footprint.scope3Waste ?? 0,
        'Employee Commuting': footprint.scope3EmployeeCommuting ?? 0,
        'Leased Assets': footprint.scope3LeasedAssets ?? 0,
        'Processing': footprint.scope3Processing ?? 0,
        'Use of Products': footprint.scope3UseOfProducts ?? 0,
        'End of Life': footprint.scope3EndOfLife ?? 0,
        'Investments': footprint.scope3Investments ?? 0,
        'Franchises': footprint.scope3Franchises ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting Scope 3 breakdown: $e');
      return {};
    }
  }
}
