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

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      _profile = ProfileModel.fromJson(response);
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
}
