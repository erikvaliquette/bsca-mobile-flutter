import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/organization_model.dart';
import '../../providers/organization_provider.dart';
import '../../services/organization_service.dart';
import '../../services/travel_emissions_service.dart';

class TripReconciliationScreen extends StatefulWidget {
  const TripReconciliationScreen({Key? key}) : super(key: key);

  @override
  State<TripReconciliationScreen> createState() => _TripReconciliationScreenState();
}

class _TripReconciliationScreenState extends State<TripReconciliationScreen> {
  bool _isLoading = false;
  String? _selectedOrganizationId;
  List<Organization> _organizations = [];
  int _reconciledCount = 0;
  String _statusMessage = '';
  bool _reconciliationComplete = false;

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  Future<void> _loadOrganizations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Use OrganizationService directly to get user organizations
      final organizationService = OrganizationService.instance;
      final organizations = await organizationService.getOrganizationsForUser(userId);
      
      setState(() {
        _organizations = organizations;
        if (organizations.length == 1) {
          _selectedOrganizationId = organizations.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading organizations: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _reconcileOrphanedTrips() async {
    if (_selectedOrganizationId == null) {
      setState(() {
        _statusMessage = 'Please select an organization first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Reconciling orphaned business trips...';
      _reconciliationComplete = false;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User ID is null');
      }

      final reconciled = await TravelEmissionsService.instance.reconcileOrphanedBusinessTrips(
        userId,
        _selectedOrganizationId!,
      );

      setState(() {
        _reconciledCount = reconciled;
        _statusMessage = 'Successfully reconciled $reconciled orphaned business trips';
        _reconciliationComplete = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error reconciling trips: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Reconciliation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reconcile Orphaned Business Trips',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This tool finds business trips that were never attributed to an organization and creates the proper attribution records.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  if (_organizations.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'You need to be a member of at least one organization to use this feature.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Organization:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          value: _selectedOrganizationId,
                          hint: const Text('Select organization'),
                          isExpanded: true,
                          items: _organizations.map((org) {
                            return DropdownMenuItem<String>(
                              value: org.id,
                              child: Text(org.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedOrganizationId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _reconcileOrphanedTrips,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Start Reconciliation'),
                          ),
                        ),
                      ],
                    ),
                  if (_statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: _reconciliationComplete ? Colors.green[50] : Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              _reconciliationComplete ? Icons.check_circle : Icons.info,
                              color: _reconciliationComplete ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _reconciliationComplete ? Colors.green[900] : Colors.orange[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_reconciliationComplete && _reconciledCount > 0) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'What happens next?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Organization carbon footprint data has been updated\n'
                      '• Trip-organization attribution records have been created\n'
                      '• You can now view the updated emissions in the organization profile',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
