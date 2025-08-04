import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bsca_mobile_flutter/models/sdg_goal.dart';
import 'package:bsca_mobile_flutter/models/sdg_target.dart';
import 'package:bsca_mobile_flutter/providers/auth_provider.dart';
import 'package:bsca_mobile_flutter/providers/organization_provider.dart';
import 'package:bsca_mobile_flutter/providers/sdg_target_provider.dart';

import 'package:bsca_mobile_flutter/widgets/sdg_icon_widget.dart';

class SdgTargetsScreen extends StatefulWidget {
  final SDGGoal sdg;

  const SdgTargetsScreen({Key? key, required this.sdg}) : super(key: key);

  @override
  _SdgTargetsScreenState createState() => _SdgTargetsScreenState();
}

class _SdgTargetsScreenState extends State<SdgTargetsScreen> {
  bool _isLoading = false;
  String? _selectedOrganizationId;
  
  @override
  void initState() {
    super.initState();
    _loadTargets();
  }
  
  Future<void> _loadTargets() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final sdgTargetProvider = Provider.of<SdgTargetProvider>(context, listen: false);
      await sdgTargetProvider.loadTargetsForSDG(widget.sdg.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading targets: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SDG ${widget.sdg.id} Targets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTargets,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTargetDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Target',
      ),
    );
  }
  
  Widget _buildBody() {
    return Consumer<SdgTargetProvider>(
      builder: (context, provider, child) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final targets = provider.getTargetsForSDG(widget.sdg.id);
        
        if (targets.isEmpty) {
          return _buildEmptyState();
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: targets.length,
          itemBuilder: (context, index) {
            final target = targets[index];
            return _buildTargetCard(target);
          },
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SDGIconWidget(
            sdgNumber: widget.sdg.id,
            size: 80,
            showLabel: false,
          ),
          const SizedBox(height: 24),
          Text(
            'No targets found for SDG ${widget.sdg.id}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const Text(
            'Create targets to track your progress towards this SDG',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddTargetDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Target'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTargetCard(SdgTarget target) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Target ${target.targetNumber}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    target.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            if (target.description != null && target.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                target.description!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditTargetDialog(target),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDeleteTarget(target),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showAddTargetDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetNumberController = TextEditingController();
    
    // Get organizations for selection
    final orgProvider = Provider.of<OrganizationProvider>(context, listen: false);
    final userOrgs = orgProvider.organizations;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add Target for SDG ${widget.sdg.id}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target Number
                  TextField(
                    controller: targetNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Target Number (e.g., 1, 2, 3)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Name
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Target Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  // Organization selection (if user has organizations)
                  if (userOrgs.isNotEmpty) ...[
                    const Text(
                      'Assign to Organization (optional):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _selectedOrganizationId,
                      decoration: const InputDecoration(
                        labelText: 'Organization',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Personal (No Organization)'),
                        ),
                        ...userOrgs.map((org) => DropdownMenuItem<String?>(
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
                onPressed: () async {
                  // Validate inputs
                  if (nameController.text.isEmpty || targetNumberController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in all required fields')),
                    );
                    return;
                  }
                  
                  final targetNumber = int.tryParse(targetNumberController.text);
                  if (targetNumber == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid target number')),
                    );
                    return;
                  }
                  
                  // Get current user ID
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final userId = authProvider.user?.id;
                  
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You must be logged in to create targets')),
                    );
                    return;
                  }
                  
                  // Create the target
                  final newTarget = SdgTarget(
                    id: '', // Will be generated by Supabase
                    sdgGoalNumber: widget.sdg.id,
                    targetNumber: targetNumber.toString(),
                    name: nameController.text,
                    description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                    userId: userId,
                    organizationId: _selectedOrganizationId,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  
                  // Save the target
                  final sdgTargetProvider = Provider.of<SdgTargetProvider>(context, listen: false);
                  final result = await sdgTargetProvider.createTarget(newTarget);
                  
                  if (result != null) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Target created successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create target: ${sdgTargetProvider.error}')),
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _showEditTargetDialog(SdgTarget target) async {
    final nameController = TextEditingController(text: target.name);
    final descriptionController = TextEditingController(text: target.description ?? '');
    final targetNumberController = TextEditingController(text: target.targetNumber.toString());
    String? selectedOrgId = target.organizationId;
    
    // Get organizations for selection
    final orgProvider = Provider.of<OrganizationProvider>(context, listen: false);
    final userOrgs = orgProvider.organizations;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Target ${target.targetNumber}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target Number
                  TextField(
                    controller: targetNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Target Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Name
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Target Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  // Organization selection (if user has organizations)
                  if (userOrgs.isNotEmpty) ...[
                    const Text(
                      'Assign to Organization (optional):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: selectedOrgId,
                      decoration: const InputDecoration(
                        labelText: 'Organization',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Personal (No Organization)'),
                        ),
                        ...userOrgs.map((org) => DropdownMenuItem<String?>(
                          value: org.id,
                          child: Text(org.name),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedOrgId = value;
                        });
                      },
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
                onPressed: () async {
                  // Validate inputs
                  if (nameController.text.isEmpty || targetNumberController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in all required fields')),
                    );
                    return;
                  }
                  
                  final targetNumber = int.tryParse(targetNumberController.text);
                  if (targetNumber == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid target number')),
                    );
                    return;
                  }
                  
                  // Update the target
                  final updatedTarget = target.copyWith(
                    targetNumber: targetNumber.toString(),
                    name: nameController.text,
                    description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                    organizationId: selectedOrgId,
                    updatedAt: DateTime.now(),
                  );
                  
                  // Save the updated target
                  final sdgTargetProvider = Provider.of<SdgTargetProvider>(context, listen: false);
                  final result = await sdgTargetProvider.updateTarget(updatedTarget);
                  
                  if (result != null) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Target updated successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update target: ${sdgTargetProvider.error}')),
                    );
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _confirmDeleteTarget(SdgTarget target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Target?'),
        content: Text(
          'Are you sure you want to delete target ${target.targetNumber}: ${target.name}? '
          'This will also remove any associated data and cannot be undone.',
        ),
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
      final sdgTargetProvider = Provider.of<SdgTargetProvider>(context, listen: false);
      final success = await sdgTargetProvider.deleteTarget(target.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Target deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete target: ${sdgTargetProvider.error}')),
        );
      }
    }
  }
}
