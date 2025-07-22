import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/profile_model.dart';
import '../../models/organization_model.dart';
import '../../services/organization_service.dart';
import '../../providers/profile_provider.dart';

class EditWorkHistoryScreen extends StatefulWidget {
  final WorkHistory? workHistory;
  
  const EditWorkHistoryScreen({super.key, this.workHistory});

  @override
  State<EditWorkHistoryScreen> createState() => _EditWorkHistoryScreenState();
}

class _EditWorkHistoryScreenState extends State<EditWorkHistoryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _companyController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;
  
  // Organization selection
  Organization? _selectedOrganization;
  List<Organization> _availableOrganizations = [];
  bool _isLoadingOrganizations = false;
  
  @override
  void initState() {
    super.initState();
    _loadOrganizations();
    
    if (widget.workHistory != null) {
      _companyController.text = widget.workHistory!.company ?? '';
      _titleController.text = widget.workHistory!.title ?? '';
      _descriptionController.text = widget.workHistory!.description ?? '';
      _startDate = widget.workHistory!.startDate;
      _endDate = widget.workHistory!.endDate;
      _isCurrent = widget.workHistory!.isCurrent ?? false;
      
      // Set selected organization if organizationId exists
      if (widget.workHistory!.organizationId != null) {
        _loadSelectedOrganization(widget.workHistory!.organizationId!);
      }
    }
  }
  
  Future<void> _loadOrganizations() async {
    setState(() {
      _isLoadingOrganizations = true;
    });
    
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final userId = profileProvider.profile?.id;
      
      debugPrint('Loading organizations for user: $userId');
      
      if (userId != null) {
        final organizations = await OrganizationService.instance.getOrganizationsForUser(userId);
        debugPrint('Loaded ${organizations.length} organizations: ${organizations.map((o) => o.name).toList()}');
        setState(() {
          _availableOrganizations = organizations;
        });
      } else {
        debugPrint('No userId found in profile provider');
      }
    } catch (e) {
      debugPrint('Error loading organizations: $e');
    } finally {
      setState(() {
        _isLoadingOrganizations = false;
      });
    }
  }
  
  Future<void> _loadSelectedOrganization(String organizationId) async {
    try {
      final organization = await OrganizationService.instance.getOrganizationById(organizationId);
      if (organization != null) {
        setState(() {
          _selectedOrganization = organization;
        });
      }
    } catch (e) {
      debugPrint('Error loading selected organization: $e');
    }
  }
  
  @override
  void dispose() {
    _companyController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    final workHistory = WorkHistory(
      company: _companyController.text,
      title: _titleController.text,
      description: _descriptionController.text,
      startDate: _startDate,
      endDate: _isCurrent ? null : _endDate,
      isCurrent: _isCurrent,
      organizationId: _selectedOrganization?.id,
    );
    
    Navigator.of(context).pop(workHistory);
  }
  
  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
      });
    }
  }
  
  Future<void> _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (pickedDate != null) {
      setState(() {
        _endDate = pickedDate;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workHistory == null ? 'Add Work Experience' : 'Edit Work Experience'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: _selectedOrganization != null ? 'Company (Optional)' : 'Company',
                  hintText: _selectedOrganization != null 
                      ? 'Auto-filled from organization or enter custom name'
                      : 'Enter company name',
                  suffixIcon: _selectedOrganization != null 
                      ? Icon(Icons.link, color: Colors.blue[600])
                      : null,
                ),
                validator: (value) {
                  // Company name is optional if organization is selected
                  if (_selectedOrganization == null && (value == null || value.isEmpty)) {
                    return 'Please enter a company name or select an organization';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Organization Selection
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Link to Organization (Optional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Link this work experience to one of your organizations for validation.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingOrganizations)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Loading your organizations...'),
                            ],
                          ),
                        )
                      else if (_availableOrganizations.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No organizations found. You need to join organizations first to link work experience for validation.',
                                  style: TextStyle(color: Colors.orange[700], fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<Organization>(
                          value: _selectedOrganization,
                          decoration: const InputDecoration(
                            labelText: 'Select Organization',
                            hintText: 'Choose an organization to link',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<Organization>(
                              value: null,
                              child: Text('No organization'),
                            ),
                            ..._availableOrganizations.map((org) => 
                              DropdownMenuItem<Organization>(
                                value: org,
                                child: Text(org.name),
                              ),
                            ),
                          ],
                          onChanged: (Organization? value) {
                            setState(() {
                              _selectedOrganization = value;
                              // Auto-fill company name when organization is selected
                              if (value != null) {
                                _companyController.text = value.name;
                              }
                            });
                          },
                        ),
                      if (_selectedOrganization != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'This work experience will be linked to ${_selectedOrganization!.name} and may require validation.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  hintText: 'Enter your job title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a position';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your responsibilities',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Time Period',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(_startDate == null 
                  ? 'Select start date' 
                  : '${_startDate!.month}/${_startDate!.day}/${_startDate!.year}'
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectStartDate,
              ),
              if (!_isCurrent) ListTile(
                title: const Text('End Date'),
                subtitle: Text(_endDate == null 
                  ? 'Select end date' 
                  : '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectEndDate,
              ),
              SwitchListTile(
                title: const Text('I currently work here'),
                value: _isCurrent,
                onChanged: (value) {
                  setState(() {
                    _isCurrent = value;
                    if (value) {
                      _endDate = null;
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
