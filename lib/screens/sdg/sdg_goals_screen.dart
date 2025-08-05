import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bsca_mobile_flutter/models/sdg_goal.dart';
import 'package:bsca_mobile_flutter/providers/user_sdg_provider.dart';
import 'package:bsca_mobile_flutter/screens/sdg/sdg_targets_screen.dart';
import 'package:bsca_mobile_flutter/widgets/sdg_icon_widget.dart';

class SdgGoalsScreen extends StatefulWidget {
  const SdgGoalsScreen({Key? key}) : super(key: key);

  @override
  _SdgGoalsScreenState createState() => _SdgGoalsScreenState();
}

class _SdgGoalsScreenState extends State<SdgGoalsScreen> {
  // Use the predefined list of SDG goals from the model
  final List<SDGGoal> _sdgGoals = SDGGoal.allGoals;
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    // Load user's selected SDGs when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserSdgProvider>(context, listen: false).loadUserSdgs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sustainable Development Goals'),
        actions: [
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
              });
            },
            tooltip: _isSelectionMode ? 'Save Selections' : 'Edit Selections',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSelectionMode 
                ? 'Select the SDGs you want to focus on'
                : 'Select an SDG to manage targets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Tap on the goals you want to add to your profile',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 16),
            Consumer<UserSdgProvider>(
              builder: (context, userSdgProvider, child) {
                if (userSdgProvider.isLoading) {
                  return const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
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
                      final isSelected = userSdgProvider.isSdgSelected(sdg.id);
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
        if (_isSelectionMode) {
          _toggleSdgSelection(sdg.id);
        } else {
          _navigateToTargetsScreen(sdg);
        }
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

  void _navigateToTargetsScreen(SDGGoal sdg) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SdgTargetsScreen(sdg: sdg),
      ),
    );
  }

  void _toggleSdgSelection(int sdgId) {
    final userSdgProvider = Provider.of<UserSdgProvider>(context, listen: false);
    userSdgProvider.toggleSdg(sdgId);
  }
}
