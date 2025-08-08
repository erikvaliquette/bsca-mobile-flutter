import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bsca_mobile_flutter/models/organization_model.dart';
import 'package:bsca_mobile_flutter/models/organization_membership_model.dart';
import 'package:bsca_mobile_flutter/models/sdg_goal.dart';
import 'package:bsca_mobile_flutter/providers/auth_provider.dart';
import 'package:bsca_mobile_flutter/providers/organization_provider.dart';
import 'package:bsca_mobile_flutter/providers/organization_sdg_provider.dart';
import 'package:bsca_mobile_flutter/services/organization_service.dart';
import 'package:bsca_mobile_flutter/services/organization_sdg_service.dart';
import 'package:bsca_mobile_flutter/services/validation_service.dart';
import 'package:bsca_mobile_flutter/services/lei_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bsca_mobile_flutter/screens/organization/carbon_footprint_screen.dart';
import 'package:bsca_mobile_flutter/screens/organization/team_members_screen.dart';
import 'package:bsca_mobile_flutter/screens/organization/activities_screen.dart';
import 'package:bsca_mobile_flutter/screens/organization/validation_requests_screen.dart';
import 'package:bsca_mobile_flutter/screens/organization/organization_sdg_selection_screen.dart';
import 'package:bsca_mobile_flutter/screens/sdg/sdg_targets_screen.dart';
import 'package:bsca_mobile_flutter/screens/carbon_calculator/carbon_calculator_screen.dart';
import 'package:bsca_mobile_flutter/widgets/sdg_icon_widget.dart';
import 'package:intl/intl.dart';
import 'package:bsca_mobile_flutter/services/organization_carbon_footprint_service.dart';
import 'package:bsca_mobile_flutter/models/organization_carbon_footprint_model.dart';

class OrganizationProfileScreen extends StatefulWidget {
  final Organization organization;

  const OrganizationProfileScreen({
    super.key,
    required this.organization,
  });

  @override
  State<OrganizationProfileScreen> createState() => _OrganizationProfileScreenState();
}

class _OrganizationProfileScreenState extends State<OrganizationProfileScreen> {
  // Add keys to force FutureBuilder refresh
  Key _teamMembersKey = UniqueKey();
  Key _validationStatsKey = UniqueKey();
  Key _sdgFocusAreasKey = UniqueKey();
  bool _isAdmin = false;
  bool _isEditMode = false; // Toggle for SDG edit mode
  late Organization _organization;
  
  void _refreshData() async {
    setState(() {
      _teamMembersKey = UniqueKey();
      _validationStatsKey = UniqueKey();
      _sdgFocusAreasKey = UniqueKey();
    });
    _checkAdminStatus();
    await _reloadOrganization();
  }
  
  Future<void> _reloadOrganization() async {
    debugPrint('Reloading organization data for ${widget.organization.id}');
    final updatedOrg = await OrganizationService.instance.getOrganizationById(widget.organization.id);
    if (updatedOrg != null && mounted) {
      setState(() {
        _organization = updatedOrg;
        debugPrint('Organization reloaded with ${updatedOrg.sdgFocusAreas?.length ?? 0} SDG focus areas');
      });
    }
  }
  
  @override
  void initState() {
    super.initState();
    _organization = widget.organization;
    _checkAdminStatus();
    _initializeOrganizationSdgProvider();
    _reloadOrganization(); // Load the latest data including SDG focus areas
  }
  
  // Initialize the organization SDG provider
  Future<void> _initializeOrganizationSdgProvider() async {
    // Use addPostFrameCallback to access context safely after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_organization.id.isNotEmpty) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.user?.id;
        if (userId != null) {
          try {
            final organizationSdgProvider = Provider.of<OrganizationSdgProvider>(context, listen: false);
            await organizationSdgProvider.init(_organization.id, userId);
          } catch (e) {
            debugPrint('Error initializing organization SDG provider: $e');
          }
        }
      }
    });
  }
  
  Future<void> _checkAdminStatus() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    if (userId != null) {
      debugPrint('Checking admin status for user $userId in organization ${widget.organization.id}');
      final isAdmin = await OrganizationSdgService.instance.isUserOrganizationAdmin(
        userId, 
        widget.organization.id
      );
      debugPrint('Admin check result: $isAdmin');
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          debugPrint('_isAdmin set to: $_isAdmin');
        });
      }
    } else {
      debugPrint('No user ID available for admin check');
    }
  }

  // Helper method to build SDG icons in view mode
  List<Widget> _buildViewModeSDGs() {
    // Get the organization SDG provider
    final organizationSdgProvider = Provider.of<OrganizationSdgProvider>(context, listen: true);
    
    // Get selected SDG IDs from the provider
    final selectedSdgIds = organizationSdgProvider.selectedSdgIds;
    
    if (selectedSdgIds.isEmpty) {
      return [const Text('No SDG focus areas selected')];
    }
    
    return selectedSdgIds.map((sdgId) {
      // Convert string ID to int
      final id = int.tryParse(sdgId);
      if (id == null) return const SizedBox.shrink();
      
      // Find the SDG goal by ID
      final sdg = SDGGoal.allGoals.firstWhere(
        (goal) => goal.id == id,
        orElse: () => SDGGoal(
          id: id, 
          name: 'Unknown SDG', 
          color: Colors.grey,
          iconPath: 'assets/images/sdg/placeholder.png',
        ),
      );
      
      return InkWell(
        onTap: () {
          // Navigate to SDG targets screen for this organization's SDG
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SdgTargetsScreen(
                sdg: sdg,
                organizationId: _organization.id,
              ),
            ),
          );
        },
        child: Tooltip(
          message: sdg.name,
          child: SDGIconWidget(
            sdgNumber: sdg.id,
            size: 60,
            showLabel: false,
          ),
        ),
      );
    }).toList();
  }
  
  // Helper method to build SDG icons in edit mode
  List<Widget> _buildEditModeSDGs() {
    // Get the organization SDG provider
    final organizationSdgProvider = Provider.of<OrganizationSdgProvider>(context, listen: true);
    
    // Create a list of all SDGs
    return SDGGoal.allGoals.map((sdg) {
      // Check if this SDG is selected using the provider
      final isSelected = organizationSdgProvider.isSdgSelected(sdg.id);
      
      return InkWell(
        onTap: () {
          if (!_isAdmin) return; // Only admins can toggle
          
          // Toggle this SDG
          _toggleSDG(sdg.id.toString());
        },
        child: Stack(
          children: [
            Opacity(
              opacity: isSelected ? 1.0 : 0.5,
              child: Tooltip(
                message: sdg.name,
                child: SDGIconWidget(
                  sdgNumber: sdg.id,
                  size: 60,
                  showLabel: false,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }
  
  // Helper method to toggle an SDG selection
  void _toggleSDG(String sdgId) async {
    if (!_isAdmin) return; // Only admins can toggle
    
    try {
      // Get the organization SDG provider
      final organizationSdgProvider = Provider.of<OrganizationSdgProvider>(context, listen: false);
      
      // Toggle the SDG using the provider - this will update the UI automatically
      // since we're using listen: true in the build methods
      await organizationSdgProvider.toggleSdg(int.parse(sdgId));
      
      // Refresh the organization data to keep everything in sync
      await _reloadOrganization();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating SDG focus areas: $e')),
      );
    }
  }
  
  // Show dialog to edit organization details
  void _showEditOrganizationDialog(BuildContext context) {
    final _nameController = TextEditingController(text: _organization.name);
    final _descriptionController = TextEditingController(text: _organization.description ?? '');
    final _taxNumberController = TextEditingController(text: _organization.taxNumber ?? '');
    final _registrationNumberController = TextEditingController(text: _organization.registrationNumber ?? '');
    final _leiCodeController = TextEditingController(text: _organization.leiCode ?? '');
    final _streetAddressController = TextEditingController(text: _organization.address?.streetAddress ?? '');
    final _cityController = TextEditingController(text: _organization.address?.city ?? '');
    final _stateProvinceController = TextEditingController(text: _organization.address?.stateProvince ?? '');
    final _postalCodeController = TextEditingController(text: _organization.address?.postalCode ?? '');
    final _countryController = TextEditingController(text: _organization.address?.country ?? '');
    final _logoUrlController = TextEditingController(text: _organization.logoUrl ?? '');
    
    String _selectedOrgType = _organization.orgType ?? 'parent';
    String _selectedAddressType = 'Headquarters';
    bool _isSearchingLEI = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Organization'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Organization Name
                  const Text(
                    'Organization Name *',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter organization name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Enter organization description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  // Business Information
                  const Text(
                    'Business Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _taxNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Tax Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _registrationNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Registration Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _leiCodeController,
                          decoration: const InputDecoration(
                            labelText: 'LEI Code',
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSearchingLEI ? null : () async {
                          if (_leiCodeController.text.length == 20) {
                            setState(() => _isSearchingLEI = true);
                            try {
                              final details = await LEIService.searchByLEI(_leiCodeController.text);
                              if (details != null) {
                                setState(() {
                                  _nameController.text = details.name;
                                  if (details.address != null) {
                                    _streetAddressController.text = details.address!.streetAddress ?? '';
                                    _cityController.text = details.address!.city ?? '';
                                    _stateProvinceController.text = details.address!.stateProvince ?? '';
                                    _countryController.text = details.address!.country ?? '';
                                    _postalCodeController.text = details.address!.postalCode ?? '';
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Organization found: ${details.name}'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error searching LEI: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              setState(() => _isSearchingLEI = false);
                            }
                          }
                        },
                        child: _isSearchingLEI 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Primary Address
                  const Text(
                    'Primary Address',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedAddressType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Headquarters', child: Text('Headquarters')),
                      DropdownMenuItem(value: 'Main Office', child: Text('Main Office')),
                      DropdownMenuItem(value: 'Branch', child: Text('Branch')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedAddressType = value!);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _streetAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _stateProvinceController,
                    decoration: const InputDecoration(
                      labelText: 'State/Province',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _postalCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Postal Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Organization Logo
                  const Text(
                    'Organization Logo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement file upload
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logo upload coming soon')),
                      );
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload Logo'),
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
            TextButton(
              onPressed: () async {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Organization name is required')),
                  );
                  return;
                }
                
                // Create address object if any address fields are filled
                OrganizationAddress? address;
                if (_streetAddressController.text.trim().isNotEmpty ||
                    _cityController.text.trim().isNotEmpty ||
                    _stateProvinceController.text.trim().isNotEmpty ||
                    _countryController.text.trim().isNotEmpty ||
                    _postalCodeController.text.trim().isNotEmpty) {
                  address = OrganizationAddress(
                    streetAddress: _streetAddressController.text.trim().isNotEmpty 
                        ? _streetAddressController.text.trim() : null,
                    city: _cityController.text.trim().isNotEmpty 
                        ? _cityController.text.trim() : null,
                    stateProvince: _stateProvinceController.text.trim().isNotEmpty 
                        ? _stateProvinceController.text.trim() : null,
                    country: _countryController.text.trim().isNotEmpty 
                        ? _countryController.text.trim() : null,
                    postalCode: _postalCodeController.text.trim().isNotEmpty 
                        ? _postalCodeController.text.trim() : null,
                  );
                }
                
                // Update organization with new values
                final updatedOrganization = _organization.copyWith(
                  name: _nameController.text.trim(),
                  description: _descriptionController.text.trim().isNotEmpty 
                      ? _descriptionController.text.trim() : null,
                  orgType: _selectedOrgType,
                  taxNumber: _taxNumberController.text.trim().isNotEmpty 
                      ? _taxNumberController.text.trim() : null,
                  registrationNumber: _registrationNumberController.text.trim().isNotEmpty 
                      ? _registrationNumberController.text.trim() : null,
                  leiCode: _leiCodeController.text.trim().isNotEmpty 
                      ? _leiCodeController.text.trim() : null,
                  address: address,
                  logoUrl: _logoUrlController.text.trim().isNotEmpty 
                      ? _logoUrlController.text.trim() : null,
                );
                
                // Store the context before async operations
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigatorContext = context;
                
                // Close the edit dialog first
                Navigator.of(context).pop();
                
                // Show loading dialog
                if (mounted) {
                  showDialog(
                    context: navigatorContext,
                    barrierDismissible: false,
                    builder: (context) => const AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Updating organization...'),
                        ],
                      ),
                    ),
                  );
                }
                
                try {
                  final organizationProvider = Provider.of<OrganizationProvider>(navigatorContext, listen: false);
                  final success = await organizationProvider.updateOrganization(updatedOrganization);
                  
                  if (mounted) {
                    // Close loading dialog
                    Navigator.of(navigatorContext).pop();
                    
                    if (success) {
                      setState(() {
                        _organization = updatedOrganization;
                      });
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Organization updated successfully')),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Failed to update organization')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    // Close loading dialog
                    Navigator.of(navigatorContext).pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Error updating organization: $e')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show confirmation dialog for deleting the organization
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Organization', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text('Are you sure you want to delete ${_organization.name}?'),
            const SizedBox(height: 16),
            const Text(
              'WARNING: This action is permanent and cannot be undone!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Deleting this organization will also remove:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• All organization memberships'),
            const Text('• All SDG focus areas'),
            const Text('• All carbon footprint data'),
            const Text('• All related organization data'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              // Store the context before async operations
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigatorContext = context;
              
              // Close the confirmation dialog first
              Navigator.of(context).pop();
              
              // Show loading indicator
              if (mounted) {
                showDialog(
                  context: navigatorContext,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Deleting organization...'),
                      ],
                    ),
                  ),
                );
              }
              
              try {
                final organizationProvider = Provider.of<OrganizationProvider>(navigatorContext, listen: false);
                final success = await organizationProvider.deleteOrganization(_organization.id);
                
                if (mounted) {
                  // Close loading dialog safely
                  try {
                    Navigator.of(navigatorContext).pop();
                  } catch (navError) {
                    debugPrint('Navigation error closing dialog: $navError');
                  }
                  
                  if (success) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Organization deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    
                    // Navigate back safely with delay
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        try {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        } catch (navError) {
                          debugPrint('Navigation error going back: $navError');
                          // Fallback: just pop once
                          try {
                            Navigator.of(context).pop();
                          } catch (fallbackError) {
                            debugPrint('Fallback navigation error: $fallbackError');
                          }
                        }
                      }
                    });
                  } else {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Failed to delete organization')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  // Close loading dialog safely
                  try {
                    Navigator.of(navigatorContext).pop();
                  } catch (navError) {
                    debugPrint('Navigation error: $navError');
                  }
                  
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error deleting organization: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Profile'),
        actions: _isAdmin ? [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                _showEditOrganizationDialog(context);
              } else if (value == 'delete') {
                _showDeleteConfirmationDialog(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit Organization'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Organization', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ] : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildAboutSection(context),
            const SizedBox(height: 24),
            _buildSDGSection(context),
            const SizedBox(height: 24),
            _buildSustainabilityMetricsSection(context),
            const SizedBox(height: 24),
            _buildCarbonFootprintSection(context),
            const SizedBox(height: 24),
            _buildTeamSection(context),
            const SizedBox(height: 24),
            _buildValidationSection(context),
            const SizedBox(height: 24),
            _buildActivitiesSection(context),
            const SizedBox(height: 24),
            _buildContactSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.organization.logoUrl != null && widget.organization.logoUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  widget.organization.logoUrl!,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        Icons.business,
                        size: 60,
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.business,
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              widget.organization.name,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (widget.organization.locationString != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text(widget.organization.locationString!),
                ],
              ),
            ],
            if (widget.organization.orgType != null) ...[
              const SizedBox(height: 8),
              Text('Organization Type: ${widget.organization.orgType == 'parent' ? 'Parent' : 'Child'}'),
            ],
            if (widget.organization.leiCode != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('LEI: ${widget.organization.leiCode}'),
                  if (widget.organization.vleiStatus == 'verified') ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.security, size: 16, color: Colors.blue),
                    const Text('vLEI', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.organization.description ?? 'No description available.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSDGSection(BuildContext context) {
    return Card(
      key: _sdgFocusAreasKey,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SDG Focus Areas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_isAdmin)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit SDG Focus Areas',
                    onPressed: () {
                      // Toggle between edit mode and view mode
                      setState(() {
                        _isEditMode = !_isEditMode;
                      });
                      
                      // If we're exiting edit mode, refresh the data
                      if (!_isEditMode) {
                        _refreshData();
                      }
                    },
                  ),
              ],
            ),
            if (_isAdmin && _isEditMode)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Tap on SDGs to select or deselect them',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // SDG focus areas display
            Consumer<OrganizationSdgProvider>(
              builder: (context, organizationSdgProvider, _) {
                return Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _isEditMode
                      ? _buildEditModeSDGs()
                      : _buildViewModeSDGs(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSustainabilityMetricsSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sustainability Metrics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.organization.sustainabilityMetrics == null || 
                widget.organization.sustainabilityMetrics!.isEmpty)
              const Text('No sustainability metrics available')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.organization.sustainabilityMetrics!.length,
                itemBuilder: (context, index) {
                  final metric = widget.organization.sustainabilityMetrics![index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _getIconForMetric(metric.name),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                metric.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (metric.description != null && metric.description!.isNotEmpty) ...[
                          Text(
                            metric.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                        ],
                        LinearProgressIndicator(
                          value: metric.target != null && metric.target! > 0
                              ? metric.value / metric.target!
                              : metric.value / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current: ${metric.value}${metric.unit ?? '%'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (metric.target != null)
                              Text(
                                'Target: ${metric.target}${metric.unit ?? '%'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarbonFootprintSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Carbon Footprint',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CarbonCalculatorScreen(
                              organization: widget.organization,
                            ),
                          ),
                        );
                      },
                      child: const Text('Calculate'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<OrganizationCarbonFootprint?>(
              future: OrganizationCarbonFootprintService.instance
                  .getOrganizationCarbonFootprint(widget.organization.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          'Error loading carbon footprint data',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }
                
                final carbonFootprint = snapshot.data;
                
                if (carbonFootprint == null) {
                  return Column(
                    children: [
                      const Icon(Icons.eco, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'No carbon footprint data available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start tracking business trips to see emissions data',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // View Details button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CarbonFootprintScreen(
                                  carbonFootprint: carbonFootprint.toLegacyCarbonFootprint(),
                                ),
                              ),
                            );
                          },
                          child: const Text('View Details'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Total emissions display
                    Row(
                      children: [
                        Icon(
                          Icons.co2,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          carbonFootprint.formattedTotalEmissions,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${carbonFootprint.year})',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Scope breakdown
                    _buildScopeBreakdown(context, carbonFootprint),
                    const SizedBox(height: 16),
                    
                    // Business travel highlight (if any)
                    if ((carbonFootprint.scope3BusinessTravel ?? 0) > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flight, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Business Travel: ${carbonFootprint.scope3BusinessTravel!.toStringAsFixed(3)} ${carbonFootprint.unit}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Reduction goals (if available)
                    if (carbonFootprint.reductionGoal != null && 
                        carbonFootprint.reductionTarget != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Reduction Goal: ${carbonFootprint.reductionGoal}% by ${DateTime.now().year + 5}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: carbonFootprint.totalEmissions > 0 ? 
                          (carbonFootprint.totalEmissions - (carbonFootprint.reductionTarget ?? 0)) / 
                          (carbonFootprint.totalEmissions * (carbonFootprint.reductionGoal ?? 1) / 100) : 0,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current: ${carbonFootprint.formattedTotalEmissions}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Target: ${carbonFootprint.reductionTarget} ${carbonFootprint.unit}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeBreakdown(BuildContext context, OrganizationCarbonFootprint carbonFootprint) {
    final scopeData = [
      {
        'name': 'Scope 1',
        'value': carbonFootprint.scope1Total,
        'color': Colors.red,
        'description': 'Direct emissions',
      },
      {
        'name': 'Scope 2',
        'value': carbonFootprint.scope2Total,
        'color': Colors.orange,
        'description': 'Indirect energy emissions',
      },
      {
        'name': 'Scope 3',
        'value': carbonFootprint.scope3Total,
        'color': Colors.blue,
        'description': 'Other indirect emissions',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emissions by Scope',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...scopeData.map((scope) {
          final percentage = carbonFootprint.totalEmissions > 0
              ? (scope['value'] as double) / carbonFootprint.totalEmissions * 100
              : 0.0;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: scope['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            scope['name'] as String,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(scope['value'] as double).toStringAsFixed(3)} ${carbonFootprint.unit}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Text(
                        scope['description'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(scope['color'] as Color),
                        minHeight: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTeamSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Team',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (widget.organization.teamMembers != null && 
                    widget.organization.teamMembers!.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamMembersScreen(
                            organizationId: widget.organization.id,
                            organizationName: widget.organization.name,
                          ),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<OrganizationMembership>>(
              key: _teamMembersKey,
              future: OrganizationService.instance.getOrganizationMemberships(widget.organization.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Text(
                    'Error loading team members: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[600]),
                  );
                }
                
                final memberships = snapshot.data ?? [];
                final approvedMemberships = memberships
                    .where((m) => m.status == 'approved')
                    .toList();
                
                if (approvedMemberships.isEmpty) {
                  return const Text('No validated team members yet');
                }
                
                return SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: approvedMemberships.length > 5 
                        ? 5 
                        : approvedMemberships.length,
                    itemBuilder: (context, index) {
                      final membership = approvedMemberships[index];
                      final profile = membership.userProfile;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                                      ? NetworkImage(profile.avatarUrl!)
                                      : null,
                                  child: profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty
                                      ? Text(
                                          profile?.displayName.isNotEmpty == true 
                                              ? profile!.displayName.substring(0, 1).toUpperCase()
                                              : profile?.firstName?.isNotEmpty == true
                                                  ? profile!.firstName!.substring(0, 1).toUpperCase()
                                                  : '?',
                                          style: const TextStyle(fontSize: 24),
                                        )
                                      : null,
                                ),
                                if (membership.role == 'admin')
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.star,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profile?.displayName.isNotEmpty == true 
                                  ? profile!.displayName.split(' ').first
                                  : profile?.firstName ?? 'Unknown',
                              style: Theme.of(context).textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (widget.organization.activities != null && 
                    widget.organization.activities!.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivitiesScreen(
                            activities: widget.organization.activities!,
                          ),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.organization.activities == null || 
                widget.organization.activities!.isEmpty)
              const Text('No recent activities available')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.organization.activities!.length > 3 
                    ? 3 
                    : widget.organization.activities!.length,
                itemBuilder: (context, index) {
                  final activity = widget.organization.activities![index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      child: _getIconForActivityType(activity.type),
                    ),
                    title: Text(activity.title),
                    subtitle: Text(
                      DateFormat('MMM d, yyyy').format(activity.date),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Note: Website field is not available in the Organization model
            // Display contact information from address if available
            if (widget.organization.address != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _formatAddress(widget.organization.address!),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              const Text('No contact information available'),
          ],
        ),
      ),
    );
  }

  Icon _getIconForMetric(String metricName) {
    final name = metricName.toLowerCase();
    if (name.contains('energy') || name.contains('renewable')) {
      return const Icon(Icons.bolt, color: Colors.amber);
    } else if (name.contains('water')) {
      return const Icon(Icons.water_drop, color: Colors.blue);
    } else if (name.contains('waste')) {
      return const Icon(Icons.delete_outline, color: Colors.green);
    } else if (name.contains('carbon') || name.contains('emission')) {
      return const Icon(Icons.co2, color: Colors.grey);
    } else {
      return const Icon(Icons.eco, color: Colors.green);
    }
  }

  // Helper method to format organization address
  String _formatAddress(OrganizationAddress address) {
    final parts = <String>[];
    
    if (address.streetAddress != null && address.streetAddress!.isNotEmpty) {
      parts.add(address.streetAddress!);
    }
    
    if (address.city != null && address.city!.isNotEmpty) {
      parts.add(address.city!);
    }
    
    if (address.stateProvince != null && address.stateProvince!.isNotEmpty) {
      parts.add(address.stateProvince!);
    }
    
    if (address.postalCode != null && address.postalCode!.isNotEmpty) {
      parts.add(address.postalCode!);
    }
    
    if (address.country != null && address.country!.isNotEmpty) {
      parts.add(address.country!);
    }
    
    return parts.isEmpty ? 'No address available' : parts.join(', ');
  }

  Icon _getIconForActivityType(String? type) {
    if (type == null) return const Icon(Icons.event);
    
    final activityType = type.toLowerCase();
    if (activityType.contains('event')) {
      return const Icon(Icons.event);
    } else if (activityType.contains('award') || activityType.contains('achievement')) {
      return const Icon(Icons.emoji_events);
    } else if (activityType.contains('initiative') || activityType.contains('project')) {
      return const Icon(Icons.lightbulb);
    } else if (activityType.contains('partnership')) {
      return const Icon(Icons.handshake);
    } else if (activityType.contains('certification')) {
      return const Icon(Icons.verified);
    } else if (activityType.contains('report') || activityType.contains('publication')) {
      return const Icon(Icons.description);
    } else if (activityType.contains('milestone')) {
      return const Icon(Icons.flag);
    } else {
      return const Icon(Icons.star);
    }
  }

  Widget _buildValidationSection(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: OrganizationService.instance.isUserAdminOfOrganization(userId, widget.organization.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Employment Validation',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Manage employment validation requests for your organization.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, int>>(
                  key: _validationStatsKey,
                  future: ValidationService.instance.getValidationStatistics(
                    organizationId: widget.organization.id,
                    adminUserId: userId,
                  ),
                  builder: (context, statsSnapshot) {
                    if (statsSnapshot.hasData && statsSnapshot.data!.isNotEmpty) {
                      final stats = statsSnapshot.data!;
                      final pendingCount = stats['pending'] ?? 0;
                      final totalCount = stats['total'] ?? 0;
                      final approvedCount = stats['approved'] ?? 0;

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(context, 'Total', totalCount.toString(), Colors.blue),
                              _buildStatItem(context, 'Approved', approvedCount.toString(), Colors.green),
                              _buildStatItem(context, 'Pending', pendingCount.toString(), Colors.orange),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ValidationRequestsScreen(
                            organizationId: widget.organization.id,
                            organizationName: widget.organization.name,
                          ),
                        ),
                      );
                      // Refresh data when returning from validation requests
                      if (result == true || result == null) {
                        _refreshData();
                      }
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text('View Validation Requests'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
