import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:bsca_mobile_flutter/models/sdg_goal.dart';
import 'package:bsca_mobile_flutter/models/action_item.dart';
import 'package:bsca_mobile_flutter/models/sdg_target.dart';
import 'package:bsca_mobile_flutter/providers/auth_provider.dart';
import 'package:bsca_mobile_flutter/providers/action_provider.dart';
import 'package:bsca_mobile_flutter/providers/subscription_provider.dart';
import 'package:bsca_mobile_flutter/providers/organization_provider.dart';
import 'package:bsca_mobile_flutter/providers/sdg_target_provider.dart';
import 'package:bsca_mobile_flutter/utils/sdg_icons.dart';
import 'package:bsca_mobile_flutter/widgets/sdg_icon_widget.dart';
import 'package:bsca_mobile_flutter/widgets/add_action_dialog.dart';
import 'package:bsca_mobile_flutter/widgets/simple_add_action_dialog.dart';
import 'package:bsca_mobile_flutter/widgets/functional_add_action_dialog.dart';
import 'package:bsca_mobile_flutter/widgets/basic_add_action_dialog.dart';
import 'package:bsca_mobile_flutter/services/sdg_icon_service.dart';
import 'package:bsca_mobile_flutter/screens/actions/add_action_screen.dart';
import 'package:bsca_mobile_flutter/screens/sdg/sdg_targets_screen.dart';
import 'package:bsca_mobile_flutter/screens/action_detail_screen.dart';

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
    _loadUserActions();
  }

  Future<void> _loadUserActions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final actionProvider = Provider.of<ActionProvider>(context, listen: false);
    
    final userId = authProvider.user?.id;
    if (userId != null) {
      await actionProvider.loadUserActions(userId);
    }
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
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error in _buildSDGListView: $e');
      return const Center(child: Text('Error loading SDG view'));
    }
  }

  // _buildAllSDGsList method removed as it's no longer needed

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
                  // Navigate to SDG Targets screen instead of just setting state
                  final sdg = SDGGoal.getById(sdgId);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SdgTargetsScreen(sdg: sdg),
                    ),
                  );
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

  // Helper methods for action management
  String _formatCategoryName(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool _isDueSoon(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    return difference <= 3 && difference >= 0;
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    
    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference <= 7) {
      return 'Due in $difference days';
    } else {
      return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    }
  }

  String _formatCompletedDate(DateTime completedDate) {
    final now = DateTime.now();
    final difference = now.difference(completedDate).inDays;
    
    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'yesterday';
    } else if (difference <= 7) {
      return '$difference days ago';
    } else {
      return 'on ${completedDate.day}/${completedDate.month}/${completedDate.year}';
    }
  }

  // Action management methods
  Future<void> _showAddActionDialog(int sdgId) async {
    try {
      // Using a dialog approach instead of full screen to avoid rendering issues
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => SimpleAddActionDialog(sdgId: sdgId),
      );
      
      if (result == true) {
        // Refresh the actions list
        await _loadUserActions();
      }
    } catch (e) {
      debugPrint('Error showing add action screen: $e');
      // Show a simple fallback dialog for now
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Action'),
          content: Text('Error loading dialog: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showEditActionDialog(ActionItem action) async {
    final titleController = TextEditingController(text: action.title);
    final descriptionController = TextEditingController(text: action.description);
    String category = action.category;
    String priority = action.priority;
    DateTime? dueDate = action.dueDate;
    SdgTarget? selectedTarget = action.sdgTarget;
    
    // Get the list of SDG targets for selection using SdgTargetProvider
    final sdgTargetProvider = Provider.of<SdgTargetProvider>(context, listen: false);
    List<SdgTarget> availableTargets = [];
    
    try {
      // If we know the SDG ID, fetch targets for that specific SDG
      if (action.sdgId != null) {
        availableTargets = await sdgTargetProvider.loadTargetsForSDG(action.sdgId!);
      } 
      // If there's an organization ID, fetch organization targets
      else if (action.organizationId != null) {
        availableTargets = await sdgTargetProvider.loadTargetsForOrganization(action.organizationId!);
      } 
      // Otherwise fetch user targets
      else {
        availableTargets = await sdgTargetProvider.loadTargetsForUser(action.userId);
      }
    } catch (e) {
      debugPrint('Error fetching SDG targets: $e');
    }
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Action'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  // Category
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'personal',
                      'energy',
                      'water',
                      'waste',
                      'transportation',
                      'food',
                      'biodiversity',
                      'community',
                      'other',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(_formatCategoryName(value)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        category = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Priority
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'low',
                      'medium',
                      'high',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        priority = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Due Date
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Due Date: ${dueDate != null ? DateFormat('MMM d, yyyy').format(dueDate!) : 'None'}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          
                          if (pickedDate != null) {
                            setState(() {
                              dueDate = pickedDate;
                            });
                          }
                        },
                        child: const Text('Select Date'),
                      ),
                      if (dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              dueDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // SDG Target Selection
                  const Text(
                    'SDG Target:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  if (availableTargets.isEmpty) ...[  
                    const Text(
                      'No SDG targets available. Create targets in the SDG section.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ] else ...[  
                    DropdownButtonFormField<SdgTarget>(
                      value: selectedTarget,
                      decoration: const InputDecoration(
                        labelText: 'Select SDG Target',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        // Add a 'None' option
                        const DropdownMenuItem<SdgTarget>(
                          value: null,
                          child: Text('None'),
                        ),
                        // Add all available targets
                        ...availableTargets.map((target) {
                          return DropdownMenuItem<SdgTarget>(
                            value: target,
                            child: Text(
                              target.description,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (newValue) {
                        setState(() {
                          selectedTarget = newValue;
                        });
                      },
                      isExpanded: true,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop({
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'category': category,
                    'priority': priority,
                    'dueDate': dueDate,
                    'sdgTarget': selectedTarget,
                  });
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    
    if (result != null) {
      final actionProvider = Provider.of<ActionProvider>(context, listen: false);
      
      // Create updated action with the new values
      final updatedAction = action.copyWith(
        title: result['title'],
        description: result['description'],
        category: result['category'],
        priority: result['priority'],
        dueDate: result['dueDate'],
        sdgTarget: result['sdgTarget'],
        sdgTargetId: result['sdgTarget']?.id,
        updatedAt: DateTime.now(),
      );
      
      final success = await actionProvider.updateAction(updatedAction);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update action: ${actionProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showProgressUpdateDialog(ActionItem action) async {
    double? newProgress = await showDialog<double>(
      context: context,
      builder: (context) => _ProgressUpdateDialog(currentProgress: action.progress),
    );
    
    if (newProgress != null && newProgress != action.progress) {
      final actionProvider = Provider.of<ActionProvider>(context, listen: false);
      final success = await actionProvider.updateActionProgress(action.id, newProgress);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update progress: ${actionProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeAction(ActionItem action) async {
    final actionProvider = Provider.of<ActionProvider>(context, listen: false);
    final success = await actionProvider.completeAction(action.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action completed! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete action: ${actionProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAction(ActionItem action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Action'),
        content: Text('Are you sure you want to delete "${action.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final actionProvider = Provider.of<ActionProvider>(context, listen: false);
      final success = await actionProvider.deleteAction(action.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete action: ${actionProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToActionDetail(ActionItem action) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActionDetailScreen(actionId: action.id),
      ),
    );
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
    return Consumer<ActionProvider>(
      builder: (context, actionProvider, child) {
        final actions = actionProvider.getActionsBySDG(sdg.id);
        
        if (actionProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (actionProvider.error != null) {
          return Card(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading actions: ${actionProvider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUserActions,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

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
                Row(
                  children: [
                    const Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (actions.isNotEmpty)
                      Text(
                        '${actions.where((a) => a.isCompleted).length}/${actions.length} completed',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: sdg.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16.0),
                if (actions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No actions yet for this SDG',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first action to start making an impact!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...actions.map((action) => _buildActionItem(action, sdg.color)).toList(),
                const SizedBox(height: 16.0),
                Center(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Action'),
                    onPressed: () => _showAddActionDialog(sdg.id),
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
      },
    );
  }

  Widget _buildActionItem(ActionItem action, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        leading: Checkbox(
          value: action.isCompleted,
          onChanged: (value) {
            if (value == true) {
              _completeAction(action);
            }
          },
        ),
        title: Text(
          action.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: action.isCompleted ? TextDecoration.lineThrough : null,
            color: action.isCompleted ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row with category
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.category, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatCategoryName(action.category),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            // Second row with priority and tracking
            const SizedBox(height: 4),
            Wrap(
              spacing: 8, // horizontal space between items
              runSpacing: 4, // vertical space between lines
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Priority indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(action.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getPriorityColor(action.priority),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    action.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(action.priority),
                    ),
                  ),
                ),
                
                // Tracking indicator
                if (action.baselineValue != null || action.targetValue != null || 
                    (action.measurements != null && action.measurements!.isNotEmpty)) 
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.analytics, size: 14, color: Colors.purple[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Tracking',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'Edit Action',
              onPressed: () => _showEditActionDialog(action),
            ),
            
            // Tracking button
            IconButton(
              icon: Icon(
                action.baselineValue != null || action.targetValue != null || 
                (action.measurements != null && action.measurements!.isNotEmpty) 
                    ? Icons.analytics 
                    : Icons.analytics_outlined,
                size: 20,
                color: Colors.blue,
              ),
              tooltip: 'Sustainability Tracking',
              onPressed: () => _navigateToActionDetail(action),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (action.description != null && action.description!.isNotEmpty) ...[  
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(action.description ?? ''),
                  const SizedBox(height: 16),
                ],
                
                // Due date
                if (action.dueDate != null) ...[  
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: _isDueSoon(action.dueDate!) ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Due: ${_formatDueDate(action.dueDate!)}',
                        style: TextStyle(
                          color: _isDueSoon(action.dueDate!) ? Colors.red : Colors.grey[600],
                          fontWeight: _isDueSoon(action.dueDate!) ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Organization
                if (action.organizationId != null) ...[  
                  Row(
                    children: [
                      Icon(Icons.business, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Organization Action',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // SDG Target
                if (action.sdgTarget != null) ...[  
                  Row(
                    children: [
                      Icon(Icons.eco, size: 16, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'SDG Target: ${action.sdgTarget!.description}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Tracking data section
                if (action.baselineValue != null || action.targetValue != null || 
                    (action.measurements != null && action.measurements!.isNotEmpty)) ...[  
                  const Text(
                    'Tracking Data:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  // Baseline
                  if (action.baselineValue != null) ...[  
                    Row(
                      children: [
                        const Text('Baseline: '),
                        Text(
                          '${action.baselineValue}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (action.baselineUnit != null) ...[  
                          const SizedBox(width: 4),
                          Text(action.baselineUnit!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Target
                  if (action.targetValue != null) ...[  
                    Row(
                      children: [
                        const Text('Target: '),
                        Text(
                          '${action.targetValue}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (action.baselineUnit != null) ...[  
                          const SizedBox(width: 4),
                          Text(action.baselineUnit!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Measurements count
                  if (action.measurements != null && action.measurements!.isNotEmpty) ...[  
                    const SizedBox(height: 4),
                    Text(
                      '${action.measurements!.length} measurement(s) recorded',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Detailed Tracking'),
                    onPressed: () => _navigateToActionDetail(action),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                
                // Progress indicator
                if (!action.isCompleted) ...[  
                  const SizedBox(height: 16),
                  _buildProgressIndicator(action.progress, color),
                  const SizedBox(height: 8),
                  Text(
                    '${(action.progress * 100).toInt()}% Complete',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                
                // Action buttons
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (!action.isCompleted)
                          TextButton.icon(
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: const Text('Complete'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                            onPressed: () => _completeAction(action),
                          ),
                        TextButton.icon(
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => _deleteAction(action),
                        ),
                      ],
                    ),
                  ],
                ),
                    _buildProgressIndicator(action.progress, color),
                    const SizedBox(height: 8.0),
                    Text(
                      '${(action.progress * 100).toInt()}% Complete',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    if (!action.isCompleted) ... [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                              onPressed: () => _showEditActionDialog(action),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () => _deleteAction(action),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.analytics, size: 16),
                              label: const Text('Tracking'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                              ),
                              onPressed: () => _navigateToActionDetail(action),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => _showProgressUpdateDialog(action),
                              child: const Text('Update Progress'),
                            ),
                            if (action.progress < 1.0)
                              ElevatedButton(
                                onPressed: () => _completeAction(action),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Complete'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                              onPressed: () => _showEditActionDialog(action),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () => _deleteAction(action),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.emoji_events, color: Colors.amber),
                              label: Text('Completed ${_formatCompletedDate(action.completedAt!)}'),
                              onPressed: null,
                            ),
                            if (action.baselineValue != null || action.targetValue != null || (action.measurements != null && action.measurements!.isNotEmpty))
                              TextButton.icon(
                                icon: const Icon(Icons.analytics, size: 16),
                                label: const Text('View Data'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                ),
                                onPressed: () => _navigateToActionDetail(action),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }
}
class _ProgressUpdateDialog extends StatefulWidget {
  final double currentProgress;

  const _ProgressUpdateDialog({
    required this.currentProgress,
  });

  @override
  State<_ProgressUpdateDialog> createState() => _ProgressUpdateDialogState();
}

class _ProgressUpdateDialogState extends State<_ProgressUpdateDialog> {
  late double _progress;

  @override
  void initState() {
    super.initState();
    _progress = widget.currentProgress;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Progress'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(_progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _progress,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(_progress * 100).toInt()}%',
            onChanged: (value) {
              setState(() {
                _progress = value;
              });
            },
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _progress >= 1.0 ? Colors.green : Colors.blue,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_progress),
          child: const Text('Update'),
        ),
      ],
    );
  }
}
