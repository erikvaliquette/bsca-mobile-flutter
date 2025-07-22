import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bsca_mobile_flutter/models/organization_membership_model.dart';

/// Service for handling employment validation and organization membership requests
class ValidationService {
  ValidationService._();
  static final ValidationService instance = ValidationService._();

  final _client = Supabase.instance.client;

  /// Request validation for employment at an organization
  /// This creates a pending membership that requires employer approval
  Future<OrganizationMembership?> requestEmploymentValidation({
    required String userId,
    required String organizationId,
    String role = 'member',
    String? message,
  }) async {
    try {
      // Check if user already has a membership (any status) for this organization
      final existingMembership = await _client
          .from('organization_members')
          .select()
          .eq('user_id', userId)
          .eq('organization_id', organizationId)
          .maybeSingle();

      if (existingMembership != null) {
        debugPrint('User already has membership for this organization');
        return OrganizationMembership.fromJson(existingMembership);
      }

      // Create new pending membership
      final membershipData = {
        'user_id': userId,
        'organization_id': organizationId,
        'role': role,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('organization_members')
          .insert(membershipData)
          .select('*, organizations(*)')
          .single();

      debugPrint('Employment validation request created successfully');
      
      // TODO: Send notification to organization admins
      await _notifyOrganizationAdmins(organizationId, userId, message);

      return OrganizationMembership.fromJson(response);
    } catch (e) {
      debugPrint('Error requesting employment validation: $e');
      return null;
    }
  }

  /// Approve an employment validation request (admin only)
  Future<bool> approveEmploymentValidation({
    required String membershipId,
    required String adminUserId,
    String? notes,
  }) async {
    try {
      // First verify that the admin has permission to approve
      final membership = await _client
          .from('organization_members')
          .select('organization_id')
          .eq('id', membershipId)
          .single();

      final isAdmin = await _isUserAdminOfOrganization(
        adminUserId, 
        membership['organization_id']
      );

      if (!isAdmin) {
        debugPrint('User is not authorized to approve this membership');
        return false;
      }

      // Update membership status to approved
      final updateData = {
        'status': 'approved',
        'joined_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('organization_members')
          .update(updateData)
          .eq('id', membershipId);

      debugPrint('Employment validation approved successfully');
      
      // TODO: Send notification to user about approval
      await _notifyUserOfApproval(membershipId);

      return true;
    } catch (e) {
      debugPrint('Error approving employment validation: $e');
      return false;
    }
  }

  /// Reject an employment validation request (admin only)
  Future<bool> rejectEmploymentValidation({
    required String membershipId,
    required String adminUserId,
    String? reason,
  }) async {
    try {
      // First verify that the admin has permission to reject
      final membership = await _client
          .from('organization_members')
          .select('organization_id')
          .eq('id', membershipId)
          .single();

      final isAdmin = await _isUserAdminOfOrganization(
        adminUserId, 
        membership['organization_id']
      );

      if (!isAdmin) {
        debugPrint('User is not authorized to reject this membership');
        return false;
      }

      // Update membership status to rejected
      final updateData = {
        'status': 'rejected',
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('organization_members')
          .update(updateData)
          .eq('id', membershipId);

      debugPrint('Employment validation rejected successfully');
      
      // TODO: Send notification to user about rejection
      await _notifyUserOfRejection(membershipId, reason);

      return true;
    } catch (e) {
      debugPrint('Error rejecting employment validation: $e');
      return false;
    }
  }

  /// Get all pending validation requests for an organization (admin only)
  Future<List<OrganizationMembership>> getPendingValidationRequests({
    required String organizationId,
    required String adminUserId,
  }) async {
    try {
      debugPrint('Getting pending validation requests for organization: $organizationId');
      
      // Verify admin permissions
      final isAdmin = await _isUserAdminOfOrganization(adminUserId, organizationId);
      if (!isAdmin) {
        debugPrint('User is not authorized to view pending requests');
        return [];
      }
      
      debugPrint('User is authorized as admin, fetching pending requests');

      // Get pending memberships without trying to join profiles
      final response = await _client
          .from('organization_members')
          .select('*')
          .eq('organization_id', organizationId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      debugPrint('Found ${response.length} pending validation requests');

      final List<OrganizationMembership> pendingRequests = [];
      
      // Manually fetch user profiles for each pending request
      for (final membership in response) {
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
          debugPrint('Error fetching profile for pending request user ${membership['user_id']}: $e');
        }
        
        pendingRequests.add(OrganizationMembership(
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
      
      debugPrint('Successfully loaded ${pendingRequests.length} pending validation requests with profiles');
      return pendingRequests;
    } catch (e) {
      debugPrint('Error getting pending validation requests: $e');
      return [];
    }
  }

  /// Get validation status for a user's request to join an organization
  Future<OrganizationMembership?> getValidationStatus({
    required String userId,
    required String organizationId,
  }) async {
    try {
      final response = await _client
          .from('organization_members')
          .select('*, organizations(*)')
          .eq('user_id', userId)
          .eq('organization_id', organizationId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return OrganizationMembership.fromJson(response);
    } catch (e) {
      debugPrint('Error getting validation status: $e');
      return null;
    }
  }

  /// Cancel a pending validation request
  Future<bool> cancelValidationRequest({
    required String userId,
    required String organizationId,
  }) async {
    try {
      // Only allow cancellation of pending requests
      await _client
          .from('organization_members')
          .delete()
          .eq('user_id', userId)
          .eq('organization_id', organizationId)
          .eq('status', 'pending');

      debugPrint('Validation request cancelled successfully');
      return true;
    } catch (e) {
      debugPrint('Error cancelling validation request: $e');
      return false;
    }
  }

  /// Check if user can request validation for an organization
  Future<bool> canRequestValidation({
    required String userId,
    required String organizationId,
  }) async {
    try {
      // Check if user already has any membership (pending, approved, or rejected)
      final existingMembership = await _client
          .from('organization_members')
          .select('status')
          .eq('user_id', userId)
          .eq('organization_id', organizationId)
          .maybeSingle();

      // Can only request if no existing membership
      return existingMembership == null;
    } catch (e) {
      debugPrint('Error checking validation eligibility: $e');
      return false;
    }
  }

  /// Private helper methods

  /// Check if user is admin of an organization
  Future<bool> _isUserAdminOfOrganization(String userId, String organizationId) async {
    try {
      debugPrint('Checking admin status for user $userId in organization $organizationId');
      
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
          debugPrint('User is admin via organization_members table');
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
          if (adminIds.contains(userId)) {
            debugPrint('User is admin via legacy admin_ids array');
            return true;
          }
        }
      } catch (e) {
        debugPrint('Error checking legacy admin_ids array: $e');
      }
      
      debugPrint('User is not an admin of this organization');
      return false;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Send notification to organization admins about new validation request
  Future<void> _notifyOrganizationAdmins(String organizationId, String userId, String? message) async {
    try {
      // Get all admins of the organization
      final admins = await _client
          .from('organization_members')
          .select('user_id, profiles(*)')
          .eq('organization_id', organizationId)
          .eq('role', 'admin')
          .eq('status', 'approved');

      // TODO: Implement notification system
      // For now, just log the notification
      debugPrint('Would notify ${admins.length} admins of validation request');
      
      // Future implementation could:
      // - Send push notifications
      // - Send emails
      // - Create in-app notifications
      // - Add to notification table
      
    } catch (e) {
      debugPrint('Error notifying organization admins: $e');
    }
  }

  /// Send notification to user about approval
  Future<void> _notifyUserOfApproval(String membershipId) async {
    try {
      // TODO: Implement user notification for approval
      debugPrint('Would notify user of employment validation approval');
    } catch (e) {
      debugPrint('Error notifying user of approval: $e');
    }
  }

  /// Send notification to user about rejection
  Future<void> _notifyUserOfRejection(String membershipId, String? reason) async {
    try {
      // TODO: Implement user notification for rejection
      debugPrint('Would notify user of employment validation rejection: $reason');
    } catch (e) {
      debugPrint('Error notifying user of rejection: $e');
    }
  }

  /// Validate organization exists and is active
  Future<bool> validateOrganizationExists(String organizationId) async {
    try {
      final org = await _client
          .from('organizations')
          .select('id, status')
          .eq('id', organizationId)
          .maybeSingle();

      return org != null && org['status'] == 'active';
    } catch (e) {
      debugPrint('Error validating organization: $e');
      return false;
    }
  }

  /// Get organization validation statistics (admin only)
  Future<Map<String, int>> getValidationStatistics({
    required String organizationId,
    required String adminUserId,
  }) async {
    try {
      // Verify admin permissions
      final isAdmin = await _isUserAdminOfOrganization(adminUserId, organizationId);
      if (!isAdmin) {
        return {};
      }

      final stats = await _client
          .from('organization_members')
          .select('status')
          .eq('organization_id', organizationId);

      final Map<String, int> statistics = {
        'total': stats.length,
        'approved': 0,
        'pending': 0,
        'rejected': 0,
      };

      for (final member in stats) {
        final status = member['status'] ?? 'pending';
        statistics[status] = (statistics[status] ?? 0) + 1;
      }

      return statistics;
    } catch (e) {
      debugPrint('Error getting validation statistics: $e');
      return {};
    }
  }
}
