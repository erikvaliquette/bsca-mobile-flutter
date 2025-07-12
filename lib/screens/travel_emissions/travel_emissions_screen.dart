import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

import '../../services/travel_emissions_service.dart';
import '../../services/supabase/supabase_client.dart';
import '../../widgets/loading_indicator.dart';

class TravelEmissionsScreen extends HookWidget {
  const TravelEmissionsScreen({Key? key}) : super(key: key);
  
  // Show dialog to edit a trip
  void _showEditTripDialog(BuildContext context, TripData trip, ValueNotifier<String> selectedMode, ValueNotifier<String> selectedPurpose) {
    // Set the initial purpose value based on the trip's purpose
    selectedPurpose.value = trip.purpose ?? 'Personal';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Purpose selection
                const Text('Trip Purpose'),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Personal'),
                        value: 'Personal',
                        groupValue: selectedPurpose.value,
                        onChanged: (value) {
                          if (value != null) {
                            selectedPurpose.value = value;
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Business'),
                        value: 'Business',
                        groupValue: selectedPurpose.value,
                        onChanged: (value) {
                          if (value != null) {
                            selectedPurpose.value = value;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Update trip in database
                  await TravelEmissionsService.instance.updateTrip(
                    trip.id!,
                    {
                      'purpose': selectedPurpose.value,
                    },
                  );
                  
                  // Close the dialog
                  Navigator.of(context).pop();
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trip updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating trip: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMode = useState('car');
    final selectedPurpose = useState('Personal');
    final isTracking = useState(false);
    final isLoading = useState(false);
    final trips = useState<List<TripData>>([]);
    final currentTrip = useState<TripData?>(null);
    final lastPosition = useState<Position?>(null);
    final positionStream = useState<Stream<Position>?>(null);
    final positionStreamSubscription = useState<StreamSubscription<Position>?>(null);
    final totalEmissions = useState(0.0);
    final showTripDetails = useState(false);
    final selectedTrip = useState<TripData?>(null);
    final editingTrip = useState<TripData?>(null);
    
    // Get the current user
    final user = Supabase.instance.client.auth.currentUser;
    
    // Define travel modes with emission factors (kg CO2e per km)
    final travelModes = [
      {'id': 'car', 'name': 'Car', 'icon': Icons.directions_car, 'emissionFactor': 0.192},
      {'id': 'motorcycle', 'name': 'Motorcycle', 'icon': Icons.motorcycle, 'emissionFactor': 0.113},
      {'id': 'truck', 'name': 'Truck', 'icon': Icons.local_shipping, 'emissionFactor': 0.250},
      {'id': 'bus', 'name': 'Bus', 'icon': Icons.directions_bus, 'emissionFactor': 0.105},
      {'id': 'train', 'name': 'Train', 'icon': Icons.train, 'emissionFactor': 0.041},
      {'id': 'boat', 'name': 'Boat', 'icon': Icons.directions_boat, 'emissionFactor': 0.195},
      {'id': 'plane', 'name': 'Plane', 'icon': Icons.airplanemode_active, 'emissionFactor': 0.255},
      {'id': 'bicycle', 'name': 'Bicycle', 'icon': Icons.directions_bike, 'emissionFactor': 0.0},
      {'id': 'walk', 'name': 'Walking', 'icon': Icons.directions_walk, 'emissionFactor': 0.0},
    ];
    
    // Calculate total emissions by mode
    final emissionsByMode = useMemoized(() {
      final result = <String, double>{};
      for (final mode in travelModes) {
        result[mode['id'] as String] = 0.0;
      }
      
      for (final trip in trips.value) {
        if (result.containsKey(trip.mode)) {
          result[trip.mode] = (result[trip.mode] ?? 0) + trip.emissions;
        }
      }
      
      return result;
    }, [trips.value]);
    
    // Load user trips
    useEffect(() {
      if (user != null) {
        loadUserTrips(isLoading, trips, totalEmissions);
      }
      return null;
    }, [user]);
    
    // Clean up position stream when widget is disposed
    useEffect(() {
      return () {
        positionStreamSubscription.value?.cancel();
      };
    }, []);
    
    // Get emission factor for selected mode
    double getEmissionFactor(String mode) {
      final modeData = travelModes.firstWhere(
        (m) => m['id'] == mode,
        orElse: () => travelModes[0],
      );
      return modeData['emissionFactor'] as double;
    }
    
    // Start tracking
    Future<void> startTracking() async {
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to be logged in to track trips')),
        );
        return;
      }
      
      isLoading.value = true;
      
      try {
        // First check if location services are enabled
        final locationEnabled = await Geolocator.isLocationServiceEnabled();
        if (!locationEnabled) {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Location Services Disabled'),
              content: const Text(
                'Please enable location services in your device settings to track your travel emissions.'
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Open Settings'),
                  onPressed: () {
                    Geolocator.openLocationSettings();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
          isLoading.value = false;
          return;
        }
        
        // Check permission status
        LocationPermission permission = await Geolocator.checkPermission();
        
        // Request permission if not granted
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          
          if (permission == LocationPermission.denied) {
            showDialog(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Location Permission Required'),
                content: const Text(
                  'This app needs location access to track your travel emissions. '
                  'Please grant location permission to use this feature.'
                ),
                actions: [
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
            isLoading.value = false;
            return;
          }
        }
        
        // Handle permanently denied permissions
        if (permission == LocationPermission.deniedForever) {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Location Permission Required'),
              content: const Text(
                'Location permissions are permanently denied. '
                'Please enable location in your device settings to use this feature.'
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Open Settings'),
                  onPressed: () {
                    Geolocator.openAppSettings();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
          isLoading.value = false;
          return;
        }
        
        // Get current position
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        lastPosition.value = position;
        
        // Create a new trip
        final newTrip = TripData(
          userId: user.id,
          startTime: DateTime.now(),
          distance: 0.0,
          mode: selectedMode.value,
          emissions: 0.0,
          isActive: true,
          purpose: selectedPurpose.value,
        );
        
        // Save trip to database
        final savedTrip = await TravelEmissionsService.instance.createTrip(newTrip);
        
        if (savedTrip != null) {
          currentTrip.value = savedTrip;
          
          // Add initial location point
          await TravelEmissionsService.instance.addLocationPoint(
            LocationPoint(
              tripId: savedTrip.id!,
              latitude: position.latitude,
              longitude: position.longitude,
              timestamp: DateTime.now().toIso8601String(),
              altitude: position.altitude,
              speed: position.speed,
            ),
          );
          
          // Start position stream
          positionStream.value = Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          );
          
          // Listen to position updates
          positionStreamSubscription.value = positionStream.value?.listen((Position position) {
            updateTripWithNewPosition(position, lastPosition, currentTrip, selectedMode);
            lastPosition.value = position;
          });
          
          isTracking.value = true;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Started tracking your ${getTravelModeName(selectedMode.value, travelModes)} journey'),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error starting tracking: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting tracking: $e')),
        );
      } finally {
        isLoading.value = false;
      }
    }
    
    // Stop tracking
    Future<void> stopTracking() async {
      isLoading.value = true;
      
      try {
        // Cancel position stream
        await positionStreamSubscription.value?.cancel();
        positionStreamSubscription.value = null;
        positionStream.value = null;
        
        if (currentTrip.value != null) {
          // Update trip in database
          final endTime = DateTime.now();
          await TravelEmissionsService.instance.updateTrip(
            currentTrip.value!.id!,
            {
              'end_time': endTime.toIso8601String(),
              'distance': currentTrip.value!.distance,
              'emissions': currentTrip.value!.emissions,
              'is_active': false,
            },
          );
          
          // Add trip to list
          final updatedTrip = TripData(
            id: currentTrip.value!.id,
            userId: currentTrip.value!.userId,
            startTime: currentTrip.value!.startTime,
            endTime: endTime,
            distance: currentTrip.value!.distance,
            mode: currentTrip.value!.mode,
            emissions: currentTrip.value!.emissions,
            isActive: false,
          );
          
          trips.value = [updatedTrip, ...trips.value];
          totalEmissions.value += updatedTrip.emissions;
          
          currentTrip.value = null;
          lastPosition.value = null;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stopped tracking your journey')),
          );
        }
        
        isTracking.value = false;
      } catch (e) {
        debugPrint('Error stopping tracking: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping tracking: $e')),
        );
      } finally {
        isLoading.value = false;
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Emissions'),
      ),
      body: user == null
          ? const Center(child: Text('Please log in to track your travel emissions'))
          : isLoading.value
              ? const Center(child: LoadingIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total emissions card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Carbon Emissions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${totalEmissions.value.toStringAsFixed(2)} kg CO₂e',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Emissions by mode chart
                        if (trips.value.isNotEmpty) ...[
                          const Text(
                            'Emissions by Mode of Travel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: emissionsByMode.values.isEmpty
                                    ? 10
                                    : emissionsByMode.values.reduce((a, b) => a > b ? a : b) * 1.2,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipBgColor: Colors.blueGrey,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final mode = emissionsByMode.keys.elementAt(groupIndex);
                                      return BarTooltipItem(
                                        '${getTravelModeName(mode, travelModes)}: ${rod.toY.toStringAsFixed(2)} kg',
                                        const TextStyle(color: Colors.white),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value < 0 || value >= emissionsByMode.length) {
                                          return const SizedBox();
                                        }
                                        final mode = emissionsByMode.keys.elementAt(value.toInt());
                                        final modeData = travelModes.firstWhere(
                                          (m) => m['id'] == mode,
                                          orElse: () => travelModes[0],
                                        );
                                        return Icon(modeData['icon'] as IconData);
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: emissionsByMode.entries
                                    .map(
                                      (entry) => BarChartGroupData(
                                        x: emissionsByMode.keys.toList().indexOf(entry.key),
                                        barRods: [
                                          BarChartRodData(
                                            toY: entry.value,
                                            color: getModeColor(entry.key),
                                            width: 20,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(4),
                                              topRight: Radius.circular(4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Mode selection
                        const Text(
                          'Select Mode of Travel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Trip purpose selection
                        const Text(
                          'Trip Purpose',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Personal'),
                                value: 'Personal',
                                groupValue: selectedPurpose.value,
                                onChanged: (value) {
                                  if (value != null) {
                                    selectedPurpose.value = value;
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Business'),
                                value: 'Business',
                                groupValue: selectedPurpose.value,
                                onChanged: (value) {
                                  if (value != null) {
                                    selectedPurpose.value = value;
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: travelModes.map((mode) {
                            final isSelected = selectedMode.value == mode['id'];
                            return InkWell(
                              onTap: isTracking.value
                                  ? null
                                  : () {
                                      selectedMode.value = mode['id'] as String;
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      mode['icon'] as IconData,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      mode['name'] as String,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.onPrimary
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        
                        // Start/Stop tracking button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isLoading.value
                                ? null
                                : isTracking.value
                                    ? stopTracking
                                    : startTracking,
                            icon: Icon(
                              isTracking.value ? Icons.stop : Icons.play_arrow,
                            ),
                            label: Text(
                              isTracking.value ? 'Stop Tracking' : 'Start Tracking',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Recent trips
                        const Text(
                          'Recent Trips',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        trips.value.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No trips recorded yet'),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: trips.value.length,
                                itemBuilder: (context, index) {
                                  final trip = trips.value[index];
                                  final modeData = travelModes.firstWhere(
                                    (m) => m['id'] == trip.mode,
                                    orElse: () => travelModes[0],
                                  );
                                  
                                  return Dismissible(
                                    key: Key(trip.id ?? 'trip-$index'),
                                    background: Container(
                                      color: Colors.blue,
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 20),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                      ),
                                    ),
                                    secondaryBackground: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      if (direction == DismissDirection.endToStart) {
                                        // Delete confirmation
                                        return await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Confirm Delete'),
                                              content: const Text('Are you sure you want to delete this trip?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      } else if (direction == DismissDirection.startToEnd) {
                                        // Edit trip
                                        _showEditTripDialog(context, trip, selectedMode, selectedPurpose);
                                        return false; // Don't dismiss the item
                                      }
                                      return false;
                                    },
                                    onDismissed: (direction) async {
                                      if (direction == DismissDirection.endToStart) {
                                        // Delete the trip
                                        isLoading.value = true;
                                        try {
                                          final success = await TravelEmissionsService.instance.deleteTrip(trip.id!);
                                          if (success) {
                                            // Remove from list
                                            final updatedTrips = List<TripData>.from(trips.value);
                                            updatedTrips.removeAt(index);
                                            trips.value = updatedTrips;
                                            
                                            // Update total emissions
                                            totalEmissions.value -= trip.emissions;
                                            
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Trip deleted successfully')),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Failed to delete trip')),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error deleting trip: $e')),
                                          );
                                        } finally {
                                          isLoading.value = false;
                                        }
                                      }
                                    },
                                    child: Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: Icon(modeData['icon'] as IconData),
                                        title: Text(
                                          '${modeData['name']} - ${trip.distance.toStringAsFixed(2)} km',
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${DateFormat('MMM d, yyyy - HH:mm').format(trip.startTime)}'
                                              '${trip.endTime != null ? ' to ${DateFormat('HH:mm').format(trip.endTime!)}' : ''}',
                                            ),
                                            Text('Purpose: ${trip.purpose ?? 'Not specified'}'),
                                          ],
                                        ),
                                        trailing: Text(
                                          '${trip.emissions.toStringAsFixed(2)} kg',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onTap: () {
                                          selectedTrip.value = trip;
                                          showTripDetails.value = true;
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
                
                // Edit trip dialog
                if (editingTrip.value != null)
                  AlertDialog(
                    title: const Text('Edit Trip'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Purpose selection
                          const Text('Trip Purpose'),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Personal'),
                                  value: 'Personal',
                                  groupValue: selectedPurpose.value,
                                  onChanged: (value) {
                                    if (value != null) {
                                      selectedPurpose.value = value;
                                    }
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Business'),
                                  value: 'Business',
                                  groupValue: selectedPurpose.value,
                                  onChanged: (value) {
                                    if (value != null) {
                                      selectedPurpose.value = value;
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          editingTrip.value = null;
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (editingTrip.value != null) {
                            isLoading.value = true;
                            try {
                              // Update trip in database
                              await TravelEmissionsService.instance.updateTrip(
                                editingTrip.value!.id!,
                                {
                                  'purpose': selectedPurpose.value,
                                },
                              );
                              
                              // Update trip in list
                              final index = trips.value.indexWhere((t) => t.id == editingTrip.value!.id);
                              if (index != -1) {
                                final updatedTrip = TripData(
                                  id: editingTrip.value!.id,
                                  userId: editingTrip.value!.userId,
                                  startTime: editingTrip.value!.startTime,
                                  endTime: editingTrip.value!.endTime,
                                  distance: editingTrip.value!.distance,
                                  mode: editingTrip.value!.mode,
                                  emissions: editingTrip.value!.emissions,
                                  isActive: editingTrip.value!.isActive,
                                  startLocation: editingTrip.value!.startLocation,
                                  endLocation: editingTrip.value!.endLocation,
                                  purpose: selectedPurpose.value,
                                );
                                
                                final updatedTrips = List<TripData>.from(trips.value);
                                updatedTrips[index] = updatedTrip;
                                trips.value = updatedTrips;
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Trip updated successfully')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error updating trip: $e')),
                              );
                            } finally {
                              isLoading.value = false;
                              editingTrip.value = null;
                            }
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
      // Trip details modal
      bottomSheet: showTripDetails.value && selectedTrip.value != null
          ? Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trip Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            showTripDetails.value = false;
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TripDetailItem(
                            icon: Icons.calendar_today,
                            label: 'Date',
                            value: DateFormat('MMMM d, yyyy').format(selectedTrip.value!.startTime),
                          ),
                          TripDetailItem(
                            icon: Icons.access_time,
                            label: 'Time',
                            value: '${DateFormat('HH:mm').format(selectedTrip.value!.startTime)} '
                                '${selectedTrip.value!.endTime != null ? '- ${DateFormat('HH:mm').format(selectedTrip.value!.endTime!)}' : '(In progress)'}',
                          ),
                          TripDetailItem(
                            icon: Icons.straighten,
                            label: 'Distance',
                            value: '${selectedTrip.value!.distance.toStringAsFixed(2)} km',
                          ),
                          TripDetailItem(
                            icon: Icons.eco,
                            label: 'Emissions',
                            value: '${selectedTrip.value!.emissions.toStringAsFixed(2)} kg CO₂e',
                          ),
                          TripDetailItem(
                            icon: travelModes.firstWhere(
                              (m) => m['id'] == selectedTrip.value!.mode,
                              orElse: () => travelModes[0],
                            )['icon'] as IconData,
                            label: 'Mode of Travel',
                            value: getTravelModeName(selectedTrip.value!.mode, travelModes),
                          ),
                          TripDetailItem(
                            icon: Icons.work,
                            label: 'Purpose',
                            value: selectedTrip.value!.purpose ?? 'Not specified',
                          ),
                          if (selectedTrip.value!.startLocation != null)
                            TripDetailItem(
                              icon: Icons.location_on,
                              label: 'Start Location',
                              value: selectedTrip.value!.startLocation!,
                            ),
                          if (selectedTrip.value!.endLocation != null)
                            TripDetailItem(
                              icon: Icons.location_off,
                              label: 'End Location',
                              value: selectedTrip.value!.endLocation!,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              showTripDetails.value = false;
                              isLoading.value = true;
                              
                              try {
                                await TravelEmissionsService.instance.deleteTrip(selectedTrip.value!.id!);
                                
                                // Update trips list
                                trips.value = trips.value.where((t) => t.id != selectedTrip.value!.id).toList();
                                totalEmissions.value -= selectedTrip.value!.emissions;
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Trip deleted')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error deleting trip: $e')),
                                );
                              } finally {
                                isLoading.value = false;
                              }
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Trip'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

// Helper widget for trip details
class TripDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const TripDetailItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper functions
Future<void> loadUserTrips(
  ValueNotifier<bool> isLoading,
  ValueNotifier<List<TripData>> trips,
  ValueNotifier<double> totalEmissions,
) async {
  if (Supabase.instance.client.auth.currentUser == null) return;
  
  try {
    isLoading.value = true;
    final userTrips = await TravelEmissionsService.instance.getUserTrips(
      Supabase.instance.client.auth.currentUser!.id,
    );
    
    trips.value = userTrips;
    
    // Calculate total emissions
    double total = 0;
    for (final trip in userTrips) {
      total += trip.emissions;
    }
    totalEmissions.value = total;
  } catch (e) {
    debugPrint('Error loading trips: $e');
  } finally {
    isLoading.value = false;
  }
}

void updateTripWithNewPosition(
  Position position,
  ValueNotifier<Position?> lastPosition,
  ValueNotifier<TripData?> currentTrip,
  ValueNotifier<String> selectedMode,
) async {
  if (lastPosition.value == null || currentTrip.value == null) return;
  
  // Calculate distance between last position and current position
  final distanceInMeters = Geolocator.distanceBetween(
    lastPosition.value!.latitude,
    lastPosition.value!.longitude,
    position.latitude,
    position.longitude,
  );
  
  // Convert to kilometers
  final distanceInKm = distanceInMeters / 1000;
  
  // Only update if we've moved a meaningful distance (to filter out GPS jitter)
  if (distanceInKm > 0.005) { // 5 meters
    final updatedDistance = currentTrip.value!.distance + distanceInKm;
    final emissionFactor = getEmissionFactor(currentTrip.value!.mode);
    final updatedEmissions = updatedDistance * emissionFactor;
    
    // Update current trip
    currentTrip.value = TripData(
      id: currentTrip.value!.id,
      userId: currentTrip.value!.userId,
      startTime: currentTrip.value!.startTime,
      distance: updatedDistance,
      mode: currentTrip.value!.mode,
      emissions: updatedEmissions,
      isActive: true,
    );
    
    // Update trip in database
    await TravelEmissionsService.instance.updateTrip(
      currentTrip.value!.id!,
      {
        'distance': updatedDistance,
        'emissions': updatedEmissions,
      },
    );
    
    // Add location point
    await TravelEmissionsService.instance.addLocationPoint(
      LocationPoint(
        tripId: currentTrip.value!.id!,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now().toIso8601String(),
        altitude: position.altitude,
        speed: position.speed,
      ),
    );
  }
}

double getEmissionFactor(String mode) {
  switch (mode) {
    case 'car':
      return 0.192;
    case 'bus':
      return 0.105;
    case 'train':
      return 0.041;
    case 'plane':
      return 0.255;
    case 'bicycle':
    case 'walk':
      return 0.0;
    default:
      return 0.192; // Default to car
  }
}

String getTravelModeName(String mode, List<Map<String, dynamic>> travelModes) {
  final modeData = travelModes.firstWhere(
    (m) => m['id'] == mode,
    orElse: () => travelModes[0],
  );
  return modeData['name'] as String;
}

Color getModeColor(String mode) {
  switch (mode) {
    case 'car':
      return Colors.blue;
    case 'motorcycle':
      return Colors.orange;
    case 'truck':
      return Colors.brown;
    case 'bus':
      return Colors.green;
    case 'train':
      return Colors.purple;
    case 'boat':
      return Colors.lightBlue;
    case 'plane':
      return Colors.red;
    case 'bicycle':
      return Colors.teal;
    case 'walk':
      return Colors.lime;
    default:
      return Colors.grey;
  }
}


