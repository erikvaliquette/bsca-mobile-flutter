import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for migrating legacy organization membership data from array fields
/// to the new organization_members junction table
class OrganizationMigrationService {
  OrganizationMigrationService._();
  static final OrganizationMigrationService instance = OrganizationMigrationService._();

  final _client = Supabase.instance.client;

  /// Migrate all legacy organization membership data to organization_members table
  Future<MigrationResult> migrateAllOrganizationMemberships() async {
    final result = MigrationResult();
    
    try {
      debugPrint('Starting organization membership migration...');
      
      // Get all organizations with array-based memberships
      final organizations = await _client
          .from('organizations')
          .select('id, name, admin_ids, member_ids')
          .not('admin_ids', 'is', null)
          .or('not.member_ids.is.null');

      debugPrint('Found ${organizations.length} organizations to process');

      for (final org in organizations) {
        final orgId = org['id'] as String;
        final orgName = org['name'] as String;
        
        debugPrint('Processing organization: $orgName ($orgId)');
        
        // Migrate admin_ids
        if (org['admin_ids'] != null) {
          final adminIds = List<String>.from(org['admin_ids']);
          for (final userId in adminIds) {
            final migrated = await _migrateUserMembership(
              userId: userId,
              organizationId: orgId,
              role: 'admin',
              status: 'approved', // Legacy data is assumed approved
            );
            
            if (migrated) {
              result.adminsMigrated++;
            } else {
              result.errors.add('Failed to migrate admin $userId for org $orgName');
            }
          }
        }
        
        // Migrate member_ids
        if (org['member_ids'] != null) {
          final memberIds = List<String>.from(org['member_ids']);
          for (final userId in memberIds) {
            // Skip if user is already an admin (avoid duplicates)
            final isAlreadyAdmin = org['admin_ids'] != null && 
                List<String>.from(org['admin_ids']).contains(userId);
            
            if (!isAlreadyAdmin) {
              final migrated = await _migrateUserMembership(
                userId: userId,
                organizationId: orgId,
                role: 'member',
                status: 'approved', // Legacy data is assumed approved
              );
              
              if (migrated) {
                result.membersMigrated++;
              } else {
                result.errors.add('Failed to migrate member $userId for org $orgName');
              }
            }
          }
        }
        
        result.organizationsProcessed++;
      }
      
      result.success = true;
      debugPrint('Migration completed successfully!');
      debugPrint('Organizations processed: ${result.organizationsProcessed}');
      debugPrint('Admins migrated: ${result.adminsMigrated}');
      debugPrint('Members migrated: ${result.membersMigrated}');
      debugPrint('Errors: ${result.errors.length}');
      
    } catch (e) {
      result.success = false;
      result.errors.add('Migration failed: $e');
      debugPrint('Migration failed: $e');
    }
    
    return result;
  }

  /// Migrate a single user's membership to organization_members table
  Future<bool> _migrateUserMembership({
    required String userId,
    required String organizationId,
    required String role,
    required String status,
  }) async {
    try {
      // Check if membership already exists
      final existing = await _client
          .from('organization_members')
          .select('id')
          .eq('user_id', userId)
          .eq('organization_id', organizationId)
          .maybeSingle();

      if (existing != null) {
        debugPrint('Membership already exists for user $userId in org $organizationId');
        return true; // Consider it successful since it already exists
      }

      // Create new membership record
      final membershipData = {
        'user_id': userId,
        'organization_id': organizationId,
        'role': role,
        'status': status,
        'joined_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('organization_members')
          .insert(membershipData);

      debugPrint('Migrated $role membership for user $userId in org $organizationId');
      return true;
    } catch (e) {
      debugPrint('Error migrating membership for user $userId: $e');
      return false;
    }
  }

  /// Check migration status - how much data still needs to be migrated
  Future<MigrationStatus> checkMigrationStatus() async {
    try {
      // Count organizations with array-based memberships
      final orgsWithArrays = await _client
          .from('organizations')
          .select('id, admin_ids, member_ids')
          .not('admin_ids', 'is', null)
          .or('not.member_ids.is.null');

      int totalArrayMemberships = 0;
      for (final org in orgsWithArrays) {
        if (org['admin_ids'] != null) {
          totalArrayMemberships += (org['admin_ids'] as List).length;
        }
        if (org['member_ids'] != null) {
          totalArrayMemberships += (org['member_ids'] as List).length;
        }
      }

      // Count existing organization_members records
      final existingMemberships = await _client
          .from('organization_members')
          .select('id', count: CountOption.exact);

      final existingCount = existingMemberships.count ?? 0;

      return MigrationStatus(
        organizationsWithArrays: orgsWithArrays.length,
        totalArrayMemberships: totalArrayMemberships,
        existingMemberships: existingCount,
        migrationNeeded: totalArrayMemberships > existingCount,
      );
    } catch (e) {
      debugPrint('Error checking migration status: $e');
      return MigrationStatus(
        organizationsWithArrays: 0,
        totalArrayMemberships: 0,
        existingMemberships: 0,
        migrationNeeded: false,
      );
    }
  }

  /// Clean up legacy array fields after successful migration (optional)
  /// WARNING: Only run this after confirming migration was successful
  Future<bool> cleanupLegacyArrayFields() async {
    try {
      debugPrint('WARNING: Cleaning up legacy array fields...');
      
      // Set all admin_ids and member_ids to empty arrays
      await _client
          .from('organizations')
          .update({
            'admin_ids': [],
            'member_ids': [],
          })
          .not('admin_ids', 'is', null)
          .or('not.member_ids.is.null');

      debugPrint('Legacy array fields cleaned up successfully');
      return true;
    } catch (e) {
      debugPrint('Error cleaning up legacy array fields: $e');
      return false;
    }
  }
}

/// Result of the migration process
class MigrationResult {
  bool success = false;
  int organizationsProcessed = 0;
  int adminsMigrated = 0;
  int membersMigrated = 0;
  List<String> errors = [];

  int get totalMigrated => adminsMigrated + membersMigrated;

  @override
  String toString() {
    return 'MigrationResult(success: $success, orgs: $organizationsProcessed, '
           'admins: $adminsMigrated, members: $membersMigrated, errors: ${errors.length})';
  }
}

/// Status of migration - what needs to be done
class MigrationStatus {
  final int organizationsWithArrays;
  final int totalArrayMemberships;
  final int existingMemberships;
  final bool migrationNeeded;

  MigrationStatus({
    required this.organizationsWithArrays,
    required this.totalArrayMemberships,
    required this.existingMemberships,
    required this.migrationNeeded,
  });

  @override
  String toString() {
    return 'MigrationStatus(orgsWithArrays: $organizationsWithArrays, '
           'totalArrayMemberships: $totalArrayMemberships, '
           'existingMemberships: $existingMemberships, '
           'migrationNeeded: $migrationNeeded)';
  }
}
