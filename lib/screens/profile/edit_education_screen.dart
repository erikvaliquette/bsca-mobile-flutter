import 'package:flutter/material.dart';
import '../../models/profile_model.dart';

class EditEducationScreen extends StatefulWidget {
  final Education? education;
  
  const EditEducationScreen({super.key, this.education});

  @override
  State<EditEducationScreen> createState() => _EditEducationScreenState();
}

class _EditEducationScreenState extends State<EditEducationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _institutionController = TextEditingController();
  final _degreeController = TextEditingController();
  final _fieldOfStudyController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.education != null) {
      _institutionController.text = widget.education!.institution ?? '';
      _degreeController.text = widget.education!.degree ?? '';
      _fieldOfStudyController.text = widget.education!.fieldOfStudy ?? '';
      _startDate = widget.education!.startDate;
      _endDate = widget.education!.endDate;
      _isCurrent = widget.education!.isCurrent ?? false;
    }
  }
  
  @override
  void dispose() {
    _institutionController.dispose();
    _degreeController.dispose();
    _fieldOfStudyController.dispose();
    super.dispose();
  }
  
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    final education = Education(
      institution: _institutionController.text,
      degree: _degreeController.text,
      fieldOfStudy: _fieldOfStudyController.text,
      startDate: _startDate,
      endDate: _isCurrent ? null : _endDate,
      isCurrent: _isCurrent,
    );
    
    Navigator.of(context).pop(education);
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
        title: Text(widget.education == null ? 'Add Education' : 'Edit Education'),
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
                controller: _institutionController,
                decoration: const InputDecoration(
                  labelText: 'Institution',
                  hintText: 'Enter school or university name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an institution name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _degreeController,
                decoration: const InputDecoration(
                  labelText: 'Degree',
                  hintText: 'Enter your degree or certificate',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a degree';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fieldOfStudyController,
                decoration: const InputDecoration(
                  labelText: 'Field of Study',
                  hintText: 'Enter your major or field of study',
                ),
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
                title: const Text('I am currently studying here'),
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
