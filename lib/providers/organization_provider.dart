import 'package:flutter/material.dart';
import 'package:bsca_mobile_flutter/models/organization_model.dart';

class OrganizationProvider with ChangeNotifier {
  Organization? _organization;
  bool _isLoading = false;
  String? _error;

  Organization? get organization => _organization;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Mock data for demonstration purposes
  Future<void> fetchOrganization() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data
      _organization = Organization(
        id: '1',
        name: 'Green Future Solutions',
        description: 'A forward-thinking organization committed to sustainable development and environmental stewardship.',
        logoUrl: 'https://via.placeholder.com/150',
        website: 'https://greenfuturesolutions.example.com',
        location: 'Montreal, Canada',
        sustainabilityMetrics: [
          SustainabilityMetric(
            name: 'Renewable Energy',
            value: '75',
            unit: '%',
            icon: Icons.bolt,
          ),
          SustainabilityMetric(
            name: 'Waste Reduction',
            value: '45',
            unit: '%',
            icon: Icons.delete_outline,
          ),
          SustainabilityMetric(
            name: 'Water Conservation',
            value: '30',
            unit: '%',
            icon: Icons.water_drop,
          ),
        ],
        carbonFootprint: CarbonFootprint(
          totalEmissions: 120.5,
          unit: 'tonnes CO2e',
          reductionGoal: 50.0,
          reductionAchieved: 15.3,
          categories: [
            EmissionCategory(
              name: 'Transportation',
              value: 45.2,
              icon: 'directions_car',
              subcategories: [
                EmissionSubcategory(
                  name: 'Car',
                  value: 25.5,
                  fuelType: 'Petrol',
                ),
                EmissionSubcategory(
                  name: 'Bus',
                  value: 10.7,
                  fuelType: 'Diesel',
                ),
                EmissionSubcategory(
                  name: 'Plane',
                  value: 9.0,
                  fuelType: 'Jet Fuel',
                ),
              ],
            ),
            EmissionCategory(
              name: 'Energy',
              value: 55.8,
              icon: 'lightbulb',
            ),
            EmissionCategory(
              name: 'Waste',
              value: 19.5,
              icon: 'delete',
            ),
          ],
        ),
        teamMembers: [
          TeamMember(
            id: '1',
            name: 'Sarah Johnson',
            role: 'Sustainability Director',
            photoUrl: 'https://via.placeholder.com/150',
            email: 'sarah@example.com',
          ),
          TeamMember(
            id: '2',
            name: 'Michael Chen',
            role: 'Environmental Analyst',
            photoUrl: 'https://via.placeholder.com/150',
            email: 'michael@example.com',
          ),
          TeamMember(
            id: '3',
            name: 'Aisha Patel',
            role: 'Project Manager',
            photoUrl: 'https://via.placeholder.com/150',
            email: 'aisha@example.com',
          ),
        ],
        sdgFocusAreas: [
          'SDG 7: Affordable and Clean Energy',
          'SDG 11: Sustainable Cities and Communities',
          'SDG 13: Climate Action',
        ],
        recentActivities: [
          OrganizationActivity(
            id: '1',
            title: 'Office Solar Panel Installation',
            description: 'Completed installation of solar panels on our main office building.',
            date: DateTime.now().subtract(const Duration(days: 5)),
            imageUrl: 'https://via.placeholder.com/300x200',
            type: ActivityType.achievement,
          ),
          OrganizationActivity(
            id: '2',
            title: 'Community Tree Planting',
            description: 'Organized a tree planting event with local community members.',
            date: DateTime.now().subtract(const Duration(days: 12)),
            imageUrl: 'https://via.placeholder.com/300x200',
            type: ActivityType.event,
          ),
          OrganizationActivity(
            id: '3',
            title: 'Carbon Neutral Commitment',
            description: 'Announced our commitment to become carbon neutral by 2030.',
            date: DateTime.now().subtract(const Duration(days: 30)),
            imageUrl: 'https://via.placeholder.com/300x200',
            type: ActivityType.announcement,
          ),
        ],
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load organization data: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrganization(Organization updatedOrganization) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Update the organization
      _organization = updatedOrganization;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update organization data: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
}
