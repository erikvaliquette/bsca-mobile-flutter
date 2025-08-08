import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/organization_provider.dart';
import '../../services/lei_service.dart';
import 'organization_profile_screen.dart';

class CreateOrganizationScreen extends StatelessWidget {
  const CreateOrganizationScreen({super.key});

  Future<void> _searchLEI(BuildContext context, StateSetter setState, 
      TextEditingController leiController, 
      TextEditingController nameController, 
      TextEditingController descriptionController,
      ValueNotifier<bool> isSearchingLEI) async {
    
    final leiCode = leiController.text.trim();
    if (leiCode.length != 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('LEI code must be exactly 20 characters')),
      );
      return;
    }

    setState(() {
      isSearchingLEI.value = true;
    });

    try {
      final leiDetails = await LEIService.searchByLEI(leiCode);
      
      setState(() {
        isSearchingLEI.value = false;
      });

      if (leiDetails != null) {
        // Auto-fill form fields with LEI data
        nameController.text = leiDetails.name;
        
        // Create description from LEI details
        String description = 'Organization imported from LEI registry.\n';
        if (leiDetails.address != null) {
          final addr = leiDetails.address!;
          description += 'Address: ';
          if (addr.streetAddress != null) description += '${addr.streetAddress}, ';
          if (addr.city != null) description += '${addr.city}, ';
          if (addr.stateProvince != null) description += '${addr.stateProvince}, ';
          if (addr.country != null) description += '${addr.country}';
          description += '\n';
        }
        if (leiDetails.status.isNotEmpty) {
          description += 'LEI Status: ${leiDetails.status}\n';
        }
        if (leiDetails.vleiStatus != 'none') {
          description += 'vLEI Status: ${leiDetails.vleiStatus}';
        }
        
        descriptionController.text = description.trim();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found: ${leiDetails.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No organization found for this LEI code'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isSearchingLEI.value = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching LEI: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final leiController = TextEditingController();
    final isSearchingLEI = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Organization'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: isSearchingLEI,
                  builder: (context, isSearching, child) => TextField(
                    controller: leiController,
                    decoration: InputDecoration(
                      labelText: 'LEI Code (Optional)',
                      hintText: 'Enter 20-character LEI code',
                      suffixIcon: isSearching 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : leiController.text.length == 20
                              ? IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: () => _searchLEI(context, setState, leiController, nameController, descriptionController, isSearchingLEI),
                                )
                              : null,
                    ),
                    maxLength: 20,
                    onChanged: (value) {
                      setState(() {}); // Refresh to show/hide search button
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Organization Name *',
                    hintText: 'Enter organization name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter organization description',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Organization name is required')),
                  );
                  return;
                }

                final organizationProvider = Provider.of<OrganizationProvider>(context, listen: false);
                
                try {
                  final newOrg = await organizationProvider.createOrganization(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isNotEmpty 
                        ? descriptionController.text.trim() : null,
                    orgType: 'parent',
                    leiCode: leiController.text.trim().isNotEmpty 
                        ? leiController.text.trim() : null,
                  );
                  
                  Navigator.of(dialogContext).pop(); // Close dialog
                  
                  if (newOrg != null) {
                    // Always refresh the organization list first
                    await organizationProvider.fetchCurrentUserOrganization();
                    
                    // Check if the widget is still mounted before showing snackbar
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Organization created successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    
                    // Navigate to the organization profile and replace this screen
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => OrganizationProfileScreen(organization: newOrg),
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to create organization - please try again'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('Organization creation error: $e');
                  
                  // Still try to refresh in case the org was created but membership failed
                  try {
                    await organizationProvider.fetchCurrentUserOrganization();
                  } catch (refreshError) {
                    debugPrint('Error refreshing after failed creation: $refreshError');
                  }
                  
                  String errorMessage = 'Error creating organization';
                  if (e.toString().contains('row-level security policy')) {
                    errorMessage = 'Organization created but membership setup failed. Please contact support.';
                  } else if (e.toString().contains('already exists')) {
                    errorMessage = 'An organization with this name already exists';
                  }
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Organization'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Create New Organization',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap the button below to create a new organization',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Organization'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
