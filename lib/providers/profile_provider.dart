import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

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
      
      // Fetch user SDGs
      final sdgResponse = await Supabase.instance.client
          .from('user_sdgs')
          .select()
          .eq('user_id', user.id);
      
      // Fetch work history
      final workHistoryResponse = await Supabase.instance.client
          .from('work_history')
          .select()
          .eq('user_id', user.id);
      
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
      
      // Fetch user settings
      // Try to fetch user settings, but handle potential schema differences
      Map<String, dynamic>? settingsResponse;
      try {
        // First try with user_id
        settingsResponse = await Supabase.instance.client
            .from('user_settings')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();
      } catch (e) {
        debugPrint('Error fetching settings with user_id: $e');
        try {
          // Then try with id
          settingsResponse = await Supabase.instance.client
              .from('user_settings')
              .select()
              .eq('id', user.id)
              .maybeSingle();
        } catch (e) {
          debugPrint('Error fetching settings with id: $e');
          // If both fail, settings will remain null
          settingsResponse = null;
        }
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
      }
      
      // Process work history
      List<Map<String, dynamic>> workHistoryJson = [];
      if (workHistoryResponse != null && workHistoryResponse is List && workHistoryResponse.isNotEmpty) {
        workHistoryJson = workHistoryResponse.map<Map<String, dynamic>>((work) => work as Map<String, dynamic>).toList();
        completeProfileData['work_history'] = workHistoryJson;
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
          'public_profile': settingsResponse['public_profile'] ?? true,
          'language': settingsResponse['language'] ?? 'en',
          'electricity_grid': settingsResponse['electricity_grid'] ?? 'National Average',
          'electricity_source': settingsResponse['electricity_source'] ?? 'Grid Mix (Default)',
          'transportation': settingsResponse['transportation'] ?? 'Car',
          'fuel_type': settingsResponse['fuel_type'] ?? 'Petrol',
        });
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
  
  // Update the full user profile including all additional fields
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
      // Update basic profile information
      final Map<String, dynamic> profileUpdateData = {
        'username': username ?? _profile!.username,
        'full_name': fullName ?? _profile!.fullName,
        'avatar_url': avatarUrl ?? _profile!.avatarUrl,
        'bio': bio ?? _profile!.bio,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Update the basic profile in Supabase
      await Supabase.instance.client
          .from('profiles')
          .update(profileUpdateData)
          .eq('id', user.id);
      
      // Update SDG goals if provided
      if (sdgGoals != null) {
        // First delete existing SDG goals
        await Supabase.instance.client
            .from('user_sdgs')
            .delete()
            .eq('user_id', user.id);
        
        // Then insert new SDG goals
        for (String sdgId in sdgGoals) {
          await Supabase.instance.client
              .from('user_sdgs')
              .insert({
                'user_id': user.id,
                'sdg_id': sdgId,
              });
        }
      }
      
      // Update work history if provided
      if (workHistory != null) {
        // First delete existing work history
        await Supabase.instance.client
            .from('work_history')
            .delete()
            .eq('user_id', user.id);
        
        // Then insert new work history
        for (WorkHistory work in workHistory) {
          await Supabase.instance.client
              .from('work_history')
              .insert({
                'user_id': user.id,
                ...work.toJson(),
              });
        }
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
        // Extract settings-specific preferences
        final Map<String, dynamic> settingsData = {
          'user_id': user.id,
          'email_notifications': preferences['email_notifications'] ?? false,
          'push_notifications': preferences['push_notifications'] ?? false,
          'public_profile': preferences['public_profile'] ?? true,
          'language': preferences['language'] ?? 'en',
          'electricity_grid': preferences['electricity_grid'] ?? 'National Average',
          'electricity_source': preferences['electricity_source'] ?? 'Grid Mix (Default)',
          'transportation': preferences['transportation'] ?? 'Car',
          'fuel_type': preferences['fuel_type'] ?? 'Petrol',
        };
        
        // Check if settings exist and update or insert accordingly
        final existingSettings = await Supabase.instance.client
            .from('user_settings')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (existingSettings != null) {
          await Supabase.instance.client
              .from('user_settings')
              .update(settingsData)
              .eq('user_id', user.id);
        } else {
          await Supabase.instance.client
              .from('user_settings')
              .insert(settingsData);
        }
        
        // Also update the preferences in the profiles table
        await Supabase.instance.client
            .from('profiles')
            .update({'preferences': preferences})
            .eq('id', user.id);
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
}
