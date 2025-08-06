import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/action_item.dart';
import '../models/action_measurement.dart';
import '../models/action_activity.dart';
import '../providers/action_provider.dart';
import '../providers/auth_provider.dart';
import '../services/action_service.dart';
import '../services/action_measurement_service.dart';
import '../services/action_activity_service.dart';
import '../widgets/action_measurement_dialog.dart';
import '../widgets/action_target_dialog.dart';
import '../widgets/action_progress_chart.dart';
import '../widgets/add_activity_dialog.dart';

class ActionDetailScreen extends StatefulWidget {
  final String actionId;

  const ActionDetailScreen({
    Key? key,
    required this.actionId,
  }) : super(key: key);

  @override
  State<ActionDetailScreen> createState() => _ActionDetailScreenState();
}

class _ActionDetailScreenState extends State<ActionDetailScreen> {
  bool _isLoading = true;
  ActionItem? _action;
  List<ActionMeasurement> _measurements = [];
  List<ActionActivity> _activities = [];
  String? _errorMessage;
  bool _isLoadingActivities = false;

  @override
  void initState() {
    super.initState();
    _loadActionData();
  }

  Future<void> _loadActionData() async {
    print('ActionDetailScreen: Starting to load action data for ID: ${widget.actionId}');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('ActionDetailScreen: Fetching action from database...');
      // Fetch action directly from database
      final action = await ActionService.getActionById(widget.actionId);
      
      print('ActionDetailScreen: Action fetched: ${action?.title ?? 'null'}');
      
      if (action == null) {
        print('ActionDetailScreen: Action not found in database');
        setState(() {
          _errorMessage = 'Action not found in database';
          _isLoading = false;
        });
        return;
      }
      
      print('ActionDetailScreen: Loading measurements and activities...');
      // Load measurements and activities for this action in parallel
      final results = await Future.wait([
        ActionMeasurementService.getMeasurementsForAction(widget.actionId),
        ActionActivityService.getActivitiesForAction(widget.actionId),
      ]);
      
      final measurements = results[0] as List<ActionMeasurement>;
      final activities = results[1] as List<ActionActivity>;
      
      print('ActionDetailScreen: Loaded ${measurements.length} measurements and ${activities.length} activities');
      
      setState(() {
        _action = action;
        _measurements = measurements;
        _activities = activities;
        _isLoading = false;
      });
      
      print('ActionDetailScreen: Data loading completed successfully');
    } catch (e) {
      print('ActionDetailScreen: Error loading action data: $e');
      setState(() {
        _errorMessage = 'Error loading action data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showBaselineDialog() async {
    if (_action == null) return;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ActionMeasurementDialog(
        action: _action!,
        isInitialSetup: true,
      ),
    );
    
    if (result == true) {
      await _loadActionData();
    }
  }

  Future<void> _showTargetDialog() async {
    if (_action == null) return;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ActionTargetDialog(
        action: _action!,
      ),
    );
    
    if (result == true) {
      await _loadActionData();
    }
  }

  Future<void> _showAddMeasurementDialog() async {
    if (_action == null) return;
    
    // Check if baseline is set
    if (_action!.baselineValue == null || _action!.baselineUnit == null) {
      final setBaseline = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Baseline Required'),
          content: const Text(
            'You need to set a baseline before adding measurements. Would you like to set a baseline now?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('SET BASELINE'),
            ),
          ],
        ),
      );
      
      if (setBaseline == true) {
        await _showBaselineDialog();
      }
      return;
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ActionMeasurementDialog(
        action: _action!,
        isInitialSetup: false,
      ),
    );
    
    if (result == true) {
      await _loadActionData();
    }
  }

  Future<void> _showAddActivityDialog() async {
    if (_action == null) return;
    
    final result = await showDialog<ActionActivity?>(
      context: context,
      builder: (context) => AddActivityDialog(
        actionId: _action!.id,
        organizationId: _action!.organizationId,
      ),
    );
    
    if (result != null) {
      await _loadActionData();
    }
  }

  Future<void> _showEditActivityDialog(ActionActivity activity) async {
    final result = await showDialog<ActionActivity?>(
      context: context,
      builder: (context) => AddActivityDialog(
        actionId: activity.actionId,
        organizationId: activity.organizationId,
        activity: activity,
      ),
    );
    
    if (result != null) {
      await _loadActionData();
    }
  }

  Future<void> _completeActivity(ActionActivity activity) async {
    try {
      setState(() {
        _isLoadingActivities = true;
      });
      
      await ActionActivityService.completeActivity(activity.id);
      await _loadActionData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity marked as completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing activity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingActivities = false;
        });
      }
    }
  }

  Future<void> _deleteActivity(ActionActivity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Are you sure you want to delete "${activity.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await ActionActivityService.deleteActivity(activity.id);
        await _loadActionData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting activity: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging
    print('ActionDetailScreen build: _isLoading=$_isLoading, _errorMessage=$_errorMessage, _action=${_action?.title}');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_action?.title ?? 'Action Details'),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading action details...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error Loading Action',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _loadActionData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _action == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Action Not Found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The requested action could not be found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : _buildContent(),
      floatingActionButton: _action != null
          ? FloatingActionButton(
              onPressed: _showAddMeasurementDialog,
              tooltip: 'Add Measurement',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildContent() {
    print('ActionDetailScreen: _buildContent called, action: ${_action?.title}');
    
    if (_action == null) {
      print('ActionDetailScreen: _buildContent - action is null');
      return const Center(child: Text('Action not found'));
    }

    print('ActionDetailScreen: _buildContent - building content for: ${_action!.title}');
    print('ActionDetailScreen: About to return widget tree');
    
    // STEP 3: Add Activities section (safe widgets only)
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action title
          Text(
            _action!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          // Edit button (separate line)
          ElevatedButton(
            onPressed: () => _showEditActionDialog(),
            child: const Text('Edit Action'),
          ),
          const SizedBox(height: 16),
          Text(
            _action!.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Progress: ${(_action!.progress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          // Activities section header
          Text(
            'Activities (${_activities.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          // Add Activity button
          ElevatedButton(
            onPressed: () => _showAddActivityDialog(),
            child: const Text('Add Activity'),
          ),
          const SizedBox(height: 16),
          // Activities list (simple approach)
          ..._activities.map((activity) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${activity.isCompleted ? '✅' : '⏳'} ${activity.title}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              // Activity buttons (separate lines to avoid Row issues)
              ElevatedButton(
                onPressed: () => _showActivityDetailsDialog(activity),
                child: const Text('View Details'),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () => _showEditActivityDialog(activity),
                child: const Text('Edit Activity'),
              ),
              const SizedBox(height: 16),
            ],
          )).toList(),
        ],
      ),
    );
  }
  
  Widget _buildSimpleInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryValue(String category) {
    const validCategories = [
      'personal', 'community', 'workplace', 'education', 
      'innovation', 'environmental', 'social', 'other'
    ];
    return validCategories.contains(category) ? category : 'other';
  }

  String _getPriorityValue(String priority) {
    const validPriorities = ['low', 'medium', 'high', 'urgent'];
    return validPriorities.contains(priority) ? priority : 'medium';
  }

  void _showEditActionDialog() {
    final titleController = TextEditingController(text: _action!.title);
    final descriptionController = TextEditingController(text: _action!.description);
    String category = _action!.category;
    String priority = _action!.priority;
    DateTime? dueDate = _action!.dueDate;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Action'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Title field
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Action Title',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Description field
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Category dropdown
              DropdownButtonFormField<String>(
                value: _getCategoryValue(category),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'personal', child: Text('Personal')),
                  DropdownMenuItem(value: 'community', child: Text('Community')),
                  DropdownMenuItem(value: 'workplace', child: Text('Workplace')),
                  DropdownMenuItem(value: 'education', child: Text('Education')),
                  DropdownMenuItem(value: 'innovation', child: Text('Innovation')),
                  DropdownMenuItem(value: 'environmental', child: Text('Environmental')),
                  DropdownMenuItem(value: 'social', child: Text('Social')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value != null) category = value;
                },
              ),
              const SizedBox(height: 16),
              // Priority dropdown
              DropdownButtonFormField<String>(
                value: _getPriorityValue(priority),
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: (value) {
                  if (value != null) priority = value;
                },
              ),
              const SizedBox(height: 16),
              // Due date picker
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due Date',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dueDate != null 
                        ? 'Due: ${DateFormat('yyyy-MM-dd').format(dueDate!)}'
                        : 'No due date set',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            dueDate = picked;
                          }
                        },
                        child: Text(dueDate != null ? 'Change Date' : 'Set Date'),
                      ),
                      if (dueDate != null)
                        ElevatedButton(
                          onPressed: () {
                            dueDate = null;
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ],
              ),
              ],
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
              // Validate input
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a title'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Create updated action
              final updatedAction = _action!.copyWith(
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                category: category,
                priority: priority,
                dueDate: dueDate,
                updatedAt: DateTime.now(),
              );
              
              Navigator.of(context).pop();
              
              // Update the action
              await _updateAction(updatedAction);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAction(ActionItem updatedAction) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Updating action...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Update via ActionService
      final success = await ActionService.updateAction(updatedAction);
      
      if (success != null) {
        // Update local state
        setState(() {
          _action = updatedAction;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Update returned null');
      }
    } catch (e) {
      print('Error updating action: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update action: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showActivityDetailsDialog(ActionActivity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activity.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Description:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(activity.description),
              const SizedBox(height: 16),
              Text(
                'Status:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    activity.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: activity.isCompleted ? Colors.green : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(activity.isCompleted ? 'Completed' : 'In Progress'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Created:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(DateFormat('yyyy-MM-dd HH:mm').format(activity.createdAt)),
              if (activity.completedAt != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Completed:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(DateFormat('yyyy-MM-dd HH:mm').format(activity.completedAt!)),
              ],
              if (activity.impactValue != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Impact:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('${activity.impactValue} ${activity.impactUnit ?? ''}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditActivityDialog(activity);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showEvidenceImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Evidence Image'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Flexible(
              child: Image.network(
                url,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activities (Tactical Level)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddActivityDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Activity'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Specific tactical actions to execute this strategic action',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_activities.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No activities yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add specific activities to break down this action into manageable tasks',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activities.length,
            itemBuilder: (context, index) {
              final activity = _activities[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(activity.status),
                    child: Icon(
                      _getStatusIcon(activity.status),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    activity.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: activity.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.statusDisplayName),
                      if (activity.hasImpact)
                        Text(
                          'Impact: ${activity.impactValue} ${activity.impactUnit}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditActivityDialog(activity);
                          break;
                        case 'complete':
                          _completeActivity(activity);
                          break;
                        case 'delete':
                          _deleteActivity(activity);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (!activity.isCompleted)
                        const PopupMenuItem(
                          value: 'complete',
                          child: ListTile(
                            leading: Icon(Icons.check_circle, color: Colors.green),
                            title: Text('Mark Complete'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description:',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(activity.description),
                          const SizedBox(height: 12),
                          
                          if (activity.verificationMethod != null) ...[
                            Text(
                              'Verification Method:',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(activity.verificationMethod!),
                            const SizedBox(height: 12),
                          ],
                          
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Created:',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(DateFormat('MMM dd, yyyy').format(activity.createdAt)),
                                  ],
                                ),
                              ),
                              if (activity.completedAt != null)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Completed:',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(DateFormat('MMM dd, yyyy').format(activity.completedAt!)),
                                    ],
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Verification:',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      activity.verificationStatusDisplayName,
                                      style: TextStyle(
                                        color: _getVerificationColor(activity.verificationStatus),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          if (activity.hasEvidence) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Evidence:',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: activity.evidenceUrls!.map((url) {
                                return Chip(
                                  label: const Text('View Evidence'),
                                  avatar: const Icon(Icons.link, size: 16),
                                  onDeleted: () {
                                    // TODO: Implement evidence viewing
                                  },
                                  deleteIcon: const Icon(Icons.open_in_new, size: 16),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'planned':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'planned':
        return Icons.schedule;
      case 'in_progress':
        return Icons.play_arrow;
      case 'completed':
        return Icons.check;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getVerificationColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMeasurementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Measurements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        if (_measurements.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No measurements recorded yet. Tap the + button to add your first measurement.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _measurements.length,
            itemBuilder: (context, index) {
              final measurement = _measurements[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    '${measurement.value} ${measurement.unit ?? _action?.baselineUnit ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('yyyy-MM-dd').format(measurement.date)),
                      if (measurement.notes != null && measurement.notes!.isNotEmpty)
                        Text(
                          measurement.notes!,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                  trailing: measurement.evidenceUrl != null
                      ? IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: () {
                            _showEvidenceImage(measurement.evidenceUrl!);
                          },
                        )
                      : null,
                ),
              );
            },
          ),
      ],
    );
  }
}
