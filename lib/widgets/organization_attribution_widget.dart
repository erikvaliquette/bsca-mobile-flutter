import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/organization_model.dart';
import '../providers/organization_provider.dart';
import '../services/subscription_helper.dart';

/// Widget for selecting organization attribution for SDG content
/// Based on the travel emissions organization selection pattern
class OrganizationAttributionWidget extends StatefulWidget {
  final String? currentOrganizationId;
  final Function(String? organizationId) onOrganizationSelected;
  final String attributionType; // 'action' only - activities cascade automatically
  final bool isRequired;
  final String? helpText;

  const OrganizationAttributionWidget({
    Key? key,
    this.currentOrganizationId,
    required this.onOrganizationSelected,
    required this.attributionType,
    this.isRequired = false,
    this.helpText,
  }) : super(key: key);

  @override
  State<OrganizationAttributionWidget> createState() => _OrganizationAttributionWidgetState();
}

class _OrganizationAttributionWidgetState extends State<OrganizationAttributionWidget> {
  String? selectedOrganizationId;
  bool isPersonal = true;

  @override
  void initState() {
    super.initState();
    selectedOrganizationId = widget.currentOrganizationId;
    isPersonal = selectedOrganizationId == null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrganizationProvider>(
      builder: (context, organizationProvider, child) {
        final organizations = organizationProvider.organizations;
        
        // Check subscription access with FutureBuilder
        return FutureBuilder<bool>(
          future: _checkAttributionAccess(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            final hasAttributionAccess = snapshot.data ?? false;
            
            if (!hasAttributionAccess) {
              return _buildUpgradePrompt();
            }
            
            return _buildAttributionContent(organizations);
          },
        );
      },
    );
  }

  Widget _buildAttributionContent(List<Organization> organizations) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            if (widget.helpText != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.helpText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 8),
            
            // Personal vs Organizational toggle
            Row(
              children: [
                Expanded(
                  child: _buildAttributionButton(
                    'Personal',
                    isPersonal,
                    () => _setPersonal(true),
                    Icons.person,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAttributionButton(
                    'Organizational',
                    !isPersonal,
                    () => _setPersonal(false),
                    Icons.business,
                  ),
                ),
              ],
            ),
            
            // Organization selection (when organizational is selected)
            if (!isPersonal) ...[
              const SizedBox(height: 12),
              _buildOrganizationSelector(organizations),
            ],
          ],
        );
  }

  Widget _buildAttributionButton(String label, bool isSelected, VoidCallback onTap, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationSelector(List<Organization> organizations) {
    if (organizations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No organizations found. ${widget.attributionType} will be saved as personal.',
                style: TextStyle(color: Colors.orange[800]),
              ),
            ),
          ],
        ),
      );
    }

    if (organizations.length == 1) {
      // Auto-select single organization
      final org = organizations.first;
      if (selectedOrganizationId != org.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            selectedOrganizationId = org.id;
          });
          widget.onOrganizationSelected(org.id);
        });
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 20,
              child: Text(
                org.name.isNotEmpty ? org.name[0].toUpperCase() : 'O',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (org.description != null)
                    Text(
                      org.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(Icons.check_circle, color: Colors.green[600]),
          ],
        ),
      );
    }

    // Multiple organizations - show dropdown
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedOrganizationId,
          hint: const Text('Select Organization'),
          items: organizations.map((org) {
            return DropdownMenuItem<String>(
              value: org.id,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    radius: 16,
                    child: Text(
                      org.name.isNotEmpty ? org.name[0].toUpperCase() : 'O',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          org.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (org.description != null)
                          Text(
                            org.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              selectedOrganizationId = value;
            });
            widget.onOrganizationSelected(value);
          },
        ),
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upgrade, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Upgrade Required',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Organization attribution for ${widget.attributionType}s requires a Professional subscription or higher.',
            style: TextStyle(color: Colors.blue[700]),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              // Navigate to subscription screen
              Navigator.pushNamed(context, '/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _setPersonal(bool personal) {
    setState(() {
      isPersonal = personal;
      if (isPersonal) {
        selectedOrganizationId = null;
      }
    });
    widget.onOrganizationSelected(isPersonal ? null : selectedOrganizationId);
  }

  Future<bool> _checkAttributionAccess() async {
    // Check subscription level for attribution access
    // FREE: No organization attribution
    // PROFESSIONAL+: Can attribute to organizations they're members of
    return await SubscriptionHelper.canAccessFeature(SubscriptionHelper.FEATURE_ORGANIZATION_ACCESS);
  }
}
