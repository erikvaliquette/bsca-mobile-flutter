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
    
    // Form controllers for Scope 1
    final naturalGasController = useTextEditingController();
    final fuelOilController = useTextEditingController();
    final propaneController = useTextEditingController();
    final dieselController = useTextEditingController();
    final refrigerantsController = useTextEditingController();
    
    // Form controllers for Scope 2
    final electricityController = useTextEditingController();
    final steamController = useTextEditingController();
    final heatingController = useTextEditingController();
    final coolingController = useTextEditingController();
    
    // Form controllers for Scope 3
    final businessTravelController = useTextEditingController();
    final employeeCommutingController = useTextEditingController();
    final wasteController = useTextEditingController();
    final purchasedGoodsController = useTextEditingController();
    final capitalGoodsController = useTextEditingController();
    final fuelEnergyController = useTextEditingController();
    final transportationController = useTextEditingController();
    
    // Calculate emissions when inputs change
    useEffect(() {
      calculateEmissions(
        scope1Emissions,
        scope2Emissions,
        scope3Emissions,
        totalEmissions,
        naturalGasController.text,
        fuelOilController.text,
        propaneController.text,
        dieselController.text,
        refrigerantsController.text,
        electricityController.text,
        steamController.text,
        heatingController.text,
        coolingController.text,
        businessTravelController.text,
        employeeCommutingController.text,
        wasteController.text,
        purchasedGoodsController.text,
        capitalGoodsController.text,
        fuelEnergyController.text,
        transportationController.text,
      );
      return null;
    }, [
      naturalGasController.text,
      fuelOilController.text,
      propaneController.text,
      dieselController.text,
      refrigerantsController.text,
      electricityController.text,
      steamController.text,
      heatingController.text,
      coolingController.text,
      businessTravelController.text,
      employeeCommutingController.text,
      wasteController.text,
      purchasedGoodsController.text,
      capitalGoodsController.text,
      fuelEnergyController.text,
      transportationController.text,
    ]);
    
    // Debug print to verify build is being called
    debugPrint('Building CarbonCalculatorScreen');
    
    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isOrganizationMode.value ? 'Organization Carbon Calculator' : 'Carbon Footprint Calculator'),
          bottom: TabBar(
            labelColor: Theme.of(context).primaryColor,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Scope 1'),
              Tab(text: 'Scope 2'),
              Tab(text: 'Scope 3'),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
            // Organization selector (if not in organization mode)
            if (!isOrganizationMode.value)
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calculate For',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Personal'),
                              value: false,
                              groupValue: isOrganizationMode.value,
                              onChanged: (value) {
                                if (value != null) {
                                  isOrganizationMode.value = value;
                                  selectedOrganization.value = null;
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Organization'),
                              value: true,
                              groupValue: isOrganizationMode.value,
                              onChanged: (value) {
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
                              },
                            ),
                          ),
                        ],
                      ),
                      if (isOrganizationMode.value && selectedOrganization.value == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Please select an organization in the Organization tab first',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
            // Summary card at the top
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Carbon Footprint',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildEmissionSummary(
                          context,
                          'Scope 1',
                          scope1Emissions.value,
                          Colors.blue,
                        ),
                        _buildEmissionSummary(
                          context,
                          'Scope 2',
                          scope2Emissions.value,
                          Colors.green,
                        ),
                        _buildEmissionSummary(
                          context,
                          'Scope 3',
                          scope3Emissions.value,
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Total: ${totalEmissions.value.toStringAsFixed(2)} tCO₂e',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (totalEmissions.value > 0)
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: scope1Emissions.value,
                                title: 'Scope 1',
                                color: Colors.blue,
                                radius: 60,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PieChartSectionData(
                                value: scope2Emissions.value,
                                title: 'Scope 2',
                                color: Colors.green,
                                radius: 60,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PieChartSectionData(
                                value: scope3Emissions.value,
                                title: 'Scope 3',
                                color: Colors.orange,
                                radius: 60,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Tab content
            Expanded(
              child: Container(
                color: Colors.white,
                child: TabBarView(
                  physics: const ClampingScrollPhysics(),
                  dragStartBehavior: DragStartBehavior.down,
                  children: [
                  // Scope 1 tab
                  _buildScope1Tab(
                    context,
                    naturalGasController,
                    fuelOilController,
                    propaneController,
                    dieselController,
                    refrigerantsController,
                  ),
                  
                  // Scope 2 tab
                  _buildScope2Tab(
                    context,
                    electricityController,
                    steamController,
                    heatingController,
                    coolingController,
                  ),
                  
                  // Scope 3 tab
                  _buildScope3Tab(
                    context,
                    businessTravelController,
                    employeeCommutingController,
                    wasteController,
                    purchasedGoodsController,
                    capitalGoodsController,
                    fuelEnergyController,
                    transportationController,
                  ),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reset button
                ElevatedButton.icon(
                  onPressed: () {
                    // Reset all form fields
                    naturalGasController.clear();
                    fuelOilController.clear();
                    propaneController.clear();
                    dieselController.clear();
                    refrigerantsController.clear();
                    electricityController.clear();
                    steamController.clear();
                    heatingController.clear();
                    coolingController.clear();
                    businessTravelController.clear();
                    employeeCommutingController.clear();
                    wasteController.clear();
                    purchasedGoodsController.clear();
                    capitalGoodsController.clear();
                    fuelEnergyController.clear();
                    transportationController.clear();
                    
                    // Reset emissions
                    scope1Emissions.value = 0.0;
                    scope2Emissions.value = 0.0;
                    scope3Emissions.value = 0.0;
                    totalEmissions.value = 0.0;
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                  ),
                ),
                
                // Save button
                ElevatedButton.icon(
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
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Carbon footprint saved successfully')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving carbon footprint: $e')),
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Build emission summary widget
  Widget _buildEmissionSummary(
    BuildContext context,
    String title,
    double value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${value.toStringAsFixed(2)} tCO₂e',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
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
