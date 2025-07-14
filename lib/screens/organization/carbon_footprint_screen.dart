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

    final reductionPercentage = carbonFootprint.reductionAchieved != null
        ? (carbonFootprint.reductionAchieved! / carbonFootprint.reductionGoal!) * 100
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
                        'Goal: ${carbonFootprint.reductionGoal} ${carbonFootprint.unit}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (carbonFootprint.reductionAchieved != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Achieved: ${carbonFootprint.reductionAchieved} ${carbonFootprint.unit}',
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
          Icon(
            IconData(
              int.tryParse(category.icon ?? '0xe25c') ?? 0xe25c,
              fontFamily: 'MaterialIcons',
            ),
          ),
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
                  .map((subcategory) => Padding(
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
                      ))
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
      transportCategory = carbonFootprint.categories!.firstWhere(
        (category) => category.name.toLowerCase().contains('transport'),
        orElse: () => EmissionCategory(name: 'Transportation', value: 0),
      );
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
  
  Widget _getTransportIcon(String transportMode) {
    IconData iconData;
    
    switch (transportMode.toLowerCase()) {
      case 'car':
        iconData = Icons.directions_car;
        break;
      case 'motorcycle':
        iconData = Icons.motorcycle;
        break;
      case 'truck':
        iconData = Icons.local_shipping;
        break;
      case 'bus':
        iconData = Icons.directions_bus;
        break;
      case 'train':
        iconData = Icons.train;
        break;
      case 'boat':
        iconData = Icons.directions_boat;
        break;
      case 'plane':
        iconData = Icons.flight;
        break;
      case 'bicycle':
        iconData = Icons.pedal_bike;
        break;
      case 'walking':
        iconData = Icons.directions_walk;
        break;
      default:
        iconData = Icons.commute;
        break;
    }
    
    return CircleAvatar(
      backgroundColor: Colors.grey[200],
      child: Icon(iconData, color: Colors.black87),
    );
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
