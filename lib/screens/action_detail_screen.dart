import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/action_item.dart';
import '../models/action_measurement.dart';
import '../models/action_activity.dart';
import '../providers/action_provider.dart';
import '../providers/auth_provider.dart';
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get action from provider
      final actionProvider = Provider.of<ActionProvider>(context, listen: false);
      final action = actionProvider.getActionById(widget.actionId);
      
      if (action == null) {
        setState(() {
          _errorMessage = 'Action not found';
          _isLoading = false;
        });
        return;
      }
      
      // Load measurements and activities for this action
      final measurements = await ActionMeasurementService.getMeasurementsForAction(widget.actionId);
      final activities = await ActionActivityService.getActivitiesForAction(widget.actionId);
      
      setState(() {
        _action = action;
        _measurements = measurements;
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_action?.title ?? 'Action Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
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
    if (_action == null) {
      return const Center(child: Text('Action not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action title and description
          Text(
            _action!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _action!.description,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          
          // Progress indicator
          LinearProgressIndicator(
            value: _action!.progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _action!.progress >= 1.0 ? Colors.green : Theme.of(context).primaryColor,
            ),
            minHeight: 10,
          ),
          const SizedBox(height: 4),
          Text(
            '${(_action!.progress * 100).toStringAsFixed(1)}% complete',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Baseline and target section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sustainability Tracking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'baseline') {
                            _showBaselineDialog();
                          } else if (value == 'target') {
                            _showTargetDialog();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'baseline',
                            child: Text('Set Baseline'),
                          ),
                          const PopupMenuItem(
                            value: 'target',
                            child: Text('Set Target'),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Baseline info
                  _buildInfoRow(
                    'Baseline',
                    _action!.baselineValue != null
                        ? '${_action!.baselineValue} ${_action!.baselineUnit ?? ''}'
                        : 'Not set',
                    _action!.baselineDate != null
                        ? DateFormat('yyyy-MM-dd').format(_action!.baselineDate!)
                        : null,
                    Icons.flag,
                    Colors.blue,
                  ),
                  if (_action!.baselineMethodology != null && _action!.baselineMethodology!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 40, top: 4),
                      child: Text(
                        'Methodology: ${_action!.baselineMethodology}',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Target info
                  _buildInfoRow(
                    'Target',
                    _action!.targetValue != null
                        ? '${_action!.targetValue} ${_action!.baselineUnit ?? ''}'
                        : 'Not set',
                    _action!.targetDate != null
                        ? DateFormat('yyyy-MM-dd').format(_action!.targetDate!)
                        : null,
                    Icons.flag,
                    Colors.green,
                  ),
                  if (_action!.verificationMethod != null && _action!.verificationMethod!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 40, top: 4),
                      child: Text(
                        'Verification: ${_action!.verificationMethod}',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Progress chart
          if (_measurements.isNotEmpty || _action!.baselineValue != null)
            Card(
              child: ActionProgressChart(
                action: _action!,
                measurements: _measurements,
              ),
            ),
          
          // Activities section
          const SizedBox(height: 24),
          _buildActivitiesSection(),
          
          // Measurements list
          const SizedBox(height: 24),
          _buildMeasurementsSection(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, String? date, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(value),
              if (date != null)
                Text(
                  'Date: $date',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ],
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
