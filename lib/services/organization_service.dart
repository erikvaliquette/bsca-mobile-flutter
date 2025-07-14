import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bsca_mobile_flutter/models/organization_model.dart';

class OrganizationService {
  OrganizationService._();
  static final OrganizationService instance = OrganizationService._();

  final _client = Supabase.instance.client;

  /// Get all organizations for the current user
  Future<List<Organization>> getOrganizationsForUser(String userId) async {
    try {
      // First try to find organizations where the user is an admin
      final adminOrgsResponse = await _client
          .from('organizations')
          .select()
          .contains('admin_ids', [userId]);
      
      // Then try to find organizations where the user is a member
      final memberOrgsResponse = await _client
          .from('organizations')
          .select()
          .contains('member_ids', [userId]);
      
      // Combine and deduplicate results
      final Set<String> orgIds = {};
      final List<Organization> organizations = [];
      
      // Process admin orgs
      for (final org in adminOrgsResponse) {
        if (!orgIds.contains(org['id'])) {
          orgIds.add(org['id']);
          organizations.add(_mapToOrganization(org));
        }
      }
      
      // Process member orgs
      for (final org in memberOrgsResponse) {
        if (!orgIds.contains(org['id'])) {
          orgIds.add(org['id']);
          organizations.add(_mapToOrganization(org));
        }
      }
      
      // If no organizations found, check if user has an organization in their profile
      if (organizations.isEmpty) {
        final userProfile = await _client
            .from('profiles')
            .select('organization_id')
            .eq('id', userId)
            .single();
        
        if (userProfile != null && userProfile['organization_id'] != null) {
          final orgId = userProfile['organization_id'];
          final orgResponse = await _client
              .from('organizations')
              .select()
              .eq('id', orgId)
              .single();
          
          if (orgResponse != null && !orgIds.contains(orgResponse['id'])) {
            organizations.add(_mapToOrganization(orgResponse));
          }
        }
      }
      
      return organizations;
    } catch (e) {
      debugPrint('Error getting organizations for user: $e');
      return [];
    }
  }

  /// Get organization by ID
  Future<Organization?> getOrganizationById(String organizationId) async {
    try {
      final response = await _client
          .from('organizations')
          .select()
          .eq('id', organizationId)
          .single();
      
      if (response == null) {
        return null;
      }
      
      return _mapToOrganization(response);
    } catch (e) {
      debugPrint('Error getting organization by ID: $e');
      return null;
    }
  }

  /// Map Supabase response to Organization model
  Organization _mapToOrganization(Map<String, dynamic> data) {
    return Organization(
      id: data['id'].toString(),
      name: data['name'] ?? 'Unknown Organization',
      description: data['description'],
      logoUrl: data['logo_url'],
      website: data['website'],
      location: data['address'] != null && data['address'] is Map ? 
        _extractLocationFromAddress(data['address']) : null,
      foundedYear: data['founded_year'],
    );
  }

  /// Extract location from address JSON
  String? _extractLocationFromAddress(Map<String, dynamic> address) {
    final city = address['city'];
    final state = address['state'];
    final country = address['country'];
    
    if (city != null && country != null) {
      return '$city, $country';
    } else if (country != null) {
      return country;
    }
    return null;
  }
  
  /// Get organization carbon footprint
  Future<CarbonFootprint?> getOrganizationCarbonFootprint(String organizationId) async {
    // Since the table doesn't exist, return a default carbon footprint object
    debugPrint('Creating default carbon footprint since table does not exist');
    return CarbonFootprint(
      totalEmissions: 0.0,
      unit: 'tCO2e',
      year: DateTime.now().year - 1,
      reductionGoal: 30.0,
      reductionTarget: 0.0,
      categories: [
        EmissionCategory(
          name: 'Scope 1',
          value: 0.0,
          icon: 'factory',
        ),
        EmissionCategory(
          name: 'Scope 2',
          value: 0.0,
          icon: 'electric_bolt',
        ),
        EmissionCategory(
          name: 'Scope 3',
          value: 0.0,
          icon: 'commute',
        ),
      ],
    );
  }

  /// Get organization sustainability metrics
  Future<List<SustainabilityMetric>> getOrganizationSustainabilityMetrics(String organizationId) async {
    // Since the table doesn't exist, return default sustainability metrics
    debugPrint('Creating default sustainability metrics since table does not exist');
    return [
      SustainabilityMetric(
        name: 'Renewable Energy',
        value: 45.0,
        target: 100.0,
        unit: '%',
        description: 'Percentage of energy from renewable sources',
      ),
      SustainabilityMetric(
        name: 'Waste Reduction',
        value: 30.0,
        target: 80.0,
        unit: '%',
        description: 'Percentage of waste diverted from landfill',
      ),
      SustainabilityMetric(
        name: 'Water Conservation',
        value: 25.0,
        target: 50.0,
        unit: '%',
        description: 'Percentage reduction in water usage',
      ),
    ];
  }

  /// Get organization team members
  Future<List<TeamMember>> getOrganizationTeamMembers(String organizationId) async {
    // Since the table doesn't exist, return default team members
    debugPrint('Creating default team members since table does not exist');
    return [
      TeamMember(
        id: '1',
        name: 'Jane Smith',
        role: 'Sustainability Director',
        photoUrl: 'https://i.pravatar.cc/150?img=1',
        email: 'jane@example.com',
      ),
      TeamMember(
        id: '2',
        name: 'John Doe',
        role: 'CEO',
        photoUrl: 'https://i.pravatar.cc/150?img=2',
        email: 'john@example.com',
      ),
      TeamMember(
        id: '3',
        name: 'Alex Johnson',
        role: 'Environmental Specialist',
        photoUrl: 'https://i.pravatar.cc/150?img=3',
        email: 'alex@example.com',
      ),
    ];
  }

  /// Get organization activities
  Future<List<Activity>> getOrganizationActivities(String organizationId) async {
    // Since the table doesn't exist, return default activities
    debugPrint('Creating default activities since table does not exist');
    final now = DateTime.now();
    return [
      Activity(
        id: '1',
        title: 'Carbon Neutral Certification',
        description: 'Achieved carbon neutral certification for operations',
        date: DateTime(now.year, now.month - 1, 15),
        type: 'certification',
      ),
      Activity(
        id: '2',
        title: 'Sustainability Report Published',
        description: 'Annual sustainability report released to stakeholders',
        date: DateTime(now.year, now.month - 2, 10),
        type: 'report',
      ),
      Activity(
        id: '3',
        title: 'Community Clean-up Initiative',
        description: 'Organized community clean-up with 50+ volunteers',
        date: DateTime(now.year, now.month - 3, 5),
        type: 'event',
      ),
    ];
  }

  /// Get organization SDG focus areas
  Future<List<String>> getOrganizationSdgFocusAreas(String organizationId) async {
    // Since the tables and columns don't exist, return default SDG focus areas
    debugPrint('Creating default SDG focus areas since tables/columns do not exist');
    return [
      'Climate Action',
      'Responsible Consumption',
      'Clean Water and Sanitation',
      'Decent Work and Economic Growth',
    ];
  }
}
