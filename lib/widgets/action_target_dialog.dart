import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/action_item.dart';
import '../providers/action_provider.dart';

class ActionTargetDialog extends StatefulWidget {
  final ActionItem action;

  const ActionTargetDialog({
    Key? key,
    required this.action,
  }) : super(key: key);

  @override
  State<ActionTargetDialog> createState() => _ActionTargetDialogState();
}

class _ActionTargetDialogState extends State<ActionTargetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _methodController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30)); // Default: 30 days from now
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Pre-fill with existing data if available
    if (widget.action.targetValue != null) {
      _valueController.text = widget.action.targetValue.toString();
    }
    if (widget.action.targetDate != null) {
      _targetDate = widget.action.targetDate!;
    }
    if (widget.action.verificationMethod != null) {
      _methodController.text = widget.action.verificationMethod!;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _methodController.dispose();
    super.dispose();
  }

  Future<void> _saveTarget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final actionProvider = Provider.of<ActionProvider>(context, listen: false);
      final double targetValue = double.parse(_valueController.text);
      
      // Validate that target is different from baseline if baseline exists
      if (widget.action.baselineValue != null) {
        if (targetValue == widget.action.baselineValue) {
          setState(() {
            _errorMessage = 'Target value must be different from baseline value';
            _isLoading = false;
          });
          return;
        }
      }
      
      // Update the action with target data
      final updatedAction = widget.action.copyWith(
        targetValue: targetValue,
        targetDate: _targetDate,
        verificationMethod: _methodController.text.isNotEmpty ? _methodController.text : null,
        updatedAt: DateTime.now(),
      );
      
      await actionProvider.updateAction(updatedAction);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Target saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
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
    // Get the unit from the action if available
    final String? unit = widget.action.baselineUnit;
    
    return AlertDialog(
      title: const Text('Set Target'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target value field
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: 'Target Value',
                  hintText: 'Enter your goal value',
                  suffixText: unit,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target value';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Target date picker
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2050),
                  );
                  if (picked != null && picked != _targetDate) {
                    setState(() {
                      _targetDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Target Date',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('yyyy-MM-dd').format(_targetDate)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Verification method field
              TextFormField(
                controller: _methodController,
                decoration: const InputDecoration(
                  labelText: 'Verification Method',
                  hintText: 'How will you verify this target is met?',
                ),
                maxLines: 2,
              ),
              
              // Show baseline info if available
              if (widget.action.baselineValue != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Current baseline: ${widget.action.baselineValue} ${unit ?? ''}',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
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
          onPressed: _isLoading ? null : _saveTarget,
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
