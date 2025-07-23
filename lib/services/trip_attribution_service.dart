import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_organization_attribution_model.dart';
import '../services/supabase/supabase_client.dart';
import 'connectivity_service.dart';

/// Service for managing trip-organization attribution
class TripAttributionService {
  static final TripAttributionService _instance = TripAttributionService._internal();
  static TripAttributionService get instance => _instance;
  
  final SupabaseClient _client = Supabase.instance.client;
  
  TripAttributionService._internal();
  
  /// Create a new trip organization attribution record
  Future<bool> createTripOrganizationAttribution(String tripId, String organizationId, double emissions) async {
    try {
      debugPrint('🔄 Creating attribution record: $emissions kg CO2e from trip $tripId to organization $organizationId');
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - attribution record will be synced later');
        return false;
      }
      
      // Check if there's already an active attribution for this trip and organization
      final existingAttribution = await _client
          .from('trip_organization_attribution')
          .select()
          .eq('trip_id', tripId)
          .eq('organization_id', organizationId)
          .eq('is_active', true)
          .maybeSingle();
      
      if (existingAttribution != null) {
        debugPrint('⚠️ Attribution record already exists, updating emissions amount');
        
        // Update the existing attribution with the new emissions amount
        final updateResult = await _client
            .from('trip_organization_attribution')
            .update({
              'emissions_amount': emissions,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingAttribution['id'])
            .select();
            
        debugPrint('✅ Attribution record updated: $updateResult');
        return true;
      }
      
      // Create a new attribution record
      final attribution = TripOrganizationAttribution.create(
        tripId: tripId,
        organizationId: organizationId,
        emissionsAmount: emissions,
      );
      
      final insertResult = await _client
          .from('trip_organization_attribution')
          .insert(attribution.toJson())
          .select();
          
      debugPrint('✅ Attribution record created: $insertResult');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating trip organization attribution: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }
  
  /// Deactivate trip organization attribution record
  Future<bool> deactivateTripOrganizationAttribution(String tripId, String organizationId) async {
    try {
      debugPrint('🔄 Deactivating attribution record for trip $tripId and organization $organizationId');
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - deactivation will be synced later');
        return false;
      }
      
      // Find the active attribution record
      final existingAttribution = await _client
          .from('trip_organization_attribution')
          .select()
          .eq('trip_id', tripId)
          .eq('organization_id', organizationId)
          .eq('is_active', true)
          .maybeSingle();
      
      if (existingAttribution == null) {
        debugPrint('⚠️ No active attribution record found to deactivate');
        return false;
      }
      
      // Deactivate the attribution record
      final updateResult = await _client
          .from('trip_organization_attribution')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existingAttribution['id'])
          .select();
          
      debugPrint('✅ Attribution record deactivated: $updateResult');
      return true;
    } catch (e) {
      debugPrint('❌ Error deactivating trip organization attribution: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }
  
  /// Get all active attribution records for a trip
  Future<List<TripOrganizationAttribution>> getTripAttributions(String tripId) async {
    try {
      debugPrint('🔍 Getting attribution records for trip $tripId');
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - cannot fetch attribution records');
        return [];
      }
      
      final attributions = await _client
          .from('trip_organization_attribution')
          .select()
          .eq('trip_id', tripId)
          .eq('is_active', true);
          
      return (attributions as List)
          .map((json) => TripOrganizationAttribution.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting trip attributions: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }
  
  /// Reconcile orphaned business trips
  /// This finds business trips without attribution records and creates them
  Future<int> reconcileOrphanedBusinessTrips(String userId, String defaultOrganizationId) async {
    try {
      debugPrint('🔄 Starting reconciliation of orphaned business trips');
      
      if (!ConnectivityService.instance.isConnected) {
        debugPrint('❌ Offline - reconciliation will be performed later');
        return 0;
      }
      
      // Get all business trips for the user
      final businessTrips = await _client
          .from('travel_trips')
          .select()
          .eq('user_id', userId)
          .eq('purpose', 'business');
          
      if (businessTrips == null || (businessTrips as List).isEmpty) {
        debugPrint('ℹ️ No business trips found for reconciliation');
        return 0;
      }
      
      int reconciled = 0;
      
      // Check each business trip for attribution records
      for (final trip in businessTrips) {
        final tripId = trip['id'];
        final emissions = double.parse(trip['emissions']?.toString() ?? '0');
        
        // Check if this trip has any active attribution records
        final attributions = await _client
            .from('trip_organization_attribution')
            .select()
            .eq('trip_id', tripId)
            .eq('is_active', true);
            
        if (attributions == null || (attributions as List).isEmpty) {
          debugPrint('🔍 Found orphaned business trip: $tripId');
          
          // Create attribution record
          final success = await createTripOrganizationAttribution(
            tripId,
            defaultOrganizationId,
            emissions,
          );
          
          if (success) {
            reconciled++;
            debugPrint('✅ Successfully reconciled orphaned trip: $tripId');
          }
        }
      }
      
      debugPrint('🎉 Reconciliation complete: $reconciled orphaned trips reconciled');
      return reconciled;
    } catch (e) {
      debugPrint('❌ Error reconciling orphaned business trips: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return 0;
    }
  }
}
