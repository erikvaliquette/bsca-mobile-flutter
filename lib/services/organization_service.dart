import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bsca_mobile_flutter/models/organization_model.dart';
import 'package:bsca_mobile_flutter/models/organization_membership_model.dart';

class OrganizationService {
  OrganizationService._();
  static final OrganizationService instance = OrganizationService._();

  final _client = Supabase.instance.client;
  
  /// Create a new organization
  Future<Organization?> createOrganization({
    required String name,
    required String userId,
    String? description,
    String? website,
    String? location,
    String? orgType,
    String? logoUrl,
  }) async {
    try {
      // 1. Create the organization record
      final response = await _client.from('organizations').insert({
        'name': name,
        'description': description,
        'website': website,
        'location': location,
        'org_type': orgType ?? 'parent', // Default to parent if not specified
        'logo_url': logoUrl,
        'admin_ids': [userId], // Legacy support
        'member_ids': [userId], // Legacy support
        'status': 'active', // Default status
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();
      
      // 2. Create organization membership for the creator (as admin)
      await _client.from('organization_members').insert({
        'organization_id': response['id'],
        'user_id': userId,
        'role': 'admin',
        'status': 'approved',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('Organization created successfully: ${response['name']}');
      return _mapToOrganization(response);
    } catch (e) {
      debugPrint('Error creating organization: $e');
      return null;
    }
  }
  
  /// Update an existing organization
  Future<Organization?> updateOrganization(Organization organization) async {
    try {
      await _client.from('organizations').update({
        'name': organization.name,
        'description': organization.description,
        'website': organization.website,
        'location': organization.location,
        'org_type': organization.orgType,
        'status': organization.status,
        'logo_url': organization.logoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', organization.id);
      
      debugPrint('Organization updated successfully: ${organization.name}');
      return organization;
    } catch (e) {
      debugPrint('Error updating organization: $e');
      return null;
    }
  }
  
  /// Delete an organization
  Future<bool> deleteOrganization(String organizationId) async {
    try {
      // 1. Delete organization memberships
      await _client.from('organization_members')
          .delete()
          .eq('organization_id', organizationId);
      
      // 2. Delete organization SDG focus areas
      await _client.from('organization_sdgs')
          .delete()
          .eq('organization_id', organizationId);
      
      // 3. Delete organization carbon footprint records
      await _client.from('organization_carbon_footprint')
          .delete()
          .eq('organization_id', organizationId);
      
      // 4. Delete the organization record
      await _client.from('organizations')
          .delete()
          .eq('id', organizationId);
      
      debugPrint('Organization deleted successfully: $organizationId');
      return true;
    } catch (e) {
      debugPrint('Error deleting organization: $e');
      return false;
    }
  }

  /// Get all organizations for the current user (approved memberships only)
  Future<List<Organization>> getOrganizationsForUser(String userId) async {
    try {
      final Set<String> orgIds = {};
      final List<Organization> organizations = [];
      
      // 1. Query organization_members table for approved memberships (new system)
      try {
        final membershipResponse = await _client
            .from('organization_members')
            .select('organization_id, role, status, organizations(*)')
            .eq('user_id', userId)
            .eq('status', 'approved');
        
        for (final membership in membershipResponse) {
          if (membership['organizations'] != null) {
            final org = _mapToOrganization(membership['organizations']);
            if (!orgIds.contains(org.id)) {
              orgIds.add(org.id);
              organizations.add(org);
            }
          }
        }
      } catch (e) {
        debugPrint('Error querying organization_members: $e');
      }
      
      // 2. BACKWARD COMPATIBILITY: Check legacy array fields in organizations table
      try {
        // Check admin_ids array
        final adminOrgsResponse = await _client
            .from('organizations')
            .select()
            .contains('admin_ids', [userId]);
        
        for (final org in adminOrgsResponse) {
          if (!orgIds.contains(org['id'])) {
            orgIds.add(org['id']);
            organizations.add(_mapToOrganization(org));
          }
        }
        
        // Check member_ids array
        final memberOrgsResponse = await _client
            .from('organizations')
            .select()
            .contains('member_ids', [userId]);
        
        for (final org in memberOrgsResponse) {
          if (!orgIds.contains(org['id'])) {
            orgIds.add(org['id']);
            organizations.add(_mapToOrganization(org));
          }
        }
      } catch (e) {
        debugPrint('Error querying legacy organization arrays: $e');
      }
      
      // 3. Also check if user has a primary organization in their profile
      try {
        final userProfile = await _client
            .from('profiles')
            .select('organization_id')
            .eq('id', userId)
            .maybeSingle();
        
        if (userProfile != null && userProfile['organization_id'] != null) {
          final orgId = userProfile['organization_id'];
          
          if (!orgIds.contains(orgId)) {
            final orgResponse = await _client
                .from('organizations')
                .select()
                .eq('id', orgId)
                .maybeSingle();
            
            if (orgResponse != null) {
              organizations.add(_mapToOrganization(orgResponse));
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching user profile organization: $e');
      }
      
      debugPrint('Found ${organizations.length} organizations for user $userId');
      return organizations;
    } catch (e) {
      debugPrint('Error getting organizations for user: $e');
      return [];
    }
  }

  /// Get all organizations for the current user including pending memberships
  Future<List<OrganizationMembership>> getOrganizationMembershipsForUser(String userId) async {
    try {
      final membershipResponse = await _client
          .from('organization_members')
          .select('*, organizations(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      final List<OrganizationMembership> memberships = [];
      
      for (final membership in membershipResponse) {
        if (membership['organizations'] != null) {
          memberships.add(OrganizationMembership(
            id: membership['id'],
            organizationId: membership['organization_id'],
            userId: membership['user_id'],
            role: membership['role'] ?? 'member',
            status: membership['status'] ?? 'pending',
            joinedAt: membership['joined_at'] != null 
                ? DateTime.parse(membership['joined_at']) 
                : null,
            createdAt: DateTime.parse(membership['created_at']),
            updatedAt: DateTime.parse(membership['updated_at']),
            organization: _mapToOrganization(membership['organizations']),
          ));
        }
      }
      
      return memberships;
    } catch (e) {
      debugPrint('Error getting organization memberships for user: $e');
      return [];
    }
  }

  /// Get all memberships for a specific organization (with user profiles)
  Future<List<OrganizationMembership>> getOrganizationMemberships(String organizationId, {String? status}) async {
    try {
      debugPrint('Fetching organization memberships for: $organizationId');
      
      // First, get the memberships without trying to join profiles
      var query = _client
          .from('organization_members')
          .select('*')
          .eq('organization_id', organizationId);
      
      if (status != null) {
        query = query.eq('status', status);
      }
      
      final membershipResponse = await query.order('created_at', ascending: false);
      debugPrint('Found ${membershipResponse.length} memberships');
      
      final List<OrganizationMembership> memberships = [];
      
      // Manually fetch user profiles for each membership
      for (final membership in membershipResponse) {
        UserProfile? userProfile;
        
        try {
          final profileResponse = await _client
              .from('profiles')
              .select('id, first_name, last_name, email, avatar_url, headline, company_name')
              .eq('id', membership['user_id'])
              .maybeSingle();
          
          if (profileResponse != null) {
            userProfile = UserProfile.fromJson(profileResponse);
          }
        } catch (e) {
          debugPrint('Error fetching profile for user ${membership['user_id']}: $e');
        }
        
        memberships.add(OrganizationMembership(
          id: membership['id'],
          organizationId: membership['organization_id'],
          userId: membership['user_id'],
          role: membership['role'] ?? 'member',
          status: membership['status'] ?? 'pending',
          joinedAt: membership['joined_at'] != null 
              ? DateTime.parse(membership['joined_at']) 
              : null,
          createdAt: DateTime.parse(membership['created_at']),
          updatedAt: DateTime.parse(membership['updated_at']),
          userProfile: userProfile,
        ));
      }
      
      debugPrint('Successfully loaded ${memberships.length} memberships with profiles');
      return memberships;
    } catch (e) {
      debugPrint('Error getting organization memberships: $e');
      return [];
    }
  }

  /// Get all members of an organization
  Future<List<OrganizationMembership>> getOrganizationMembers(String organizationId, {String? status}) async {
    try {
      var query = _client
          .from('organization_members')
          .select('*, profiles(*)')
          .eq('organization_id', organizationId);
      
      if (status != null) {
        query = query.eq('status', status);
      }
      
      final membershipResponse = await query.order('created_at', ascending: false);
      
      final List<OrganizationMembership> memberships = [];
      
      for (final membership in membershipResponse) {
        memberships.add(OrganizationMembership(
          id: membership['id'],
          organizationId: membership['organization_id'],
          userId: membership['user_id'],
          role: membership['role'] ?? 'member',
          status: membership['status'] ?? 'pending',
          joinedAt: membership['joined_at'] != null 
              ? DateTime.parse(membership['joined_at']) 
              : null,
          createdAt: DateTime.parse(membership['created_at']),
          updatedAt: DateTime.parse(membership['updated_at']),
          userProfile: membership['profiles'] != null 
              ? _mapToUserProfile(membership['profiles']) 
              : null,
        ));
      }
      
      return memberships;
    } catch (e) {
      debugPrint('Error getting organization members: $e');
      return [];
    }
  }

  /// Check if user is admin of an organization
  Future<bool> isUserAdminOfOrganization(String userId, String organizationId) async {
    try {
      // 1. Check new organization_members table
      try {
        final membership = await _client
            .from('organization_members')
            .select('role')
            .eq('user_id', userId)
            .eq('organization_id', organizationId)
            .eq('status', 'approved')
            .maybeSingle();
        
        if (membership != null && membership['role'] == 'admin') {
          return true;
        }
      } catch (e) {
        debugPrint('Error checking organization_members for admin status: $e');
      }
      
      // 2. BACKWARD COMPATIBILITY: Check legacy admin_ids array
      try {
        final orgResponse = await _client
            .from('organizations')
            .select('admin_ids')
            .eq('id', organizationId)
            .maybeSingle();
        
        if (orgResponse != null && orgResponse['admin_ids'] != null) {
          final adminIds = List<String>.from(orgResponse['admin_ids']);
          return adminIds.contains(userId);
        }
      } catch (e) {
        debugPrint('Error checking legacy admin_ids: $e');
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Check if user is member of an organization (any role, approved status)
  Future<bool> isUserMemberOfOrganization(String userId, String organizationId) async {
    try {
      // 1. Check new organization_members table
      try {
        final membership = await _client
            .from('organization_members')
            .select('id')
            .eq('user_id', userId)
            .eq('organization_id', organizationId)
            .eq('status', 'approved')
            .maybeSingle();
        
        if (membership != null) {
          return true;
        }
      } catch (e) {
        debugPrint('Error checking organization_members for membership: $e');
      }
      
      // 2. BACKWARD COMPATIBILITY: Check legacy arrays
      try {
        final orgResponse = await _client
            .from('organizations')
            .select('admin_ids, member_ids')
            .eq('id', organizationId)
            .maybeSingle();
        
        if (orgResponse != null) {
          // Check admin_ids array
          if (orgResponse['admin_ids'] != null) {
            final adminIds = List<String>.from(orgResponse['admin_ids']);
            if (adminIds.contains(userId)) {
              return true;
            }
          }
          
          // Check member_ids array
          if (orgResponse['member_ids'] != null) {
            final memberIds = List<String>.from(orgResponse['member_ids']);
            if (memberIds.contains(userId)) {
              return true;
            }
          }
        }
      } catch (e) {
        debugPrint('Error checking legacy member arrays: $e');
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking membership status: $e');
      return false;
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
      
      // Get SDG focus areas from the organization_sdgs junction table
      final sdgResponse = await _client
          .from('organization_sdgs')
          .select('sdg_id')
          .eq('organization_id', organizationId);
      
      List<String>? sdgFocusAreas;
      if (sdgResponse != null && sdgResponse.isNotEmpty) {
        sdgFocusAreas = sdgResponse.map<String>((item) => item['sdg_id'].toString()).toList();
        debugPrint('Loaded ${sdgFocusAreas.length} SDG focus areas for organization $organizationId');
      }
      
      final organization = _mapToOrganization(response);
      return organization.copyWith(sdgFocusAreas: sdgFocusAreas);
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
      orgType: data['org_type'],
      status: data['status'],
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
  
  /// Map Supabase response to UserProfile model
  UserProfile _mapToUserProfile(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'].toString(),
      firstName: data['first_name'],
      lastName: data['last_name'],
      email: data['email'],
      avatarUrl: data['avatar_url'],
      headline: data['headline'],
      companyName: data['company_name'],
    );
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
  
  /// Search for organizations by name
  /// 
  /// This searches the public.organizations table for organizations matching the search term
  /// Returns a list of organizations that match the search term (case insensitive)
  Future<List<Organization>> searchOrganizations(String searchTerm) async {
    try {
      debugPrint('Searching for organizations with term: $searchTerm');
      
      if (searchTerm.isEmpty) {
        return [];
      }
      
      final response = await _client
          .from('organizations')
          .select()
          .ilike('name', '%$searchTerm%')
          .order('name')
          .limit(10);
      
      final List<Organization> organizations = [];
      
      for (final org in response) {
        organizations.add(_mapToOrganization(org));
      }
      
      debugPrint('Found ${organizations.length} organizations matching "$searchTerm"');
      return organizations;
    } catch (e) {
      debugPrint('Error searching organizations: $e');
      return [];
    }
  }
}
