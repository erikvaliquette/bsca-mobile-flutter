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
  
  List<BusinessConnection> _sentInvitations = [];
  List<BusinessConnection> get sentInvitations => _sentInvitations;
  
  List<BusinessConnection> _receivedInvitations = [];
  List<BusinessConnection> get receivedInvitations => _receivedInvitations;
  
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
      
      // First, get all users who already have an accepted connection with the current user
      final acceptedConnections = await client
          .from('business_connections')
          .select('user_id, counterparty_id')
          .or('user_id.eq.$userId,counterparty_id.eq.$userId')
          .eq('status', 'accepted');
      
      debugPrint('🔍 Accepted connections: $acceptedConnections');
      
      // Create a set of user IDs that already have an accepted connection
      Set<String> connectedUserIds = {};
      if (acceptedConnections != null && acceptedConnections is List) {
        for (var connection in acceptedConnections) {
          if (connection['user_id'] == userId) {
            connectedUserIds.add(connection['counterparty_id']);
          } else {
            connectedUserIds.add(connection['user_id']);
          }
        }
      }
      
      debugPrint('🔍 Users with accepted connections: $connectedUserIds');

      // Get pending requests where current user is the counterparty (receiving requests)
      debugPrint('🔍 Fetching pending requests for user: $userId');
      final pendingResponse = await client
          .from('business_connections')
          .select()
          .eq('counterparty_id', userId)
          .eq('status', 'pending');
      
      debugPrint('📃 Raw pending response: $pendingResponse');
      debugPrint('📈 Pending response count: ${(pendingResponse as List).length}');

      // Filter out pending requests from users who already have an accepted connection
      final filteredPendingResponse = pendingResponse.where((request) {
        final senderId = request['user_id'];
        return !connectedUserIds.contains(senderId);
      }).toList();
      
      debugPrint('🔍 After filtering out accepted connections, pending count: ${filteredPendingResponse.length}');
      
      List<BusinessConnection> requests = [];
      int newRequestCount = 0;

      // For each pending request, fetch the requester's profile data
      for (var request in filteredPendingResponse) {
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
          final firstName = profileResponse['first_name'] ?? '';
          final lastName = profileResponse['last_name'] ?? '';
          requestData.name = '$firstName $lastName'.trim().isNotEmpty 
              ? '$firstName $lastName'.trim() 
              : profileResponse['email'] ?? 'Unknown User';
          requestData.organization = profileResponse['company_name'];
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

  Future<void> fetchSentInvitations() async {
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('❌ User not authenticated');
        return;
      }

      debugPrint('📤 Fetching sent invitations for user: $userId');

      final sentResponse = await client
          .from('business_connections')
          .select()
          .eq('user_id', userId)
          .eq('status', 'pending');

      debugPrint('📤 Raw sent invitations response: $sentResponse');
      debugPrint('📊 Sent invitations count: ${(sentResponse as List).length}');

      if (sentResponse != null) {
        List<BusinessConnection> sentList = [];

        for (var invitation in sentResponse as List) {
          final counterpartyId = invitation['counterparty_id'] as String;

          // Fetch counterparty profile
          final profileResponse = await client
              .from('profiles')
              .select('first_name, last_name, avatar_url, headline, country, company_name')
              .eq('id', counterpartyId)
              .single();

          if (profileResponse != null) {
            final profile = profileResponse as Map<String, dynamic>;
            final firstName = profile['first_name'] as String? ?? '';
            final lastName = profile['last_name'] as String? ?? '';
            final fullName = '$firstName $lastName'.trim();

            sentList.add(BusinessConnection(
              id: invitation['id'] as String,
              name: fullName.isEmpty ? 'Unknown User' : fullName,
              userId: userId!,
              counterpartyId: counterpartyId,
              relationshipType: invitation['relationship_type'] as String? ?? 'professional',
              status: 'pending',
              location: profile['country'] as String?,
              title: profile['headline'] as String?,
              organization: profile['company_name'] as String?,
              profileImageUrl: profile['avatar_url'] as String?,
              createdAt: DateTime.parse(invitation['created_at'] as String),
              updatedAt: DateTime.parse(invitation['updated_at'] as String),
            ));
          }
        }

        _sentInvitations = sentList;
        debugPrint('Fetched ${_sentInvitations.length} sent invitations');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error fetching sent invitations: $e');
    }
  }

  Future<void> fetchReceivedInvitations() async {
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('User not authenticated for fetching received invitations');
        return;
      }

      debugPrint('📍 Fetching received invitations for user: $userId');
      
      // First, get all users who already have an accepted connection with the current user
      final acceptedConnections = await client
          .from('business_connections')
          .select('user_id, counterparty_id')
          .or('user_id.eq.$userId,counterparty_id.eq.$userId')
          .eq('status', 'accepted');
      
      debugPrint('📍 Accepted connections: $acceptedConnections');
      
      // Create a set of user IDs that already have an accepted connection
      Set<String> connectedUserIds = {};
      if (acceptedConnections != null && acceptedConnections is List) {
        for (var connection in acceptedConnections) {
          if (connection['user_id'] == userId) {
            connectedUserIds.add(connection['counterparty_id']);
          } else {
            connectedUserIds.add(connection['user_id']);
          }
        }
      }
      
      debugPrint('📍 Users with accepted connections: $connectedUserIds');
      
      // Get all pending invitations in the system for debugging
      final allPendingInvitations = await client
          .from('business_connections')
          .select()
          .eq('status', 'pending');
      
      debugPrint('📍 All pending invitations in system: $allPendingInvitations');
      
      // Check for a specific invitation for debugging
      if (allPendingInvitations != null && allPendingInvitations is List) {
        for (var invitation in allPendingInvitations) {
          debugPrint('📍 Checking invitation: user_id=${invitation['user_id']}, counterparty_id=${invitation['counterparty_id']}');
        }
      }
      
      // Debug check for a specific invitation
      debugPrint('📍 Checking for specific invitation from Free User test to Erik');
      final specificInvitation = await client
          .from('business_connections')
          .select()
          .eq('user_id', '20416cbc-2496-4e5d-bad2-e931ef8858c6')
          .eq('counterparty_id', userId);
      
      debugPrint('📍 Specific invitation check result: $specificInvitation');
      
      // Get all business connections for debugging
      final allConnections = await client
          .from('business_connections')
          .select();
      
      debugPrint('📍 All business connections in system: $allConnections');
      
      // Get all connections where the current user is the counterparty
      final counterpartyConnections = await client
          .from('business_connections')
          .select()
          .eq('counterparty_id', userId);
      
      debugPrint('📍 All connections where user is counterparty: $counterpartyConnections');

      // Query for pending invitations where current user is the counterparty
      final query = 'counterparty_id=$userId AND status=pending';
      debugPrint('📍 Query used: $query');
      
      final response = await client
          .from('business_connections')
          .select('''
            id,
            user_id,
            counterparty_id,
            status,
            relationship_type,
            created_at,
            updated_at,
            profiles!user_id(*)
          ''')
          .eq('counterparty_id', userId)
          .eq('status', 'pending');

      debugPrint('📍 Raw received invitations response: $response');
      debugPrint('📈 Received invitations count: ${response?.length ?? 0}');

      if (response != null && response is List) {
        // Filter out invitations from users who already have an accepted connection
        final filteredResponse = response.where((data) {
          final senderId = data['user_id'];
          return !connectedUserIds.contains(senderId);
        }).toList();
        
        debugPrint('📍 After filtering out accepted connections, invitations count: ${filteredResponse.length}');
        
        _receivedInvitations = filteredResponse.map((data) {
          final profile = data['profiles'] ?? {};
          final firstName = profile['first_name'] ?? '';
          final lastName = profile['last_name'] ?? '';
          final fullName = '$firstName $lastName'.trim();
          
          return BusinessConnection(
            id: data['id'],
            name: fullName.isEmpty ? 'Unknown User' : fullName,
            userId: data['user_id'],
            counterpartyId: data['counterparty_id'],
            status: data['status'],
            relationshipType: data['relationship_type'],
            createdAt: data['created_at'] != null
                ? DateTime.parse(data['created_at'])
                : DateTime.now(),
            updatedAt: data['updated_at'] != null
                ? DateTime.parse(data['updated_at'])
                : DateTime.now(),
            location: profile['country'],
            title: profile['headline'],
            organization: profile['organization'],
            profileImageUrl: profile['avatar_url'],
          );
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error fetching received invitations: $e');
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
      debugPrint('🔍 Fetching discover profiles for user: $userId');
      final myConnectionsResponse = await client
          .from('business_connections')
          .select('counterparty_id, status')
          .eq('user_id', userId);

      debugPrint('📋 My connections response: $myConnectionsResponse');

      // Create maps for connection status tracking
      Map<String, String> connectionStatus = {};
      List<String> excludedUserIds = [];
      
      if (myConnectionsResponse != null) {
        for (var connection in myConnectionsResponse as List) {
          final counterpartyId = connection['counterparty_id'] as String;
          final status = connection['status'] as String;
          connectionStatus[counterpartyId] = status;
          debugPrint('📊 Connection status for $counterpartyId: $status');
          
          // Exclude both accepted and pending connections from discover
          if (status == 'accepted' || status == 'pending') {
            excludedUserIds.add(counterpartyId);
          }
        }
      }
      
      debugPrint('📺️ Final connection status map: $connectionStatus');
      debugPrint('❌ Excluded user IDs: $excludedUserIds');

      // Add current user ID to exclude
      excludedUserIds.add(userId);

      // Fetch profiles excluding accepted and pending connections
      // Only include profiles that are public (is_public is TRUE or NULL)
      final profilesResponse = await client
          .from('profiles')
          .select('id, first_name, last_name, avatar_url, headline, country')
          .not('id', 'in', '(${excludedUserIds.join(',')})')
          .or('is_public.is.null,is_public.eq.true')
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
          final profileStatus = connectionStatus[profileId] ?? '';
          debugPrint('👤 Creating discover profile for ${profile['first_name']} ${profile['last_name']} (ID: $profileId) with status: "$profileStatus"');
          
          final discoverProfile = BusinessConnection(
            id: 'discover-$profileId', // Prefix with 'discover-' to ensure unique IDs
            userId: '',
            counterpartyId: profileId,
            relationshipType: '',
            status: profileStatus, // Include connection status if exists
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
      
      // IMPORTANT: First check if a connection already exists in either direction
      final existingConnections = await client
          .from('business_connections')
          .select()
          .or('and(user_id.eq.$userId,counterparty_id.eq.$counterpartyId),and(user_id.eq.$counterpartyId,counterparty_id.eq.$userId)');
      
      debugPrint('🔍 Checking for existing connections before sending request: $existingConnections');
      
      // If an accepted connection already exists, don't create a new one
      if (existingConnections != null && existingConnections is List && existingConnections.isNotEmpty) {
        bool hasAccepted = existingConnections.any((conn) => conn['status'] == 'accepted');
        
        if (hasAccepted) {
          debugPrint('⚠️ An accepted connection already exists, not creating a new request');
          return;
        }
        
        // If there's a pending connection, update its status instead of creating a new one
        bool hasPending = existingConnections.any((conn) => conn['status'] == 'pending');
        
        if (hasPending) {
          debugPrint('⚠️ A pending connection already exists, not creating a new request');
          return;
        }
      }

      // No existing connection, create a new one
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
      await fetchSentInvitations(); // Also refresh sent invitations
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

  // Accept a connection request and create bi-directional connection
  Future<bool> acceptConnectionRequest(String connectionId, String requesterId) async {
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('User not authenticated for accepting connection');
        return false;
      }

      debugPrint('🔄 Accepting connection request: $connectionId from user: $requesterId');
      debugPrint('📃 Current received invitations: ${_receivedInvitations.map((i) => i.id).toList()}');
      
      // First, immediately remove from local lists to prevent UI flicker
      _updateInvitationsLists(connectionId);
      
      // Update notification badge
      if (_notificationProvider != null) {
        _notificationProvider!.decrementContactRequestCount();
      }
      
      // Notify UI of changes immediately
      notifyListeners();

      // Get the original connection details to determine the direction
      final originalConnection = await client
          .from('business_connections')
          .select()
          .eq('id', connectionId)
          .single();
      
      debugPrint('🔎 Original connection: $originalConnection');
      
      if (originalConnection != null) {
        String originalUserId = originalConnection['user_id'];
        String originalCounterpartyId = originalConnection['counterparty_id'];
        
        debugPrint('🔄 Updating ALL connections between $originalUserId and $originalCounterpartyId to accepted');
        
        // CRITICAL FIX: First find ALL connections between these two users in BOTH directions
        final existingConnections = await client
            .from('business_connections')
            .select()
            .or('and(user_id.eq.$originalUserId,counterparty_id.eq.$originalCounterpartyId),and(user_id.eq.$originalCounterpartyId,counterparty_id.eq.$originalUserId)');
        
        debugPrint('🔍 All existing connections between users: $existingConnections');
        
        // Check if a reciprocal connection exists (where current user is the sender)
        bool hasReciprocalConnection = false;
        String? reciprocalConnectionId;
        
        if (existingConnections != null && existingConnections is List) {
          for (var conn in existingConnections) {
            if (conn['user_id'] == originalCounterpartyId && conn['counterparty_id'] == originalUserId) {
              hasReciprocalConnection = true;
              reciprocalConnectionId = conn['id'];
              debugPrint('✅ Found existing reciprocal connection: ${conn['id']}');
              break;
            }
          }
        }
        
        // If no reciprocal connection exists, create one with status 'accepted'
        if (!hasReciprocalConnection) {
          debugPrint('✅ No reciprocal connection found, creating one with status "accepted"');
          
          // Create a new reciprocal connection with status 'accepted'
          final insertResponse = await client
              .from('business_connections')
              .insert({
                'user_id': originalCounterpartyId,
                'counterparty_id': originalUserId,
                'status': 'accepted',
                'relationship_type': 'professional',
              })
              .select();
          
          debugPrint('✅ Created new reciprocal connection: $insertResponse');
          
          if (insertResponse != null && insertResponse is List && insertResponse.isNotEmpty) {
            reciprocalConnectionId = insertResponse[0]['id'];
          }
        } else {
          // Reciprocal connection exists, update it to 'accepted'
          debugPrint('✅ Reciprocal connection found, updating to "accepted"');
          
          if (reciprocalConnectionId != null) {
            final updateReciprocalResponse = await client
                .from('business_connections')
                .update({
                  'status': 'accepted', 
                  'updated_at': DateTime.now().toIso8601String()
                })
                .eq('id', reciprocalConnectionId);
                
            debugPrint('✅ Updated reciprocal connection $reciprocalConnectionId to accepted: $updateReciprocalResponse');
          }
        }
        
        // Now update the original connection to 'accepted'
        final updateResponse = await client
            .from('business_connections')
            .update({
              'status': 'accepted', 
              'updated_at': DateTime.now().toIso8601String()
            })
            .eq('id', connectionId);
        
        debugPrint('✅ Update original connection response: $updateResponse');
        
        // CRITICAL FIX: Update ALL connections between these users to 'accepted'
        // This ensures we don't have any lingering 'pending' connections
        final directUpdateAllResponse = await client
            .from('business_connections')
            .update({
              'status': 'accepted', 
              'updated_at': DateTime.now().toIso8601String()
            })
            .or('and(user_id.eq.$originalUserId,counterparty_id.eq.$originalCounterpartyId),and(user_id.eq.$originalCounterpartyId,counterparty_id.eq.$originalUserId)');
            
        debugPrint('✅ Direct update ALL connections response: $directUpdateAllResponse');
        
        // Add a small delay to ensure database consistency
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Final verification - check that ALL connections are now 'accepted'
        final finalConnections = await client
            .from('business_connections')
            .select()
            .or('and(user_id.eq.$originalUserId,counterparty_id.eq.$originalCounterpartyId),and(user_id.eq.$originalCounterpartyId,counterparty_id.eq.$originalUserId)');
        
        debugPrint('🔍 Final verification of all connections: $finalConnections');
        
        // If any connections are still pending, force update them
        if (finalConnections != null && finalConnections is List) {
          for (var conn in finalConnections) {
            if (conn['status'] == 'pending') {
              debugPrint('⚠️ Found a connection still in pending status: ${conn['id']}');
              
              // Force update this specific connection to accepted
              final forceUpdateResponse = await client
                  .from('business_connections')
                  .update({
                    'status': 'accepted', 
                    'updated_at': DateTime.now().toIso8601String()
                  })
                  .eq('id', conn['id']);
                  
              debugPrint('✅ Force updated pending connection to accepted: $forceUpdateResponse');
            }
          }
        }
      }
      
      // Refresh data after server operations
      debugPrint('🔄 Refreshing connections and discover profiles');
      await fetchConnections();
      await fetchDiscoverProfiles();
      
      // Force refresh of invitations to ensure they're up to date
      debugPrint('🔄 Force refreshing invitations');
      await fetchReceivedInvitations();
      await fetchSentInvitations();
      
      debugPrint('📃 After refresh, received invitations: ${_receivedInvitations.map((i) => i.id).toList()}');
      debugPrint('✅ Connection request accepted and bi-directional connection created');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error accepting connection request: $e');
      // If there was an error, refresh the lists to restore the invitation if needed
      await fetchReceivedInvitations();
      await fetchSentInvitations();
      return false;
    }
  }

  // Helper method to update invitations lists after accepting or rejecting a request
  void _updateInvitationsLists(String connectionId) {
    _receivedInvitations.removeWhere((invitation) => invitation.id == connectionId);
    _sentInvitations.removeWhere((invitation) => invitation.id == connectionId);
    notifyListeners();
  }

  // Reject a connection request
  Future<bool> rejectConnectionRequest(String connectionId) async {
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('User not authenticated for rejecting connection');
        return false;
      }
      
      debugPrint('🔄 Rejecting connection request: $connectionId');

      // First, immediately remove from local lists to prevent UI flicker
      _receivedInvitations.removeWhere((invitation) => invitation.id == connectionId);
      _pendingRequests.removeWhere((request) => request.id == connectionId);
      
      // Update notification badge
      if (_notificationProvider != null) {
        _notificationProvider!.decrementContactRequestCount();
      }
      
      // Notify UI of changes immediately
      notifyListeners();

      // Update the request status to 'rejected'
      final updateResponse = await client
          .from('business_connections')
          .update({'status': 'rejected', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', connectionId)
          .select();
      
      debugPrint('✅ Update response: $updateResponse');
      
      // Refresh connections
      await fetchConnections();
      
      debugPrint('✅ Connection request rejected');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error rejecting connection request: $e');
      // If there was an error, refresh the lists to restore the invitation if needed
      await fetchReceivedInvitations();
      return false;
    }
  }
}
