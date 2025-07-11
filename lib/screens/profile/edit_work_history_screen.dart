import 'package:flutter/material.dart';
import '../../models/profile_model.dart';

class EditWorkHistoryScreen extends StatefulWidget {
  final WorkHistory? workHistory;
  
  const EditWorkHistoryScreen({super.key, this.workHistory});

  @override
  State<EditWorkHistoryScreen> createState() => _EditWorkHistoryScreenState();
}

class _EditWorkHistoryScreenState extends State<EditWorkHistoryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.workHistory != null) {
      _companyController.text = widget.workHistory!.company ?? '';
      _positionController.text = widget.workHistory!.position ?? '';
      _descriptionController.text = widget.workHistory!.description ?? '';
      _startDate = widget.workHistory!.startDate;
      _endDate = widget.workHistory!.endDate;
      _isCurrent = widget.workHistory!.isCurrent ?? false;
    }
  }
  
  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    final workHistory = WorkHistory(
      company: _companyController.text,
      position: _positionController.text,
      description: _descriptionController.text,
      startDate: _startDate,
      endDate: _isCurrent ? null : _endDate,
      isCurrent: _isCurrent,
    );
    
    Navigator.of(context).pop(workHistory);
  }
  
  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
      });
    }
  }
  
  Future<void> _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (pickedDate != null) {
      setState(() {
        _endDate = pickedDate;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workHistory == null ? 'Add Work Experience' : 'Edit Work Experience'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company',
                  hintText: 'Enter company name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a company name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  hintText: 'Enter your job title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a position';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your responsibilities',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Time Period',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(_startDate == null 
                  ? 'Select start date' 
                  : '${_startDate!.month}/${_startDate!.day}/${_startDate!.year}'
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectStartDate,
              ),
              if (!_isCurrent) ListTile(
                title: const Text('End Date'),
                subtitle: Text(_endDate == null 
                  ? 'Select end date' 
                  : '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectEndDate,
              ),
              SwitchListTile(
                title: const Text('I currently work here'),
                value: _isCurrent,
                onChanged: (value) {
                  setState(() {
                    _isCurrent = value;
                    if (value) {
                      _endDate = null;
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
