import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bsca_mobile_flutter/models/sdg_goal.dart';
import 'package:bsca_mobile_flutter/providers/auth_provider.dart';
import 'package:bsca_mobile_flutter/utils/sdg_icons.dart';
import 'package:bsca_mobile_flutter/widgets/sdg_icon_widget.dart';
import 'package:bsca_mobile_flutter/services/sdg_icon_service.dart';

class ActionsScreen extends StatefulWidget {
  const ActionsScreen({super.key});

  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen> {
  bool _isLoading = true;
  List<int> _userSDGs = [];
  int? _selectedSDG;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserSDGs();
  }

  Future<void> _loadUserSDGs() async {
    print('Loading user SDGs...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // For development purposes, use mock data if Supabase is not properly set up
      // Remove this in production and use the actual Supabase query
      setState(() {
        // Mock data for testing - using SDGs 13, 17, and 12 as examples
        _userSDGs = [13, 17, 12];
        _isLoading = false;
      });
      print('Loaded mock SDGs: $_userSDGs');
      
      /* Uncomment this for actual Supabase integration
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Fetch user's selected SDGs from Supabase
      final response = await Supabase.instance.client
          .from('user_sdgs')
          .select('sdg_id')
          .eq('user_id', userId);

      if (response is List) {
        final sdgIds = response.map((item) => item['sdg_id'] as int).toList();
        setState(() {
          _userSDGs = sdgIds;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load SDGs';
          _isLoading = false;
        });
      }
      */
    } catch (e) {
      print('Error loading SDGs: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building ActionsScreen, isLoading: $_isLoading, error: $_error, selectedSDG: $_selectedSDG');
    
    // Simple UI for debugging
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('Refreshing data...');
              _loadUserSDGs();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }
  
  Widget _buildBody() {
    try {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      } else if (_error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserSDGs,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      } else if (_selectedSDG != null) {
        return _buildSDGDetailView();
      } else {
        // Fallback simple UI if the complex one fails
        try {
          return _buildSDGListView();
        } catch (e) {
          print('Error in _buildSDGListView: $e');
          return _buildSimpleSDGList();
        }
      }
    } catch (e) {
      print('Error in build method: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Something went wrong',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = false;
                  _error = null;
                  _selectedSDG = null;
                });
              },
              child: const Text('Reset View'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildUserSDGsGrid() {
    print('Building user SDGs grid with ${_userSDGs.length} SDGs');
    try {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.75,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _userSDGs.length,
        itemBuilder: (context, index) {
          try {
            final sdgId = _userSDGs[index];
            print('Building grid item for SDG $sdgId');
            final sdg = SDGGoal.getById(sdgId);
            
            return GestureDetector(
              onTap: () {
                print('User tapped on SDG ${sdg.id}');
                setState(() {
                  _selectedSDG = sdgId;
                });
              },
              child: Center(
                child: SDGIconWidget(
                  sdgNumber: sdg.id,
                  size: 60.0,
                  showLabel: false,
                ),
              ),
            );
          } catch (e) {
            print('Error building SDG grid item: $e');
            return const SizedBox.shrink();
          }
        },
      );
    } catch (e) {
      print('Error building user SDGs grid: $e');
      return const Center(
        child: Text('Error loading SDGs'),
      );
    }
  }

  Widget _buildSDGListView() {
    print('Building SDG list view with ${_userSDGs.length} user SDGs');
    try {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Your Selected SDGs Section
              Card(
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
                        'Your Selected SDGs',
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        'Track your progress and impact on the UN Sustainable Development Goals you\'ve selected.',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      if (_userSDGs.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Text(
                              'You haven\'t selected any SDGs yet. Visit your profile to select SDGs that matter to you.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        _buildUserSDGsGrid(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24.0),
              
              // All SDGs Section
              Card(
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
                        'Sustainable Development Goals',
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        'Select a Sustainable Development Goal to track your progress and impact.',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      _buildAllSDGsList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error in _buildSDGListView: $e');
      return const Center(child: Text('Error loading SDG view'));
    }
  }

  Widget _buildAllSDGsList() {
    print('Building all SDGs list');
    try {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: SDGGoal.allGoals.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          try {
            final sdg = SDGGoal.allGoals[index];
            final bool isSelected = _userSDGs.contains(sdg.id);
            
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              leading: SDGIconWidget(
                sdgNumber: sdg.id,
                size: 50.0,
                showLabel: false,
              ),
              title: Text(
                'SDG ${sdg.id}: ${sdg.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                _getSDGDescription(sdg.id),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: SizedBox(
                width: 80, // Fixed width to prevent layout issues
                child: ElevatedButton(
                  onPressed: () {
                    print('View button pressed for SDG ${sdg.id}');
                    setState(() {
                      _selectedSDG = sdg.id;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('View'),
                ),
              ),
              onTap: () {
                print('List tile tapped for SDG ${sdg.id}');
                setState(() {
                  _selectedSDG = sdg.id;
                });
              },
            );
          } catch (e) {
            print('Error building SDG list item at index $index: $e');
            return const ListTile(
              title: Text('Error loading SDG'),
            );
          }
        },
      );
    } catch (e) {
      print('Error building all SDGs list: $e');
      return const Center(
        child: Text('Error loading SDGs list'),
      );
    }
  }

  // Simple fallback UI for when the complex UI fails
  Widget _buildSimpleSDGList() {
    print('Building simple SDG list fallback');
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // User's selected SDGs section
        const Text(
          'Your Selected SDGs',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_userSDGs.isEmpty)
          const Text('You haven\'t selected any SDGs yet.')
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _userSDGs.map((sdgId) {
              final sdg = SDGGoal.getById(sdgId);
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSDG = sdgId;
                  });
                },
                child: Chip(
                  avatar: SizedBox(
                    width: 24,
                    height: 24,
                    child: SDGIconWidget(
                      sdgNumber: sdgId,
                      size: 24,
                      showLabel: false,
                      isCircular: true,
                    ),
                  ),
                  label: Text(sdg.name),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: SDGIcons.getSDGColor(sdgId)),
                ),
              );
            }).toList(),
          ),
          
        const SizedBox(height: 24),
        
        // All SDGs section
        const Text(
          'All Sustainable Development Goals',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...SDGGoal.allGoals.map((sdg) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: ListTile(
              leading: SDGIconWidget(
                sdgNumber: sdg.id,
                size: 40,
                showLabel: false,
                isCircular: true,
              ),
              title: Text('SDG ${sdg.id}: ${sdg.name}'),
              subtitle: Text(
                _getSDGDescription(sdg.id),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                setState(() {
                  _selectedSDG = sdg.id;
                });
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSDGIcon(int sdgId, double size) {
    try {
      return SDGIconWidget(
        sdgNumber: sdgId,
        size: size,
        showLabel: false,
      );
    } catch (e) {
      print('Error building SDG icon: $e');
      // Fallback to a simple container with a question mark
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(size * 0.1),
          border: Border.all(color: Colors.grey, width: size * 0.04),
        ),
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.36,
            ),
          ),
        ),
      );
    }
  }

  String _getSDGDescription(int sdgId) {
    // Brief descriptions for each SDG
    final descriptions = {
      1: 'End poverty in all its forms everywhere',
      2: 'End hunger, achieve food security and improved nutrition',
      3: 'Ensure healthy lives and promote well-being for all',
      4: 'Ensure inclusive and equitable quality education',
      5: 'Achieve gender equality and empower all women and girls',
      6: 'Ensure availability and sustainable management of water',
      7: 'Ensure access to affordable, reliable, sustainable energy',
      8: 'Promote sustained, inclusive economic growth',
      9: 'Build resilient infrastructure and foster innovation',
      10: 'Reduce inequality within and among countries',
      11: 'Make cities and human settlements inclusive and sustainable',
      12: 'Ensure sustainable consumption and production patterns',
      13: 'Take urgent action to combat climate change and its impacts',
      14: 'Conserve and sustainably use oceans and marine resources',
      15: 'Protect and restore terrestrial ecosystems and forests',
      16: 'Promote peaceful and inclusive societies for sustainable development',
      17: 'Strengthen the means of implementation for sustainable development',
    };
    
    return descriptions[sdgId] ?? '';
  }



  Widget _buildSDGDetailView() {
    print('Building SDG detail view for SDG: $_selectedSDG');
    // Safety check - if _selectedSDG is null, return to list view
    if (_selectedSDG == null) {
      print('Selected SDG is null, returning to list view');
      // Use a microtask to avoid build errors during rendering
      Future.microtask(() {
        setState(() {
          _selectedSDG = null;
        });
      });
      return const Center(child: CircularProgressIndicator());
    }
    
    final sdg = SDGGoal.getById(_selectedSDG!);
    print('Found SDG: ${sdg.name}');
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to All SDGs'),
                  onPressed: () {
                    print('Back button pressed');
                    setState(() {
                      _selectedSDG = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Card(
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: BorderSide(color: sdg.color, width: 2.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildSDGIcon(sdg.id, 80.0),
                    const SizedBox(height: 16.0),
                    Text(
                      'SDG ${sdg.id}: ${sdg.name}',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: sdg.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24.0),
                    _buildProgressIndicator(0.65, sdg.color),
                    const SizedBox(height: 8.0),
                    Text(
                      '65% Progress',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: sdg.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            _buildActionsList(sdg),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(double value, Color color) {
    return Container(
      height: 12.0,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsList(SDGGoal sdg) {
    // This would ideally be fetched from the database
    final actions = [
      {
        'title': 'Reduce Carbon Footprint',
        'description': 'Track and reduce your carbon emissions from travel and daily activities.',
        'progress': 0.8,
        'isCompleted': false,
      },
      {
        'title': 'Sustainable Consumption',
        'description': 'Choose products with minimal environmental impact and reduce waste.',
        'progress': 0.5,
        'isCompleted': false,
      },
      {
        'title': 'Community Engagement',
        'description': 'Participate in local sustainability initiatives and community projects.',
        'progress': 0.3,
        'isCompleted': false,
      },
      {
        'title': 'Educational Workshop',
        'description': 'Complete the online workshop on sustainable development principles.',
        'progress': 1.0,
        'isCompleted': true,
      },
    ];

    return Card(
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
              'Actions',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            ...actions.map((action) => _buildActionItem(action, sdg.color)).toList(),
            const SizedBox(height: 16.0),
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add New Action'),
                onPressed: () {
                  // This would open a dialog or navigate to a screen to add a new action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Add new action feature coming soon!'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: sdg.color,
                  side: BorderSide(color: sdg.color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(Map<String, dynamic> action, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(
                action['isCompleted'] ? Icons.check_circle : Icons.circle_outlined,
                color: action['isCompleted'] ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  action['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: action['isCompleted'] ? TextDecoration.lineThrough : null,
                    color: action['isCompleted'] ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action['description'],
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  if (!action['isCompleted']) ...[
                    _buildProgressIndicator(action['progress'], color),
                    const SizedBox(height: 8.0),
                    Text(
                      '${(action['progress'] * 100).toInt()}% Complete',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            // This would update the action progress
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Update progress feature coming soon!'),
                              ),
                            );
                          },
                          child: const Text('Update Progress'),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.emoji_events, color: Colors.amber),
                          label: const Text('Completed!'),
                          onPressed: null,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
