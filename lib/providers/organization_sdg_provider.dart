import 'package:flutter/foundation.dart';
import 'package:bsca_mobile_flutter/services/organization_sdg_service.dart';
import 'package:bsca_mobile_flutter/models/sdg_goal.dart';

/// Provider for managing organization SDG focus areas
class OrganizationSdgProvider extends ChangeNotifier {
  final OrganizationSdgService _organizationSdgService = OrganizationSdgService.instance;
  
  String? _organizationId;
  List<String> _selectedSdgIds = [];
  bool _isLoading = false;
  bool _isAdmin = false;
  String? _error;

  /// Get the currently selected SDG IDs
  List<String> get selectedSdgIds => _selectedSdgIds;
  
  /// Get the selected SDG goals as objects
  List<SDGGoal> get selectedSdgGoals => 
      SDGGoal.getByIds(_selectedSdgIds.map((id) => int.parse(id)).toList());
  
  /// Check if a specific SDG is selected
  bool isSdgSelected(int sdgId) => _selectedSdgIds.contains(sdgId.toString());
  
  /// Loading state
  bool get isLoading => _isLoading;
  
  /// Error message, if any
  String? get error => _error;
  
  /// Whether the current user is an admin of the organization
  bool get isAdmin => _isAdmin;

  /// Initialize the provider with an organization ID and check admin status
  Future<void> init(String organizationId, String userId) async {
    _organizationId = organizationId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Check if user is admin
      _isAdmin = await _organizationSdgService.isUserOrganizationAdmin(userId, organizationId);
      
      // Load SDG focus areas
      await loadOrganizationSdgFocusAreas();
    } catch (e) {
      _error = 'Failed to initialize organization SDG provider: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load organization SDG focus areas from the database
  Future<void> loadOrganizationSdgFocusAreas() async {
    if (_organizationId == null) {
      _error = 'No organization ID provided';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _selectedSdgIds = await _organizationSdgService.getOrganizationSdgFocusAreas(_organizationId!);
    } catch (e) {
      _error = 'Failed to load organization SDG focus areas: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle selection of an SDG
  Future<void> toggleSdg(int sdgId) async {
    if (_organizationId == null) {
      _error = 'No organization ID provided';
      notifyListeners();
      return;
    }
    
    if (!_isAdmin) {
      _error = 'Only organization admins can modify SDG focus areas';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final sdgIdStr = sdgId.toString();
      List<String> updatedSdgIds = List.from(_selectedSdgIds);
      
      if (_selectedSdgIds.contains(sdgIdStr)) {
        updatedSdgIds.remove(sdgIdStr);
      } else {
        updatedSdgIds.add(sdgIdStr);
      }
      
      final success = await _organizationSdgService.updateOrganizationSdgFocusAreas(
        _organizationId!, 
        updatedSdgIds
      );
      
      if (success) {
        _selectedSdgIds = updatedSdgIds;
      } else {
        _error = 'Failed to update organization SDG focus areas';
      }
    } catch (e) {
      _error = 'Error toggling organization SDG focus area: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set multiple SDGs at once (replaces current selections)
  Future<void> setSelectedSdgs(List<int> sdgIds) async {
    if (_organizationId == null) {
      _error = 'No organization ID provided';
      notifyListeners();
      return;
    }
    
    if (!_isAdmin) {
      _error = 'Only organization admins can modify SDG focus areas';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final sdgIdStrings = sdgIds.map((id) => id.toString()).toList();
      
      final success = await _organizationSdgService.updateOrganizationSdgFocusAreas(
        _organizationId!, 
        sdgIdStrings
      );
      
      if (success) {
        _selectedSdgIds = sdgIdStrings;
      } else {
        _error = 'Failed to update organization SDG focus areas';
        // Reload to ensure consistency
        await loadOrganizationSdgFocusAreas();
      }
    } catch (e) {
      _error = 'Error setting organization SDG focus areas: $e';
      debugPrint(_error);
      // Reload to ensure consistency
      await loadOrganizationSdgFocusAreas();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
