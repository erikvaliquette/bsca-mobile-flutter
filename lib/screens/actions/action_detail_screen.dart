import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bsca_mobile_flutter/models/action_item.dart';
import 'package:bsca_mobile_flutter/models/action_measurement.dart';
import 'package:bsca_mobile_flutter/models/sdg_target.dart';
import 'package:bsca_mobile_flutter/models/sdg_target_data.dart';
import 'package:bsca_mobile_flutter/providers/action_provider.dart';
import 'package:bsca_mobile_flutter/providers/auth_provider.dart';
import 'package:bsca_mobile_flutter/providers/organization_provider.dart';
import 'package:bsca_mobile_flutter/providers/sdg_target_provider.dart';
import 'package:bsca_mobile_flutter/services/action_attribution_service.dart';
import 'package:bsca_mobile_flutter/services/action_target_integration_service.dart';
import 'package:bsca_mobile_flutter/services/sdg_target_data_service.dart';
import 'package:bsca_mobile_flutter/services/sdg_target_service.dart';
import 'package:bsca_mobile_flutter/services/supabase/supabase_client.dart';
import 'package:bsca_mobile_flutter/widgets/organization_attribution_widget.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class ActionDetailScreen extends StatefulWidget {
  final ActionItem action;

  const ActionDetailScreen({Key? key, required this.action}) : super(key: key);

  @override
  _ActionDetailScreenState createState() => _ActionDetailScreenState();
}

class _ActionDetailScreenState extends State<ActionDetailScreen> {
  late ActionTargetIntegrationService _integrationService;
  late ActionItem _action;
  SdgTargetData? _targetData;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  final TextEditingController _measurementController = TextEditingController();
  final TextEditingController _baselineController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _action = widget.action;
    
    // Initialize the integration service
    final sdgTargetProvider = Provider.of<SdgTargetProvider>(context, listen: false);
    
    // Create a service instance using the new constructors
    _integrationService = ActionTargetIntegrationService();
    
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load target data if this action is linked to an SDG target
      if (_action.sdgTargetId != null) {
        final targetDataList = await _integrationService.getTargetDataForAction(_action);
        setState(() {
          _targetData = targetDataList.isNotEmpty ? targetDataList.first : null;
        });
      } else {
        setState(() {
          _targetData = null;
        });
      }
      
      // Set initial values for controllers
      if (_action.baselineValue != null) {
        _baselineController.text = _action.baselineValue.toString();
      }
      
      if (_action.targetValue != null) {
        _targetController.text = _action.targetValue.toString();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addMeasurement() async {
    if (_measurementController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a measurement value')),
      );
      return;
    }

    final value = double.tryParse(_measurementController.text);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new measurement
      final measurement = ActionMeasurement(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
        actionId: _action.id,
        value: value,
        date: DateTime.now(),
        notes: 'Measurement added via Action Detail Screen',
      );

      // If the action is linked to an SDG target, record the measurement there too
      if (_action.sdgTargetId != null) {
        await _integrationService.recordActionMeasurement(_action, measurement);
      }

      // Update the action with the new measurement
      final measurements = _action.measurements?.toList() ?? [];
      measurements.add(measurement);
      
      // TODO: Update the action in the database with the new measurement
      // This would typically be done through an ActionService

      setState(() {
        _action = _action.copyWith(measurements: measurements);
        _measurementController.clear();
      });

      // Reload target data to show the new measurement
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Measurement added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add measurement: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBaseline() async {
    if (_baselineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a baseline value')),
      );
      return;
    }

    final value = double.tryParse(_baselineController.text);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // If the action is linked to an SDG target, update the baseline there too
      if (_action.sdgTargetId != null) {
        await _integrationService.updateTargetBaseline(_action, value);
      }

      // Update the action with the new baseline
      setState(() {
        _action = _action.copyWith(baselineValue: value);
      });

      // TODO: Update the action in the database with the new baseline
      // This would typically be done through an ActionService

      // Reload target data to show the updated baseline
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baseline updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update baseline: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTarget() async {
    if (_targetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a target value')),
      );
      return;
    }

    final value = double.tryParse(_targetController.text);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // If the action is linked to an SDG target, update the target there too
      if (_action.sdgTargetId != null) {
        await _integrationService.updateTargetValue(_action, value);
      }

      // Update the action with the new target
      setState(() {
        _action = _action.copyWith(targetValue: value);
      });

      // TODO: Update the action in the database with the new target
      // This would typically be done through an ActionService

      // Reload target data to show the updated target
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update target: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_action.title),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(child: Text('Error: $_errorMessage'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action details section
          _buildActionDetails(),
          const Divider(height: 32),
          
          // Attribution section
          _buildAttributionSection(),
          const Divider(height: 32),
          
          // Tracking section
          _buildTrackingSection(),
          const Divider(height: 32),
          
          // Measurements section
          _buildMeasurementsSection(),
          const SizedBox(height: 24),
          
          // SDG Target Data section (if applicable)
          if (_action.sdgTargetId != null) ...[
            _buildSdgTargetSection(),
            const Divider(height: 32),
          ],
          
          // Chart section (if there are measurements)
          if (_action.measurements != null && _action.measurements!.isNotEmpty) ...[
            _buildChartSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildActionDetails() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            // Description
            if (_action.description.isNotEmpty) ...[
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_action.description),
              const SizedBox(height: 8),
            ],
            
            // Category
            Row(
              children: [
                const Text(
                  'Category:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(_action.category),
              ],
            ),
            const SizedBox(height: 4),
            
            // Priority
            Row(
              children: [
                const Text(
                  'Priority:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(_action.priority.toUpperCase()),
              ],
            ),
            const SizedBox(height: 4),
            
            // Due date
            if (_action.dueDate != null) ...[
              Row(
                children: [
                  const Text(
                    'Due Date:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(DateFormat('MMM d, yyyy').format(_action.dueDate!)),
                ],
              ),
            ],
            
            // Organization
            if (_action.organizationId != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'Organization Action:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Text('Yes'),
                ],
              ),
            ],
            
            // SDG Target
            if (_action.sdgTarget != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'SDG Target:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_action.sdgTarget!.description)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sustainability Tracking',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Baseline
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _baselineController,
                    decoration: const InputDecoration(
                      labelText: 'Baseline Value',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _updateBaseline,
                  child: const Text('Update Baseline'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Target
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetController,
                    decoration: const InputDecoration(
                      labelText: 'Target Value',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _updateTarget,
                  child: const Text('Update Target'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Unit
            Text(
              'Unit: ${_action.baselineUnit ?? 'Not specified'}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Measurements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Add new measurement
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _measurementController,
                    decoration: const InputDecoration(
                      labelText: 'New Measurement',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addMeasurement,
                  child: const Text('Add Measurement'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Measurements list
            if (_action.measurements == null || _action.measurements!.isEmpty) ...[
              const Center(
                child: Text(
                  'No measurements recorded yet',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _action.measurements!.length,
                itemBuilder: (context, index) {
                  final measurement = _action.measurements![index];
                  return ListTile(
                    title: Text('${measurement.value} ${_action.baselineUnit ?? ''}'),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(measurement.date)),
                    trailing: measurement.notes != null && measurement.notes!.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Measurement Notes'),
                                  content: Text(measurement.notes!),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : null,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSdgTargetSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SDG Target Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Display SDG target details if available
            if (_action.sdgTarget != null) ...[  
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SDG ${_action.sdgTarget!.sdgId}.${_action.sdgTarget!.targetNumber}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _action.sdgTarget!.description,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (_action.sdgTarget!.description != null && _action.sdgTarget!.description!.isNotEmpty) ...[  
                      const SizedBox(height: 8),
                      Text(
                        _action.sdgTarget!.description!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            Text(
              'Target Data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            if (_targetData.isEmpty) ...[
              const Center(
                child: Text(
                  'No SDG target data available',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _targetData.length,
                itemBuilder: (context, index) {
                  final data = _targetData[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data.month.displayName} ${data.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          
                          // Baseline
                          if (data.baseline != null) ...[
                            Row(
                              children: [
                                const Text('Baseline: '),
                                Text(
                                  '${data.baseline} ${_action.baselineUnit ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                          
                          // Target
                          if (data.target != null) ...[
                            Row(
                              children: [
                                const Text('Target: '),
                                Text(
                                  '${data.target} ${_action.baselineUnit ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                          
                          // Actual
                          if (data.actual != null) ...[
                            Row(
                              children: [
                                const Text('Actual: '),
                                Text(
                                  '${data.actual} ${_action.baselineUnit ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                          
                          // Progress indicator if both target and actual exist
                          if (data.target != null && data.actual != null) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: data.actual! / data.target!,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                data.actual! >= data.target!
                                    ? Colors.green
                                    : Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${((data.actual! / data.target!) * 100).toStringAsFixed(1)}% of target',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    // Sort measurements by date
    final measurements = List<ActionMeasurement>.from(_action.measurements!)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    // Create chart data points
    final spots = measurements
        .map((m) => FlSpot(
              m.date.millisecondsSinceEpoch.toDouble(),
              m.value,
            ))
        .toList();
    
    // Calculate min and max dates for the X axis
    final minDate = measurements.first.date;
    final maxDate = measurements.last.date;
    final dateRange = maxDate.difference(minDate).inDays;
    
    // Calculate Y axis range
    double minY = measurements.map((m) => m.value).reduce((a, b) => a < b ? a : b);
    double maxY = measurements.map((m) => m.value).reduce((a, b) => a > b ? a : b);
    
    // Add baseline and target to the chart if they exist
    List<HorizontalLine> horizontalLines = [];
    
    if (_action.baselineValue != null) {
      horizontalLines.add(
        HorizontalLine(
          y: _action.baselineValue!,
          color: Colors.red,
          strokeWidth: 1,
          dashArray: [5, 5],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 5, bottom: 5),
            style: const TextStyle(color: Colors.red, fontSize: 10),
            labelResolver: (line) => 'Baseline: ${_action.baselineValue}',
          ),
        ),
      );
      
      // Adjust Y axis range to include baseline
      minY = minY < _action.baselineValue! ? minY : _action.baselineValue!;
      maxY = maxY > _action.baselineValue! ? maxY : _action.baselineValue!;
    }
    
    if (_action.targetValue != null) {
      horizontalLines.add(
        HorizontalLine(
          y: _action.targetValue!,
          color: Colors.green,
          strokeWidth: 1,
          dashArray: [5, 5],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 5, bottom: 5),
            style: const TextStyle(color: Colors.green, fontSize: 10),
            labelResolver: (line) => 'Target: ${_action.targetValue}',
          ),
        ),
      );
      
      // Adjust Y axis range to include target
      minY = minY < _action.targetValue! ? minY : _action.targetValue!;
      maxY = maxY > _action.targetValue! ? maxY : _action.targetValue!;
    }
    
    // Add some padding to Y axis range
    final yPadding = (maxY - minY) * 0.1;
    minY -= yPadding;
    maxY += yPadding;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Chart',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTextStyles: (context, value) => const TextStyle(
                        color: Color(0xff68737d),
                        fontSize: 10,
                      ),
                      getTitles: (value) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return DateFormat('MMM d').format(date);
                      },
                      margin: 8,
                    ),
                    leftTitles: SideTitles(
                      showTitles: true,
                      getTextStyles: (context, value) => const TextStyle(
                        color: Color(0xff67727d),
                        fontSize: 10,
                      ),
                      getTitles: (value) {
                        return value.toStringAsFixed(1);
                      },
                      reservedSize: 28,
                      margin: 12,
                    ),
                    rightTitles: SideTitles(showTitles: false),
                    topTitles: SideTitles(showTitles: false),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xff37434d), width: 1),
                  ),
                  minX: minDate.millisecondsSinceEpoch.toDouble(),
                  maxX: maxDate.millisecondsSinceEpoch.toDouble(),
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      colors: [Theme.of(context).primaryColor],
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(horizontalLines: horizontalLines),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributionSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            // Show inherited attribution from parent Target
            if (_targetData?.target?.organizationId == null) ..[
              // No attribution - personal action (inherited from target)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Action',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Attribution inherited from Target: Personal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ..[              // Has organizational attribution - show inherited from target
              FutureBuilder<Map<String, dynamic>?>(
                future: _getOrganizationInfo(_targetData!.target!.organizationId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      child: const CircularProgressIndicator(),
                    );
                  }
                  
                  final orgInfo = snapshot.data;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.business, color: Colors.green[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                orgInfo?['name'] ?? 'Organization',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                              if (orgInfo?['description'] != null)
                                Text(
                                  orgInfo!['description'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Text(
                                'Attribution inherited from Target',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            
            // Note: Attribution is managed at the Target level
            // Actions inherit attribution from their parent Target
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attribution is managed at the Target level and inherited by all Actions and Activities.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Remove old attribution edit section
            if (false) ..[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Manage Attribution',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              OrganizationAttributionWidget(
                currentOrganizationId: _attributions.isNotEmpty 
                    ? _attributions.first.organizationId 
                    : null,
                onOrganizationSelected: (organizationId) {
                  _handleAttributionChange(organizationId);
                },
                attributionType: 'action',
                helpText: 'Change the attribution of this action between personal and organizational.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Attribution is now managed at the Target level
  // This method is no longer needed since actions inherit attribution from their parent target

  /// Get organization information for display
  Future<Map<String, dynamic>?> _getOrganizationInfo(String organizationId) async {
    try {
      final response = await Supabase.instance.client
          .from('organizations')
          .select('id, name, description')
          .eq('id', organizationId)
          .single();
      return response;
    } catch (e) {
      debugPrint('Error fetching organization info: $e');
      return null;
    }
  }
}
