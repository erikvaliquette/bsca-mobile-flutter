import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import '../../models/fuel_types.dart';
import '../../providers/organization_provider.dart';
import '../../services/background_trip_tracking_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/trip_attribution_service.dart';
import '../../services/location_service.dart';
import '../../services/travel_emissions_service.dart';
import '../../services/subscription_helper.dart';
import '../../widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'trip_reconciliation_screen.dart';

class TravelEmissionsScreen extends HookWidget {
  const TravelEmissionsScreen({Key? key}) : super(key: key);
  
  // Show dialog to edit a trip
  void _showEditTripDialog(BuildContext context, TripData trip, ValueNotifier<String> selectedMode, ValueNotifier<String?> selectedFuelType, ValueNotifier<String> selectedPurpose) {
    // Set the initial values based on the trip's data
    String dialogPurpose = trip.purpose ?? 'Personal';
    String dialogMode = trip.mode;
    String? dialogFuelType = trip.fuelType;
    
    // Define travel modes list for dropdown
    final List<Map<String, dynamic>> travelModes = [
      {'id': 'car', 'name': 'Car', 'icon': Icons.directions_car},
      {'id': 'motorcycle', 'name': 'Motorcycle', 'icon': Icons.motorcycle},
      {'id': 'truck', 'name': 'Truck', 'icon': Icons.local_shipping},
      {'id': 'bus', 'name': 'Bus', 'icon': Icons.directions_bus},
      {'id': 'train', 'name': 'Train', 'icon': Icons.train},
      {'id': 'boat', 'name': 'Boat', 'icon': Icons.directions_boat},
      {'id': 'plane', 'name': 'Plane', 'icon': Icons.airplanemode_active},
      {'id': 'bicycle', 'name': 'Bicycle', 'icon': Icons.directions_bike},
      {'id': 'walk', 'name': 'Walking', 'icon': Icons.directions_walk},
    ];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Get fuel types for the selected mode
            final fuelTypes = FuelTypes.getFuelTypesForMode(dialogMode);
            
            // If the selected fuel type is not valid for the new mode, reset it to default
            if (FuelTypes.requiresFuelType(dialogMode) && 
                (dialogFuelType == null || 
                !fuelTypes.any((f) => f['id'] == dialogFuelType))) {
              dialogFuelType = FuelTypes.getDefaultFuelType(dialogMode);
            }
            
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Edit Trip',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode of travel selection
                    const Text(
                      'Mode of Travel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: dialogMode,
                          items: travelModes.map((mode) {
                            return DropdownMenuItem<String>(
                              value: mode['id'] as String,
                              child: Row(
                                children: [
                                  Icon(mode['icon'] as IconData, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 12),
                                  Text(mode['name'] as String),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                dialogMode = value;
                                // Reset fuel type when mode changes
                                dialogFuelType = FuelTypes.getDefaultFuelType(value);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Fuel type selection (if applicable)
                    if (FuelTypes.requiresFuelType(dialogMode)) ...[  
                      const Text(
                        'Fuel Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: dialogFuelType,
                            items: fuelTypes.map((fuelType) {
                              return DropdownMenuItem<String>(
                                value: fuelType['id'] as String,
                                child: Text(fuelType['name'] as String),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  dialogFuelType = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Purpose selection
                    const Text(
                      'Trip Purpose',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                dialogPurpose = 'Personal';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dialogPurpose == 'Personal' 
                                ? Theme.of(context).primaryColor 
                                : Colors.grey[200],
                              foregroundColor: dialogPurpose == 'Personal' 
                                ? Colors.white 
                                : Colors.black87,
                              elevation: dialogPurpose == 'Personal' ? 2 : 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Personal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                dialogPurpose = 'Business';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dialogPurpose == 'Business' 
                                ? Theme.of(context).primaryColor 
                                : Colors.grey[200],
                              foregroundColor: dialogPurpose == 'Business' 
                                ? Colors.white 
                                : Colors.black87,
                              elevation: dialogPurpose == 'Business' ? 2 : 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Business'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.grey[200],
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // Calculate new emissions based on the updated mode and fuel type
                            final emissionFactor = FuelTypes.getEmissionFactor(dialogMode, dialogFuelType);
                            final newEmissions = trip.distance * emissionFactor;
                            
                            // Update the ValueNotifier with the dialog values
                            selectedMode.value = dialogMode;
                            selectedPurpose.value = dialogPurpose;
                            if (FuelTypes.requiresFuelType(dialogMode)) {
                              selectedFuelType.value = dialogFuelType;
                            } else {
                              selectedFuelType.value = null;
                            }
                            
                            // Handle organization attribution for business trips
                            String? selectedOrganizationId;
                            if (dialogPurpose == 'Business') {
                              final organizationProvider = Provider.of<OrganizationProvider>(context, listen: false);
                              final organizations = organizationProvider.organizations;
                              
                              if (organizations.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No organizations found. Business trip will be saved without organization attribution.'),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                selectedOrganizationId = null;
                              } else if (organizations.length == 1) {
                                // Only one organization, use it automatically
                                selectedOrganizationId = organizations.first.id;
                              } else {
                                // Multiple organizations, show selection dialog
                                selectedOrganizationId = await showDialog<String>(
                                  context: context,
                                  builder: (BuildContext dialogContext) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text(
                                        'Select Organization',
                                        style: TextStyle(
                                          color: Theme.of(dialogContext).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Which organization should this business trip be attributed to?',
                                              style: TextStyle(fontSize: 16),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 16),
                                            ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: organizations.length,
                                              itemBuilder: (context, index) {
                                                final org = organizations[index];
                                                return Card(
                                                  margin: const EdgeInsets.only(bottom: 8),
                                                  child: ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundColor: Theme.of(dialogContext).primaryColor,
                                                      child: Text(
                                                        org.name.isNotEmpty ? org.name[0].toUpperCase() : 'O',
                                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                    title: Text(
                                                      org.name,
                                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    subtitle: org.description != null
                                                        ? Text(
                                                            org.description!,
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          )
                                                        : null,
                                                    onTap: () {
                                                      Navigator.of(dialogContext).pop(org.id);
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(dialogContext).pop(null);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                            
                            // Update trip in database (excluding organization_id as travel_trips table doesn't have this column)
                            await TravelEmissionsService.instance.updateTrip(
                              trip.id!,
                              {
                                'mode': dialogMode,
                                'purpose': dialogPurpose,
                                'emissions': newEmissions,
                                if (FuelTypes.requiresFuelType(dialogMode)) 'fuel_type': dialogFuelType,
                                if (!FuelTypes.requiresFuelType(dialogMode)) 'fuel_type': null,
                                // Note: organization_id is NOT saved to travel_trips table
                                // Organization attribution is handled separately via organization_carbon_footprint table
                              },
                            );
                            
                            // Handle organization emissions attribution with proper de-attribution
                            await _handleEmissionsReattribution(
                              originalTrip: trip,
                              newPurpose: dialogPurpose,
                              newOrganizationId: selectedOrganizationId,
                              newEmissions: newEmissions,
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
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(true);
    final isTracking = useState(false);
    final isConnected = useState(ConnectivityService.instance.isConnected);
    final trips = useState<List<TripData>>([]);
    final totalEmissions = useState(0.0);
    final selectedMode = useState('car');
    final selectedFuelType = useState<String?>(FuelTypes.getDefaultFuelType('car'));
    final selectedPurpose = useState('commute');
    final currentTrip = useState<TripData?>(BackgroundTripTrackingService.instance.currentTrip);
    final lastPosition = useState<Position?>(BackgroundTripTrackingService.instance.lastPosition);
    final connectivitySubscription = useState<StreamSubscription<bool>?>(null);
    final showTripDetails = useState(false);
    final selectedTrip = useState<TripData?>(null);
    final editingTrip = useState<TripData?>(null);
    
    // Get the current user
    final user = Supabase.instance.client.auth.currentUser;
    
    // Define travel modes with emission factors (kg CO2e per km)
    final List<Map<String, dynamic>> travelModes = [
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
    
    // Update fuel type when mode changes
    useEffect(() {
      if (FuelTypes.requiresFuelType(selectedMode.value)) {
        selectedFuelType.value = FuelTypes.getDefaultFuelType(selectedMode.value);
      } else {
        selectedFuelType.value = null;
      }
      return null;
    }, [selectedMode.value]);
    
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
    
    // Load user trips on init and set up connectivity and background service listeners
    useEffect(() {
      // Initial load of user trips
      loadUserTrips(isLoading, trips, totalEmissions);
      
      // Listen for connectivity changes
      connectivitySubscription.value = ConnectivityService.instance.connectionStatus.listen((connected) {
        isConnected.value = connected;
        
        // Show snackbar when connectivity changes
        if (connected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are back online. Syncing data...'),
              duration: Duration(seconds: 2),
            ),
          );
          
          // Reload trips when coming back online to get any newly synced data
          loadUserTrips(isLoading, trips, totalEmissions);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are offline. Data will be saved locally.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
      
      // Listen to background service state changes
      final currentTripSubscription = BackgroundTripTrackingService.instance.currentTripStream.listen((trip) {
        currentTrip.value = trip;
      });
      
      final isTrackingSubscription = BackgroundTripTrackingService.instance.isTrackingStream.listen((tracking) {
        isTracking.value = tracking;
      });
      
      final lastPositionSubscription = BackgroundTripTrackingService.instance.lastPositionStream.listen((position) {
        lastPosition.value = position;
      });
      
      // Initialize tracking state from background service
      isTracking.value = BackgroundTripTrackingService.instance.isTracking;
      
      return () {
        connectivitySubscription.value?.cancel();
        currentTripSubscription.cancel();
        isTrackingSubscription.cancel();
        lastPositionSubscription.cancel();
      };
    }, []);
    
    // Clean up position stream and connectivity subscription when widget is disposed
    useEffect(() {
      return () async {
        await connectivitySubscription.value?.cancel();
      };
    }, []);
    
    // Get emission factor for selected mode and fuel type
    double getEmissionFactor(String mode, String? fuelType) {
      return FuelTypes.getEmissionFactor(mode, fuelType);
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
        // Handle location permissions using the LocationService
        final permissionGranted = await LocationService.instance.handleLocationPermission(context);
        if (!permissionGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to track trips')),
          );
          isLoading.value = false;
          return;
        }
        
        // Check connectivity and show appropriate message
        final isConnected = ConnectivityService.instance.isConnected;
        if (!isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are offline. Trip will be saved locally and synced when online.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Start tracking using the background service
        final success = await BackgroundTripTrackingService.instance.startTracking(
          userId: user.id,
          mode: selectedMode.value,
          fuelType: selectedFuelType.value,
          purpose: selectedPurpose.value,
        );
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Started tracking your journey')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start tracking. Please try again.')),
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
        // Handle organization attribution for business trips
        String? selectedOrganizationId;
        if (selectedPurpose.value == 'Business') {
          // Check if user has access to business trip attribution feature
          final canAccessBusinessTrips = await SubscriptionHelper.canAccessFeature(
            SubscriptionHelper.FEATURE_BUSINESS_TRIP_ATTRIBUTION
          );
          
          if (!canAccessBusinessTrips) {
            // Show upgrade prompt and revert to Personal
            await SubscriptionHelper.showUpgradePromptIfNeeded(
              context,
              SubscriptionHelper.FEATURE_BUSINESS_TRIP_ATTRIBUTION,
              customMessage: 'Business trip attribution is available in Professional tier and above.'
            );
            // Reset to Personal - directly update the value notifier
            selectedPurpose.value = 'Personal';
            return;
          }
          
          final organizationProvider = Provider.of<OrganizationProvider>(context, listen: false);
          final organizations = organizationProvider.organizations;
          
          if (organizations.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No organizations found. Business trip will be saved without organization attribution.'),
                duration: Duration(seconds: 3),
              ),
            );
            selectedOrganizationId = null;
          } else if (organizations.length == 1) {
            // Only one organization, use it automatically
            selectedOrganizationId = organizations.first.id;
          } else {
            // Multiple organizations, show selection dialog
            selectedOrganizationId = await showDialog<String>(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(
                    'Select Organization',
                    style: TextStyle(
                      color: Theme.of(dialogContext).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Which organization should this business trip be attributed to?',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: organizations.length,
                          itemBuilder: (context, index) {
                            final org = organizations[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(dialogContext).primaryColor,
                                  child: Text(
                                    org.name.isNotEmpty ? org.name[0].toUpperCase() : 'O',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  org.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: org.description != null
                                    ? Text(
                                        org.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.of(dialogContext).pop(org.id);
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(null);
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                );
              },
            );
          }
        }
        
        // Stop tracking using the background service
        final completedTrip = await BackgroundTripTrackingService.instance.stopTracking(
          selectedOrganizationId: selectedOrganizationId,
        );
        
        if (completedTrip != null) {
          // Check if trip has meaningful distance
          if (completedTrip.distance < 0.01) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trip cancelled - no significant movement detected'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            // Add completed trip to the list and update totals
            trips.value = [completedTrip, ...trips.value];
            totalEmissions.value += completedTrip.emissions;
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Stopped tracking your journey')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No trip in progress')),
          );
        }
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
        actions: [
          // Menu for additional options
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reconcile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TripReconciliationScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'reconcile',
                child: Row(
                  children: [
                    Icon(Icons.sync_problem),
                    SizedBox(width: 8),
                    Text('Reconcile Orphaned Trips'),
                  ],
                ),
              ),
            ],
          ),
          // Connectivity status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: isConnected.value
                ? const Icon(Icons.wifi, color: Colors.green)
                : const Icon(Icons.wifi_off, color: Colors.red),
          ),
        ],
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
                        SizedBox(
                          width: double.infinity,
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
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
                                  const SizedBox(height: 12),
                                  Text(
                                    '${totalEmissions.value.toStringAsFixed(2)} kg CO₂e',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Mode selection
                        const Text(
                          'Select Mode of Travel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Icon-based mode selection grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.0,
                          children: travelModes.map((mode) {
                            final isSelected = selectedMode.value == mode['id'];
                            return GestureDetector(
                              onTap: isTracking.value
                                  ? null
                                  : () {
                                      selectedMode.value = mode['id'] as String;
                                    },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _getModeColor(mode['id'] as String)
                                      : _getModeColor(mode['id'] as String).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      mode['icon'] as IconData,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      mode['name'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        
                        // Fuel type selection (only show if the selected mode requires fuel type)
                        if (FuelTypes.requiresFuelType(selectedMode.value)) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Fuel Type',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: FuelTypes.getFuelTypesForMode(selectedMode.value).map((fuelType) {
                              final isSelected = selectedFuelType.value == fuelType['id'];
                              
                              return GestureDetector(
                                onTap: () {
                                  selectedFuelType.value = fuelType['id'] as String;
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _getFuelTypeColor(fuelType['id'] as String)
                                        : _getFuelTypeColor(fuelType['id'] as String).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getFuelTypeIcon(fuelType['id'] as String),
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        fuelType['name'] as String,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        
                        // Trip purpose selection
                        const SizedBox(height: 24),
                        Text(
                          'Trip Purpose',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => selectedPurpose.value = 'Personal',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selectedPurpose.value == 'Personal'
                                        ? Colors.grey[300]
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedPurpose.value == 'Personal'
                                          ? Colors.grey[400]!
                                          : Colors.grey[300]!,
                                      width: 1,
                                    ),
                                    boxShadow: selectedPurpose.value == 'Personal'
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: selectedPurpose.value == 'Personal'
                                            ? Colors.grey[700]
                                            : Colors.grey[500],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Personal',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: selectedPurpose.value == 'Personal'
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: selectedPurpose.value == 'Personal'
                                              ? Colors.grey[700]
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => selectedPurpose.value = 'Business',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selectedPurpose.value == 'Business'
                                        ? Colors.grey[300]
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedPurpose.value == 'Business'
                                          ? Colors.grey[400]!
                                          : Colors.grey[300]!,
                                      width: 1,
                                    ),
                                    boxShadow: selectedPurpose.value == 'Business'
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.business,
                                        color: selectedPurpose.value == 'Business'
                                            ? Colors.grey[700]
                                            : Colors.grey[500],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Business',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: selectedPurpose.value == 'Business'
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: selectedPurpose.value == 'Business'
                                              ? Colors.grey[700]
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                        Row(
                          children: [
                            const Text(
                              'Recent Trips',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Swipe right to edit, swipe left to delete',
                              child: Icon(
                                Icons.help_outline,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Swipe right to edit, swipe left to delete',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
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
                                        _showEditTripDialog(context, trip, selectedMode, selectedFuelType, selectedPurpose);
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
                                            
                                            // Check if widget is still mounted before showing snackbar
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Trip deleted successfully')),
                                              );
                                            }
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Failed to delete trip')),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error deleting trip: $e')),
                                            );
                                          }
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
                                            if (trip.fuelType != null) Text('Fuel Type: ${trip.fuelType}'),
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
                                        onLongPress: () {
                                          _showEditTripDialog(context, trip, selectedMode, selectedFuelType, selectedPurpose);
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
                          if (selectedTrip.value!.fuelType != null) TripDetailItem(
                            icon: Icons.local_gas_station,
                            label: 'Fuel Type',
                            value: selectedTrip.value!.fuelType!,
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

  /// Get color for transport mode
  Color _getModeColor(String mode) {
    return getModeColor(mode);
  }

  /// Get color for fuel type
  Color _getFuelTypeColor(String fuelType) {
    switch (fuelType) {
      case 'petrol':
        return Colors.orange;
      case 'diesel':
        return Colors.brown;
      case 'electric':
        return Colors.green;
      case 'hybrid':
        return Colors.lightGreen;
      case 'natural_gas':
        return Colors.blue;
      case 'biofuel':
        return Colors.amber;
      case 'jet_fuel':
        return Colors.red;
      case 'sustainable_aviation_fuel':
        return Colors.teal;
      case 'human_powered':
        return Colors.lime;
      case 'wind_power':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for fuel type
  IconData _getFuelTypeIcon(String fuelType) {
    switch (fuelType) {
      case 'petrol':
        return Icons.local_gas_station;
      case 'diesel':
        return Icons.local_gas_station;
      case 'electric':
        return Icons.electric_bolt;
      case 'hybrid':
        return Icons.eco;
      case 'natural_gas':
        return Icons.gas_meter;
      case 'biofuel':
        return Icons.grass;
      case 'jet_fuel':
        return Icons.airplanemode_active;
      case 'sustainable_aviation_fuel':
        return Icons.eco;
      case 'human_powered':
        return Icons.fitness_center;
      case 'wind_power':
        return Icons.air;
      default:
        return Icons.help;
    }
  }

  /// Handle emissions reattribution when editing trips
  /// This properly handles de-attribution from old organization and attribution to new organization
  /// Now uses the junction table for more robust attribution tracking
  Future<void> _handleEmissionsReattribution({
    required TripData originalTrip,
    required String newPurpose,
    required String? newOrganizationId,
    required double newEmissions,
  }) async {
    final wasBusinessTrip = originalTrip.purpose == 'Business';
    final isBusinessTrip = newPurpose == 'Business';
    final oldOrganizationId = originalTrip.organizationId;
    final oldEmissions = originalTrip.emissions;
    
    debugPrint('🔄 Handling emissions reattribution:');
    debugPrint('   Was Business: $wasBusinessTrip (${oldEmissions} kg CO2e to org: $oldOrganizationId)');
    debugPrint('   Is Business: $isBusinessTrip (${newEmissions} kg CO2e to org: $newOrganizationId)');
    
    try {
      // Step 1: Handle old attribution
      if (wasBusinessTrip && oldEmissions > 0) {
        if (oldOrganizationId != null) {
          // Normal case: remove attribution from known organization
          debugPrint('➖ Removing old attribution: ${oldEmissions} kg CO2e from organization $oldOrganizationId');
          
          // First check if there's an active attribution record in the junction table
          final attributions = await TripAttributionService.instance.getTripAttributions(originalTrip.id!);
          final hasActiveAttribution = attributions.any((attr) => attr.organizationId == oldOrganizationId && attr.isActive);
          
          if (hasActiveAttribution) {
            // If there's an active attribution record, deactivate it and update the organization carbon footprint
            final deAttributionSuccess = await TravelEmissionsService.instance.deAttributeEmissionsFromOrganization(
              oldOrganizationId,
              oldEmissions,
              originalTrip.id!,
            );
            
            if (deAttributionSuccess) {
              debugPrint('✅ Successfully removed old attribution');
            } else {
              debugPrint('⚠️ Failed to remove old attribution');
            }
          } else {
            // No active attribution record found, but we have an organizationId
            // This is a data inconsistency - log it but continue
            debugPrint('⚠️ Inconsistency detected: Trip has organizationId but no active attribution record');
          }
        } else {
          // Special case: orphaned business trip (was business but never attributed)
          debugPrint('🔍 Found orphaned business trip (${oldEmissions} kg CO2e) - was never attributed to an organization');
          // Orphaned case: check if this trip has any attribution records despite organizationId being null
          debugPrint('🔍 Checking for orphaned attribution records for trip ${originalTrip.id}');
          final attributions = await TripAttributionService.instance.getTripAttributions(originalTrip.id!);
          
          if (attributions.isNotEmpty) {
            // Unexpected: We have attribution records despite null organizationId
            debugPrint('⚠️ Inconsistency detected: Trip has null organizationId but has attribution records');
            
            // Deactivate all attribution records for this trip
            for (final attr in attributions) {
              await TravelEmissionsService.instance.deAttributeEmissionsFromOrganization(
                attr.organizationId,
                attr.emissionsAmount,
                originalTrip.id!,
              );
            }
            
            debugPrint('✅ Deactivated all attribution records for orphaned trip');
          } else {
            // If it's changing to personal, we don't need to do anything since it was never attributed
            // If it's staying business but now has an organization, we'll handle that in Step 2
            if (!isBusinessTrip) {
              debugPrint('✅ Orphaned business trip changing to personal - no de-attribution needed');
            }
          }
        }
      }
      
      // Step 2: Add new attribution if it's now a business trip
      if (isBusinessTrip && newOrganizationId != null && newEmissions > 0) {
        debugPrint('➕ Adding new attribution: ${newEmissions} kg CO2e to organization $newOrganizationId');
        final attributionSuccess = await TravelEmissionsService.instance.attributeEmissionsToOrganization(
          newOrganizationId,
          newEmissions,
          originalTrip.id!,
        );
        if (attributionSuccess) {
          debugPrint('✅ Successfully added new attribution');
        } else {
          debugPrint('⚠️ Failed to add new attribution');
        }
      }
      
      // Log the final state
      if (!wasBusinessTrip && !isBusinessTrip) {
        debugPrint('ℹ️ No attribution changes needed (personal → personal)');
      } else if (wasBusinessTrip && !isBusinessTrip) {
        debugPrint('🏠 Trip changed from business to personal - emissions de-attributed');
      } else if (!wasBusinessTrip && isBusinessTrip) {
        debugPrint('🏢 Trip changed from personal to business - emissions attributed');
      } else if (oldOrganizationId == newOrganizationId) {
        debugPrint('🔄 Same organization, emissions updated from ${oldEmissions} to ${newEmissions} kg CO2e');
      } else {
        debugPrint('🔀 Organization transfer completed: $oldOrganizationId → $newOrganizationId');
      }
      
    } catch (error) {
      debugPrint('❌ Error during emissions reattribution: $error');
    }
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
    
    // Get trips using our offline-capable service
    final userTrips = await TravelEmissionsService.instance.getUserTrips(
      Supabase.instance.client.auth.currentUser!.id,
    ).catchError((error) {
      debugPrint('Error loading trips: $error');
      return <TripData>[];
    });
    
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

// Using FuelTypes.getEmissionFactor instead of this local function

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


