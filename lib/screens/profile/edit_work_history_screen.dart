import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/profile_model.dart';
import '../../models/organization_model.dart';
import '../../services/organization_service.dart';
import '../../services/validation_service.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';

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
  final _searchController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;
  bool _isSaving = false;
  
  // Organization selection
  Organization? _selectedOrganization;
  List<Organization> _availableOrganizations = [];
  bool _isLoadingOrganizations = false;
  
  // Organization search
  List<Organization> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  bool _showSearchResults = false;
  
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
        _loadSelectedOrganization(widget.workHistory!.organizationId!).then((_) {
          // Also set the search controller text to match the organization name
          if (_selectedOrganization != null) {
            _searchController.text = _selectedOrganization!.name;
          }
        });
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
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  /// Search for organizations with debounce
  void _searchOrganizations(String query) {
    // Cancel previous timer
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    
    // Set a new timer to delay the search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 2) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _showSearchResults = false;
        });
        return;
      }
      
      setState(() {
        _isSearching = true;
        _showSearchResults = true;
      });
      
      try {
        final results = await OrganizationService.instance.searchOrganizations(query);
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      } catch (e) {
        debugPrint('Error searching organizations: $e');
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }
  
  /// Select an organization from search results
  void _selectSearchResult(Organization organization) {
    setState(() {
      _selectedOrganization = organization;
      _companyController.text = organization.name;
      _showSearchResults = false;
      _searchController.text = organization.name;
    });
    
    // Check validation status when an organization is selected
    _checkValidationStatus(organization.id);
  }
  
  // Check if user already has a validation request for this organization
  Future<void> _checkValidationStatus(String organizationId) async {
    try {
      final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
      if (profile == null) return;
      
      final status = await ValidationService.instance.getValidationStatus(
        userId: profile.id,
        organizationId: organizationId,
      );
      
      if (mounted && status != null) {
        String message;
        switch (status.status) {
          case 'pending':
            message = 'Your employment validation request is pending approval';
            break;
          case 'approved':
            message = 'Your employment at this organization is validated';
            break;
          case 'rejected':
            message = 'Your previous validation request was rejected. You can submit a new request.';
            break;
          default:
            message = 'Employment validation will be required';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking validation status: $e');
    }
  }
  
  Future<void> _saveWorkHistory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final userId = authProvider.user!.id;

      // Create work history object
      final workHistory = WorkHistory(
        company: _selectedOrganization != null
            ? _selectedOrganization!.name
            : _companyController.text,
        title: _titleController.text,
        startDate: _startDate,
        endDate: _isCurrent ? null : _endDate,
        isCurrent: _isCurrent,
        description: _descriptionController.text,
        organizationId: _selectedOrganization?.id,
      );

      debugPrint('Saving work history: ${workHistory.company}, ${workHistory.title}');
      debugPrint('Organization ID: ${workHistory.organizationId}');

      // Get current profile data
      final currentProfile = profileProvider.profile;
      if (currentProfile == null) {
        throw Exception('Profile not loaded');
      }
      
      // Get current work history or create empty list
      List<WorkHistory> updatedWorkHistory = List<WorkHistory>.from(currentProfile.workHistory ?? []);
      
      // If editing existing work history
      if (widget.workHistory != null) {
        // Find and replace the existing work history entry
        final index = updatedWorkHistory.indexWhere((w) => 
          w.company == widget.workHistory!.company && 
          w.title == widget.workHistory!.title);
        
        if (index != -1) {
          updatedWorkHistory[index] = workHistory;
        } else {
          updatedWorkHistory.add(workHistory);
        }
      } else {
        // Add new work history entry
        updatedWorkHistory.add(workHistory);
      }
      
      // Update the full profile with the updated work history list
      await profileProvider.updateFullProfile(
        workHistory: updatedWorkHistory,
      );

      // Check if we need to request validation
      if (_selectedOrganization != null && _selectedOrganization!.id != null) {
        final validationService = ValidationService.instance;
        final canRequest = await validationService.canRequestValidation(
          userId: userId, 
          organizationId: _selectedOrganization!.id!,
        );

        if (canRequest) {
          // Request validation
          await validationService.requestEmploymentValidation(
            userId: userId, 
            organizationId: _selectedOrganization!.id!,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Validation request sent to organization')),
            );
          }
        }
      }

      // Explicitly refresh the profile data to ensure the profile screen updates
      await profileProvider.fetchCurrentUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Work history saved successfully')),
        );
        
        // Use Future.delayed to avoid Flutter navigation errors
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.of(context).pop(workHistory);
          }
        });
      }
    } catch (e) {
      debugPrint('Error saving work history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving work history: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
            onPressed: _saveWorkHistory,
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
              
              // Organization Search and Selection
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
                      
                      // Organization search field
                      TextFormField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search for Organization',
                          hintText: 'Type to search for an organization',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _showSearchResults = false;
                                    _searchResults = [];
                                  });
                                },
                              )
                            : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: _searchOrganizations,
                      ),
                      
                      // Search results
                      if (_showSearchResults)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _isSearching
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _searchResults.isEmpty
                              ? ListTile(
                                  leading: Icon(Icons.info_outline, color: Colors.orange[700]),
                                  title: const Text('No organizations found'),
                                  subtitle: const Text('You can still add this work experience without linking to an organization.'),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final org = _searchResults[index];
                                    return ListTile(
                                      title: Text(org.name),
                                      subtitle: org.address != null ? Text(_formatOrgAddress(org.address!)) : null,
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                      onTap: () => _selectSearchResult(org),
                                    );
                                  },
                                ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Your organizations section
                      if (_availableOrganizations.isNotEmpty) ...[  
                        Text(
                          'Or select from your organizations:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedOrganization?.id,
                          decoration: const InputDecoration(
                            labelText: 'Your Organizations',
                            hintText: 'Choose from your organizations',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('No organization'),
                            ),
                            ..._availableOrganizations.map((org) => 
                              DropdownMenuItem<String>(
                                value: org.id,
                                child: Text(org.name),
                              ),
                            ),
                          ],
                          onChanged: (String? value) {
                            if (value == null) {
                              setState(() {
                                _selectedOrganization = null;
                              });
                              return;
                            }
                            
                            // Find the organization with the selected ID
                            final selectedOrg = _availableOrganizations.firstWhere(
                              (org) => org.id == value,
                              orElse: () => _availableOrganizations.first,
                            );
                            
                            setState(() {
                              _selectedOrganization = selectedOrg;
                              _companyController.text = selectedOrg.name;
                              _searchController.text = selectedOrg.name;
                            });
                            
                            // Check validation status for the selected organization
                            _checkValidationStatus(selectedOrg.id);
                          },
                        ),
                      ],
                      
                      if (_selectedOrganization != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, size: 20, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'This work experience will be linked to ${_selectedOrganization!.name} and will require validation.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  // Helper method to format organization address
  String _formatOrgAddress(OrganizationAddress address) {
    final parts = <String>[];
    
    if (address.city != null && address.city!.isNotEmpty) {
      parts.add(address.city!);
    }
    
    if (address.stateProvince != null && address.stateProvince!.isNotEmpty) {
      parts.add(address.stateProvince!);
    }
    
    if (address.country != null && address.country!.isNotEmpty) {
      parts.add(address.country!);
    }
    
    return parts.isEmpty ? 'No location available' : parts.join(', ');
  }
}
