import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bsca_mobile_flutter/models/organization_model.dart';
import 'package:bsca_mobile_flutter/providers/organization_provider.dart';
import 'package:bsca_mobile_flutter/services/notifications/notification_provider.dart';
import 'package:bsca_mobile_flutter/screens/organization/organization_profile_screen.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch organization data when the screen loads
    Future.microtask(() async {
      final organizationProvider = Provider.of<OrganizationProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      
      // Fetch organization data
      await organizationProvider.fetchCurrentUserOrganization();
      
      // Fetch pending validation requests to update notification badges
      await organizationProvider.fetchPendingValidationRequests();
      
      // Clear organization notifications when user views the organization screen
      notificationProvider.clearOrganizationNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizations'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOrganizationDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Add Organization',
      ),
      body: Consumer<OrganizationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading organizations',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(provider.error ?? 'Unknown error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.fetchCurrentUserOrganization();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final organizations = provider.organizations;
          if (organizations.isEmpty) {
            return const Center(
              child: Text('No organizations available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: organizations.length,
            itemBuilder: (context, index) {
              final organization = organizations[index];
              return _buildOrganizationCard(context, organization);
            },
          );
        },
      ),
    );
  }

  // Show dialog to create a new organization
  void _showCreateOrganizationDialog(BuildContext context) {
    final _nameController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _websiteController = TextEditingController();
    final _locationController = TextEditingController();
    final _orgTypeController = TextEditingController(text: 'parent');
    final _logoUrlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Organization'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'Website'),
              ),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              DropdownButtonFormField<String>(
                value: _orgTypeController.text,
                decoration: const InputDecoration(labelText: 'Organization Type'),
                items: const [
                  DropdownMenuItem(value: 'parent', child: Text('Parent')),
                  DropdownMenuItem(value: 'child', child: Text('Child')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _orgTypeController.text = value;
                  }
                },
              ),
              TextField(
                controller: _logoUrlController,
                decoration: const InputDecoration(labelText: 'Logo URL'),
              ),
            ],
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
              
              // Store the context before async operations
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigatorContext = context;
              
              // Close the create dialog first
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
                        Text('Creating organization...'),
                      ],
                    ),
                  ),
                );
              }
              
              try {
                final organizationProvider = Provider.of<OrganizationProvider>(navigatorContext, listen: false);
                
                final newOrg = await organizationProvider.createOrganization(
                  name: _nameController.text.trim(),
                  description: _descriptionController.text.trim().isNotEmpty 
                      ? _descriptionController.text.trim() : null,
                  website: _websiteController.text.trim().isNotEmpty 
                      ? _websiteController.text.trim() : null,
                  location: _locationController.text.trim().isNotEmpty 
                      ? _locationController.text.trim() : null,
                  orgType: _orgTypeController.text,
                  logoUrl: _logoUrlController.text.trim().isNotEmpty 
                      ? _logoUrlController.text.trim() : null,
                );
                
                if (mounted) {
                  // Close loading dialog
                  Navigator.of(navigatorContext).pop();
                  
                  if (newOrg != null) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Organization created successfully')),
                    );
                    
                    // Navigate to the organization profile screen
                    if (mounted) {
                      Navigator.of(navigatorContext).push(
                        MaterialPageRoute(
                          builder: (context) => OrganizationProfileScreen(
                            organization: newOrg,
                          ),
                        ),
                      );
                    }
                  } else {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Failed to create organization')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  // Close loading dialog
                  Navigator.of(navigatorContext).pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error creating organization: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrganizationCard(BuildContext context, Organization organization) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          // Select this organization and load its details
          await Provider.of<OrganizationProvider>(context, listen: false)
              .selectOrganization(organization);
          
          // Navigate to the organization profile screen
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrganizationProfileScreen(
                  organization: Provider.of<OrganizationProvider>(context).selectedOrganization!,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Organization logo
              if (organization.logoUrl != null && organization.logoUrl!.isNotEmpty)
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    image: DecorationImage(
                      image: NetworkImage(organization.logoUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.business,
                    size: 30,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              
              // Organization details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organization.name,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (organization.location != null && organization.location!.isNotEmpty) ...[  
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              organization.location!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Arrow icon
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
