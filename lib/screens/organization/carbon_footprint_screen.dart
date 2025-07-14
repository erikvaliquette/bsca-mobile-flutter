import 'package:flutter/material.dart';
import 'package:bsca_mobile_flutter/models/organization_model.dart';
import 'package:fl_chart/fl_chart.dart';

class CarbonFootprintScreen extends StatelessWidget {
  final CarbonFootprint carbonFootprint;

  const CarbonFootprintScreen({
    super.key,
    required this.carbonFootprint,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carbon Footprint'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(context),
            const SizedBox(height: 24),
            _buildReductionGoalCard(context),
            const SizedBox(height: 24),
            if (carbonFootprint.categories != null &&
                carbonFootprint.categories!.isNotEmpty)
              _buildCategoriesSection(context),
            const SizedBox(height: 24),
            _buildTravelEmissionsSection(context),
            const SizedBox(height: 24),
            _buildFuelTypesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Total Carbon Emissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  carbonFootprint.totalEmissions.toString(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  carbonFootprint.unit,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (carbonFootprint.categories != null &&
                carbonFootprint.categories!.isNotEmpty)
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: _getPieChartSections(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections() {
    if (carbonFootprint.categories == null || carbonFootprint.categories!.isEmpty) {
      return [];
    }

    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];

    return List.generate(
      carbonFootprint.categories!.length,
      (index) {
        final category = carbonFootprint.categories![index];
        final double percentage =
            (category.value / carbonFootprint.totalEmissions) * 100;
        
        return PieChartSectionData(
          color: colors[index % colors.length],
          value: category.value,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildReductionGoalCard(BuildContext context) {
    if (carbonFootprint.reductionGoal == null) {
      return const SizedBox.shrink();
    }

    final reductionPercentage = carbonFootprint.reductionTarget != null && carbonFootprint.reductionGoal! > 0
        ? (carbonFootprint.reductionTarget! / carbonFootprint.reductionGoal!) * 100
        : 0.0;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reduction Goal Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Goal: ${carbonFootprint.reductionGoal}% by ${carbonFootprint.year ?? 'future'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (carbonFootprint.reductionTarget != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Target: ${carbonFootprint.reductionTarget} ${carbonFootprint.unit}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: reductionPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  strokeWidth: 10,
                ),
                const SizedBox(width: 16),
                Text(
                  '${reductionPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emission Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            for (var category in carbonFootprint.categories!)
              _buildCategoryItem(context, category),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, EmissionCategory category) {
    return ExpansionTile(
      title: Row(
        children: [
          _getIconForCategory(category.icon),
          const SizedBox(width: 12),
          Text(category.name),
          const Spacer(),
          Text(
            '${category.value} ${carbonFootprint.unit}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      children: [
        if (category.subcategories != null && category.subcategories!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: category.subcategories!
                  .map((subcategory) => _buildSubcategoryItem(context, subcategory))
                  .toList(),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('No subcategories available'),
          ),
      ],
    );
  }

  Widget _buildSubcategoryItem(BuildContext context, EmissionSubcategory subcategory) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subcategory.name),
                if (subcategory.fuelType != null)
                  Text(
                    'Fuel: ${subcategory.fuelType}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${subcategory.value} ${carbonFootprint.unit}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelTypesSection(BuildContext context) {
    // Extract all fuel types from subcategories
    final List<String> fuelTypes = [];
    
    if (carbonFootprint.categories != null) {
      for (var category in carbonFootprint.categories!) {
        if (category.subcategories != null) {
          for (var subcategory in category.subcategories!) {
            if (subcategory.fuelType != null && 
                !fuelTypes.contains(subcategory.fuelType)) {
              fuelTypes.add(subcategory.fuelType!);
            }
          }
        }
      }
    }

    if (fuelTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fuel Types Used',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fuelTypes
                  .map((fuelType) => Chip(
                        label: Text(fuelType),
                        backgroundColor: _getFuelTypeColor(fuelType),
                        labelStyle: const TextStyle(
                          color: Colors.white,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTravelEmissionsSection(BuildContext context) {
    // Find the transportation category if it exists
    EmissionCategory? transportCategory;
    if (carbonFootprint.categories != null) {
      for (var category in carbonFootprint.categories!) {
        if (category.name.toLowerCase().contains('transport')) {
          transportCategory = category;
          break;
        }
      }
    }
    
    if (transportCategory == null || transportCategory.subcategories == null || transportCategory.subcategories!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Travel Emissions by Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transportCategory.subcategories!.length,
              itemBuilder: (context, index) {
                final subcategory = transportCategory!.subcategories![index];
                return ListTile(
                  leading: _getTransportIcon(subcategory.name),
                  title: Text(subcategory.name),
                  subtitle: subcategory.fuelType != null
                      ? Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getFuelTypeColor(subcategory.fuelType!).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                subcategory.fuelType!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getFuelTypeColor(subcategory.fuelType!),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      : null,
                  trailing: Text(
                    '${subcategory.value} ${carbonFootprint.unit}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _getIconForCategory(String? iconName) {
    if (iconName == null) return const Icon(Icons.eco);
    
    switch (iconName.toLowerCase()) {
      case 'factory':
        return const Icon(Icons.factory);
      case 'electric_bolt':
        return const Icon(Icons.electric_bolt);
      case 'commute':
        return const Icon(Icons.commute);
      case 'co2':
        return const Icon(Icons.co2);
      case 'water_drop':
        return const Icon(Icons.water_drop);
      case 'recycling':
        return const Icon(Icons.recycling);
      case 'energy':
        return const Icon(Icons.bolt);
      case 'agriculture':
        return const Icon(Icons.agriculture);
      case 'business':
        return const Icon(Icons.business);
      case 'flight':
        return const Icon(Icons.flight);
      case 'local_shipping':
        return const Icon(Icons.local_shipping);
      default:
        return const Icon(Icons.eco);
    }
  }

  Widget _getTransportIcon(String transportMode) {
    switch (transportMode.toLowerCase()) {
      case 'car':
        return CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.directions_car, color: Colors.black87),
        );
      case 'motorcycle':
        return CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.motorcycle, color: Colors.black87),
        );
      case 'truck':
        return CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.local_shipping, color: Colors.black87),
        );
      case 'bus':
        return CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.directions_bus, color: Colors.black87),
        );
      case 'train':
        return CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.train, color: Colors.black87),
        );
      case 'boat':
        return CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.directions_boat, color: Colors.black87),
        );
      case 'plane':
        return CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.flight, color: Colors.black87),
        );
      case 'bicycle':
        return CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.pedal_bike, color: Colors.black87),
        );
      case 'walking':
        return CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.directions_walk, color: Colors.black87),
        );
      default:
        return CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.commute, color: Colors.black87),
        );
    }
  }

  Color _getFuelTypeColor(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'petrol':
        return Colors.red[400]!;
      case 'diesel':
        return Colors.brown;
      case 'electric':
        return Colors.blue;
      case 'hybrid':
        return Colors.teal;
      case 'natural gas':
        return Colors.amber[700]!;
      case 'biofuel':
        return Colors.green;
      case 'jet fuel':
        return Colors.deepPurple;
      case 'sustainable aviation fuel':
        return Colors.purple;
      case 'human powered':
        return Colors.lightGreen;
      case 'wind power':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}
