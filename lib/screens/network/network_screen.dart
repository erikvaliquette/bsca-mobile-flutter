import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business_connection_model.dart';
import '../../providers/business_connection_provider.dart';
import '../../services/notifications/notification_provider.dart';
import '../../services/supabase/supabase_client.dart';
import '../../utils/sdg_icons.dart';
import '../../widgets/sdg_icon_widget.dart';
import 'user_profile_screen.dart';

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
    _tabController = TabController(length: 2, vsync: this);
    
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
          provider.fetchConnections();
        } else if (_tabController.index == 1) {
          provider.fetchDiscoverProfiles();
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
      appBar: AppBar(
        title: const Text('Network'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'My Connections'),
            Tab(text: 'Discover'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
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
                              size: 30.0,
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
                      
                      if (connections.isEmpty) {
                        return const Center(
                          child: Text('No connections found'),
                        );
                      }
                      
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: connections.length,
                        itemBuilder: (context, index) {
                          return _buildBusinessConnectionCard(
                            connections[index],
                            showActions: true,
                            onDisconnect: () => _handleDisconnect(connections[index]),
                            onMessage: () => _handleMessage(connections[index]),
                          );
                        },
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
                          childAspectRatio: 0.85,
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
                ],
              ),
            ),
          ),
        ],
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
  void _handleMessage(BusinessConnection connection) {
    // Navigate to message screen with the connection
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Message ${connection.name}')),
          body: Center(child: Text('Message functionality coming soon')),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending connection request: $e')),
      );
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
          alignment: Alignment.center,
          children: [
          // Avatar (either image or text)
          Positioned(
            top: 20,
            child: connection.profileImageUrl != null && connection.profileImageUrl!.isNotEmpty
                ? CircleAvatar(
                    radius: 36.0,
                    backgroundImage: NetworkImage(connection.profileImageUrl!),
                  )
                : Text(
                    connection.initials ?? '',
                    style: const TextStyle(
                      fontSize: 72.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          
          // Name and Location
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    connection.name,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (displayLocation.isNotEmpty)
                    Text(
                      displayLocation,
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          
          // Action buttons
          if (showActions)
            Positioned(
              top: 5,
              right: 5,
              child: Row(
                children: [
                  if (onMessage != null)
                    IconButton(
                      icon: const Icon(Icons.message, color: Colors.white),
                      onPressed: onMessage,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Message',
                    ),
                  if (onDisconnect != null)
                    IconButton(
                      icon: const Icon(Icons.person_remove, color: Colors.white),
                      onPressed: onDisconnect,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Disconnect',
                    ),
                ],
              ),
            ),
          
          // Connection status button for discover profiles (positioned in top-right)
          if (isDiscover)
            Positioned(
              top: 8,
              right: 8,
              child: _buildConnectionStatusWidget(connection, onConnect),
            ),
          ],
        ),
      ),
    );
  }

  // Build connection status widget based on current connection state
  Widget _buildConnectionStatusWidget(BusinessConnection connection, VoidCallback? onConnect) {
    final status = connection.status;
    
    if (status == 'pending') {
      // Show "Request Sent" for pending connections
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: const Text(
          'Request Sent',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      );
    } else if (status == 'accepted') {
      // Show "Connected" for accepted connections (shouldn't appear in discover but just in case)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: const Text(
          'Connected',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      );
    } else {
      // Show + button for no connection or rejected connections
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.blue),
          onPressed: () {
            print('+ button tapped on profile card: ${connection.name}');
            onConnect?.call();
          },
          iconSize: 20,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          tooltip: 'Send Connection Request',
        ),
      );
    }
  }

  // Old _buildSDGIcon method removed - now using the reusable SDGIconWidget
}
