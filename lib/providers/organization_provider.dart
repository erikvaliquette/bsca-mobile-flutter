import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/organization_model.dart';
import '../services/organization_service.dart';
import '../services/validation_service.dart';
import '../services/notifications/notification_provider.dart';
import '../models/organization_membership_model.dart';

class OrganizationProvider with ChangeNotifier {
  List<Organization> _organizations = [];
  Organization? _selectedOrganization;
  bool _isLoading = false;
  String? _error;
  
  // Notification provider reference for badge updates
  NotificationProvider? _notificationProvider;
  
  // Pending validation requests for organizations where user is admin
  List<OrganizationMembership> _pendingValidationRequests = [];
  List<OrganizationMembership> get pendingValidationRequests => _pendingValidationRequests;
  
  // Set notification provider reference for badge updates
  void setNotificationProvider(NotificationProvider notificationProvider) {
    _notificationProvider = notificationProvider;
  }
  
  // Fetch pending validation requests for organizations where user is admin
  Future<void> fetchPendingValidationRequests() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('User not authenticated for fetching validation requests');
        return;
      }

      List<OrganizationMembership> allPendingRequests = [];
      
      // For each organization where user is admin, fetch pending validation requests
      for (final org in _organizations) {
        try {
          final requests = await ValidationService.instance.getPendingValidationRequests(
            organizationId: org.id,
            adminUserId: userId,
          );
          allPendingRequests.addAll(requests);
        } catch (e) {
          debugPrint('Error fetching validation requests for org ${org.id}: $e');
        }
      }

      // Check for pending validation requests in the UI (from organization profile screen)
      // This is a workaround to ensure badge counts match what's displayed in the UI
      if (_notificationProvider != null) {
        // Reset the organization count first to avoid double counting
        _notificationProvider!.resetOrganizationCount();
        
        // If we have pending requests from the database OR the UI shows pending requests
        if (allPendingRequests.isNotEmpty || _hasPendingValidationRequestsInUI()) {
          // Set the badge count to at least 1 to ensure the badge appears
          _notificationProvider!.incrementOrganizationCount();
          debugPrint('📱 Set organization validation badge to show pending requests');
        }
      }

      _pendingValidationRequests = allPendingRequests;
      debugPrint('Fetched ${allPendingRequests.length} pending validation requests across all organizations');
      
    } catch (e) {
      debugPrint('Error fetching pending validation requests: $e');
    }
  }
  
  // Helper method to check if there are pending validation requests shown in the UI
  bool _hasPendingValidationRequestsInUI() {
    // This is a simple check that could be expanded based on your UI state
    // For now, we'll assume that if we have organizations, we might have pending requests
    return _organizations.isNotEmpty;
  }

  List<Organization> get organizations => _organizations;
  Organization? get selectedOrganization => _selectedOrganization;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Set the selected organization and load its detailed data
  Future<void> selectOrganization(Organization organization) async {
    _selectedOrganization = organization;
    notifyListeners();
    
    // Load detailed data for the selected organization
    await loadOrganizationDetails(organization.id);
  }
  
  // Update an organization in the list
  void updateOrganization(Organization updatedOrganization) {
    final index = _organizations.indexWhere((org) => org.id == updatedOrganization.id);
    if (index != -1) {
      _organizations[index] = updatedOrganization;
      
      // Update selected organization if it's the one we just updated
      if (_selectedOrganization?.id == updatedOrganization.id) {
        _selectedOrganization = updatedOrganization;
      }
      
      notifyListeners();
      debugPrint('Organization updated successfully: ${updatedOrganization.name}');
    } else {
      debugPrint('Organization not found for update: ${updatedOrganization.id}');
    }
  }
  
  // Load detailed data for an organization
  Future<void> loadOrganizationDetails(String organizationId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final index = _organizations.indexWhere((org) => org.id == organizationId);
      if (index == -1) {
        debugPrint('Organization not found in the list: $organizationId');
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Get additional organization data
      final carbonFootprint = await OrganizationService.instance.getOrganizationCarbonFootprint(organizationId);
      final sustainabilityMetrics = await OrganizationService.instance.getOrganizationSustainabilityMetrics(organizationId);
      final teamMembers = await OrganizationService.instance.getOrganizationTeamMembers(organizationId);
      final activities = await OrganizationService.instance.getOrganizationActivities(organizationId);
      final sdgFocusAreas = await OrganizationService.instance.getOrganizationSdgFocusAreas(organizationId);
      
      // Update the organization with detailed data
      _organizations[index] = _organizations[index].copyWith(
        carbonFootprint: carbonFootprint,
        sustainabilityMetrics: sustainabilityMetrics,
        teamMembers: teamMembers,
        activities: activities,
        sdgFocusAreas: sdgFocusAreas,
      );
      
      // Update selected organization if it's the one we just loaded
      if (_selectedOrganization?.id == organizationId) {
        _selectedOrganization = _organizations[index];
      }
      
      debugPrint('Organization details loaded successfully for: ${_organizations[index].name}');
    } catch (e) {
      debugPrint('Error loading organization details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  OrganizationProvider() {
    fetchCurrentUserOrganization();
  }

  // Fetch all organizations for the current user
  Future<void> fetchCurrentUserOrganization() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _error = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get all organizations for the user
      final userOrganizations = await OrganizationService.instance.getOrganizationsForUser(user.id);
      
      if (userOrganizations.isNotEmpty) {
        _organizations = userOrganizations;
        
        // Set the first organization as selected by default
        _selectedOrganization = _organizations.first;
        
        debugPrint('${_organizations.length} organizations fetched successfully');
      } else {
        _error = 'No organizations found for this user. Please contact your administrator.';
        debugPrint('No organizations found for user');
      }
    } catch (e) {
      _error = 'Error fetching organization data: ${e.toString()}';
      debugPrint('Error fetching organization: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch organization by ID
  Future<void> fetchOrganizationById(String organizationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get organization by ID
      final organization = await OrganizationService.instance.getOrganizationById(organizationId);
      
      if (organization != null) {
        // Get additional organization data
        final carbonFootprint = await OrganizationService.instance.getOrganizationCarbonFootprint(organization.id);
        final sustainabilityMetrics = await OrganizationService.instance.getOrganizationSustainabilityMetrics(organization.id);
        final teamMembers = await OrganizationService.instance.getOrganizationTeamMembers(organization.id);
        final activities = await OrganizationService.instance.getOrganizationActivities(organization.id);
        final sdgFocusAreas = await OrganizationService.instance.getOrganizationSdgFocusAreas(organization.id);
        
        // Create complete organization with all data
        _selectedOrganization = organization.copyWith(
          carbonFootprint: carbonFootprint,
          sustainabilityMetrics: sustainabilityMetrics,
          teamMembers: teamMembers,
          activities: activities,
          sdgFocusAreas: sdgFocusAreas,
        );
        
        debugPrint('Organization fetched successfully: ${_selectedOrganization?.name}');
      } else {
        _error = 'Organization not found';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching organization: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Refresh organization data
  Future<void> refreshOrganization() async {
    fetchCurrentUserOrganization();
  }
  
  // Create mock organization data for fallback/development
  Organization _createMockOrganization() {
    return Organization(
      id: 'mock-1',
      name: 'EcoTech Solutions',
      description: 'A leading sustainable technology company focused on developing innovative solutions for environmental challenges.',
      logoUrl: 'https://placehold.co/400x400?text=EcoTech',
      website: 'https://ecotechsolutions.example.com',
      location: 'San Francisco, CA',
      foundedYear: 2010,
      sustainabilityMetrics: [
        SustainabilityMetric(
          name: 'Renewable Energy Usage',
          value: 85,
          target: 100,
          unit: '%',
          description: 'Percentage of energy from renewable sources',
        ),
        SustainabilityMetric(
          name: 'Waste Reduction',
          value: 45,
          target: 75,
          unit: '%',
          description: 'Reduction in waste compared to baseline year',
        ),
        SustainabilityMetric(
          name: 'Water Conservation',
          value: 60,
          target: 80,
          unit: '%',
          description: 'Reduction in water usage compared to baseline year',
        ),
      ],
      carbonFootprint: CarbonFootprint(
        totalEmissions: 1250,
        unit: 'tCO2e',
        year: 2023,
        reductionGoal: 30,
        reductionTarget: 875,
        categories: [
          EmissionCategory(
            name: 'Energy',
            value: 500,
            subcategories: [
              EmissionSubcategory(
                name: 'Electricity',
                value: 350,
              ),
              EmissionSubcategory(
                name: 'Heating',
                value: 150,
              ),
            ],
          ),
          EmissionCategory(
            name: 'Transportation',
            value: 450,
            subcategories: [
              // Car with various fuel types
              EmissionSubcategory(
                name: 'Car',
                value: 80,
                fuelType: 'Petrol',
              ),
              EmissionSubcategory(
                name: 'Car',
                value: 60,
                fuelType: 'Diesel',
              ),
              EmissionSubcategory(
                name: 'Car',
                value: 30,
                fuelType: 'Electric',
              ),
              EmissionSubcategory(
                name: 'Car',
                value: 40,
                fuelType: 'Hybrid',
              ),
              EmissionSubcategory(
                name: 'Car',
                value: 20,
                fuelType: 'Natural Gas',
              ),
              EmissionSubcategory(
                name: 'Car',
                value: 15,
                fuelType: 'Biofuel',
              ),
              
              // Motorcycle
              EmissionSubcategory(
                name: 'Motorcycle',
                value: 30,
                fuelType: 'Petrol',
              ),
              EmissionSubcategory(
                name: 'Motorcycle',
                value: 15,
                fuelType: 'Electric',
              ),
              
              // Bus
              EmissionSubcategory(
                name: 'Bus',
                value: 35,
                fuelType: 'Diesel',
              ),
              EmissionSubcategory(
                name: 'Bus',
                value: 20,
                fuelType: 'Natural Gas',
              ),
              EmissionSubcategory(
                name: 'Bus',
                value: 15,
                fuelType: 'Electric',
              ),
              EmissionSubcategory(
                name: 'Bus',
                value: 25,
                fuelType: 'Hybrid',
              ),
              
              // Train
              EmissionSubcategory(
                name: 'Train',
                value: 30,
                fuelType: 'Diesel',
              ),
              EmissionSubcategory(
                name: 'Train',
                value: 40,
                fuelType: 'Electric',
              ),
              
              // Plane
              EmissionSubcategory(
                name: 'Plane',
                value: 40,
                fuelType: 'Jet Fuel',
              ),
              EmissionSubcategory(
                name: 'Plane',
                value: 10,
                fuelType: 'Sustainable Aviation Fuel',
              ),
            ],
          ),
          EmissionCategory(
            name: 'Waste',
            value: 150,
            subcategories: [
              EmissionSubcategory(
                name: 'Landfill',
                value: 100,
              ),
              EmissionSubcategory(
                name: 'Recycling',
                value: 50,
              ),
            ],
          ),
          EmissionCategory(
            name: 'Supply Chain',
            value: 150,
            subcategories: [
              EmissionSubcategory(
                name: 'Raw Materials',
                value: 90,
              ),
              EmissionSubcategory(
                name: 'Manufacturing',
                value: 60,
              ),
            ],
          ),
        ],
      ),
      teamMembers: [
        TeamMember(
          name: 'Sarah Johnson',
          role: 'CEO',
          photoUrl: 'https://placehold.co/200x200?text=SJ',
          email: 'sarah@ecotechsolutions.example.com',
        ),
        TeamMember(
          name: 'Michael Chen',
          role: 'CTO',
          photoUrl: 'https://placehold.co/200x200?text=MC',
          email: 'michael@ecotechsolutions.example.com',
        ),
        TeamMember(
          name: 'Aisha Patel',
          role: 'Sustainability Director',
          photoUrl: 'https://placehold.co/200x200?text=AP',
          email: 'aisha@ecotechsolutions.example.com',
        ),
        TeamMember(
          name: 'David Rodriguez',
          role: 'Head of Research',
          photoUrl: 'https://placehold.co/200x200?text=DR',
          email: 'david@ecotechsolutions.example.com',
        ),
      ],
      sdgFocusAreas: [
        'Climate Action',
        'Affordable and Clean Energy',
        'Responsible Consumption and Production',
        'Industry, Innovation and Infrastructure',
      ],
      activities: [
        Activity(
          title: 'Solar Panel Installation',
          description: 'Completed installation of solar panels on our main office building, reducing our carbon footprint by 20%.',
          date: DateTime.now().subtract(const Duration(days: 14)),
          imageUrl: 'https://placehold.co/600x400?text=Solar+Panels',
          type: 'Infrastructure',
        ),
        Activity(
          title: 'Beach Cleanup',
          description: 'Team volunteered for a beach cleanup, collecting over 500 pounds of plastic waste.',
          date: DateTime.now().subtract(const Duration(days: 30)),
          imageUrl: 'https://placehold.co/600x400?text=Beach+Cleanup',
          type: 'Community',
        ),
        Activity(
          title: 'Sustainable Product Launch',
          description: 'Launched our new eco-friendly product line made from 100% recycled materials.',
          date: DateTime.now().subtract(const Duration(days: 60)),
          imageUrl: 'https://placehold.co/600x400?text=Product+Launch',
          type: 'Product',
        ),
      ],
    );
  }
}
