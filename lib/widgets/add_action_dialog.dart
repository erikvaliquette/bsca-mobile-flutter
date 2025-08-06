import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/organization_model.dart';
import '../providers/action_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/organization_provider.dart';

class AddActionDialog extends StatefulWidget {
  final int sdgId;

  const AddActionDialog({
    super.key,
    required this.sdgId,
  });

  @override
  State<AddActionDialog> createState() => _AddActionDialogState();
}

class _AddActionDialogState extends State<AddActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'reduction';
  String _selectedPriority = 'medium';
  DateTime? _dueDate;
  Organization? _selectedOrganization;
  bool _isLoading = false;

  final List<String> _categories = [
    'reduction',
    'innovation',
    'education',
    'policy',
  ];

  final List<String> _priorities = [
    'low',
    'medium',
    'high',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_task, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'Add New Action',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Action Title *',
                      hintText: 'Enter a clear, actionable title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      if (value.trim().length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      return null;
                    },
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Describe what you want to accomplish',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      if (value.trim().length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                    maxLength: 500,
                  ),
                  const SizedBox(height: 16),
                  
                  // Category dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(_formatCategoryName(category)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Priority dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: _priorities.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag,
                              color: _getPriorityColor(priority),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(_formatPriorityName(priority)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPriority = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Due date picker
                  InkWell(
                    onTap: _selectDueDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date (Optional)',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                            : 'Select due date',
                        style: TextStyle(
                          color: _dueDate != null ? Colors.black : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Organization attribution (for Professional+ users)
                  Consumer<SubscriptionProvider>(
                    builder: (context, subscriptionProvider, child) {
                      final canAttributeToOrg = subscriptionProvider.canAccessBusinessTripAttribution;
                      
                      if (!canAttributeToOrg) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            border: Border.all(color: Colors.blue[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Upgrade to Professional to attribute actions to your organization',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return Consumer<OrganizationProvider>(
                        builder: (context, orgProvider, child) {
                          final organizations = orgProvider.organizations;
                          
                          if (organizations.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                border: Border.all(color: Colors.orange[200]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.business, color: Colors.orange[700], size: 20),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Join an organization to attribute actions to it',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return DropdownButtonFormField<Organization?>(
                            value: _selectedOrganization,
                            decoration: const InputDecoration(
                              labelText: 'Attribute to Organization (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<Organization?>(
                                value: null,
                                child: Text('Personal Action'),
                              ),
                              ...organizations.map((org) {
                                return DropdownMenuItem<Organization?>(
                                  value: org,
                                  child: Text(org.name),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedOrganization = value;
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createAction,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create Action'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCategoryName(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }

  String _formatPriorityName(String priority) {
    return priority[0].toUpperCase() + priority.substring(1);
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

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _createAction() async {
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

      final action = await actionProvider.createAction(
        userId: userId,
        sdgId: widget.sdgId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        organizationId: _selectedOrganization?.id,
        dueDate: _dueDate,
        priority: _selectedPriority,
      );

      if (action != null) {
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Action created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to create action');
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
