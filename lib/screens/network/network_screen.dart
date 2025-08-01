import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business_connection_model.dart';
import '../../providers/business_connection_provider.dart';
import '../../providers/message_provider.dart';
import '../../services/subscription_helper.dart';
import '../../widgets/upgrade_prompt_widget.dart';
import '../../services/notifications/notification_provider.dart';
import '../../services/supabase/supabase_client.dart';
import '../../utils/sdg_icons.dart';
import '../../widgets/sdg_icon_widget.dart';
import 'user_profile_screen.dart';
import '../messaging/conversation_screen.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedSDGFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch connections when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BusinessConnectionProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      
      provider.fetchConnections();
      provider.fetchDiscoverProfiles();
      
      // Fetch pending contact requests to update notification badges
      provider.fetchPendingRequests();
      
      // Clear contact request notifications when user views the network screen
      notificationProvider.clearContactRequestNotifications();
      
      // Listen for tab changes to refresh data if needed
      _tabController.addListener(() {
        if (_tabController.index == 0) {
          provider.fetchDiscoverProfiles();
        } else if (_tabController.index == 1) {
          provider.fetchSentInvitations();
          provider.fetchReceivedInvitations();
        } else if (_tabController.index == 2) {
          provider.fetchConnections();
          provider.fetchPendingRequests(); // Fetch pending requests for My Connections tab
        }
        // Trigger rebuild to show/hide + button
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // TabBar moved to top with padding for notch/dynamic island
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: 'My Connections'),
                  Tab(text: 'Discover'),
                  Tab(text: 'Invitations'),
                ],
              ),
            ),
            // Search and Filter Bar
            Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or country...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                  ),
                  onChanged: (value) {
                    // Update search query in provider
                    Provider.of<BusinessConnectionProvider>(context, listen: false)
                        .setSearchQuery(value);
                  },
                ),
                
                const SizedBox(height: 16.0),
                
                // SDG Filter Icons
                Container(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by SDG Goal:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: SDGIcons.getAllSDGNumbers().map((sdgNumber) {
                            return SDGIconWidget(
                              sdgNumber: sdgNumber,
                              isSelected: _selectedSDGFilter == sdgNumber,
                              onTap: () {
                                setState(() {
                                  if (_selectedSDGFilter == sdgNumber) {
                                    // If already selected, deselect it
                                    _selectedSDGFilter = null;
                                  } else {
                                    // Otherwise, select it
                                    _selectedSDGFilter = sdgNumber;
                                  }
                                  
                                  // Update filter in provider
                                  Provider.of<BusinessConnectionProvider>(context, listen: false)
                                      .setSDGFilter(_selectedSDGFilter);
                                });
                              },
                              size: 60,
                              showLabel: false,
                              useAssetIcon: true,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Connections Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TabBarView(
                controller: _tabController,
                children: [
                  // My Connections Tab
                  Consumer<BusinessConnectionProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (provider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Error loading connections',
                                style: TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => provider.fetchConnections(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final connections = provider.filteredConnections;
                      final pendingRequests = provider.pendingRequests;
                      
                      return Column(
                        children: [
                          // Pending Connection Requests Section
                          if (pendingRequests.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.notifications_active, color: Colors.orange.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Pending Connection Requests (${pendingRequests.length})',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...pendingRequests.map((request) => _buildPendingRequestCard(request)),
                                ],
                              ),
                            ),
                          ],
                          
                          // Existing Connections Section
                          Expanded(
                            child: connections.isEmpty
                                ? const Center(
                                    child: Text('No connections found'),
                                  )
                                : ListView.builder(
                                    itemCount: connections.length,
                                    itemBuilder: (context, index) {
                                      return _buildHorizontalConnectionCard(
                                        connections[index],
                                        onDisconnect: () => _handleDisconnect(connections[index]),
                                        onMessage: () async => await _handleMessage(connections[index]),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  // Discover Tab
                  Consumer<BusinessConnectionProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoadingDiscover) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (provider.discoverError != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Error loading discover profiles',
                                style: TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => provider.fetchDiscoverProfiles(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final profiles = provider.filteredDiscoverProfiles;
                      
                      if (profiles.isEmpty) {
                        return const Center(
                          child: Text('No profiles found'),
                        );
                      }
                      
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 0.65, // Adjusted for taller cards with headline
                        ),
                        itemCount: profiles.length,
                        itemBuilder: (context, index) {
                          return _buildBusinessConnectionCard(
                            profiles[index],
                            isDiscover: true,
                            onConnect: () => _handleConnect(profiles[index]),
                          );
                        },
                      );
                    },
                  ),
                  
                  // Invitations Tab
                  Consumer<BusinessConnectionProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sent Invitations Section
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                              child: Text(
                                'Sent Invitations',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            provider.sentInvitations.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.only(bottom: 24.0),
                                    child: Text('No sent invitations'),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: provider.sentInvitations.length,
                                    itemBuilder: (context, index) {
                                      final invitation = provider.sentInvitations[index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.blue.shade200,
                                          backgroundImage: invitation.profileImageUrl != null && invitation.profileImageUrl!.isNotEmpty
                                            ? NetworkImage(invitation.profileImageUrl!)
                                            : null,
                                          child: (invitation.profileImageUrl == null || invitation.profileImageUrl!.isEmpty)
                                            ? Text(_getInitials(invitation.name))
                                            : null,
                                        ),
                                        title: Text(invitation.name),
                                        subtitle: Text('${invitation.organization ?? 'No organization'} • ${invitation.title ?? 'No title'}'),
                                        trailing: const Chip(
                                          label: Text('Pending'),
                                          backgroundColor: Colors.amber,
                                        ),
                                      );
                                    },
                                  ),
                                  
                            const Divider(height: 32),
                            
                            // Received Invitations Section
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                              child: Text(
                                'Received Invitations',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            provider.receivedInvitations.isEmpty
                                ? const Text('No received invitations')
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: provider.receivedInvitations.length,
                                    itemBuilder: (context, index) {
                                      final invitation = provider.receivedInvitations[index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.blue.shade200,
                                          backgroundImage: invitation.profileImageUrl != null && invitation.profileImageUrl!.isNotEmpty
                                            ? NetworkImage(invitation.profileImageUrl!)
                                            : null,
                                          child: (invitation.profileImageUrl == null || invitation.profileImageUrl!.isEmpty)
                                            ? Text(_getInitials(invitation.name))
                                            : null,
                                        ),
                                        title: Text(invitation.name),
                                        subtitle: Text('${invitation.organization ?? 'No organization'} • ${invitation.title ?? 'No title'}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                             IconButton(
                                               icon: const Icon(Icons.check_circle, color: Colors.green),
                                               onPressed: () => _handleAcceptInvitation(invitation),
                                             ),
                                             IconButton(
                                               icon: const Icon(Icons.cancel, color: Colors.red),
                                               onPressed: () => _handleRejectInvitation(invitation),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  // Handle disconnect action
  void _handleDisconnect(BusinessConnection connection) async {
    try {
      final client = SupabaseService.client;
      await client
          .from('business_connections')
          .delete()
          .eq('id', connection.id);
      
      // Refresh connections
      final provider = Provider.of<BusinessConnectionProvider>(context, listen: false);
      provider.fetchConnections();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection with ${connection.name} removed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing connection: $e')),
      );
    }
  }
  
  // Handle message action
  Future<void> _handleMessage(BusinessConnection connection) async {
    // Show loading indicator
    final loadingSnackBar = SnackBar(
      content: Row(
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 20),
          Text('Opening conversation with ${connection.name}...'),
        ],
      ),
      duration: const Duration(seconds: 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);
    
    // Get current user ID from MessageProvider
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    final currentUserId = messageProvider.getCurrentUserId();
    
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start conversation. Please try again.')),
      );
      return;
    }
    
    // Verify we have a valid counterparty ID (the other user in the connection)
    if (connection.counterpartyId == null || connection.counterpartyId.isEmpty) {
      print('Error: Connection has invalid counterpartyId: ${connection.counterpartyId}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start conversation: Invalid user ID')),
      );
      return;
    }
    
    // Verify we're not trying to message ourselves
    if (currentUserId == connection.counterpartyId) {
      print('Error: Attempting to message self. Current user: $currentUserId, Counterparty: ${connection.counterpartyId}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot start conversation with yourself')),
      );
      return;
    }
    
    print('Starting conversation between current user: $currentUserId and counterparty: ${connection.counterpartyId}');
    
    // Create virtual room ID for direct message using counterpartyId (not userId)
    final userIds = [currentUserId, connection.counterpartyId]
      ..sort(); // Sort to ensure consistent room ID regardless of who initiates
    final roomId = 'dm_${userIds.join('_')}';
    
    print('Generated room ID: $roomId');
    
    // Refresh chat rooms to ensure we have the latest data
    await messageProvider.refreshChatRooms();
    
    // Check if a conversation already exists with this user
    final existingChatRooms = messageProvider.chatRooms;
    final existingRoomIndex = existingChatRooms.indexWhere((room) => room.roomId == roomId);
    
    if (existingRoomIndex != -1) {
      print('Found existing conversation at index $existingRoomIndex: ${existingChatRooms[existingRoomIndex].name}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening existing conversation with ${connection.name}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    } else {
      print('No existing conversation found with room ID: $roomId');
    }
    
    // Navigate to conversation screen (same action for both new and existing conversations)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConversationScreen(roomId: roomId),
      ),
    );
  }
  
  // Handle connect action for discover profiles
  void _handleConnect(BusinessConnection profile) async {
    try {
      final provider = Provider.of<BusinessConnectionProvider>(context, listen: false);
      await provider.sendConnectionRequest(profile.counterpartyId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection request sent to ${profile.name}')),
      );
    } catch (e) {
      // Check if the error is due to connection limit
      if (e.toString().contains('CONNECTION_LIMIT_REACHED')) {
        // Show upgrade prompt for connection limit
        showDialog(
          context: context,
          builder: (context) => UpgradePromptWidget(
            featureKey: SubscriptionHelper.FEATURE_UNLIMITED_CONNECTIONS,
            customMessage: 'Free tier is limited to 100 network connections. Upgrade to Professional tier for unlimited connections.',
            isDialog: true,
          ),
        );
      } else {
        // Handle other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending connection request: $e')),
        );
      }
    }
  }
  

  
  // Handle profile view action
  void _handleViewProfile(BusinessConnection profile, {bool showConnectButton = false}) {
    print('_handleViewProfile called for: ${profile.name}');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          profile: profile,
          showConnectButton: showConnectButton,
        ),
      ),
    );
  }
  
  Widget _buildBusinessConnectionCard(
    BusinessConnection connection, {
    bool isDiscover = false,
    bool showActions = false,
    VoidCallback? onConnect,
    VoidCallback? onDisconnect,
    VoidCallback? onMessage,
  }) {
    // Safely determine avatar color based on connection id to ensure consistency
    final String safeId = connection.id ?? 'default-id';
    final int colorValue = safeId.hashCode % 2;
    final Color avatarColor = colorValue == 0 ? Colors.blue : Colors.blue.shade200;
    
    // Format location for display
    final String displayLocation = connection.location ?? '';
    
    // Get headline from title field
    final String headline = connection.title ?? '';
    
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: avatarColor,
      child: InkWell(
        onTap: () {
          print('Profile card tapped: ${connection.name}');
          _handleViewProfile(connection, showConnectButton: isDiscover);
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Stack(
          children: [
            // Main content in a column layout
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar (either image or text) - moved upwards
                  connection.profileImageUrl != null && connection.profileImageUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 32.0,
                          backgroundImage: NetworkImage(connection.profileImageUrl!),
                        )
                      : Text(
                          connection.initials ?? '',
                          style: const TextStyle(
                            fontSize: 60.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                  
                  const SizedBox(height: 8),
                  
                  // Name
                  Text(
                    connection.name,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Headline (from title field)
                  if (headline.isNotEmpty) ...[                    
                    const SizedBox(height: 4),
                    Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // Location
                  if (displayLocation.isNotEmpty) ...[                    
                    const SizedBox(height: 4),
                    Text(
                      displayLocation,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // Spacer to push connect button to bottom
                  if (isDiscover) const Spacer(),
                  
                  // Action buttons below location
                  if (showActions) ...[                    
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (onMessage != null)
                          IconButton(
                            icon: const Icon(Icons.message, color: Colors.white),
                            onPressed: onMessage,
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Message',
                          ),
                        if (onMessage != null && onDisconnect != null)
                          const SizedBox(width: 12),
                        if (onDisconnect != null)
                          IconButton(
                            icon: const Icon(Icons.person_remove, color: Colors.white),
                            onPressed: onDisconnect,
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Disconnect',
                          ),
                      ],
                    ),
                  ],
                  
                  // Connection status button for discover profiles (moved to bottom)
                  if (isDiscover) ...[                    
                    const SizedBox(height: 8),
                    _buildConnectionStatusWidget(connection, onConnect),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build horizontal card for My Connections tab
  Widget _buildHorizontalConnectionCard(
    BusinessConnection connection, {
    VoidCallback? onDisconnect,
    VoidCallback? onMessage,
  }) {
    // Format location for display
    final String displayLocation = connection.location ?? '';
    
    // Get headline from title field
    final String headline = connection.title ?? '';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          print('Connection card tapped: ${connection.name}');
          _handleViewProfile(connection, showConnectButton: false);
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar on the left
              CircleAvatar(
                radius: 32.0,
                backgroundColor: Theme.of(context).primaryColor,
                backgroundImage: connection.profileImageUrl != null && connection.profileImageUrl!.isNotEmpty
                    ? NetworkImage(connection.profileImageUrl!)
                    : null,
                child: connection.profileImageUrl == null || connection.profileImageUrl!.isEmpty
                    ? Text(
                        connection.initials ?? '',
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              
              const SizedBox(width: 16.0),
              
              // Content section - narrower with proper styling
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      Text(
                        connection.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Location
                      if (displayLocation.isNotEmpty) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          displayLocation,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      // Headline/Title
                      if (headline.isNotEmpty) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          headline,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Message button
                  if (onMessage != null)
                    IconButton(
                      icon: Icon(Icons.message, color: Theme.of(context).primaryColor),
                      onPressed: onMessage,
                      tooltip: 'Message',
                    ),
                  
                  // Disconnect button
                  if (onDisconnect != null)
                    IconButton(
                      icon: const Icon(Icons.person_remove, color: Colors.red),
                      onPressed: onDisconnect,
                      tooltip: 'Disconnect',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build connection status widget based on current connection state
  Widget _buildConnectionStatusWidget(BusinessConnection connection, VoidCallback? onConnect) {
    final status = connection.status;
    print('🎯 _buildConnectionStatusWidget for ${connection.name}: status="$status"');
    
    if (status == 'pending') {
      // Show "Request Sent" for pending connections
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade300),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Request Sent',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      );
    } else if (status == 'accepted') {
      // Show "Connected" for accepted connections (shouldn't appear in discover but just in case)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade300),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Connected',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      );
    } else {
      // Show connect button for no connection or rejected connections
      return ElevatedButton.icon(
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Connect'),
        onPressed: () {
          print('Connect button tapped on profile card: ${connection.name}');
          onConnect?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    }
  }

  // Build pending connection request card with accept/reject buttons
  Widget _buildPendingRequestCard(BusinessConnection request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 25,
            backgroundImage: request.profileImageUrl != null
                ? NetworkImage(request.profileImageUrl!)
                : null,
            backgroundColor: Colors.blue.shade100,
            child: request.profileImageUrl == null
                ? Text(
                    _getInitials(request.name),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          
          // Request Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (request.title != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    request.title!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
                if (request.location != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    request.location!,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Action Buttons
          Column(
            children: [
              // Accept Button
              SizedBox(
                width: 80,
                height: 32,
                child: ElevatedButton(
                  onPressed: () => _handleAcceptRequest(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Accept'),
                ),
              ),
              const SizedBox(height: 6),
              // Reject Button
              SizedBox(
                width: 80,
                height: 32,
                child: OutlinedButton(
                  onPressed: () => _handleRejectRequest(request),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Handle accepting a connection request
  Future<void> _handleAcceptRequest(BusinessConnection request) async {
    final provider = Provider.of<BusinessConnectionProvider>(context, listen: false);
    
    final success = await provider.acceptConnectionRequest(request.id, request.userId);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Connection request from ${request.name} accepted!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to accept connection request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle rejecting a connection request
  Future<void> _handleRejectRequest(BusinessConnection request) async {
    final provider = Provider.of<BusinessConnectionProvider>(context, listen: false);
    
    final success = await provider.rejectConnectionRequest(request.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Connection request from ${request.name} rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to reject connection request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle accepting an invitation
  Future<void> _handleAcceptInvitation(BusinessConnection invitation) async {
    final provider = Provider.of<BusinessConnectionProvider>(context, listen: false);
    
    final success = await provider.acceptConnectionRequest(invitation.id, invitation.userId);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Invitation from ${invitation.name} accepted!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to accept invitation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle rejecting an invitation
  Future<void> _handleRejectInvitation(BusinessConnection invitation) async {
    final provider = Provider.of<BusinessConnectionProvider>(context, listen: false);
    
    final success = await provider.rejectConnectionRequest(invitation.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Invitation from ${invitation.name} rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to reject connection request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to get initials from name
  String _getInitials(String name) {
    List<String> names = name.split(' ');
    String initials = '';
    for (String n in names) {
      if (n.isNotEmpty) {
        initials += n[0].toUpperCase();
      }
    }
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }

  // Old _buildSDGIcon method removed - now using the reusable SDGIconWidget
}
