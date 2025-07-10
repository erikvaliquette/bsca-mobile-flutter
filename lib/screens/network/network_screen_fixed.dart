import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business_connection_model.dart';
import '../../providers/business_connection_provider.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _selectedSDGFilter = -1; // -1 means no filter selected

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Fetch connections when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BusinessConnectionProvider>(context, listen: false);
      provider.fetchConnections();
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
            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'My Connections'),
                Tab(text: 'Discover'),
              ],
            ),
            
            // Search Filter
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by Name',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                        ),
                        onChanged: (value) {
                          final provider = Provider.of<BusinessConnectionProvider>(context, listen: false);
                          provider.setSearchQuery(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // SDG Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by SDG Goals',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSDGIcon(1, Colors.red, 'assets/icons/sdg1.png'),
                            _buildSDGIcon(2, Colors.amber, 'assets/icons/sdg2.png'),
                            _buildSDGIcon(3, Colors.green, 'assets/icons/sdg3.png'),
                            _buildSDGIcon(4, Colors.red.shade800, 'assets/icons/sdg4.png'),
                            _buildSDGIcon(5, Colors.orange, 'assets/icons/sdg5.png'),
                            _buildSDGIcon(6, Colors.blue.shade300, 'assets/icons/sdg6.png'),
                            _buildSDGIcon(7, Colors.amber.shade300, 'assets/icons/sdg7.png'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Connections Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Consumer<BusinessConnectionProvider>(
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
                        return _buildBusinessConnectionCard(connections[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSDGIcon(int number, Color color, String iconPath) {
    bool isSelected = _selectedSDGFilter == number;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSDGFilter = isSelected ? -1 : number;
        });
        final provider = Provider.of<BusinessConnectionProvider>(context, listen: false);
        provider.setSDGFilter(isSelected ? null : number);
      },
      child: Container(
        width: 40.0,
        height: 40.0,
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4.0),
          border: isSelected ? Border.all(color: Colors.black, width: 2.0) : null,
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessConnectionCard(BusinessConnection connection) {
    // Determine avatar color based on connection id to ensure consistency
    final int colorValue = connection.id.hashCode % 2;
    final Color avatarColor = colorValue == 0 ? Colors.blue : Colors.blue.shade200;
    
    // Get display location (use location, title, or organization in that order)
    final String displayLocation = connection.location ?? 
                                  connection.title ?? 
                                  connection.organization ?? 
                                  '';
    
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: avatarColor,
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
                    connection.initials,
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
        ],
      ),
    );
  }
}

// Helper class for sample connections (can be removed once Supabase integration is complete)
class Connection {
  final String name;
  final String location;
  final String avatarText;
  final Color avatarColor;

  Connection({
    required this.name,
    required this.location,
    required this.avatarText,
    required this.avatarColor,
  });
}
