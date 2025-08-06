import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bsca_mobile_flutter/models/sdg_target.dart';
import 'package:bsca_mobile_flutter/models/action_item.dart';
import 'package:bsca_mobile_flutter/models/action_activity.dart';
import 'package:bsca_mobile_flutter/providers/auth_provider.dart';
import 'package:bsca_mobile_flutter/providers/organization_provider.dart';
import 'package:bsca_mobile_flutter/providers/action_provider.dart';
import 'package:bsca_mobile_flutter/services/action_activity_service.dart';
import 'package:uuid/uuid.dart';

class AddActionScreen extends StatefulWidget {
  final int sdgId;
  final SdgTarget? target;

  const AddActionScreen({
    Key? key,
    required this.sdgId,
    this.target,
  }) : super(key: key);

  @override
  State<AddActionScreen> createState() => _AddActionScreenState();
}

class _AddActionScreenState extends State<AddActionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priorityController = TextEditingController();
  final _dueDateController = TextEditingController();
  
  // Activity fields
  final _activityTitleController = TextEditingController();
  final _activityDescriptionController = TextEditingController();
  final _impactValueController = TextEditingController();
  final _impactUnitController = TextEditingController();
  final _verificationMethodController = TextEditingController();
  
  String _selectedCategory = 'reduction';
  String _selectedPriority = 'medium';
  DateTime? _selectedDueDate;
  String? _selectedOrganizationId;
  bool _createInitialActivity = false;
  bool _isLoading = false;

  final List<String> _categories = ['reduction', 'innovation', 'education', 'policy'];
  final List<String> _priorities = ['low', 'medium', 'high'];
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
    _categoryController.text = _selectedCategory;
    _priorityController.text = _selectedPriority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priorityController.dispose();
    _dueDateController.dispose();
    _activityTitleController.dispose();
    _activityDescriptionController.dispose();
    _impactValueController.dispose();
    _impactUnitController.dispose();
    _verificationMethodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add New Action'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAction,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSDGInfo(),
                const SizedBox(height: 24),
                _buildActionSection(),
                const SizedBox(height: 24),
                _buildActivitySection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSDGInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SDG ${widget.sdgId}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.target != null) ...[
              const SizedBox(height: 8),
              Text(
                'Target ${widget.target!.targetNumber}: ${widget.target!.description}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Action Details (Strategic Level)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Define the strategic action you want to take',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Action Title *',
            hintText: 'e.g., Implement GHG emissions reduction strategy',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an action title';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Action Description *',
            hintText: 'Describe the strategic approach and goals',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an action description';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Use column layout on smaller screens to prevent overflow
            if (constraints.maxWidth < 500) {
              return Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.substring(0, 1).toUpperCase() + category.substring(1)),
                      );
                    }).toList(),
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
                    items: _priorities.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority.substring(0, 1).toUpperCase() + priority.substring(1)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPriority = value!;
                      });
                    },
                  ),
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.substring(0, 1).toUpperCase() + category.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: _priorities.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority.substring(0, 1).toUpperCase() + priority.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value!;
                        });
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
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
        const SizedBox(height: 16),
        _buildOrganizationSelector(),
      ],
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _createInitialActivity,
              onChanged: (value) {
                setState(() {
                  _createInitialActivity = value ?? false;
                });
              },
            ),
            Expanded(
              child: Text(
                'Create Initial Activity (Tactical Level)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Optionally define a specific activity to execute this action',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        if (_createInitialActivity) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _activityTitleController,
            decoration: const InputDecoration(
              labelText: 'Activity Title',
              hintText: 'e.g., Replace 100 diesel delivery vans with electric vehicles',
              border: OutlineInputBorder(),
            ),
            validator: _createInitialActivity
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an activity title';
                    }
                    return null;
                  }
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _activityDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Activity Description',
              hintText: 'Describe the specific steps and implementation details',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: _createInitialActivity
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an activity description';
                    }
                    return null;
                  }
                : null,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Use column layout on smaller screens to prevent overflow
              if (constraints.maxWidth < 500) {
                return Column(
                  children: [
                    TextFormField(
                      controller: _impactValueController,
                      decoration: const InputDecoration(
                        labelText: 'Expected Impact Value',
                        hintText: '12.5',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
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
                  ],
                );
              } else {
                return Row(
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
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
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
                );
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _verificationMethodController,
            decoration: const InputDecoration(
              labelText: 'Verification Method',
              hintText: 'How will this activity\'s impact be verified?',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ],
    );
  }

  Widget _buildOrganizationSelector() {
    return Consumer<OrganizationProvider>(
      builder: (context, orgProvider, child) {
        final organizations = orgProvider.organizations;
        
        if (organizations.isEmpty) {
          return const SizedBox.shrink();
        }

        return DropdownButtonFormField<String>(
          value: _selectedOrganizationId,
          decoration: const InputDecoration(
            labelText: 'Organization (Optional)',
            hintText: 'Select organization for business actions',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Personal Action'),
            ),
            ...organizations.map((org) {
              return DropdownMenuItem<String>(
                value: org.id,
                child: Text(org.name),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedOrganizationId = value;
            });
          },
        );
      },
    );
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

  Future<void> _saveAction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final actionProvider = Provider.of<ActionProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create the action using ActionProvider's named parameters
      final createdAction = await actionProvider.createAction(
        userId: userId,
        sdgId: widget.sdgId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        organizationId: _selectedOrganizationId,
        sdgTargetId: widget.target?.id,
        dueDate: _selectedDueDate,
      );

      if (createdAction == null) {
        throw Exception('Failed to create action');
      }

      // Create initial activity if requested
      if (_createInitialActivity && _activityTitleController.text.trim().isNotEmpty) {
        final now = DateTime.now();
        final activityId = const Uuid().v4();
        final activity = ActionActivity(
          id: activityId,
          actionId: createdAction.id,
          title: _activityTitleController.text.trim(),
          description: _activityDescriptionController.text.trim(),
          userId: userId,
          organizationId: _selectedOrganizationId,
          createdAt: now,
          updatedAt: now,
          impactValue: _impactValueController.text.isNotEmpty
              ? double.tryParse(_impactValueController.text)
              : null,
          impactUnit: _impactUnitController.text.isNotEmpty
              ? _impactUnitController.text
              : null,
          verificationMethod: _verificationMethodController.text.isNotEmpty
              ? _verificationMethodController.text
              : null,
        );

        await ActionActivityService.createActivity(activity);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating action: $e'),
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
