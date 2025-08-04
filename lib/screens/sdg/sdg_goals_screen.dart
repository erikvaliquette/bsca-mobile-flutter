import 'package:flutter/material.dart';
import 'package:bsca_mobile_flutter/models/sdg_goal.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sustainable Development Goals'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select an SDG to manage targets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
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
                  return _buildSdgCard(sdg);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSdgCard(SDGGoal sdg) {
    return InkWell(
      onTap: () => _navigateToTargetsScreen(sdg),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
}
