import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/travel_emissions_service.dart';
import '../../services/subscription_helper.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/upgrade_prompt_widget.dart';

class MyTravelEmissionsScreen extends StatefulWidget {
  const MyTravelEmissionsScreen({Key? key}) : super(key: key);

  @override
  State<MyTravelEmissionsScreen> createState() => _MyTravelEmissionsScreenState();
}

class _MyTravelEmissionsScreenState extends State<MyTravelEmissionsScreen> {
  bool _isLoading = true;
  List<TripData> _trips = [];
  double _totalEmissions = 0.0;
  double _totalDistance = 0.0;
  int _totalTrips = 0;
  Map<String, double> _emissionsByMode = {};
  Map<String, int> _tripsByMode = {};
  Map<String, double> _distanceByMode = {};
  Map<String, double> _emissionsByPurpose = {};
  String _mostUsedMode = '';
  String _highestEmissionMode = '';

  @override
  void initState() {
    super.initState();
    _loadTravelData();
  }

  Future<void> _loadTravelData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get all trips for the user
      final trips = await TravelEmissionsService.instance.getUserTrips(userId);
      
      // Calculate statistics
      _calculateStatistics(trips);

      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading travel data: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading travel data: $e')),
        );
      }
    }
  }

  void _calculateStatistics(List<TripData> trips) {
    _totalEmissions = 0.0;
    _totalDistance = 0.0;
    _totalTrips = trips.length;
    _emissionsByMode.clear();
    _tripsByMode.clear();
    _distanceByMode.clear();
    _emissionsByPurpose.clear();

    for (final trip in trips) {
      // Total emissions and distance
      _totalEmissions += trip.emissions;
      _totalDistance += trip.distance;

      // Emissions and trips by mode
      _emissionsByMode[trip.mode] = (_emissionsByMode[trip.mode] ?? 0.0) + trip.emissions;
      _tripsByMode[trip.mode] = (_tripsByMode[trip.mode] ?? 0) + 1;
      _distanceByMode[trip.mode] = (_distanceByMode[trip.mode] ?? 0.0) + trip.distance;

      // Emissions by purpose
      final purpose = trip.purpose ?? 'Personal';
      _emissionsByPurpose[purpose] = (_emissionsByPurpose[purpose] ?? 0.0) + trip.emissions;
    }

    // Find most used mode and highest emission mode
    if (_tripsByMode.isNotEmpty) {
      _mostUsedMode = _tripsByMode.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    if (_emissionsByMode.isNotEmpty) {
      _highestEmissionMode = _emissionsByMode.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Travel Emissions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : RefreshIndicator(
              onRefresh: _loadTravelData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                    
                    // Carbon Offset Information
                    _buildCarbonOffsetCard(),
                    const SizedBox(height: 24),
                    
                    // Emissions by Mode Chart
                    if (_emissionsByMode.isNotEmpty) ...[
                      _buildSectionTitle('Emissions by Transport Mode'),
                      const SizedBox(height: 16),
                      _buildEmissionsByModeChart(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Purpose Breakdown
                    if (_emissionsByPurpose.isNotEmpty) ...[
                      _buildSectionTitle('Emissions by Purpose'),
                      const SizedBox(height: 16),
                      _buildPurposeBreakdown(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Mode Statistics
                    if (_tripsByMode.isNotEmpty) ...[
                      _buildSectionTitle('Transport Mode Statistics'),
                      const SizedBox(height: 16),
                      _buildModeStatistics(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Recent Trips
                    if (_trips.isNotEmpty) ...[
                      _buildSectionTitle('Recent Trips'),
                      const SizedBox(height: 16),
                      _buildRecentTrips(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Emissions',
            '${_totalEmissions.toStringAsFixed(2)} kg CO₂e',
            Icons.cloud,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Distance',
            '${_totalDistance.toStringAsFixed(1)} km',
            Icons.route,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Trips',
            _totalTrips.toString(),
            Icons.trip_origin,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: SizedBox(
        height: 140, // Increased height for better proportions
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Optimized padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(icon, color: color, size: 24), // Smaller icon for better fit
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarbonOffsetCard() {
    // Calculate trees needed to offset emissions
    // Average tree absorbs about 22 kg CO2 per year (IPCC data)
    final treesNeeded = (_totalEmissions / 22).ceil();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.nature,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Carbon Offset',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(
                      text: 'It would take approximately ',
                    ),
                    TextSpan(
                      text: '$treesNeeded trees',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const TextSpan(
                      text: ' one full year to absorb your total travel emissions.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _launchIPCCUrl(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Learn more at IPCC',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: Colors.blue[700],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchIPCCUrl() async {
    const url = 'https://www.ipcc.ch/report/ar6/wg3/chapter/chapter-12/';
    final uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open IPCC link'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
          ),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmissionsByModeChart() {
    if (_emissionsByMode.isEmpty) return const SizedBox.shrink();

    final sortedEntries = _emissionsByMode.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 160, // Reduced height to make chart smaller
              child: PieChart(
                PieChartData(
                  sections: sortedEntries.map((entry) {
                    final percentage = (entry.value / _totalEmissions) * 100;
                    return PieChartSectionData(
                      color: _getModeColor(entry.key),
                      value: entry.value,
                      title: '', // Remove title from chart sections
                      radius: 60, // Smaller radius
                      titleStyle: const TextStyle(
                        fontSize: 0, // Hide text on chart
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 3,
                  centerSpaceRadius: 30, // Smaller center space
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: sortedEntries.map((entry) {
                final percentage = (entry.value / _totalEmissions) * 100;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getModeColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_getTravelModeName(entry.key)} (${percentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeBreakdown() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add business trip upgrade prompt if needed
            FutureBuilder<bool>(
              future: SubscriptionHelper.canAccessFeature(SubscriptionHelper.FEATURE_BUSINESS_TRIP_ATTRIBUTION),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                
                final canAccessBusinessTrips = snapshot.data ?? false;
                
                if (!canAccessBusinessTrips && _emissionsByPurpose.containsKey('Business')) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: const Text(
                              'Upgrade to Professional tier to attribute trips to business purposes',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => UpgradePromptWidget(
                                  featureKey: SubscriptionHelper.FEATURE_BUSINESS_TRIP_ATTRIBUTION,
                                  customMessage: 'Business trip attribution is available in Professional tier and above.',
                                  isDialog: true,
                                ),
                              );
                            },
                            child: const Text('UPGRADE'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            ..._emissionsByPurpose.entries.map((entry) {
              final percentage = (_emissionsByPurpose[entry.key]! / _totalEmissions) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          entry.key == 'Business' ? Colors.orange : Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeStatistics() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatRow('Most Used Mode', _getTravelModeName(_mostUsedMode)),
            const Divider(),
            _buildStatRow('Highest Emission Mode', _getTravelModeName(_highestEmissionMode)),
            const Divider(),
            _buildStatRow('Average Trip Distance', '${(_totalDistance / _totalTrips).toStringAsFixed(1)} km'),
            const Divider(),
            _buildStatRow('Average Emissions per Trip', '${(_totalEmissions / _totalTrips).toStringAsFixed(2)} kg CO₂e'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTrips() {
    // Show all trips instead of limiting to 5
    final allTrips = _trips.toList();
    
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Add a header with trip count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'All Trips (${allTrips.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          const Divider(),
          // List all trips
          ...allTrips.map((trip) {
            return ListTile(
              leading: Icon(
                _getModeIcon(trip.mode),
                color: _getModeColor(trip.mode),
                size: 28,
              ),
              title: Text(
                '${_getTravelModeName(trip.mode)} - ${trip.distance.toStringAsFixed(1)} km',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '${DateFormat('MMM dd, yyyy').format(trip.startTime)} • ${trip.emissions.toStringAsFixed(2)} kg CO₂e',
              ),
              trailing: Chip(
                label: Text(
                  trip.purpose ?? 'Personal',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: trip.purpose == 'Business' ? Colors.orange[100] : Colors.blue[100],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'car':
        return Colors.blue;
      case 'motorcycle':
        return Colors.orange;
      case 'truck':
        return Colors.red;
      case 'bus':
        return Colors.green;
      case 'train':
        return Colors.purple;
      case 'boat':
        return Colors.cyan;
      case 'plane':
        return Colors.indigo;
      case 'bicycle':
        return Colors.lime;
      case 'walk':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'car':
        return Icons.directions_car;
      case 'motorcycle':
        return Icons.motorcycle;
      case 'truck':
        return Icons.local_shipping;
      case 'bus':
        return Icons.directions_bus;
      case 'train':
        return Icons.train;
      case 'boat':
        return Icons.directions_boat;
      case 'plane':
        return Icons.airplanemode_active;
      case 'bicycle':
        return Icons.directions_bike;
      case 'walk':
        return Icons.directions_walk;
      default:
        return Icons.help;
    }
  }

  String _getTravelModeName(String mode) {
    switch (mode) {
      case 'car':
        return 'Car';
      case 'motorcycle':
        return 'Motorcycle';
      case 'truck':
        return 'Truck';
      case 'bus':
        return 'Bus';
      case 'train':
        return 'Train';
      case 'boat':
        return 'Boat';
      case 'plane':
        return 'Plane';
      case 'bicycle':
        return 'Bicycle';
      case 'walk':
        return 'Walking';
      default:
        return mode.toUpperCase();
    }
  }
}
