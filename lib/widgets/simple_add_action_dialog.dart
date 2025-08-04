import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bsca_mobile_flutter/providers/action_provider.dart';
import 'package:bsca_mobile_flutter/providers/auth_provider.dart';
import 'package:bsca_mobile_flutter/models/sdg_target.dart';
import 'package:bsca_mobile_flutter/providers/organization_provider.dart';
import 'package:bsca_mobile_flutter/providers/sdg_target_provider.dart';

class SimpleAddActionDialog extends StatefulWidget {
  final int sdgId;

  const SimpleAddActionDialog({
    Key? key,
    required this.sdgId,
  }) : super(key: key);

  @override
  _SimpleAddActionDialogState createState() => _SimpleAddActionDialogState();
}

class _SimpleAddActionDialogState extends State<SimpleAddActionDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'personal';
  String _selectedPriority = 'medium';
  String? _selectedOrganizationId;
  String? _selectedSdgTargetId;
  List<SdgTarget> _availableSdgTargets = [];
  bool _isLoading = false;
  bool _isLoadingTargets = true;

  @override
  void initState() {
    super.initState();
    _loadSdgTargets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSdgTargets() async {
    setState(() {
      _isLoadingTargets = true;
    });
    
    try {
      // Get the current user ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get the user's organizations
      final orgProvider = Provider.of<OrganizationProvider>(context, listen: false);
      final userOrgs = orgProvider.organizations;
      
      // Use SdgTargetProvider to fetch targets for this SDG ID
      final sdgTargetProvider = Provider.of<SdgTargetProvider>(context, listen: false);
      final targets = await sdgTargetProvider.loadTargetsForSDG(widget.sdgId);
      
      if (mounted) {
        setState(() {
          _availableSdgTargets = targets;
          _isLoadingTargets = false;
          
          // If the user has only one organization, select it by default
          if (userOrgs.length == 1) {
            _selectedOrganizationId = userOrgs.first.id;
          }
        });
      }
    } catch (e) {
      print('Error loading SDG targets: $e');
      if (mounted) {
        setState(() {
          _isLoadingTargets = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the organization provider for organization selection
    final orgProvider = Provider.of<OrganizationProvider>(context);
    final userOrgs = orgProvider.organizations;
    
    return AlertDialog(
      title: Text('Add Action for SDG ${widget.sdgId}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Action Title',
                hintText: 'Enter a clear, actionable title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what you want to accomplish',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'personal', child: Text('Personal')),
                DropdownMenuItem(value: 'community', child: Text('Community')),
                DropdownMenuItem(value: 'workplace', child: Text('Workplace')),
                DropdownMenuItem(value: 'education', child: Text('Education')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            // Organization selection dropdown (only if user has organizations)
            if (userOrgs.isNotEmpty) ...[  
              DropdownButtonFormField<String>(
                value: _selectedOrganizationId,
                decoration: const InputDecoration(
                  labelText: 'Organization (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Select an organization',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Personal (No Organization)'),
                  ),
                  ...userOrgs.map((org) => DropdownMenuItem<String>(
                    value: org.id,
                    child: Text(org.name),
                  )).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedOrganizationId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            // SDG Target selection dropdown
            _isLoadingTargets
                ? const Center(child: CircularProgressIndicator())
                : _availableSdgTargets.isEmpty
                    ? const Text('No SDG targets available for this SDG')
                    : DropdownButtonFormField<String>(
                        value: _selectedSdgTargetId,
                        decoration: const InputDecoration(
                          labelText: 'SDG Target (Optional)',
                          border: OutlineInputBorder(),
                          hintText: 'Select a specific target',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('General (No specific target)'),
                          ),
                          ..._availableSdgTargets.map((target) => DropdownMenuItem<String>(
                            value: target.id,
                            child: Text('${target.targetNumber}: ${target.description}'),
                          )).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSdgTargetId = value;
                          });
                        },
                      ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createAction,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createAction() async {
    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final userId = authProvider.user?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('Creating action for user: $userId, SDG: ${widget.sdgId}');
      
      // Create a complete action data with all required fields
      final now = DateTime.now().toIso8601String();
      final actionData = {
        'user_id': userId,
        'sdg_id': widget.sdgId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? 
                      'No description provided' : _descriptionController.text.trim(),
        'category': _selectedCategory,
        'progress': 0.0,
        'is_completed': false,
        'created_at': now,
        'updated_at': now,
        'priority': _selectedPriority,
        'organization_id': _selectedOrganizationId,
        'sdg_target_id': _selectedSdgTargetId,
      };
      
      // Remove null values to avoid database errors
      actionData.removeWhere((key, value) => value == null);
      
      print('Inserting action data: $actionData');
      
      // Direct Supabase approach with error handling
      try {
        // First try: Direct insert with complete data
        final response = await Supabase.instance.client
            .from('user_actions')
            .insert(actionData)
            .select()
            .maybeSingle(); // Use maybeSingle() instead of single() to avoid errors if no rows returned
        
        if (response == null) {
          throw Exception('No response returned from insert operation');
        }
        
        print('Success! Supabase response: $response');
        
        // Refresh actions list
        if (mounted) {
          final actionProvider = Provider.of<ActionProvider>(context, listen: false);
          await actionProvider.loadUserActions(userId);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Action created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
        return;
      } catch (directInsertError) {
        print('Direct insert failed: $directInsertError');
      }
      
      // Second try: Use RPC function if available
      try {
        final rpcResponse = await Supabase.instance.client
            .rpc('create_user_action', params: actionData)
            .catchError((error) {
              print('RPC error caught: $error');
              throw Exception('RPC call failed: $error');
            });
        
        if (rpcResponse == null) {
          throw Exception('No response from RPC function');
        }
        
        print('RPC response: $rpcResponse');
        
        if (mounted) {
          final actionProvider = Provider.of<ActionProvider>(context, listen: false);
          await actionProvider.loadUserActions(userId);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Action created via RPC'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
        return;
      } catch (rpcError) {
        print('RPC approach failed: $rpcError');
      }
      
      // Third try: Use ActionProvider as fallback
      final actionProvider = Provider.of<ActionProvider>(context, listen: false);
      final action = await actionProvider.createAction(
        userId: userId,
        sdgId: widget.sdgId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        organizationId: _selectedOrganizationId,
        sdgTargetId: _selectedSdgTargetId,
      );
      
      if (action != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action created via provider'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        throw Exception('All creation methods failed');
      }
    } catch (e) {
      print('Error creating action: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
