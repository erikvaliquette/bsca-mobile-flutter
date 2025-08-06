import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/action_activity.dart';
import '../providers/auth_provider.dart';
import '../services/action_activity_service.dart';

class AddActivityDialog extends StatefulWidget {
  final String actionId;
  final String? organizationId;
  final ActionActivity? activity; // For editing existing activity

  const AddActivityDialog({
    Key? key,
    required this.actionId,
    this.organizationId,
    this.activity,
  }) : super(key: key);

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _impactValueController = TextEditingController();
  final _impactUnitController = TextEditingController();
  final _impactDescriptionController = TextEditingController();
  final _verificationMethodController = TextEditingController();
  final _dueDateController = TextEditingController();

  String _selectedStatus = 'planned';
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  final List<String> _statusOptions = ['planned', 'in_progress', 'completed', 'cancelled'];
  final List<String> _impactUnits = [
    'metric tons CO₂e',
    'kWh saved',
    'people reached',
    'hours volunteered',
    'dollars saved',
    'waste reduced (kg)',
    'water saved (liters)',
    'trees planted',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.activity != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final activity = widget.activity!;
    _titleController.text = activity.title;
    _descriptionController.text = activity.description;
    _selectedStatus = activity.status;
    _impactValueController.text = activity.impactValue?.toString() ?? '';
    _impactUnitController.text = activity.impactUnit ?? '';
    _impactDescriptionController.text = activity.impactDescription ?? '';
    _verificationMethodController.text = activity.verificationMethod ?? '';
    _selectedDueDate = activity.dueDate;
    if (_selectedDueDate != null) {
      _dueDateController.text = '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _impactValueController.dispose();
    _impactUnitController.dispose();
    _impactDescriptionController.dispose();
    _verificationMethodController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.activity != null;
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Scaffold(
          appBar: AppBar(
            title: Text(isEditing ? 'Edit Activity' : 'Add Activity'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : _saveActivity,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Activity Title *',
                      hintText: 'e.g., Replace 100 diesel delivery vans with electric vehicles',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an activity title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Activity Description *',
                      hintText: 'Describe the specific steps and implementation details',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an activity description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: _statusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(_getStatusDisplayName(status)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _dueDateController,
                          decoration: const InputDecoration(
                            labelText: 'Due Date (Optional)',
                            hintText: 'Select target completion date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: _selectDueDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Impact Tracking',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _impactValueController,
                          decoration: const InputDecoration(
                            labelText: 'Expected Impact Value',
                            hintText: '12.5',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _impactUnitController.text.isNotEmpty ? _impactUnitController.text : null,
                          decoration: const InputDecoration(
                            labelText: 'Impact Unit',
                            border: OutlineInputBorder(),
                          ),
                          items: _impactUnits.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (value) {
                            _impactUnitController.text = value ?? '';
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _impactDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Impact Description (Optional)',
                      hintText: 'Describe the expected environmental/social impact',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Verification',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _verificationMethodController,
                    decoration: const InputDecoration(
                      labelText: 'Verification Method (Optional)',
                      hintText: 'How will this activity\'s impact be verified?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'planned':
        return 'Planned';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
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

      final now = DateTime.now();
      final isEditing = widget.activity != null;

      final activity = ActionActivity(
        id: isEditing ? widget.activity!.id : const Uuid().v4(),
        actionId: widget.actionId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _selectedStatus,
        userId: userId,
        organizationId: widget.organizationId,
        createdAt: isEditing ? widget.activity!.createdAt : now,
        updatedAt: now,
        dueDate: _selectedDueDate,
        impactValue: _impactValueController.text.isNotEmpty
            ? double.tryParse(_impactValueController.text)
            : null,
        impactUnit: _impactUnitController.text.isNotEmpty
            ? _impactUnitController.text
            : null,
        impactDescription: _impactDescriptionController.text.isNotEmpty
            ? _impactDescriptionController.text
            : null,
        verificationMethod: _verificationMethodController.text.isNotEmpty
            ? _verificationMethodController.text
            : null,
        completedAt: _selectedStatus == 'completed' && !isEditing
            ? now
            : widget.activity?.completedAt,
      );

      ActionActivity savedActivity;
      if (isEditing) {
        savedActivity = await ActionActivityService.updateActivity(activity);
      } else {
        savedActivity = await ActionActivityService.createActivity(activity);
      }

      if (mounted) {
        Navigator.of(context).pop(savedActivity);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving activity: $e'),
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
