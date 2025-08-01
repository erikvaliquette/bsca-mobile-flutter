import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/organization_model.dart';
import '../../providers/organization_provider.dart';
import '../../services/carbon_calculator_service.dart';
import '../../services/subscription_helper.dart';
import '../../services/subscription_service.dart';

import '../../models/fuel_types.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/loading_indicator.dart';

class CarbonCalculatorScreen extends HookWidget {
  final Organization? organization;
  
  const CarbonCalculatorScreen({
    Key? key,
    this.organization,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // State variables
    final isLoading = useState(false);
    final scope1Emissions = useState(0.0);
    final scope2Emissions = useState(0.0);
    final scope3Emissions = useState(0.0);
    final totalEmissions = useState(0.0);
    final isOrganizationMode = useState(organization != null);
    final selectedOrganization = useState<Organization?>(organization);
    
    // Form controllers for Scope 1 - Fleet Vehicles
    final fleetPetrolController = useTextEditingController();
    final fleetDieselController = useTextEditingController();
    final fleetNaturalGasController = useTextEditingController();
    
    // Form controllers for Scope 1 - On-site Equipment
    final onsiteNaturalGasController = useTextEditingController();
    final onsitePropaneController = useTextEditingController();
    final refrigerantController = useTextEditingController();
    
    // Form controllers for Scope 2
    final electricityController = useTextEditingController();
    final districtHeatingController = useTextEditingController();
    final steamController = useTextEditingController();
    
    // Form controllers for Scope 3 - Business Travel
    final airTravelController = useTextEditingController();
    final carTravelController = useTextEditingController();
    final publicTransportController = useTextEditingController();
    
    // Form controllers for Scope 3 - Employee Commuting
    final carCommutingController = useTextEditingController();
    final publicTransportCommutingController = useTextEditingController();
    
    // Form controllers for Scope 3 - Other
    final purchasedGoodsController = useTextEditingController();
    final wasteController = useTextEditingController();
    final waterController = useTextEditingController();
    
    // Calculate emissions when inputs change
    useEffect(() {
      // Calculate Scope 1 emissions
      double scope1 = 0.0;
      scope1 += _parseDouble(fleetPetrolController.text) * 2.31; // Petrol emission factor
      scope1 += _parseDouble(fleetDieselController.text) * 2.68; // Diesel emission factor
      scope1 += _parseDouble(fleetNaturalGasController.text) * 2.03; // Natural gas emission factor
      scope1 += _parseDouble(onsiteNaturalGasController.text) * 2.03; // Natural gas emission factor
      scope1 += _parseDouble(onsitePropaneController.text) * 1.51; // Propane emission factor
      scope1 += _parseDouble(refrigerantController.text) * 1774; // Refrigerant emission factor (R404A)
      scope1Emissions.value = scope1;
      
      // Calculate Scope 2 emissions
      double scope2 = 0.0;
      scope2 += _parseDouble(electricityController.text) * 0.233; // Electricity emission factor
      scope2 += _parseDouble(districtHeatingController.text) * 0.18; // District heating emission factor
      scope2 += _parseDouble(steamController.text) * 0.27; // Steam emission factor
      scope2Emissions.value = scope2;
      
      // Calculate Scope 3 emissions
      double scope3 = 0.0;
      scope3 += _parseDouble(airTravelController.text) * 0.115; // Air travel emission factor
      scope3 += _parseDouble(carTravelController.text) * 0.17; // Car travel emission factor
      scope3 += _parseDouble(publicTransportController.text) * 0.03; // Public transport emission factor
      scope3 += _parseDouble(carCommutingController.text) * 0.17; // Car commuting emission factor
      scope3 += _parseDouble(publicTransportCommutingController.text) * 0.03; // Public transport commuting emission factor
      scope3 += _parseDouble(purchasedGoodsController.text) * 0.5; // Purchased goods emission factor
      scope3 += _parseDouble(wasteController.text) * 0.21; // Waste emission factor
      scope3 += _parseDouble(waterController.text) * 0.344; // Water emission factor
      scope3Emissions.value = scope3;
      
      // Calculate total emissions
      totalEmissions.value = scope1 + scope2 + scope3;
      
      return null;
    }, [
      fleetPetrolController.text,
      fleetDieselController.text,
      fleetNaturalGasController.text,
      onsiteNaturalGasController.text,
      onsitePropaneController.text,
      refrigerantController.text,
      electricityController.text,
      districtHeatingController.text,
      steamController.text,
      airTravelController.text,
      carTravelController.text,
      publicTransportController.text,
      carCommutingController.text,
      publicTransportCommutingController.text,
      purchasedGoodsController.text,
      wasteController.text,
      waterController.text,
    ]);
    
    // Debug print to verify build is being called
    debugPrint('Building CarbonCalculatorScreen');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carbon Calculator'),
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calculate and track your carbon footprint',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Organization selector
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FutureBuilder<bool>(
                        future: SubscriptionHelper.canAccessFeature(
                          'organization_access'
                        ),
                        builder: (context, snapshot) {
                          final canAccessOrganizations = snapshot.data ?? false;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Calculate For',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  if (!canAccessOrganizations)
                                    Tooltip(
                                      message: 'Available in Enterprise tier and above',
                                      child: Icon(
                                        Icons.lock_outline,
                                        color: Colors.grey[400],
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Radio<bool>(
                                    value: false,
                                    groupValue: isOrganizationMode.value,
                                    onChanged: (value) {
                                      if (value != null) {
                                        isOrganizationMode.value = value;
                                        selectedOrganization.value = null;
                                      }
                                    },
                                  ),
                                  const Text('Personal'),
                                  const SizedBox(width: 24),
                                  Radio<bool>(
                                    value: true,
                                    groupValue: isOrganizationMode.value,
                                    // Disable the radio button completely for users without access
                                    onChanged: canAccessOrganizations ? (value) {
                                      if (value != null) {
                                        isOrganizationMode.value = value;
                                        // Get the current organization from provider
                                        final orgProvider = Provider.of<OrganizationProvider>(
                                          context, 
                                          listen: false
                                        );
                                        if (orgProvider.selectedOrganization != null) {
                                          selectedOrganization.value = orgProvider.selectedOrganization;
                                        }
                                      }
                                    } : (value) async {
                                      // Show upgrade prompt
                                      await SubscriptionHelper.showUpgradePromptIfNeeded(
                                        context,
                                        'organization_access',
                                        customMessage: 'Organization access is available in Enterprise tier and above.'
                                      );
                                      // Ensure we reset to Personal mode if they try to select Organization
                                      isOrganizationMode.value = false;
                                      selectedOrganization.value = null;
                                    },
                                  ),
                                  Row(
                                    children: [
                                      const Text('Organization'),
                                      if (!canAccessOrganizations)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4.0),
                                          child: Icon(
                                            Icons.lock_outline,
                                            color: Colors.grey[400],
                                            size: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              if (isOrganizationMode.value && selectedOrganization.value != null && canAccessOrganizations)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Selected: ${selectedOrganization.value!.name}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Scope 1: Direct Emissions
                  const Text(
                    'Scope 1: Direct Emissions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Fleet Vehicles Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fleet Vehicles',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Petrol (liters)',
                            '0',
                            fleetPetrolController,
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Diesel (liters)',
                            '0',
                            fleetDieselController,
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Natural Gas (kg)',
                            '0',
                            fleetNaturalGasController,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // On-site Equipment Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'On-site Equipment',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Natural Gas (m³)',
                            '0',
                            onsiteNaturalGasController,
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Propane (liters)',
                            '0',
                            onsitePropaneController,
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Refrigerant Leaks (kg)',
                            '0',
                            refrigerantController,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Scope 2: Indirect Emissions from Purchased Energy
                  const Text(
                    'Scope 2: Indirect Emissions from Energy',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Electricity Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Electricity & Heating',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Electricity Usage (kWh)',
                            '0',
                            electricityController,
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'District Heating (kWh)',
                            '0',
                            districtHeatingController,
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Steam (kg)',
                            '0',
                            steamController,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Scope 3: Other Indirect Emissions
                  const Text(
                    'Scope 3: Other Indirect Emissions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Business Travel Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Business Travel',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Air Travel (km)',
                            '0',
                            airTravelController,
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Car Travel (km)',
                            '0',
                            carTravelController,
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Public Transport (km)',
                            '0',
                            publicTransportController,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Employee Commuting Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Employee Commuting',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Car Commuting (km)',
                            '0',
                            carCommutingController,
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Public Transport Commuting (km)',
                            '0',
                            publicTransportCommutingController,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Other Scope 3 Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Other Emissions',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Purchased Goods (kg CO₂e)',
                            '0',
                            purchasedGoodsController,
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Waste Generated (kg)',
                            '0',
                            wasteController,
                          ),
                          const SizedBox(height: 12),
                          _buildModernInputField(
                            context,
                            'Water Usage (m³)',
                            '0',
                            waterController,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Total Carbon Footprint Summary
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Carbon Footprint',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildEmissionSummary(
                                      context,
                                      'Scope 1',
                                      scope1Emissions.value,
                                      Colors.blue,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildEmissionSummary(
                                      context,
                                      'Scope 2',
                                      scope2Emissions.value,
                                      Colors.green,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildEmissionSummary(
                                      context,
                                      'Scope 3',
                                      scope3Emissions.value,
                                      Colors.orange,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'TOTAL',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${totalEmissions.value.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const Text(
                                      'tCO₂e',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Save and Reset buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Reset all form fields
                            fleetPetrolController.clear();
                            fleetDieselController.clear();
                            fleetNaturalGasController.clear();
                            onsiteNaturalGasController.clear();
                            onsitePropaneController.clear();
                            refrigerantController.clear();
                            electricityController.clear();
                            districtHeatingController.clear();
                            steamController.clear();
                            airTravelController.clear();
                            carTravelController.clear();
                            publicTransportController.clear();
                            carCommutingController.clear();
                            publicTransportCommutingController.clear();
                            purchasedGoodsController.clear();
                            wasteController.clear();
                            waterController.clear();
                            
                            // Reset emissions
                            scope1Emissions.value = 0.0;
                            scope2Emissions.value = 0.0;
                            scope3Emissions.value = 0.0;
                            totalEmissions.value = 0.0;
                            
                            // Show confirmation
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All fields have been reset')),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Save the calculation
                            isLoading.value = true;
                            try {
                              // Get organization ID if in organization mode
                              String? organizationId;
                              if (isOrganizationMode.value && selectedOrganization.value != null) {
                                organizationId = selectedOrganization.value!.id;
                              }
                              
                              // Save using the service
                              await CarbonCalculatorService.instance.saveCarbonFootprint(
                                scope1Emissions: scope1Emissions.value,
                                scope2Emissions: scope2Emissions.value,
                                scope3Emissions: scope3Emissions.value,
                                totalEmissions: totalEmissions.value,
                                organizationId: organizationId,
                              );
                              
                              // Update organization provider if in organization mode
                              if (isOrganizationMode.value && selectedOrganization.value != null) {
                                final orgProvider = Provider.of<OrganizationProvider>(
                                  context, 
                                  listen: false
                                );
                                
                                // Create carbon footprint model
                                final carbonFootprint = CarbonFootprint(
                                  totalEmissions: totalEmissions.value,
                                  unit: 'tCO₂e',
                                  year: DateTime.now().year,
                                  reductionGoal: 30.0, // Default 30% reduction goal
                                  reductionTarget: totalEmissions.value * 0.7, // 30% reduction
                                  categories: [
                                    EmissionCategory(
                                      name: 'Scope 1: Direct Emissions',
                                      value: scope1Emissions.value,
                                      icon: 'local_fire_department',
                                    ),
                                    EmissionCategory(
                                      name: 'Scope 2: Indirect Emissions',
                                      value: scope2Emissions.value,
                                      icon: 'electric_bolt',
                                    ),
                                    EmissionCategory(
                                      name: 'Scope 3: Value Chain Emissions',
                                      value: scope3Emissions.value,
                                      icon: 'business',
                                    ),
                                  ],
                                );
                                
                                // Update the organization with the new carbon footprint
                                final updatedOrg = selectedOrganization.value!.copyWith(
                                  carbonFootprint: carbonFootprint,
                                );
                                
                                // Update the provider
                                orgProvider.updateOrganization(updatedOrg);
                              }
                              
                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Carbon footprint saved successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error saving carbon footprint: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              isLoading.value = false;
                            }
                          },
                          icon: isLoading.value 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (isLoading.value)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
  
  // Helper method to build emission summary items
  Widget _buildEmissionSummary(BuildContext context, String title, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          '${value.toStringAsFixed(2)} tCO₂e',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
  
  // Helper method to safely parse double values
  double _parseDouble(String? value) {
    if (value == null || value.isEmpty) {
      return 0.0;
    }
    return double.tryParse(value) ?? 0.0;
  }
  
  // Build modern scope selection button
  Widget _buildScopeButton(BuildContext context, String title, IconData icon, bool isSelected) {
    return ElevatedButton.icon(
      onPressed: () {
        // Handle scope selection
      },
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
    );
  }
  
  // Build modern input field for carbon data
  Widget _buildModernInputField(
    BuildContext context,
    String label,
    String defaultValue,
    TextEditingController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            hintText: defaultValue,
          ),
        ),
      ),
    );
  }
  
  // This duplicate _buildEmissionSummary method was removed to fix the compilation error
  
  // Build Scope 1 tab content
  Widget _buildScope1Tab(
    BuildContext context,
    TextEditingController naturalGasController,
    TextEditingController fuelOilController,
    TextEditingController propaneController,
    TextEditingController dieselController,
    TextEditingController refrigerantsController,
  ) {
    // Debug print to verify tab is being built
    debugPrint('Building Scope 1 Tab');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scope 1: Direct Emissions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your direct emissions from owned or controlled sources.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Natural Gas
          _buildInputField(
            context,
            'Natural Gas (therms)',
            'Enter amount',
            naturalGasController,
            Icons.local_fire_department,
          ),
          
          // Fuel Oil
          _buildInputField(
            context,
            'Fuel Oil (gallons)',
            'Enter amount',
            fuelOilController,
            Icons.local_gas_station,
          ),
          
          // Propane
          _buildInputField(
            context,
            'Propane (gallons)',
            'Enter amount',
            propaneController,
            Icons.propane_tank,
          ),
          
          // Diesel
          _buildInputField(
            context,
            'Diesel (gallons)',
            'Enter amount',
            dieselController,
            Icons.local_shipping,
          ),
          
          // Refrigerants
          _buildInputField(
            context,
            'Refrigerants (kg)',
            'Enter amount',
            refrigerantsController,
            Icons.ac_unit,
          ),
        ],
      ),
    );
  }
  
  // Build Scope 2 tab content
  Widget _buildScope2Tab(
    BuildContext context,
    TextEditingController electricityController,
    TextEditingController steamController,
    TextEditingController heatingController,
    TextEditingController coolingController,
  ) {
    // Debug print to verify tab is being built
    debugPrint('Building Scope 2 Tab');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scope 2: Indirect Emissions from Purchased Energy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your indirect emissions from the generation of purchased electricity, steam, heating, and cooling.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Electricity
          _buildInputField(
            context,
            'Electricity (kWh)',
            'Enter amount',
            electricityController,
            Icons.electric_bolt,
          ),
          
          // Steam
          _buildInputField(
            context,
            'Steam (MMBtu)',
            'Enter amount',
            steamController,
            Icons.waves,
          ),
          
          // Heating
          _buildInputField(
            context,
            'Heating (MMBtu)',
            'Enter amount',
            heatingController,
            Icons.fireplace,
          ),
          
          // Cooling
          _buildInputField(
            context,
            'Cooling (ton-hours)',
            'Enter amount',
            coolingController,
            Icons.ac_unit,
          ),
        ],
      ),
    );
  }
  
  // Build Scope 3 tab content
  Widget _buildScope3Tab(
    BuildContext context,
    TextEditingController businessTravelController,
    TextEditingController employeeCommutingController,
    TextEditingController wasteController,
    TextEditingController purchasedGoodsController,
    TextEditingController capitalGoodsController,
    TextEditingController fuelEnergyController,
    TextEditingController transportationController,
  ) {
    // Debug print to verify tab is being built
    debugPrint('Building Scope 3 Tab');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scope 3: Other Indirect Emissions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your other indirect emissions that occur in your value chain.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Business Travel
          _buildInputField(
            context,
            'Business Travel (miles)',
            'Enter amount',
            businessTravelController,
            Icons.flight,
          ),
          
          // Employee Commuting
          _buildInputField(
            context,
            'Employee Commuting (miles)',
            'Enter amount',
            employeeCommutingController,
            Icons.directions_car,
          ),
          
          // Waste
          _buildInputField(
            context,
            'Waste (tons)',
            'Enter amount',
            wasteController,
            Icons.delete,
          ),
          
          // Purchased Goods and Services
          _buildInputField(
            context,
            'Purchased Goods and Services (\$)',
            'Enter amount',
            purchasedGoodsController,
            Icons.shopping_cart,
          ),
          
          // Capital Goods
          _buildInputField(
            context,
            'Capital Goods (\$)',
            'Enter amount',
            capitalGoodsController,
            Icons.business_center,
          ),
          
          // Fuel and Energy-Related Activities
          _buildInputField(
            context,
            'Fuel and Energy-Related Activities (kWh)',
            'Enter amount',
            fuelEnergyController,
            Icons.power,
          ),
          
          // Transportation and Distribution
          _buildInputField(
            context,
            'Transportation and Distribution (ton-miles)',
            'Enter amount',
            transportationController,
            Icons.local_shipping,
          ),
        ],
      ),
    );
  }
  
  // Build input field widget
  Widget _buildInputField(
    BuildContext context,
    String label,
    String hint,
    TextEditingController controller,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// Calculate emissions based on input values
void calculateEmissions(
  ValueNotifier<double> scope1Emissions,
  ValueNotifier<double> scope2Emissions,
  ValueNotifier<double> scope3Emissions,
  ValueNotifier<double> totalEmissions,
  String naturalGas,
  String fuelOil,
  String propane,
  String diesel,
  String refrigerants,
  String electricity,
  String steam,
  String heating,
  String cooling,
  String businessTravel,
  String employeeCommuting,
  String waste,
  String purchasedGoods,
  String capitalGoods,
  String fuelEnergy,
  String transportation,
) {
  // Emission factors (tCO2e per unit)
  const double naturalGasFactor = 0.0053; // per therm
  const double fuelOilFactor = 0.010; // per gallon
  const double propaneFactor = 0.0057; // per gallon
  const double dieselFactor = 0.010; // per gallon
  const double refrigerantsFactor = 1.8; // per kg (average for common refrigerants)
  
  const double electricityFactor = 0.000379; // per kWh (US average)
  const double steamFactor = 0.0661; // per MMBtu
  const double heatingFactor = 0.0531; // per MMBtu
  const double coolingFactor = 0.0141; // per ton-hour
  
  const double businessTravelFactor = 0.000404; // per mile (average)
  const double employeeCommutingFactor = 0.000404; // per mile (average)
  const double wasteFactor = 0.5; // per ton
  const double purchasedGoodsFactor = 0.0001; // per dollar
  const double capitalGoodsFactor = 0.00005; // per dollar
  const double fuelEnergyFactor = 0.0001; // per kWh
  const double transportationFactor = 0.0002; // per ton-mile
  
  // Calculate Scope 1 emissions
  double scope1 = 0.0;
  scope1 += _parseDouble(naturalGas) * naturalGasFactor;
  scope1 += _parseDouble(fuelOil) * fuelOilFactor;
  scope1 += _parseDouble(propane) * propaneFactor;
  scope1 += _parseDouble(diesel) * dieselFactor;
  scope1 += _parseDouble(refrigerants) * refrigerantsFactor;
  
  // Calculate Scope 2 emissions
  double scope2 = 0.0;
  scope2 += _parseDouble(electricity) * electricityFactor;
  scope2 += _parseDouble(steam) * steamFactor;
  scope2 += _parseDouble(heating) * heatingFactor;
  scope2 += _parseDouble(cooling) * coolingFactor;
  
  // Calculate Scope 3 emissions
  double scope3 = 0.0;
  scope3 += _parseDouble(businessTravel) * businessTravelFactor;
  scope3 += _parseDouble(employeeCommuting) * employeeCommutingFactor;
  scope3 += _parseDouble(waste) * wasteFactor;
  scope3 += _parseDouble(purchasedGoods) * purchasedGoodsFactor;
  scope3 += _parseDouble(capitalGoods) * capitalGoodsFactor;
  scope3 += _parseDouble(fuelEnergy) * fuelEnergyFactor;
  scope3 += _parseDouble(transportation) * transportationFactor;
  
  // Update state
  scope1Emissions.value = scope1;
  scope2Emissions.value = scope2;
  scope3Emissions.value = scope3;
  totalEmissions.value = scope1 + scope2 + scope3;
}

// Parse double from string with error handling
double _parseDouble(String value) {
  if (value.isEmpty) {
    return 0.0;
  }
  try {
    return double.parse(value);
  } catch (e) {
    return 0.0;
  }
}
