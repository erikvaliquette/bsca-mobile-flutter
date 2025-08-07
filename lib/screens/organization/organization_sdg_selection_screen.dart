import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bsca_mobile_flutter/models/sdg_goal.dart';
import 'package:bsca_mobile_flutter/providers/organization_sdg_provider.dart';
import 'package:bsca_mobile_flutter/providers/auth_provider.dart';
import 'package:bsca_mobile_flutter/widgets/sdg_icon_widget.dart';

class OrganizationSdgSelectionScreen extends StatefulWidget {
  final String organizationId;
  final String organizationName;

  const OrganizationSdgSelectionScreen({
    Key? key, 
    required this.organizationId,
    required this.organizationName,
  }) : super(key: key);

  @override
  _OrganizationSdgSelectionScreenState createState() => _OrganizationSdgSelectionScreenState();
}

class _OrganizationSdgSelectionScreenState extends State<OrganizationSdgSelectionScreen> {
  // Use the predefined list of SDG goals from the model
  final List<SDGGoal> _sdgGoals = SDGGoal.allGoals;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize the provider when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  Future<void> _initializeProvider() async {
    if (!_isInitialized) {
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      if (userId != null) {
        await Provider.of<OrganizationSdgProvider>(context, listen: false)
            .init(widget.organizationId, userId);
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.organizationName} SDG Focus Areas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select SDGs for your organization to focus on',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'These SDGs will be displayed on your organization profile and can be used for attribution in sustainability actions.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<OrganizationSdgProvider>(
              builder: (context, orgSdgProvider, child) {
                if (!_isInitialized || orgSdgProvider.isLoading) {
                  return const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (!orgSdgProvider.isAdmin) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Only organization administrators can modify SDG focus areas',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                if (orgSdgProvider.error != null) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${orgSdgProvider.error}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              orgSdgProvider.loadOrganizationSdgFocusAreas();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _sdgGoals.length,
                    itemBuilder: (context, index) {
                      final sdg = _sdgGoals[index];
                      final isSelected = orgSdgProvider.isSdgSelected(sdg.id);
                      return _buildSdgCard(sdg, isSelected);
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

  Widget _buildSdgCard(SDGGoal sdg, [bool isSelected = false]) {
    return InkWell(
      onTap: () {
        _toggleSdgSelection(sdg.id);
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected ? BorderSide(color: sdg.color, width: 3) : BorderSide.none,
        ),
        color: isSelected ? sdg.color.withOpacity(0.1) : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SDGIconWidget(
              sdgNumber: sdg.id,
              size: 60,
              showLabel: false,
              isSelected: isSelected,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                sdg.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSdgSelection(int sdgId) {
    final orgSdgProvider = Provider.of<OrganizationSdgProvider>(context, listen: false);
    if (orgSdgProvider.isAdmin) {
      orgSdgProvider.toggleSdg(sdgId);
    }
  }
}
