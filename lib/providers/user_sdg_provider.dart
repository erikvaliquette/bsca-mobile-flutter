import 'package:flutter/foundation.dart';
import 'package:bsca_mobile_flutter/services/user_sdg_service.dart';
import 'package:bsca_mobile_flutter/models/sdg_goal.dart';

/// Provider for managing user SDG selections
class UserSdgProvider extends ChangeNotifier {
  final UserSdgService _userSdgService = UserSdgService();
  
  List<int> _selectedSdgIds = [];
  bool _isLoading = false;
  String? _error;

  /// Get the currently selected SDG IDs
  List<int> get selectedSdgIds => _selectedSdgIds;
  
  /// Get the selected SDG goals as objects
  List<SDGGoal> get selectedSdgGoals => 
      SDGGoal.getByIds(_selectedSdgIds);
  
  /// Check if a specific SDG is selected
  bool isSdgSelected(int sdgId) => _selectedSdgIds.contains(sdgId);
  
  /// Loading state
  bool get isLoading => _isLoading;
  
  /// Error message, if any
  String? get error => _error;

  /// Load user SDG selections from the database
  Future<void> loadUserSdgs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _selectedSdgIds = await _userSdgService.getUserSdgs();
    } catch (e) {
      _error = 'Failed to load SDG selections: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle selection of an SDG
  Future<void> toggleSdg(int sdgId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _userSdgService.toggleUserSdg(sdgId);
      if (success) {
        if (_selectedSdgIds.contains(sdgId)) {
          _selectedSdgIds.remove(sdgId);
        } else {
          _selectedSdgIds.add(sdgId);
        }
      } else {
        _error = 'Failed to toggle SDG selection';
      }
    } catch (e) {
      _error = 'Error toggling SDG selection: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set multiple SDGs at once (replaces current selections)
  Future<void> setSelectedSdgs(List<int> sdgIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Clear existing selections
      await _userSdgService.clearUserSdgs();
      
      // Save new selections
      final success = await _userSdgService.saveUserSdgs(sdgIds);
      if (success) {
        _selectedSdgIds = List.from(sdgIds);
      } else {
        _error = 'Failed to save SDG selections';
        // Reload to ensure consistency
        await loadUserSdgs();
      }
    } catch (e) {
      _error = 'Error setting SDG selections: $e';
      debugPrint(_error);
      // Reload to ensure consistency
      await loadUserSdgs();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
