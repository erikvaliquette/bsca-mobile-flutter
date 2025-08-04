import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/action_item.dart';
import '../models/action_measurement.dart';

class ActionProgressChart extends StatelessWidget {
  final ActionItem action;
  final List<ActionMeasurement> measurements;
  final bool showBaseline;
  final bool showTarget;

  const ActionProgressChart({
    Key? key,
    required this.action,
    required this.measurements,
    this.showBaseline = true,
    this.showTarget = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If we don't have measurements, show a placeholder
    if (measurements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No measurement data available yet. Add measurements to track your progress.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Sort measurements by date
    final sortedMeasurements = List<ActionMeasurement>.from(measurements)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Create data points for the chart
    final List<FlSpot> measurementSpots = [];
    final List<DateTime> dates = [];
    final List<double> values = [];

    // Add baseline point if available and showBaseline is true
    if (action.baselineValue != null && action.baselineDate != null && showBaseline) {
      dates.add(action.baselineDate!);
      values.add(action.baselineValue!);
    }

    // Add measurement points
    for (var measurement in sortedMeasurements) {
      dates.add(measurement.date);
      values.add(measurement.value);
    }

    // Add target point if available and showTarget is true
    if (action.targetValue != null && action.targetDate != null && showTarget) {
      dates.add(action.targetDate!);
      values.add(action.targetValue!);
    }

    // Sort all dates for proper x-axis
    dates.sort((a, b) => a.compareTo(b));
    
    // Find min and max dates for x-axis scaling
    final minDate = dates.first;
    final maxDate = dates.last;
    final dateRange = maxDate.difference(minDate).inDays;
    
    // Find min and max values for y-axis scaling with 10% padding
    double minValue = values.reduce((a, b) => a < b ? a : b);
    double maxValue = values.reduce((a, b) => a > b ? a : b);
    final valuePadding = (maxValue - minValue) * 0.1;
    minValue -= valuePadding;
    maxValue += valuePadding;

    // Convert dates to x values (days since minDate)
    for (int i = 0; i < dates.length; i++) {
      final xValue = dates[i].difference(minDate).inDays.toDouble();
      final yValue = i < values.length ? values[i].toDouble() : 0.0;
      measurementSpots.add(FlSpot(xValue, yValue));
    }

    // Create spots for baseline and target lines if available
    List<FlSpot>? baselineSpots;
    List<FlSpot>? targetSpots;
    
    if (action.baselineValue != null && showBaseline) {
      baselineSpots = [
        FlSpot(0, action.baselineValue!.toDouble()),
        FlSpot(dateRange.toDouble(), action.baselineValue!.toDouble()),
      ];
    }
    
    if (action.targetValue != null && showTarget) {
      targetSpots = [
        FlSpot(0, action.targetValue!.toDouble()),
        FlSpot(dateRange.toDouble(), action.targetValue!.toDouble()),
      ];
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Chart',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Chart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        // Convert x value back to date
                        final date = minDate.add(Duration(days: value.toInt()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('MM/dd').format(date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: dateRange.toDouble(),
                minY: minValue,
                maxY: maxValue,
                lineBarsData: [
                  // Main measurements line
                  LineChartBarData(
                    spots: measurementSpots,
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Baseline line (if available)
                  if (baselineSpots != null)
                    LineChartBarData(
                      spots: baselineSpots,
                      isCurved: false,
                      color: Colors.grey,
                      barWidth: 1,
                      isStrokeCapRound: false,
                      dotData: FlDotData(show: false),
                      dashArray: [5, 5], // Dashed line
                    ),
                  // Target line (if available)
                  if (targetSpots != null)
                    LineChartBarData(
                      spots: targetSpots,
                      isCurved: false,
                      color: Colors.green,
                      barWidth: 1,
                      isStrokeCapRound: false,
                      dotData: FlDotData(show: false),
                      dashArray: [5, 5], // Dashed line
                    ),
                ],
              ),
            ),
          ),
          
          // Legend
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Measurements', Theme.of(context).primaryColor),
                if (showBaseline && action.baselineValue != null)
                  _buildLegendItem('Baseline', Colors.grey),
                if (showTarget && action.targetValue != null)
                  _buildLegendItem('Target', Colors.green),
              ],
            ),
          ),
          
          // Unit display
          if (action.baselineUnit != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Unit: ${action.baselineUnit}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
