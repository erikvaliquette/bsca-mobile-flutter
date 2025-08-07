import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bsca_mobile_flutter/models/sdg_goal.dart';
import 'package:bsca_mobile_flutter/models/sdg_target.dart';
import 'package:bsca_mobile_flutter/models/action_item.dart';
import 'package:bsca_mobile_flutter/models/action_activity.dart';
// Organization model import removed - using direct name lookup instead
import 'package:bsca_mobile_flutter/providers/auth_provider.dart';
import 'package:bsca_mobile_flutter/providers/organization_provider.dart';
import 'package:bsca_mobile_flutter/providers/sdg_target_provider.dart';
import 'package:bsca_mobile_flutter/providers/action_provider.dart';
import 'package:bsca_mobile_flutter/services/action_activity_service.dart';

import 'package:bsca_mobile_flutter/widgets/sdg_icon_widget.dart';
import 'package:bsca_mobile_flutter/widgets/add_activity_dialog.dart';
import 'package:bsca_mobile_flutter/screens/actions/add_action_screen.dart';
import 'package:bsca_mobile_flutter/screens/action_detail_screen.dart';

class SdgTargetsScreen extends StatefulWidget {
  final SDGGoal sdg;
  final String? organizationId; // Optional organization ID for organization SDG targets

  const SdgTargetsScreen({
    Key? key, 
    required this.sdg, 
    this.organizationId,
  }) : super(key: key);

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
      final actionProvider = Provider.of<ActionProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final userId = authProvider.user?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Check if we're in organization mode
      final bool isOrganizationMode = widget.organizationId != null;
      
      if (isOrganizationMode) {
        // Load organization-specific targets and actions
        await Future.wait([
          sdgTargetProvider.loadTargetsForOrganizationSDG(widget.organizationId!, widget.sdg.id),
          actionProvider.loadOrganizationActions(widget.organizationId!),
        ]);
      } else {
        // Load personal targets and actions
        await Future.wait([
          sdgTargetProvider.loadTargetsForSDG(widget.sdg.id),
          actionProvider.loadUserActions(userId),
        ]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
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
    final bool isOrganizationMode = widget.organizationId != null;
    final String title = isOrganizationMode 
        ? 'Organization SDG ${widget.sdg.id} Targets'
        : 'SDG ${widget.sdg.id} Targets';
        
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTargets,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isOrganizationMode) {
            _showAddOrganizationTargetDialog();
          } else {
            _showAddTargetDialog();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Target',
      ),
      body: _buildScrollableBody(),
    );
  }
  
  Widget _buildScrollableBody() {
    return Consumer<SdgTargetProvider>(
      builder: (context, provider, child) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final targets = provider.getTargetsForSDG(widget.sdg.id);
        
        if (targets.isEmpty) {
          return _buildEmptyState();
        }
        
        return CustomScrollView(
          slivers: [
            // Compact header
            SliverToBoxAdapter(
              child: _buildCompactHeader(),
            ),
            // Targets list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildTargetCard(targets[index]),
                childCount: targets.length,
              ),
            ),
            // Add some padding at the bottom
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: widget.sdg.color.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // More compact layout with icon and title side by side
          Row(
            children: [
              SDGIconWidget(
                sdgNumber: widget.sdg.id,
                size: 60, // Smaller icon
                showLabel: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sdg.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.sdg.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSdgContext(widget.sdg.id),
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Divider
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Your Targets heading
          Text(
            'Your Targets',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  // Keep the original header for reference or for the empty state
  Widget _buildSdgHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: widget.sdg.color.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SDG Icon at the top
          SDGIconWidget(
            sdgNumber: widget.sdg.id,
            size: 100,
            showLabel: false,
          ),
          const SizedBox(height: 16),
          // SDG Title
          Text(
            widget.sdg.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.sdg.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // SDG Context
          Text(
            _getSdgContext(widget.sdg.id),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Impact Examples
          Text(
            'How You Can Impact:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ..._getImpactExamples(widget.sdg.id).map((example) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: widget.sdg.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(example, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
          )).toList(),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Your Targets',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
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
    return CustomScrollView(
      slivers: [
        // Compact header
        SliverToBoxAdapter(
          child: _buildCompactHeader(),
        ),
        // Empty state message
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
          ),
        ),
      ],
    );
  }
  
  Widget _buildTargetCard(SdgTarget target) {
    return Consumer<ActionProvider>(
      builder: (context, actionProvider, child) {
        // Get actions for this target
        final targetActions = actionProvider.actions
            .where((action) => action.sdgTargetId == target.id)
            .toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.all(16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Target ${target.targetNumber}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      target.description,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (targetActions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${targetActions.length} action${targetActions.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: target.actionDescription != null && target.actionDescription!.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        target.actionDescription!,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    )
                  : null,
              children: [
                // Target Management Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _navigateToAddAction(target),
                      icon: const Icon(Icons.add_task, size: 18),
                      label: const Text('Add Action'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEditTargetDialog(target),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmDeleteTarget(target),
                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Actions Section
                if (targetActions.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.play_arrow,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Actions (Strategic Level)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...targetActions.map((action) => _buildActionCard(action)),
                ] else ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No actions yet for this target',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first strategic action to work towards this SDG target',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard(ActionItem action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue.withValues(alpha: 0.05),
      ),
      child: FutureBuilder<List<ActionActivity>>(
        future: ActionActivityService.getActivitiesForAction(action.id),
        builder: (context, snapshot) {
          final activities = snapshot.data ?? [];
          
          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.all(12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ACTION',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      action.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (activities.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${activities.length} activit${activities.length != 1 ? 'ies' : 'y'}',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: action.description.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        action.description,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : null,
              children: [
                // Action Management Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _navigateToActionDetail(action),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _addActivityToAction(action),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Add Activity'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Activities Section
                if (activities.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.task_alt,
                        color: Colors.orange[700],
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Activities (Tactical Level)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...activities.map((activity) => _buildActivityCard(activity)),
                ] else ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 32,
                          color: Colors.orange[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No activities yet',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add tactical activities to execute this action',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(ActionActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _getStatusColor(activity.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  activity.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(activity.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (activity.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              activity.description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (activity.impactValue != null && activity.impactUnit != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 14,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Impact: ${activity.impactValue} ${activity.impactUnit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _navigateToActionDetail(ActionItem action) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActionDetailScreen(actionId: action.id),
      ),
    );
  }

  Future<void> _addActivityToAction(ActionItem action) async {
    // Show the add activity dialog directly
    final result = await showDialog<ActionActivity?>(
      context: context,
      builder: (context) => AddActivityDialog(
        actionId: action.id,
        organizationId: action.organizationId,
      ),
    );
    
    if (result != null) {
      // Refresh the actions to show the new activity count
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final actionProvider = Provider.of<ActionProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      if (userId != null) {
        await actionProvider.loadUserActions(userId);
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  Future<void> _showAddOrganizationTargetDialog() async {
    // Similar to _showAddTargetDialog but specifically for organization targets
    final targetNameController = TextEditingController();
    final actionDescriptionController = TextEditingController();
    final targetNumberController = TextEditingController();
    
    // For organization targets, we already know the organization ID
    final String organizationId = widget.organizationId!;
    
    // Get organization name for display
    final orgProvider = Provider.of<OrganizationProvider>(context, listen: false);
    String organizationName = 'Organization';
    
    try {
      final organization = orgProvider.organizations.firstWhere(
        (org) => org.id == organizationId,
      );
      organizationName = organization.name;
    } catch (e) {
      // Use default name if organization not found
    }
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Target for $organizationName - SDG ${widget.sdg.id}'),
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
              
              // Target Name (maps to description in database)
              TextField(
                controller: targetNameController,
                decoration: const InputDecoration(
                  labelText: 'Target Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Action Description
              TextField(
                controller: actionDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
            onPressed: () async {
              // Validate inputs
              if (targetNameController.text.isEmpty || targetNumberController.text.isEmpty) {
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
              
              // Create the target with organization ID pre-filled
              final newTarget = SdgTarget(
                id: '', // Will be generated by Supabase
                sdgId: widget.sdg.id,
                sdgGoalNumber: widget.sdg.id,
                targetNumber: targetNumber,
                description: targetNameController.text,
                actionDescription: actionDescriptionController.text.isNotEmpty ? actionDescriptionController.text : null,
                userId: userId,
                organizationId: organizationId, // Always set for organization targets
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              // Save the target
              final sdgTargetProvider = Provider.of<SdgTargetProvider>(context, listen: false);
              final result = await sdgTargetProvider.createTarget(newTarget);
              
              if (result != null) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Organization target created successfully')),
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
      ),
    );
  }

  Future<void> _showAddTargetDialog() async {
    final targetNameController = TextEditingController(); // This will be used for description field
    final actionDescriptionController = TextEditingController();
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
                  
                  // Target Name (maps to description in database)
                  TextField(
                    controller: targetNameController,
                    decoration: const InputDecoration(
                      labelText: 'Target Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Action Description
                  TextField(
                    controller: actionDescriptionController,
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
                          child: Text('Personal'),
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
                  if (targetNameController.text.isEmpty || targetNumberController.text.isEmpty) {
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
                    sdgId: widget.sdg.id, // Using sdgId to match database schema
                    sdgGoalNumber: widget.sdg.id, // Keep for backward compatibility
                    targetNumber: targetNumber,
                    description: targetNameController.text, // Map target name to description field
                    actionDescription: actionDescriptionController.text.isNotEmpty ? actionDescriptionController.text : null,
                    userId: userId,
                    // Only set organizationId if it's not empty
                    organizationId: _selectedOrganizationId?.isNotEmpty == true ? _selectedOrganizationId : null,
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
    final targetNameController = TextEditingController(text: target.description);
    final descriptionController = TextEditingController(text: target.actionDescription ?? '');
    final targetNumberController = TextEditingController(text: target.targetNumber.toString());
    String? selectedOrgId = target.organizationId;
    
    // Get organizations for selection
    final orgProvider = Provider.of<OrganizationProvider>(context, listen: false);
    final userOrgs = orgProvider.organizations;
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Target ${target.targetNumber}'),
              contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: IntrinsicWidth(
                  child: SingleChildScrollView(
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
                      
                      // Name (maps to description field)
                      TextField(
                        controller: targetNameController,
                        decoration: const InputDecoration(
                          labelText: 'Target Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Action Description
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Action Description (optional)',
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
                              child: Text('Personal'),
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
                  if (targetNameController.text.isEmpty || targetNumberController.text.isEmpty) {
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
                    targetNumber: targetNumber,
                    description: targetNameController.text,
                    actionDescription: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                    // Only set organizationId if it's not empty
                    organizationId: selectedOrgId?.isNotEmpty == true ? selectedOrgId : null,
                    sdgId: widget.sdg.id, // Ensure sdgId is set correctly
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
        );
      },
    );
  }
  
  void _navigateToAddAction(SdgTarget target) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddActionScreen(
          sdgId: widget.sdg.id,
          target: target,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTarget(SdgTarget target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Target?'),
        content: Text(
          'Are you sure you want to delete target ${target.targetNumber}: ${target.description}? '
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
  
  String _getSdgContext(int sdgId) {
    switch (sdgId) {
      case 1:
        return 'End poverty in all its forms everywhere. Despite progress, about 10% of the world still lives in extreme poverty.'; 
      case 2:
        return 'End hunger, achieve food security and improved nutrition, and promote sustainable agriculture.'; 
      case 3:
        return 'Ensure healthy lives and promote well-being for all at all ages, including reducing maternal mortality and ending preventable deaths of children.'; 
      case 4:
        return 'Ensure inclusive and equitable quality education and promote lifelong learning opportunities for all.'; 
      case 5:
        return 'Achieve gender equality and empower all women and girls, including ending discrimination and violence against women.'; 
      case 6:
        return 'Ensure availability and sustainable management of water and sanitation for all.'; 
      case 7:
        return 'Ensure access to affordable, reliable, sustainable and modern energy for all.'; 
      case 8:
        return 'Promote sustained, inclusive and sustainable economic growth, full and productive employment and decent work for all.'; 
      case 9:
        return 'Build resilient infrastructure, promote inclusive and sustainable industrialization and foster innovation.'; 
      case 10:
        return 'Reduce inequality within and among countries by promoting social, economic and political inclusion.'; 
      case 11:
        return 'Make cities and human settlements inclusive, safe, resilient and sustainable.'; 
      case 12:
        return 'Ensure sustainable consumption and production patterns by using resources efficiently and reducing waste.'; 
      case 13:
        return 'Take urgent action to combat climate change and its impacts through mitigation and adaptation strategies.'; 
      case 14:
        return 'Conserve and sustainably use the oceans, seas and marine resources for sustainable development.'; 
      case 15:
        return 'Protect, restore and promote sustainable use of terrestrial ecosystems, sustainably manage forests, combat desertification, halt land degradation and biodiversity loss.'; 
      case 16:
        return 'Promote peaceful and inclusive societies for sustainable development, provide access to justice for all and build effective, accountable institutions.'; 
      case 17:
        return 'Strengthen the means of implementation and revitalize the global partnership for sustainable development.'; 
      default:
        return 'The Sustainable Development Goals are a universal call to action to end poverty, protect the planet and ensure that all people enjoy peace and prosperity.';
    }
  }
  
  List<String> _getImpactExamples(int sdgId) {
    switch (sdgId) {
      case 1: // No Poverty
        return [
          'Support local businesses and fair trade products',
          'Volunteer with or donate to poverty alleviation organizations',
          'Advocate for living wages and economic policies that reduce inequality',
          'Mentor entrepreneurs from disadvantaged communities'
        ];
      case 2: // Zero Hunger
        return [
          'Support local farmers and sustainable agriculture',
          'Reduce food waste in your business and supply chain',
          'Donate to food banks and meal programs',
          'Implement sustainable food procurement policies'
        ];
      case 3: // Good Health and Well-being
        return [
          'Promote employee wellness programs',
          'Support healthcare access initiatives',
          'Reduce pollution and environmental health hazards',
          'Invest in mental health resources and awareness'
        ];
      case 4: // Quality Education
        return [
          'Offer internships and apprenticeships',
          'Support educational programs in underserved communities',
          'Provide employee continuing education opportunities',
          'Mentor students and share professional expertise'
        ];
      case 5: // Gender Equality
        return [
          'Implement equal pay and promotion policies',
          'Support women-owned businesses in your supply chain',
          'Provide family-friendly workplace policies',
          'Ensure gender balance in leadership positions'
        ];
      case 6: // Clean Water and Sanitation
        return [
          'Reduce water consumption in operations',
          'Prevent water pollution in your supply chain',
          'Support clean water access projects',
          'Implement water recycling and conservation measures'
        ];
      case 7: // Affordable and Clean Energy
        return [
          'Transition to renewable energy sources',
          'Improve energy efficiency in operations',
          'Support clean energy innovation and access',
          'Implement energy management systems'
        ];
      case 8: // Decent Work and Economic Growth
        return [
          'Create quality jobs with fair wages and benefits',
          'Ensure safe working conditions throughout supply chains',
          'Support small business development',
          'Implement ethical labor practices and policies'
        ];
      case 9: // Industry, Innovation and Infrastructure
        return [
          'Invest in sustainable infrastructure',
          'Support research and development for sustainable solutions',
          'Implement circular economy principles',
          'Share technology and innovation with developing regions'
        ];
      case 10: // Reduced Inequalities
        return [
          'Implement inclusive hiring and promotion practices',
          'Ensure accessibility for people with disabilities',
          'Support minority-owned businesses',
          'Advocate for policies that reduce economic inequality'
        ];
      case 11: // Sustainable Cities and Communities
        return [
          'Support affordable housing initiatives',
          'Implement sustainable transportation options',
          'Participate in community development projects',
          'Reduce urban environmental footprint'
        ];
      case 12: // Responsible Consumption and Production
        return [
          'Implement circular economy principles in your business',
          'Reduce packaging and waste in products and operations',
          'Source materials sustainably and ethically',
          'Educate consumers about sustainable choices'
        ];
      case 13: // Climate Action
        return [
          'Measure and reduce your carbon footprint',
          'Set science-based emissions reduction targets',
          'Implement climate adaptation strategies',
          'Support climate policy and awareness'
        ];
      case 14: // Life Below Water
        return [
          'Eliminate single-use plastics in operations',
          'Source seafood sustainably',
          'Support ocean conservation initiatives',
          'Prevent water pollution in your supply chain'
        ];
      case 15: // Life on Land
        return [
          'Implement sustainable land use practices',
          'Support reforestation and habitat restoration',
          'Source materials to prevent deforestation',
          'Protect biodiversity in areas of operation'
        ];
      case 16: // Peace, Justice and Strong Institutions
        return [
          'Implement anti-corruption policies',
          'Ensure transparency in business operations',
          'Support access to justice initiatives',
          'Promote inclusive decision-making'
        ];
      case 17: // Partnerships for the Goals
        return [
          'Form multi-stakeholder partnerships for sustainability',
          'Share knowledge and best practices',
          'Support capacity building in developing countries',
          'Align business strategies with the SDGs'
        ];
      default:
        return [
          'Set specific, measurable targets related to the SDGs',
          'Track and report on your progress',
          'Collaborate with others to amplify your impact',
          'Integrate sustainability into your core business strategy'
        ];
    }
  }
}
