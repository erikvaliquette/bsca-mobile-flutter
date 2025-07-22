import '../models/organization_model.dart';

/// Model for organization carbon footprint data from Supabase
class OrganizationCarbonFootprint {
  final String id;
  final String organizationId;
  final int year;
  final double totalEmissions;
  final String unit;
  final double? reductionGoal;
  final double? reductionTarget;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Scope 1 emissions
  final double scope1Total;
  final double? scope1StationaryCombustion;
  final double? scope1MobileCombustion;
  final double? scope1FugitiveEmissions;
  final double? scope1ProcessEmissions;
  
  // Scope 2 emissions
  final double scope2Total;
  final double? scope2Electricity;
  final double? scope2Steam;
  final double? scope2Heating;
  final double? scope2Cooling;
  
  // Scope 3 emissions
  final double scope3Total;
  final double? scope3PurchasedGoods;
  final double? scope3CapitalGoods;
  final double? scope3FuelEnergy;
  final double? scope3Transportation;
  final double? scope3Waste;
  final double? scope3BusinessTravel;
  final double? scope3EmployeeCommuting;
  final double? scope3LeasedAssets;
  final double? scope3Processing;
  final double? scope3UseOfProducts;
  final double? scope3EndOfLife;
  final double? scope3Investments;
  final double? scope3Franchises;

  OrganizationCarbonFootprint({
    required this.id,
    required this.organizationId,
    required this.year,
    required this.totalEmissions,
    required this.unit,
    this.reductionGoal,
    this.reductionTarget,
    this.createdAt,
    this.updatedAt,
    required this.scope1Total,
    this.scope1StationaryCombustion,
    this.scope1MobileCombustion,
    this.scope1FugitiveEmissions,
    this.scope1ProcessEmissions,
    required this.scope2Total,
    this.scope2Electricity,
    this.scope2Steam,
    this.scope2Heating,
    this.scope2Cooling,
    required this.scope3Total,
    this.scope3PurchasedGoods,
    this.scope3CapitalGoods,
    this.scope3FuelEnergy,
    this.scope3Transportation,
    this.scope3Waste,
    this.scope3BusinessTravel,
    this.scope3EmployeeCommuting,
    this.scope3LeasedAssets,
    this.scope3Processing,
    this.scope3UseOfProducts,
    this.scope3EndOfLife,
    this.scope3Investments,
    this.scope3Franchises,
  });

  factory OrganizationCarbonFootprint.fromJson(Map<String, dynamic> json) {
    return OrganizationCarbonFootprint(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      year: json['year'] as int,
      totalEmissions: double.parse(json['total_emissions']?.toString() ?? '0'),
      unit: json['unit'] as String,
      reductionGoal: json['reduction_goal'] != null 
          ? double.parse(json['reduction_goal'].toString()) 
          : null,
      reductionTarget: json['reduction_target'] != null 
          ? double.parse(json['reduction_target'].toString()) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      scope1Total: double.parse(json['scope1_total']?.toString() ?? '0'),
      scope1StationaryCombustion: json['scope1_stationary_combustion'] != null 
          ? double.parse(json['scope1_stationary_combustion'].toString()) 
          : null,
      scope1MobileCombustion: json['scope1_mobile_combustion'] != null 
          ? double.parse(json['scope1_mobile_combustion'].toString()) 
          : null,
      scope1FugitiveEmissions: json['scope1_fugitive_emissions'] != null 
          ? double.parse(json['scope1_fugitive_emissions'].toString()) 
          : null,
      scope1ProcessEmissions: json['scope1_process_emissions'] != null 
          ? double.parse(json['scope1_process_emissions'].toString()) 
          : null,
      scope2Total: double.parse(json['scope2_total']?.toString() ?? '0'),
      scope2Electricity: json['scope2_electricity'] != null 
          ? double.parse(json['scope2_electricity'].toString()) 
          : null,
      scope2Steam: json['scope2_steam'] != null 
          ? double.parse(json['scope2_steam'].toString()) 
          : null,
      scope2Heating: json['scope2_heating'] != null 
          ? double.parse(json['scope2_heating'].toString()) 
          : null,
      scope2Cooling: json['scope2_cooling'] != null 
          ? double.parse(json['scope2_cooling'].toString()) 
          : null,
      scope3Total: double.parse(json['scope3_total']?.toString() ?? '0'),
      scope3PurchasedGoods: json['scope3_purchased_goods'] != null 
          ? double.parse(json['scope3_purchased_goods'].toString()) 
          : null,
      scope3CapitalGoods: json['scope3_capital_goods'] != null 
          ? double.parse(json['scope3_capital_goods'].toString()) 
          : null,
      scope3FuelEnergy: json['scope3_fuel_energy'] != null 
          ? double.parse(json['scope3_fuel_energy'].toString()) 
          : null,
      scope3Transportation: json['scope3_transportation'] != null 
          ? double.parse(json['scope3_transportation'].toString()) 
          : null,
      scope3Waste: json['scope3_waste'] != null 
          ? double.parse(json['scope3_waste'].toString()) 
          : null,
      scope3BusinessTravel: json['scope3_business_travel'] != null 
          ? double.parse(json['scope3_business_travel'].toString()) 
          : null,
      scope3EmployeeCommuting: json['scope3_employee_commuting'] != null 
          ? double.parse(json['scope3_employee_commuting'].toString()) 
          : null,
      scope3LeasedAssets: json['scope3_leased_assets'] != null 
          ? double.parse(json['scope3_leased_assets'].toString()) 
          : null,
      scope3Processing: json['scope3_processing'] != null 
          ? double.parse(json['scope3_processing'].toString()) 
          : null,
      scope3UseOfProducts: json['scope3_use_of_products'] != null 
          ? double.parse(json['scope3_use_of_products'].toString()) 
          : null,
      scope3EndOfLife: json['scope3_end_of_life'] != null 
          ? double.parse(json['scope3_end_of_life'].toString()) 
          : null,
      scope3Investments: json['scope3_investments'] != null 
          ? double.parse(json['scope3_investments'].toString()) 
          : null,
      scope3Franchises: json['scope3_franchises'] != null 
          ? double.parse(json['scope3_franchises'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'year': year,
      'total_emissions': totalEmissions,
      'unit': unit,
      'reduction_goal': reductionGoal,
      'reduction_target': reductionTarget,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'scope1_total': scope1Total,
      'scope1_stationary_combustion': scope1StationaryCombustion,
      'scope1_mobile_combustion': scope1MobileCombustion,
      'scope1_fugitive_emissions': scope1FugitiveEmissions,
      'scope1_process_emissions': scope1ProcessEmissions,
      'scope2_total': scope2Total,
      'scope2_electricity': scope2Electricity,
      'scope2_steam': scope2Steam,
      'scope2_heating': scope2Heating,
      'scope2_cooling': scope2Cooling,
      'scope3_total': scope3Total,
      'scope3_purchased_goods': scope3PurchasedGoods,
      'scope3_capital_goods': scope3CapitalGoods,
      'scope3_fuel_energy': scope3FuelEnergy,
      'scope3_transportation': scope3Transportation,
      'scope3_waste': scope3Waste,
      'scope3_business_travel': scope3BusinessTravel,
      'scope3_employee_commuting': scope3EmployeeCommuting,
      'scope3_leased_assets': scope3LeasedAssets,
      'scope3_processing': scope3Processing,
      'scope3_use_of_products': scope3UseOfProducts,
      'scope3_end_of_life': scope3EndOfLife,
      'scope3_investments': scope3Investments,
      'scope3_franchises': scope3Franchises,
    };
  }

  /// Get a formatted string of the total emissions
  String get formattedTotalEmissions => '${totalEmissions.toStringAsFixed(2)} $unit';

  /// Get the percentage breakdown of each scope
  Map<String, double> get scopePercentages {
    if (totalEmissions == 0) return {'Scope 1': 0, 'Scope 2': 0, 'Scope 3': 0};
    
    return {
      'Scope 1': (scope1Total / totalEmissions) * 100,
      'Scope 2': (scope2Total / totalEmissions) * 100,
      'Scope 3': (scope3Total / totalEmissions) * 100,
    };
  }

  /// Get the most significant Scope 3 categories (non-zero values)
  Map<String, double> get significantScope3Categories {
    final categories = <String, double>{};
    
    if ((scope3BusinessTravel ?? 0) > 0) categories['Business Travel'] = scope3BusinessTravel!;
    if ((scope3Transportation ?? 0) > 0) categories['Transportation'] = scope3Transportation!;
    if ((scope3PurchasedGoods ?? 0) > 0) categories['Purchased Goods'] = scope3PurchasedGoods!;
    if ((scope3EmployeeCommuting ?? 0) > 0) categories['Employee Commuting'] = scope3EmployeeCommuting!;
    if ((scope3Waste ?? 0) > 0) categories['Waste'] = scope3Waste!;
    if ((scope3FuelEnergy ?? 0) > 0) categories['Fuel & Energy'] = scope3FuelEnergy!;
    
    return categories;
  }

  /// Convert to the legacy CarbonFootprint model for compatibility with existing screens
  CarbonFootprint toLegacyCarbonFootprint() {
    // Create emission categories from scope data
    final categories = <EmissionCategory>[];
    
    // Add Scope 1 category
    if (scope1Total > 0) {
      categories.add(EmissionCategory(
        name: 'Scope 1 - Direct Emissions',
        value: scope1Total,
      ));
    }
    
    // Add Scope 2 category
    if (scope2Total > 0) {
      categories.add(EmissionCategory(
        name: 'Scope 2 - Energy Indirect',
        value: scope2Total,
      ));
    }
    
    // Add Scope 3 category
    if (scope3Total > 0) {
      categories.add(EmissionCategory(
        name: 'Scope 3 - Other Indirect',
        value: scope3Total,
      ));
    }
    
    // Add specific Scope 3 subcategories if they have data
    if ((scope3BusinessTravel ?? 0) > 0) {
      categories.add(EmissionCategory(
        name: 'Business Travel',
        value: scope3BusinessTravel!,
      ));
    }
    
    if ((scope3Transportation ?? 0) > 0) {
      categories.add(EmissionCategory(
        name: 'Transportation',
        value: scope3Transportation!,
      ));
    }
    
    if ((scope3EmployeeCommuting ?? 0) > 0) {
      categories.add(EmissionCategory(
        name: 'Employee Commuting',
        value: scope3EmployeeCommuting!,
      ));
    }
    
    return CarbonFootprint(
      totalEmissions: totalEmissions,
      unit: unit,
      year: year,
      reductionGoal: reductionGoal,
      reductionTarget: reductionTarget,
      categories: categories.isNotEmpty ? categories : null,
    );
  }
}
