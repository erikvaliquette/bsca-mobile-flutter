import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business_connection_model.dart';
import '../services/supabase/supabase_client.dart';
import '../services/notifications/notification_provider.dart';

class BusinessConnectionProvider extends ChangeNotifier {
  List<BusinessConnection> _connections = [];
  List<BusinessConnection> get connections => _connections;

  List<BusinessConnection> _discoverProfiles = [];
  List<BusinessConnection> get discoverProfiles => _discoverProfiles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingDiscover = false;
  bool get isLoadingDiscover => _isLoadingDiscover;

  String? _error;
  String? get error => _error;

  String? _discoverError;
  String? get discoverError => _discoverError;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  int? _sdgFilter;
  int? get selectedSDGFilter => _sdgFilter;
  
  // Notification provider reference for badge updates
  NotificationProvider? _notificationProvider;
  
  // Pending incoming contact requests
  List<BusinessConnection> _pendingRequests = [];
  List<BusinessConnection> get pendingRequests => _pendingRequests;
  
  // Set notification provider reference for badge updates
  void setNotificationProvider(NotificationProvider notificationProvider) {
    _notificationProvider = notificationProvider;
  }
  
  // Fetch pending incoming contact requests (where current user is counterparty)
  Future<void> fetchPendingRequests() async {
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('User not authenticated for fetching pending requests');
        return;
      }

      // Get pending requests where current user is the counterparty (receiving requests)
      final pendingResponse = await client
          .from('business_connections')
          .select()
          .eq('counterparty_id', userId)
          .eq('status', 'pending');

      List<BusinessConnection> requests = [];
      int newRequestCount = 0;

      // For each pending request, fetch the requester's profile data
      for (var request in pendingResponse as List) {
        final requestData = BusinessConnection.fromJson(request);

        try {
          // Fetch profile data for the requester (user_id)
          final profileResponse = await client
              .from('profiles')
              .select()
              .eq('id', requestData.userId)
              .single();

          // Fetch SDG data for the requester
          final sdgResponse = await client
              .from('user_sdgs')
              .select('sdg_id')
              .eq('user_id', requestData.userId);

          final sdgGoals = (sdgResponse as List)
              .map((sdg) => sdg['sdg_id'] as int)
              .toList();

          // Update request data with profile information
          requestData.name = profileResponse['username'] ?? profileResponse['email'] ?? 'Unknown User';
          requestData.organization = profileResponse['organization'];
          requestData.profileImageUrl = profileResponse['avatar_url'];
          requestData.title = profileResponse['headline'];
          requestData.location = profileResponse['country'];
          requestData.sdgGoals = sdgGoals;

          requests.add(requestData);
          newRequestCount++;
        } catch (e) {
          debugPrint('Error fetching profile for pending request ${requestData.id}: $e');
        }
      }

      // Update notification badge if there are new requests
      if (newRequestCount > _pendingRequests.length && _notificationProvider != null) {
        final badgeIncrement = newRequestCount - _pendingRequests.length;
        for (int i = 0; i < badgeIncrement; i++) {
          _notificationProvider!.incrementContactRequestCount();
        }
        debugPrint('📱 Incremented contact request badge by $badgeIncrement');
      }

      _pendingRequests = requests;
      debugPrint('Fetched ${requests.length} pending contact requests');
      
    } catch (e) {
      debugPrint('Error fetching pending contact requests: $e');
    }
  }

  List<BusinessConnection> get filteredConnections {
    if (_searchQuery.isEmpty && _sdgFilter == null) {
      return _connections;
    }

    return _connections.where((connection) {
      // Filter by search query
      bool matchesSearch = _searchQuery.isEmpty ||
          connection.name.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter by SDG
      bool matchesSDG = _sdgFilter == null ||
          (connection.sdgGoals != null && connection.sdgGoals!.contains(_sdgFilter));

      return matchesSearch && matchesSDG;
    }).toList();
  }

  List<BusinessConnection> get filteredDiscoverProfiles {
    if (_searchQuery.isEmpty && _sdgFilter == null) {
      return _discoverProfiles;
    }

    return _discoverProfiles.where((profile) {
      // Filter by search query
      bool matchesSearch = _searchQuery.isEmpty ||
          profile.name.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter by SDG
      bool matchesSDG = _sdgFilter == null ||
          (profile.sdgGoals != null && profile.sdgGoals!.contains(_sdgFilter));

      return matchesSearch && matchesSDG;
    }).toList();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Set SDG filter
  void setSDGFilter(int? sdgNumber) {
    _sdgFilter = sdgNumber;
    notifyListeners();
  }

  // Fetch connections from Supabase
  Future<void> fetchConnections() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        _error = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // First get business connections
      final connectionsResponse = await client
          .from('business_connections')
          .select()
          .eq('user_id', userId)
          .eq('status', 'accepted');

      List<BusinessConnection> connections = [];

      // For each connection, fetch the profile data
      for (var connection in connectionsResponse as List) {
        final connectionData = BusinessConnection.fromJson(connection);

        try {
          // Fetch profile data for the counterparty
          final profileResponse = await client
              .from('profiles')
              .select()
              .eq('id', connectionData.counterpartyId)
              .single();

          // Fetch SDG data for the counterparty
          final sdgResponse = await client
              .from('user_sdgs')
              .select('sdg_id')
              .eq('user_id', connectionData.counterpartyId);

          // Extract SDG IDs
          List<int> sdgGoals = [];
          if (sdgResponse != null) {
            sdgGoals = (sdgResponse as List).map((sdg) => sdg['sdg_id'] as int).toList();
          }

          // Update connection with profile data
          connectionData.name = '${profileResponse['first_name']} ${profileResponse['last_name']}';
          connectionData.profileImageUrl = profileResponse['avatar_url'];
          connectionData.title = profileResponse['headline'];
          connectionData.location = profileResponse['country'];
          connectionData.sdgGoals = sdgGoals;

          connections.add(connectionData);
        } catch (e) {
          debugPrint('Error fetching profile for connection ${connectionData.id}: $e');
        }
      }

      _connections = connections;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDiscoverProfiles() async {
    _isLoadingDiscover = true;
    _discoverError = null;
    notifyListeners();

    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        _discoverError = 'User not authenticated';
        _isLoadingDiscover = false;
        notifyListeners();
        return;
      }

      // Get all connections with their status
      final myConnectionsResponse = await client
          .from('business_connections')
          .select('counterparty_id, status')
          .eq('user_id', userId);

      // Create maps for connection status tracking
      Map<String, String> connectionStatus = {};
      List<String> acceptedUserIds = [];
      
      if (myConnectionsResponse != null) {
        for (var connection in myConnectionsResponse as List) {
          final counterpartyId = connection['counterparty_id'] as String;
          final status = connection['status'] as String;
          connectionStatus[counterpartyId] = status;
          
          // Only exclude accepted connections from discover
          if (status == 'accepted') {
            acceptedUserIds.add(counterpartyId);
          }
        }
      }

      // Add current user ID to exclude
      acceptedUserIds.add(userId);

      // Fetch profiles excluding only accepted connections
      final profilesResponse = await client
          .from('profiles')
          .select('id, first_name, last_name, avatar_url, headline, country')
          .not('id', 'in', '(${acceptedUserIds.join(',')})')
          .limit(20);

      List<BusinessConnection> discoverProfiles = [];

      // For each profile, create a BusinessConnection object
      for (var profile in profilesResponse as List) {
        final String profileId = profile['id'];

        try {
          // Fetch SDG data for the profile
          final sdgResponse = await client
              .from('user_sdgs')
              .select('sdg_id')
              .eq('user_id', profileId);

          // Extract SDG IDs
          List<int> sdgGoals = [];
          if (sdgResponse != null) {
            sdgGoals = (sdgResponse as List).map((sdg) => sdg['sdg_id'] as int).toList();
          }

          // Create a BusinessConnection object for the discover profile
          final discoverProfile = BusinessConnection(
            id: 'discover-$profileId', // Prefix with 'discover-' to ensure unique IDs
            userId: '',
            counterpartyId: profileId,
            relationshipType: '',
            status: connectionStatus[profileId] ?? '', // Include connection status if exists
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            name: '${profile['first_name']} ${profile['last_name']}',
            profileImageUrl: profile['avatar_url'],
            title: profile['headline'],
            location: profile['country'],
            organization: '',
            sdgGoals: sdgGoals,
          );

          discoverProfiles.add(discoverProfile);
        } catch (e) {
          debugPrint('Error fetching SDGs for profile $profileId: $e');
        }
      }

      _discoverProfiles = discoverProfiles;
    } catch (e) {
      _discoverError = e.toString();
    } finally {
      _isLoadingDiscover = false;
      notifyListeners();
    }
  }

  // Add a new connection
  Future<void> addConnection(BusinessConnection connection) async {
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await client
          .from('business_connections')
          .insert(connection.toJson())
          .select();

      final newConnection = BusinessConnection.fromJson(response[0]);
      _connections.add(newConnection);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add connection: $e');
    }
  }

  Future<void> sendConnectionRequest(String counterpartyId) async {
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await client
          .from('business_connections')
          .insert({
            'user_id': userId,
            'counterparty_id': counterpartyId,
            'relationship_type': 'professional',
            'status': 'pending'
          });

      // Refresh discover profiles after sending a connection request
      await fetchDiscoverProfiles();
    } catch (e) {
      throw Exception('Failed to send connection request: $e');
    }
  }

  // Update an existing connection
  Future<void> updateConnection(BusinessConnection connection) async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.client
          .from('business_connections')
          .update(connection.toJson())
          .eq('id', connection.id);
      
      await fetchConnections(); // Refresh the list
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to update connection: $e';
      notifyListeners();
      print('Error updating connection: $e');
    }
  }

  // Delete a connection
  Future<void> deleteConnection(String connectionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.client
          .from('business_connections')
          .delete()
          .eq('id', connectionId);
      
      await fetchConnections(); // Refresh the list
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to delete connection: $e';
      notifyListeners();
      print('Error deleting connection: $e');
    }
  }
}
