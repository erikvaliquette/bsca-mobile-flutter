import 'package:flutter/material.dart';
import '../../models/profile_model.dart';

class EditCertificationScreen extends StatefulWidget {
  final Certification? certification;
  
  const EditCertificationScreen({super.key, this.certification});

  @override
  State<EditCertificationScreen> createState() => _EditCertificationScreenState();
}

class _EditCertificationScreenState extends State<EditCertificationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _issuingOrgController = TextEditingController();
  final _credentialIdController = TextEditingController();
  final _credentialUrlController = TextEditingController();
  
  DateTime? _issueDate;
  DateTime? _expirationDate;
  bool _noExpiration = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.certification != null) {
      _nameController.text = widget.certification!.name ?? '';
      _issuingOrgController.text = widget.certification!.issuingOrganization ?? '';
      _credentialIdController.text = widget.certification!.credentialId ?? '';
      _credentialUrlController.text = widget.certification!.credentialUrl ?? '';
      _issueDate = widget.certification!.issueDate;
      _expirationDate = widget.certification!.expirationDate;
      _noExpiration = widget.certification!.expirationDate == null;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _issuingOrgController.dispose();
    _credentialIdController.dispose();
    _credentialUrlController.dispose();
    super.dispose();
  }
  
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    final certification = Certification(
      name: _nameController.text,
      issuingOrganization: _issuingOrgController.text,
      issueDate: _issueDate,
      expirationDate: _noExpiration ? null : _expirationDate,
      credentialId: _credentialIdController.text.isNotEmpty ? _credentialIdController.text : null,
      credentialUrl: _credentialUrlController.text.isNotEmpty ? _credentialUrlController.text : null,
    );
    
    Navigator.of(context).pop(certification);
  }
  
  Future<void> _selectIssueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (pickedDate != null) {
      setState(() {
        _issueDate = pickedDate;
      });
    }
  }
  
  Future<void> _selectExpirationDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: _issueDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate != null) {
      setState(() {
        _expirationDate = pickedDate;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.certification == null ? 'Add Certification' : 'Edit Certification'),
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
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Certification Name',
                  hintText: 'Enter certification or license name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a certification name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _issuingOrgController,
                decoration: const InputDecoration(
                  labelText: 'Issuing Organization',
                  hintText: 'Enter the organization that issued this credential',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an issuing organization';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Dates',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Issue Date'),
                subtitle: Text(_issueDate == null 
                  ? 'Select issue date' 
                  : '${_issueDate!.month}/${_issueDate!.day}/${_issueDate!.year}'
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectIssueDate,
              ),
              if (!_noExpiration) ListTile(
                title: const Text('Expiration Date'),
                subtitle: Text(_expirationDate == null 
                  ? 'Select expiration date' 
                  : '${_expirationDate!.month}/${_expirationDate!.day}/${_expirationDate!.year}'
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectExpirationDate,
              ),
              SwitchListTile(
                title: const Text('This certification does not expire'),
                value: _noExpiration,
                onChanged: (value) {
                  setState(() {
                    _noExpiration = value;
                    if (value) {
                      _expirationDate = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Additional Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _credentialIdController,
                decoration: const InputDecoration(
                  labelText: 'Credential ID',
                  hintText: 'Enter credential ID (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _credentialUrlController,
                decoration: const InputDecoration(
                  labelText: 'Credential URL',
                  hintText: 'Enter URL to verify this credential (optional)',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
