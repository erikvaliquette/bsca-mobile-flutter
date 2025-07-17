import 'package:flutter/material.dart';

// Helper methods for selection dialogs
class SelectionDialogs {
  static void showLanguageSelectionDialog(BuildContext context, Map<String, dynamic> preferences, Function setState) {
    final options = [
      {'code': 'en', 'name': 'English'},
      {'code': 'fr', 'name': 'French'},
      {'code': 'es', 'name': 'Spanish'},
      {'code': 'de', 'name': 'German'},
      {'code': 'zh', 'name': 'Chinese'},
      {'code': 'ja', 'name': 'Japanese'},
    ];
    
    _showSelectionDialog(context, 'Select Language', options, 'language', preferences, setState);
  }
  static void showElectricityGridSelectionDialog(BuildContext context, Map<String, dynamic> preferences, Function setState) {
    final options = [
      {'code': 'global', 'name': 'Global Average'},
      {'code': 'north_america', 'name': 'North America'},
      {'code': 'europe', 'name': 'Europe'},
      {'code': 'asia', 'name': 'Asia'},
      {'code': 'africa', 'name': 'Africa'},
      {'code': 'oceania', 'name': 'Oceania'},
    ];
    
    _showSelectionDialog(context, 'Select Electricity Grid', options, 'electricity_grid', preferences, setState);
  }
  
  static void showHomeElectricityGridSelectionDialog(BuildContext context, Map<String, dynamic> preferences, Function setState) {
    final options = [
      {'code': 'global', 'name': 'Global Average'},
      {'code': 'north_america', 'name': 'North America'},
      {'code': 'europe', 'name': 'Europe'},
      {'code': 'asia', 'name': 'Asia'},
      {'code': 'africa', 'name': 'Africa'},
      {'code': 'oceania', 'name': 'Oceania'},
    ];
    
    _showSelectionDialog(context, 'Select Home Electricity Grid', options, 'home_electricity_grid', preferences, setState);
  }
  
  static void showBusinessElectricityGridSelectionDialog(BuildContext context, Map<String, dynamic> preferences, Function setState) {
    final options = [
      {'code': 'global', 'name': 'Global Average'},
      {'code': 'north_america', 'name': 'North America'},
      {'code': 'europe', 'name': 'Europe'},
      {'code': 'asia', 'name': 'Asia'},
      {'code': 'africa', 'name': 'Africa'},
      {'code': 'oceania', 'name': 'Oceania'},
    ];
    
    _showSelectionDialog(context, 'Select Business Electricity Grid', options, 'business_electricity_grid', preferences, setState);
  }
  
  static void showElectricitySourceSelectionDialog(BuildContext context, Map<String, dynamic> preferences, Function setState) {
    final options = [
      {'code': 'grid_mix', 'name': 'Grid Mix (Default)'},
      {'code': 'coal', 'name': 'Coal'},
      {'code': 'natural_gas', 'name': 'Natural Gas'},
      {'code': 'nuclear', 'name': 'Nuclear'},
      {'code': 'hydro', 'name': 'Hydroelectric'},
      {'code': 'solar', 'name': 'Solar'},
      {'code': 'wind', 'name': 'Wind'},
    ];
    
    _showSelectionDialog(context, 'Select Electricity Source', options, 'electricity_source', preferences, setState);
  }
  
  static void showTransportationModeSelectionDialog(BuildContext context, Map<String, dynamic> preferences, Function setState) {
    final options = [
      {'code': 'car', 'name': 'Car'},
      {'code': 'bus', 'name': 'Bus'},
      {'code': 'train', 'name': 'Train'},
      {'code': 'bicycle', 'name': 'Bicycle'},
      {'code': 'walk', 'name': 'Walk'},
      {'code': 'motorcycle', 'name': 'Motorcycle'},
    ];
    
    _showSelectionDialog(context, 'Select Transportation Mode', options, 'transportation', preferences, setState);
  }
  
  static void showFuelTypeSelectionDialog(BuildContext context, Map<String, dynamic> preferences, Function setState) {
    final options = [
      {'code': 'petrol', 'name': 'Petrol/Gasoline'},
      {'code': 'diesel', 'name': 'Diesel'},
      {'code': 'electric', 'name': 'Electric'},
      {'code': 'hybrid', 'name': 'Hybrid'},
      {'code': 'hydrogen', 'name': 'Hydrogen'},
      {'code': 'natural_gas', 'name': 'Natural Gas'},
    ];
    
    _showSelectionDialog(context, 'Select Fuel Type', options, 'fuel_type', preferences, setState);
  }
  
  static void _showSelectionDialog(
    BuildContext context, 
    String title, 
    List<Map<String, String>> options, 
    String preferenceKey, 
    Map<String, dynamic> preferences,
    Function setState
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return ListTile(
                title: Text(option['name']!),
                selected: preferences[preferenceKey] == option['code'],
                onTap: () {
                  setState(() {
                    preferences[preferenceKey] = option['code'];
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }
}
