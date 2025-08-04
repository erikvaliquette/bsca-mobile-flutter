import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/action_item.dart';
import '../models/action_measurement.dart';
import '../providers/action_provider.dart';
import '../services/action_measurement_service.dart';

class ActionMeasurementDialog extends StatefulWidget {
  final ActionItem action;
  final bool isInitialSetup; // True if setting up baseline/target, false if adding a measurement

  const ActionMeasurementDialog({
    Key? key,
    required this.action,
    this.isInitialSetup = false,
  }) : super(key: key);

  @override
  State<ActionMeasurementDialog> createState() => _ActionMeasurementDialogState();
}

class _ActionMeasurementDialogState extends State<ActionMeasurementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedUnit;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  // Common units for sustainability measurements
  final List<String> _commonUnits = [
    'kg CO₂e', // Carbon emissions
    'kWh',     // Energy
    'm³',      // Water volume
    'kg',      // Weight
    'items',   // Count
    '%',       // Percentage
    'other'    // Custom unit
  ];

  @override
  void initState() {
    super.initState();
    
    // Pre-fill with existing data if available
    if (widget.isInitialSetup && widget.action.baselineValue != null) {
      _valueController.text = widget.action.baselineValue.toString();
      _selectedUnit = widget.action.baselineUnit;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final actionProvider = Provider.of<ActionProvider>(context, listen: false);
      final double value = double.parse(_valueController.text);
      
      if (widget.isInitialSetup) {
        // Save baseline and target data
        final now = DateTime.now();
        
        // Update the action with baseline data
        final updatedAction = widget.action.copyWith(
          baselineValue: value,
          baselineUnit: _selectedUnit,
          baselineDate: _selectedDate,
          baselineMethodology: _notesController.text.isNotEmpty ? _notesController.text : null,
          updatedAt: now,
        );
        
        await actionProvider.updateAction(updatedAction);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Baseline data saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Create a new measurement
        final String measurementId = const Uuid().v4();
        
        // Check if this measurement represents meaningful change
        if (!ActionMeasurementService.isMeaningfulChange(widget.action, value)) {
          setState(() {
            _errorMessage = 'This change is too small to be meaningful. Please enter a more significant value.';
            _isLoading = false;
          });
          return;
        }
        
        final measurement = ActionMeasurement(
          id: measurementId,
          actionId: widget.action.id,
          date: _selectedDate,
          value: value,
          unit: _selectedUnit,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
        
        // Save the measurement
        await ActionMeasurementService.createMeasurement(measurement);
        
        // Update action progress
        final updatedAction = await ActionMeasurementService.updateActionProgress(widget.action);
        
        // Refresh action in provider
        await actionProvider.loadUserActions(widget.action.userId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Measurement saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.isInitialSetup ? 'Set Baseline Data' : 'Add Measurement';
    
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Value field
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: widget.isInitialSetup ? 'Baseline Value' : 'Measurement Value',
                  hintText: 'Enter a numeric value',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Unit dropdown
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  hintText: 'Select a unit',
                ),
                items: _commonUnits.map((unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a unit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Date picker
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Notes field
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: widget.isInitialSetup ? 'Methodology/Notes' : 'Notes',
                  hintText: widget.isInitialSetup 
                      ? 'Describe how this baseline was measured'
                      : 'Add any relevant details about this measurement',
                ),
                maxLines: 3,
              ),
              
              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveData,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('SAVE'),
        ),
      ],
    );
  }
}
