import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/fuel_types.dart';
import '../../providers/organization_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/location_service.dart';
import '../../services/travel_emissions_service.dart';
import '../../widgets/loading_indicator.dart';
import 'package:provider/provider.dart';

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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              unselectedWidgetColor: Colors.grey[400],
                            ),
                            child: RadioListTile<String>(
                              title: const Text(
                                'Personal',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              value: 'Personal',
                              groupValue: dialogPurpose,
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    dialogPurpose = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              unselectedWidgetColor: Colors.grey[400],
                            ),
                            child: RadioListTile<String>(
                              title: const Text(
                                'Business',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              value: 'Business',
                              groupValue: dialogPurpose,
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    dialogPurpose = value;
                                  });
                                }
                              },
                            ),
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
                            
                            // Update trip in database
                            await TravelEmissionsService.instance.updateTrip(
                              trip.id!,
                              {
                                'mode': dialogMode,
                                'purpose': dialogPurpose,
                                'emissions': newEmissions,
                                if (FuelTypes.requiresFuelType(dialogMode)) 'fuel_type': dialogFuelType,
                                if (!FuelTypes.requiresFuelType(dialogMode)) 'fuel_type': null,
                                if (selectedOrganizationId != null) 'organization_id': selectedOrganizationId,
                                if (dialogPurpose != 'Business') 'organization_id': null, // Clear organization if not business
                              },
                            );
                            
                            // Handle organization emissions attribution
                            if (dialogPurpose == 'Business' && selectedOrganizationId != null && newEmissions > 0) {
                              // If this was previously a business trip with different organization, we should ideally
                              // subtract from old organization and add to new one, but for simplicity we'll just add to new
                              debugPrint('🏢 Attempting to attribute $newEmissions kg CO2e to organization $selectedOrganizationId (from edit)');
                              try {
                                final attributionSuccess = await TravelEmissionsService.instance.attributeEmissionsToOrganization(
                                  selectedOrganizationId,
                                  newEmissions,
                                  trip.id!,
                                );
                                if (attributionSuccess) {
                                  debugPrint('✅ Successfully attributed emissions to organization (from edit)');
                                } else {
                                  debugPrint('⚠️ Failed to attribute emissions to organization (from edit)');
                                }
                              } catch (error) {
                                debugPrint('❌ Exception during emission attribution (from edit): $error');
                              }
                            }
                            
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
    final currentTrip = useState<TripData?>(null);
    final lastPosition = useState<Position?>(null);
    final positionStream = useState<Stream<Position>?>(null);
    final positionStreamSubscription = useState<StreamSubscription<Position>?>(null);
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
    
    // Load user trips on init and set up connectivity listener
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
      
      return () {
        connectivitySubscription.value?.cancel();
      };
    }, []);
    
    // Clean up position stream and connectivity subscription when widget is disposed
    useEffect(() {
      return () async {
        await positionStreamSubscription.value?.cancel();
        await connectivitySubscription.value?.cancel();
      };
    }, []);
    
    // Update trip with new position
    void updateTripWithNewPosition(
      Position position,
      ValueNotifier<Position?> lastPosition,
      ValueNotifier<TripData?> currentTrip,
      ValueNotifier<String> selectedMode,
      ValueNotifier<String?> selectedFuelType,
    ) {
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
      
      // Update trip distance
      final newDistance = currentTrip.value!.distance + distanceInKm;
      
      // Calculate emissions based on mode and distance
      final emissionFactor = FuelTypes.getEmissionFactor(
        selectedMode.value,
        selectedFuelType.value,
      );
      final newEmissions = newDistance * emissionFactor;
      
      // Check if this is the first meaningful movement (save trip to database)
      final isTemporaryTrip = currentTrip.value!.id!.startsWith('temp_');
      final hasMinimumDistance = newDistance >= 0.01; // 10 meters
      
      if (isTemporaryTrip && hasMinimumDistance) {
        // Save trip to database now that we have meaningful movement
        final tripToSave = currentTrip.value!.copyWith(
          id: null, // Remove temp ID so database can generate real ID
          distance: newDistance,
          emissions: newEmissions,
        );
        
        TravelEmissionsService.instance.createTrip(tripToSave).then((savedTrip) {
          if (savedTrip != null) {
            // Update current trip with real database ID
            currentTrip.value = savedTrip.copyWith(
              distance: newDistance,
              emissions: newEmissions,
            );
            debugPrint('Trip saved to database with ID: ${savedTrip.id}');
          }
        }).catchError((error) {
          debugPrint('Error saving trip to database: $error');
        });
      } else if (!isTemporaryTrip) {
        // Update existing trip in database
        TravelEmissionsService.instance.updateTrip(
          currentTrip.value!.id!,
          {
            'distance': newDistance,
            'emissions': newEmissions,
          },
        ).catchError((error) {
          debugPrint('Error updating trip: $error');
          // Continue tracking even if there's an error updating the trip
        });
      }
      
      // Only save location points if trip is saved in database (not temporary)
      if (!currentTrip.value!.id!.startsWith('temp_')) {
        TravelEmissionsService.instance.addLocationPoint(
          LocationPoint(
            tripId: currentTrip.value!.id!,
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now().toIso8601String(),
            altitude: position.altitude,
            speed: position.speed,
          ),
        ).catchError((error) {
          debugPrint('Error adding location point: $error');
          // Continue tracking even if there's an error saving the location point
        });
      }
      
      // Update current trip
      currentTrip.value = TripData(
        id: currentTrip.value!.id,
        userId: currentTrip.value!.userId,
        startTime: currentTrip.value!.startTime,
        endTime: currentTrip.value!.endTime,
        distance: newDistance,
        mode: currentTrip.value!.mode,
        fuelType: currentTrip.value!.fuelType,
        emissions: newEmissions,
        isActive: true,
        purpose: currentTrip.value!.purpose,
        startLocation: currentTrip.value!.startLocation,
        endLocation: currentTrip.value!.endLocation,
      );
    }
    
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
        // This will show the necessary dialogs and request permissions if needed
        final permissionGranted = await LocationService.instance.handleLocationPermission(context);
        if (!permissionGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to track trips')),
          );
          isLoading.value = false;
          return;
        }
        
        // Try to get current position with timeout
        Position? position;
        try {
          position = await LocationService.instance.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 15), onTimeout: () {
            throw TimeoutException('Location request timed out');
          });
        } catch (e) {
          debugPrint('Error getting current position: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to get current location. Please try again.')),
          );
          isLoading.value = false;
          return;
        }
        
        lastPosition.value = position;
        
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
        
        // Create a new trip with start location
        final startLocationString = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        
        final newTrip = TripData(
          userId: user.id,
          startTime: DateTime.now(),
          distance: 0.0,
          mode: selectedMode.value,
          fuelType: selectedFuelType.value,
          emissions: 0.0,
          isActive: true,
          purpose: selectedPurpose.value,
          startLocation: startLocationString,
        );
        
        // Don't save trip to database yet - wait for meaningful movement
        // Keep trip in memory with a temporary local ID
        final tempTrip = newTrip.copyWith(id: 'temp_${const Uuid().v4()}');
        currentTrip.value = tempTrip;
          
          // Don't save location points yet since trip isn't in database
          // Location points will be saved when trip gets meaningful movement
          
          // Start position stream
          positionStream.value = LocationService.instance.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          );
          
          // Listen to position updates
          positionStreamSubscription.value = positionStream.value?.listen((Position position) {
            updateTripWithNewPosition(position, lastPosition, currentTrip, selectedMode, selectedFuelType);
            lastPosition.value = position;
          });
          
          isTracking.value = true;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Started tracking your ${getTravelModeName(selectedMode.value, travelModes)} journey'),
            ),
          );
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
          // Check if trip has meaningful distance (minimum 0.01 km = 10 meters)
          final minDistance = 0.01; // 10 meters minimum
          final tripDistance = currentTrip.value!.distance;
          
          if (tripDistance < minDistance) {
            // For temporary trips, just discard them. For saved trips, delete from database.
            if (!currentTrip.value!.id!.startsWith('temp_')) {
              await TravelEmissionsService.instance.deleteTrip(currentTrip.value!.id!);
            }
            
            currentTrip.value = null;
            lastPosition.value = null;
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trip cancelled - no significant movement detected'),
                duration: Duration(seconds: 2),
              ),
            );
            
            isTracking.value = false;
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
          
          final endTime = DateTime.now();
          
          // Add end location if we have a last position
          String? endLocationString;
          if (lastPosition.value != null) {
            endLocationString = '${lastPosition.value!.latitude.toStringAsFixed(6)}, ${lastPosition.value!.longitude.toStringAsFixed(6)}';
          }
          
          // Handle organization attribution for business trips
          String? selectedOrganizationId;
          if (currentTrip.value!.purpose == 'Business') {
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
          
          // Handle temporary trips that need to be saved to database
          if (currentTrip.value!.id!.startsWith('temp_')) {
            // Save temporary trip to database
            final tripToSave = currentTrip.value!.copyWith(
              id: null, // Remove temp ID
              endTime: endTime,
              endLocation: endLocationString,
              isActive: false,
              organizationId: selectedOrganizationId,
            );
            
            final savedTrip = await TravelEmissionsService.instance.createTrip(tripToSave);
            if (savedTrip != null) {
              currentTrip.value = savedTrip;
              debugPrint('Temporary trip saved to database with ID: ${savedTrip.id}');
              
              // Attribute emissions to organization if this is a business trip
              if (selectedOrganizationId != null && savedTrip.emissions > 0) {
                debugPrint('🏢 Attempting to attribute ${savedTrip.emissions} kg CO2e to organization $selectedOrganizationId');
                try {
                  final attributionSuccess = await TravelEmissionsService.instance.attributeEmissionsToOrganization(
                    selectedOrganizationId,
                    savedTrip.emissions,
                    savedTrip.id!,
                  );
                  if (attributionSuccess) {
                    debugPrint('✅ Successfully attributed emissions to organization');
                  } else {
                    debugPrint('⚠️ Failed to attribute emissions to organization');
                  }
                } catch (error) {
                  debugPrint('❌ Exception during emission attribution: $error');
                }
              }
            }
          } else {
            // Update existing trip in database
            final updates = {
              'end_time': endTime.toIso8601String(),
              'distance': currentTrip.value!.distance,
              'emissions': currentTrip.value!.emissions,
              'is_active': false,
              'fuel_type': currentTrip.value!.fuelType,
              if (endLocationString != null) 'end_location': endLocationString,
              if (selectedOrganizationId != null) 'organization_id': selectedOrganizationId,
            };
            
            await TravelEmissionsService.instance.updateTrip(
              currentTrip.value!.id!,
              updates,
            );
            
            // Attribute emissions to organization if this is a business trip
            if (selectedOrganizationId != null && currentTrip.value!.emissions > 0) {
              debugPrint('🏢 Attempting to attribute ${currentTrip.value!.emissions} kg CO2e to organization $selectedOrganizationId');
              try {
                final attributionSuccess = await TravelEmissionsService.instance.attributeEmissionsToOrganization(
                  selectedOrganizationId,
                  currentTrip.value!.emissions,
                  currentTrip.value!.id!,
                );
                if (attributionSuccess) {
                  debugPrint('✅ Successfully attributed emissions to organization');
                } else {
                  debugPrint('⚠️ Failed to attribute emissions to organization');
                }
              } catch (error) {
                debugPrint('❌ Exception during emission attribution: $error');
              }
            }
          }
          
          // Batch sync location points for this trip (only if it was saved in database)
          if (!currentTrip.value!.id!.startsWith('temp_')) {
            TravelEmissionsService.instance.syncTripLocationPoints(
              currentTrip.value!.id!,
            ).catchError((error) {
              debugPrint('Error syncing location points: $error');
              // Continue even if sync fails - points will be synced later
              return false;
            });
          }
          
          // Add trip to list
          final updatedTrip = TripData(
            id: currentTrip.value!.id,
            userId: currentTrip.value!.userId,
            startTime: currentTrip.value!.startTime,
            endTime: endTime,
            distance: currentTrip.value!.distance,
            mode: currentTrip.value!.mode,
            fuelType: currentTrip.value!.fuelType,
            emissions: currentTrip.value!.emissions,
            isActive: false,
            purpose: currentTrip.value!.purpose,
            organizationId: selectedOrganizationId,
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
        actions: [
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
                        Text(
                          'Trip Purpose',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    unselectedWidgetColor: Colors.grey[400],
                                  ),
                                  child: RadioListTile<String>(
                                    title: Text(
                                      'Personal',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: selectedPurpose.value == 'Personal' 
                                            ? Theme.of(context).primaryColor 
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    value: 'Personal',
                                    groupValue: selectedPurpose.value,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => selectedPurpose.value = value!,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    unselectedWidgetColor: Colors.grey[400],
                                  ),
                                  child: RadioListTile<String>(
                                    title: Text(
                                      'Business',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: selectedPurpose.value == 'Business' 
                                            ? Theme.of(context).primaryColor 
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    value: 'Business',
                                    groupValue: selectedPurpose.value,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => selectedPurpose.value = value!,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                          const SizedBox(height: 12),
                          Container(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: FuelTypes.getFuelTypesForMode(selectedMode.value).length,
                              itemBuilder: (context, index) {
                                final fuelType = FuelTypes.getFuelTypesForMode(selectedMode.value)[index];
                                final isSelected = selectedFuelType.value == fuelType['id'];
                                
                                return GestureDetector(
                                  onTap: () {
                                    selectedFuelType.value = fuelType['id'] as String;
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        fuelType['name'] as String,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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


