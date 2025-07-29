import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../services/validation_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  // Getters
  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch the current user's profile from Supabase
  Future<void> fetchCurrentUserProfile() async {
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

      // Fetch basic profile data first
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      // Create a base profile from the profiles table
      final Map<String, dynamic> completeProfileData = Map<String, dynamic>.from(profileResponse);
      
      // Debug the profile response
      debugPrint('Profile response: ${profileResponse.toString()}');
      
      // Initialize preferences if not present
      if (completeProfileData['preferences'] == null) {
        completeProfileData['preferences'] = {};
      }
      
      // Store the is_public value to be merged later with other preferences
      // Default to true if is_public is null
      bool isPublic = profileResponse['is_public'] ?? true;
      debugPrint('Loaded profile visibility (is_public): $isPublic');
      
      // Fetch user SDGs
      final sdgResponse = await Supabase.instance.client
          .from('user_sdgs')
          .select()
          .eq('user_id', user.id);
      
      // Fetch work history
      debugPrint('Fetching work history for user: ${user.id}');
      final workHistoryResponse = await Supabase.instance.client
          .from('work_history')
          .select()
          .eq('user_id', user.id);
      debugPrint('Work history response: $workHistoryResponse');
      debugPrint('Work history count: ${workHistoryResponse?.length ?? 0}');
      
      // Fetch education history
      final educationResponse = await Supabase.instance.client
          .from('education_history')
          .select()
          .eq('user_id', user.id);
      
      // Fetch certifications
      final certificationsResponse = await Supabase.instance.client
          .from('certifications')
          .select()
          .eq('user_id', user.id);
      
      // Fetch user settings from the new table structure
      Map<String, dynamic>? settingsResponse;
      try {
        settingsResponse = await Supabase.instance.client
            .from('user_settings')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        
        if (settingsResponse != null) {
          debugPrint('Successfully fetched user settings');
          
          // Map settings to preferences in the profile model
          Map<String, dynamic> preferences = {};
          
          // Map user profile fields
          preferences['first_name'] = settingsResponse['first_name'] ?? '';
          preferences['last_name'] = settingsResponse['last_name'] ?? '';
          
          // Map notification settings
          preferences['email_notifications'] = settingsResponse['email_notifications'] ?? false;
          preferences['push_notifications'] = settingsResponse['push_notifications'] ?? false;
          preferences['public_profile'] = settingsResponse['public_profile'] ?? true;
          preferences['language'] = settingsResponse['language'] ?? 'en';
          
          // Map energy settings
          preferences['electricity_grid'] = settingsResponse['electricity_grid'] ?? 'global';
          preferences['home_electricity_grid'] = settingsResponse['home_electricity_grid'] ?? 'global';
          preferences['business_electricity_grid'] = settingsResponse['business_electricity_grid'] ?? 'global';
          preferences['electricity_source'] = settingsResponse['electricity_source'] ?? 'grid_mix';
          
          // Map transportation settings
          preferences['transportation'] = settingsResponse['transportation_mode'] ?? 'car';
          preferences['fuel_type'] = settingsResponse['fuel_type'] ?? 'petrol';
          
          completeProfileData['preferences'] = preferences;
        }
      } catch (e) {
        debugPrint('Error fetching settings: $e');
        // If it fails, settings will remain null
        settingsResponse = null;
      }
      
      // Process SDG goals
      List<String> sdgGoals = [];
      if (sdgResponse != null && sdgResponse is List && sdgResponse.isNotEmpty) {
        // Map SDG IDs to human-readable names
        sdgGoals = sdgResponse.map<String>((sdg) {
          final sdgId = sdg['sdg_id'].toString();
          // Map the SDG ID to a human-readable name
          return _mapSdgIdToName(sdgId);
        }).toList();
        completeProfileData['sdg_goals'] = sdgGoals;
        
        // Debug SDG goals
        debugPrint('SDG goals fetched: $sdgGoals');
        debugPrint('Raw SDG response: $sdgResponse');
      }
      
      // Process work history
      debugPrint('Processing work history data...');
      List<Map<String, dynamic>> workHistoryJson = [];
      if (workHistoryResponse != null && workHistoryResponse is List && workHistoryResponse.isNotEmpty) {
        debugPrint('Work history found: ${workHistoryResponse.length} items');
        workHistoryJson = workHistoryResponse.map<Map<String, dynamic>>((work) => work as Map<String, dynamic>).toList();
        completeProfileData['work_history'] = workHistoryJson;
        debugPrint('Work history processed and added to profile data');
      } else {
        debugPrint('No work history found - workHistoryResponse is null, not a list, or empty');
        debugPrint('workHistoryResponse type: ${workHistoryResponse.runtimeType}');
        debugPrint('workHistoryResponse value: $workHistoryResponse');
      }
      
      // Process education history
      List<Map<String, dynamic>> educationJson = [];
      if (educationResponse != null && educationResponse is List && educationResponse.isNotEmpty) {
        educationJson = educationResponse.map<Map<String, dynamic>>((edu) => edu as Map<String, dynamic>).toList();
        completeProfileData['education'] = educationJson;
      }
      
      // Process certifications
      List<Map<String, dynamic>> certificationsJson = [];
      if (certificationsResponse != null && certificationsResponse is List && certificationsResponse.isNotEmpty) {
        certificationsJson = certificationsResponse.map<Map<String, dynamic>>((cert) => cert as Map<String, dynamic>).toList();
        completeProfileData['certifications'] = certificationsJson;
      }
      
      // Process user settings as preferences
      Map<String, dynamic> preferences = profileResponse['preferences'] ?? {};
      if (settingsResponse != null) {
        // Merge settings into preferences
        preferences.addAll({
          'email_notifications': settingsResponse['email_notifications'] ?? false,
          'push_notifications': settingsResponse['push_notifications'] ?? false,
          'public_profile': isPublic, // Use the is_public value from the profiles table
          'language': settingsResponse['language'] ?? 'en',
          'electricity_grid': settingsResponse['electricity_grid'] ?? 'National Average',
          'electricity_source': settingsResponse['electricity_source'] ?? 'Grid Mix (Default)',
          'transportation': settingsResponse['transportation'] ?? 'Car',
          'fuel_type': settingsResponse['fuel_type'] ?? 'Petrol',
        });
        completeProfileData['preferences'] = preferences;
      } else {
        // If no settings response, still ensure public_profile is set
        preferences['public_profile'] = isPublic;
        completeProfileData['preferences'] = preferences;
      }
      
      // Debug the complete profile data
      debugPrint('Complete profile data: ${completeProfileData.toString()}');
      
      // Create a complete profile model with all fetched data
      _profile = ProfileModel.fromJson(completeProfileData);
      
      debugPrint('Profile fetched successfully: ${_profile?.toString()}');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching profile: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update the user's profile in Supabase
  Future<void> updateProfile({
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
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

      if (_profile == null) {
        _error = 'Profile not loaded';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final updatedProfile = _profile!.copyWith(
        username: username,
        fullName: fullName,
        avatarUrl: avatarUrl,
        bio: bio,
        preferences: preferences,
        updatedAt: DateTime.now(),
      );

      final response = await Supabase.instance.client
          .from('profiles')
          .update(updatedProfile.toJson())
          .eq('id', user.id);

      _profile = updatedProfile;
      debugPrint('Profile updated successfully');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating profile: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Updates the full user profile with all provided information
  Future<void> updateFullProfile({
    String? username, 
    String? fullName, 
    String? avatarUrl,
    String? bio,
    List<String>? sdgGoals,
    List<WorkHistory>? workHistory,
    List<Education>? education,
    List<Certification>? certifications,
    Map<String, dynamic>? preferences,
  }) async {
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

      if (_profile == null) {
        _error = 'Profile not loaded';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Begin a transaction for all updates
      // Update basic profile information - only include fields that exist in the table
      final Map<String, dynamic> profileUpdateData = {
        'avatar_url': avatarUrl ?? _profile!.avatarUrl,
        'bio': bio ?? _profile!.bio,
        'updated_at': DateTime.now().toIso8601String(),
        // Save the public profile preference to the is_public column
        'is_public': preferences != null ? preferences['public_profile'] ?? true : _profile!.preferences?['public_profile'] ?? true,
      };
      
      // Update the basic profile in Supabase
      try {
        await Supabase.instance.client
            .from('profiles')
            .update(profileUpdateData)
            .eq('id', user.id);
        debugPrint('Updated basic profile information successfully');
      } catch (e) {
        debugPrint('Error updating basic profile information: $e');
        // Continue with other updates even if this fails
      }
      
      // Update SDG goals if provided
      if (sdgGoals != null) {
        try {
          debugPrint('Starting SDG goals update for user ${user.id}');
          debugPrint('SDG goals to save: $sdgGoals');
          
          // First delete existing SDG goals
          final deleteResponse = await Supabase.instance.client
              .from('user_sdgs')
              .delete()
              .eq('user_id', user.id);
          debugPrint('Deleted existing SDG goals');
          
          // Then insert new SDG goals
          for (String goalName in sdgGoals) {
            // Convert goal name to SDG ID
            final sdgId = _mapSdgNameToId(goalName);
            if (sdgId != null) {
              try {
                final insertResponse = await Supabase.instance.client
                    .from('user_sdgs')
                    .insert({
                      'user_id': user.id,
                      'sdg_id': int.parse(sdgId), // Convert to integer as sdg_id is int4
                    });
                debugPrint('Inserted SDG: $goalName with ID: $sdgId');
              } catch (e) {
                debugPrint('Error inserting SDG $goalName with ID $sdgId: $e');
              }
            } else {
              debugPrint('Could not map SDG name to ID: $goalName');
            }
          }
        } catch (e) {
          debugPrint('Error updating SDG goals: $e');
        }
      }
      
      // Update work history if provided
      if (workHistory != null) {
        debugPrint('Updating work history for user ${user.id}');
        debugPrint('Work history items to save: ${workHistory.length}');
        
        // First delete existing work history
        await Supabase.instance.client
            .from('work_history')
            .delete()
            .eq('user_id', user.id);
        debugPrint('Deleted existing work history');
        
        // Then insert new work history
        for (WorkHistory work in workHistory) {
          final workData = {
            'user_id': user.id,
            ...work.toJson(),
          };
          debugPrint('Inserting work history: $workData');
          
          await Supabase.instance.client
              .from('work_history')
              .insert(workData);
          
          debugPrint('Successfully inserted work history for ${work.company}');
          
          // If work history has organizationId, create validation request
          if (work.organizationId != null) {
            debugPrint('Work history has organizationId: ${work.organizationId}, creating validation request');
            try {
              final validationService = ValidationService.instance;
              await validationService.requestEmploymentValidation(
                userId: user.id,
                organizationId: work.organizationId!,
                role: 'member', // Default role for employment validation
              );
              debugPrint('Created validation request for organization ${work.organizationId}');
            } catch (e) {
              debugPrint('Error creating validation request: $e');
            }
          }
        }
        debugPrint('Completed work history update');
      }
      
      // Update education if provided
      if (education != null) {
        // First delete existing education
        await Supabase.instance.client
            .from('education_history')
            .delete()
            .eq('user_id', user.id);
        
        // Then insert new education
        for (Education edu in education) {
          await Supabase.instance.client
              .from('education_history')
              .insert({
                'user_id': user.id,
                ...edu.toJson(),
              });
        }
      }
      
      // Update certifications if provided
      if (certifications != null) {
        // First delete existing certifications
        await Supabase.instance.client
            .from('certifications')
            .delete()
            .eq('user_id', user.id);
        
        // Then insert new certifications
        for (Certification cert in certifications) {
          await Supabase.instance.client
              .from('certifications')
              .insert({
                'user_id': user.id,
                ...cert.toJson(),
              });
        }
      }
      
      // Update user settings if preferences are provided
      if (preferences != null) {
        try {
          // Extract settings-specific preferences for the new table structure
          final Map<String, dynamic> settingsData = {
            'id': user.id,
            
            // User profile fields
            'first_name': preferences['first_name'] ?? '',
            'last_name': preferences['last_name'] ?? '',
            
            // Notification settings
            'email_notifications': preferences['email_notifications'] ?? false,
            'push_notifications': preferences['push_notifications'] ?? false,
            'public_profile': preferences['public_profile'] ?? true,
            'language': preferences['language'] ?? 'en',
            
            // Energy settings
            'electricity_grid': preferences['electricity_grid'] ?? 'global',
            'home_electricity_grid': preferences['home_electricity_grid'] ?? 'global',
            'business_electricity_grid': preferences['business_electricity_grid'] ?? 'global',
            'electricity_source': preferences['electricity_source'] ?? 'grid_mix',
            
            // Transportation settings
            'transportation_mode': preferences['transportation'] ?? 'car',
            'fuel_type': preferences['fuel_type'] ?? 'petrol',
            
            // Update timestamp
            'updated_at': DateTime.now().toIso8601String(),
          };
          
          // Check if settings exist and update or insert accordingly
          final existingSettings = await Supabase.instance.client
              .from('user_settings')
              .select()
              .eq('id', user.id)
              .maybeSingle();
          
          if (existingSettings != null) {
            await Supabase.instance.client
                .from('user_settings')
                .update(settingsData)
                .eq('id', user.id);
            debugPrint('Updated user settings successfully');
          } else {
            // Add created_at for new records
            settingsData['created_at'] = DateTime.now().toIso8601String();
            
            await Supabase.instance.client
                .from('user_settings')
                .insert(settingsData);
            debugPrint('Inserted new user settings successfully');
          }
          
          // Also update the preferences in the profiles table for backward compatibility
          await Supabase.instance.client
              .from('profiles')
              .update({'preferences': preferences})
              .eq('id', user.id);
        } catch (e) {
          debugPrint('Error updating user settings: $e');
          // Continue with the rest of the profile update even if settings update fails
        }
      }
      
      // Refresh the profile to get the updated data
      await fetchCurrentUserProfile();
      
      debugPrint('Full profile updated successfully');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating full profile: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Helper method to map SDG ID to human-readable name
  String _mapSdgIdToName(String sdgId) {
    // Map of SDG IDs to human-readable names
    final Map<String, String> sdgMap = {
      '1': 'No Poverty',
      '2': 'Zero Hunger',
      '3': 'Good Health and Well-being',
      '4': 'Quality Education',
      '5': 'Gender Equality',
      '6': 'Clean Water and Sanitation',
      '7': 'Affordable and Clean Energy',
      '8': 'Decent Work and Economic Growth',
      '9': 'Industry, Innovation and Infrastructure',
      '10': 'Reduced Inequality',
      '11': 'Sustainable Cities and Communities',
      '12': 'Responsible Consumption and Production',
      '13': 'Climate Action',
      '14': 'Life Below Water',
      '15': 'Life on Land',
      '16': 'Peace, Justice and Strong Institutions',
      '17': 'Partnerships for the Goals',
    };
    
    // Return the mapped name or the ID if not found
    return sdgMap[sdgId] ?? 'SDG $sdgId';
  }
  
  // Helper method to map SDG name to ID
  String? _mapSdgNameToId(String sdgName) {
    // Map of SDG names to IDs
    final Map<String, String> sdgNameToIdMap = {
      'No Poverty': '1',
      'Zero Hunger': '2',
      'Good Health and Well-being': '3',
      'Quality Education': '4',
      'Gender Equality': '5',
      'Clean Water and Sanitation': '6',
      'Affordable and Clean Energy': '7',
      'Decent Work and Economic Growth': '8',
      'Industry, Innovation and Infrastructure': '9',
      'Reduced Inequality': '10',
      'Sustainable Cities and Communities': '11',
      'Responsible Consumption and Production': '12',
      'Climate Action': '13',
      'Life Below Water': '14',
      'Life on Land': '15',
      'Peace, Justice and Strong Institutions': '16',
      'Partnerships for the Goals': '17',
    };
    
    // Try to extract SDG number if the name contains it (e.g., "SDG 1: No Poverty")
    final RegExp sdgRegex = RegExp(r'SDG (\d+)');
    final match = sdgRegex.firstMatch(sdgName);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    
    // Otherwise, look up the name in the map
    return sdgNameToIdMap[sdgName];
  }
}
