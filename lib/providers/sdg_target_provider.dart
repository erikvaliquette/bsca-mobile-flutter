import 'package:flutter/material.dart';
import 'package:bsca_mobile_flutter/models/sdg_target.dart';
import 'package:bsca_mobile_flutter/services/sdg_target_service.dart';
import 'package:bsca_mobile_flutter/services/supabase/supabase_client.dart';
import 'package:bsca_mobile_flutter/services/target_cascading_attribution_service.dart';

class SdgTargetProvider with ChangeNotifier {
  final SdgTargetService _targetService;
  
  List<SdgTarget> _targets = [];
  Map<int, List<SdgTarget>> _targetsBySDG = {};
  bool _isLoading = false;
  String? _error;
  
  SdgTargetProvider() 
      : _targetService = SdgTargetService();
  
  List<SdgTarget> get targets => _targets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Get all targets for a specific SDG
  List<SdgTarget> getTargetsForSDG(int sdgId) {
    return _targetsBySDG[sdgId] ?? [];
  }
  
  /// Load all SDG targets
  Future<void> loadAllTargets() async {
    _setLoading(true);
    _setError(null);
    
    try {
      final targets = await _targetService.getAllTargets();
      _targets = targets;
      
      // Organize targets by SDG ID for easier access
      _organizeTargetsBySDG();
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
    }
  }
  
  /// Load targets for a specific SDG
  Future<List<SdgTarget>> loadTargetsForSDG(int sdgId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final targets = await _targetService.getTargetsBySDG(sdgId);
      
      // Update the cache
      _targetsBySDG[sdgId] = targets;
      
      _setLoading(false);
      notifyListeners();
      return targets;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }
  
  /// Load targets for a specific organization
  Future<List<SdgTarget>> loadTargetsForOrganization(String organizationId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final targets = await _targetService.getTargetsByOrganization(organizationId);
      _setLoading(false);
      notifyListeners();
      return targets;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }
  
  /// Load targets for a specific organization and SDG
  Future<List<SdgTarget>> loadTargetsForOrganizationSDG(String organizationId, int sdgId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final targets = await _targetService.getTargetsByOrganizationAndSDG(organizationId, sdgId);
      
      // Update the cache for this SDG
      _targetsBySDG[sdgId] = targets;
      
      _setLoading(false);
      notifyListeners();
      return targets;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }
  
  /// Load targets for a specific user
  Future<List<SdgTarget>> loadTargetsForUser(String userId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final targets = await _targetService.getTargetsByUser(userId);
      _setLoading(false);
      notifyListeners();
      return targets;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }
  
  /// Get a target by ID
  Future<SdgTarget?> getTargetById(String id) async {
    // First check if we already have it in our list
    final existingTarget = _targets.where((t) => t.id == id).firstOrNull;
    if (existingTarget != null) {
      return existingTarget;
    }
    
    // Otherwise fetch it from the service
    return await _targetService.getTargetById(id);
  }
  
  /// Create a new SDG target
  Future<SdgTarget?> createTarget(SdgTarget target) async {
    try {
      final newTarget = await _targetService.createTarget(target);
      
      if (newTarget != null) {
        _targets.add(newTarget);
        
        // Update the SDG-specific cache
        if (newTarget.sdgGoalNumber != null) {
          if (_targetsBySDG.containsKey(newTarget.sdgGoalNumber)) {
            _targetsBySDG[newTarget.sdgGoalNumber]!.add(newTarget);
          } else {
            _targetsBySDG[newTarget.sdgGoalNumber!] = [newTarget];
          }
        }
        
        notifyListeners();
      }
      
      return newTarget;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return null;
    }
  }
  
  /// Update an existing SDG target
  Future<SdgTarget?> updateTarget(SdgTarget target) async {
    try {
      // Get the old target to compare organization attribution
      final oldTarget = _targets.where((t) => t.id == target.id).firstOrNull;
      final oldOrganizationId = oldTarget?.organizationId;
      final newOrganizationId = target.organizationId;
      
      final updatedTarget = await _targetService.updateTarget(target);
      
      if (updatedTarget != null) {
        // Handle cascading attribution if organization changed
        if (oldOrganizationId != newOrganizationId) {
          debugPrint('🎯 Target organization attribution changed - triggering cascade');
          debugPrint('   Old Org: $oldOrganizationId');
          debugPrint('   New Org: $newOrganizationId');
          
          // Use the target's userId as attributedBy, or fallback to a default
          final attributedBy = updatedTarget.userId ?? 'system';
          
          await TargetCascadingAttributionService.instance().handleTargetAttributionChange(
            targetId: updatedTarget.id,
            oldOrganizationId: oldOrganizationId,
            newOrganizationId: newOrganizationId,
            attributedBy: attributedBy,
          );
        }
        
        // Update in the main list
        final index = _targets.indexWhere((t) => t.id == target.id);
        if (index != -1) {
          _targets[index] = updatedTarget;
        }
        
        // Update in the SDG-specific cache
        if (updatedTarget.sdgGoalNumber != null) {
          if (_targetsBySDG.containsKey(updatedTarget.sdgGoalNumber)) {
            final sdgIndex = _targetsBySDG[updatedTarget.sdgGoalNumber]!.indexWhere((t) => t.id == target.id);
            if (sdgIndex != -1) {
              _targetsBySDG[updatedTarget.sdgGoalNumber]![sdgIndex] = updatedTarget;
            }
          }
        }
        
        notifyListeners();
      }
      
      return updatedTarget;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return null;
    }
  }
  
  /// Delete an SDG target
  Future<bool> deleteTarget(String id) async {
    try {
      final success = await _targetService.deleteTarget(id);
      
      if (success) {
        // Find the target to get its SDG ID before removing
        final targetToRemove = _targets.firstWhere((t) => t.id == id);
        
        // Remove from main list
        _targets.removeWhere((t) => t.id == id);
        
        // Remove from SDG-specific cache
        if (targetToRemove.sdgGoalNumber != null && _targetsBySDG.containsKey(targetToRemove.sdgGoalNumber)) {
          _targetsBySDG[targetToRemove.sdgGoalNumber]!.removeWhere((t) => t.id == id);
        }
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }
  
  // Helper method to organize targets by SDG ID
  void _organizeTargetsBySDG() {
    _targetsBySDG.clear();
    
    for (final target in _targets) {
      if (target.sdgGoalNumber != null) {
        if (_targetsBySDG.containsKey(target.sdgGoalNumber)) {
          _targetsBySDG[target.sdgGoalNumber]!.add(target);
        } else {
          _targetsBySDG[target.sdgGoalNumber!] = [target];
        }
      }
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
  }
  
  void _setError(String? errorMessage) {
    _error = errorMessage;
  }
}
