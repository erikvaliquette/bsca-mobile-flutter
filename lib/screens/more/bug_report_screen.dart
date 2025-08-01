import 'package:flutter/material.dart';
import '../../services/bug_report_service.dart';

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stepsController = TextEditingController();
  final _expectedController = TextEditingController();
  final _actualController = TextEditingController();
  final _errorLogsController = TextEditingController();
  
  String _selectedPriority = 'medium';
  bool _isSubmitting = false;
  bool _showOptionalFields = false;

  final BugReportService _bugReportService = BugReportService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stepsController.dispose();
    _expectedController.dispose();
    _actualController.dispose();
    _errorLogsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Bug'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitBugReport,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.red[600]),
                        const SizedBox(width: 8),
                        const Text(
                          'Bug Report',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help us improve SDG Network by reporting bugs you encounter.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Required Fields
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Required Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Bug Title *',
                        hintText: 'Brief description of the issue',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a bug title';
                        }
                        if (value.trim().length < 5) {
                          return 'Title must be at least 5 characters';
                        }
                        return null;
                      },
                      maxLength: 100,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Detailed description of the bug',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        if (value.trim().length < 10) {
                          return 'Description must be at least 10 characters';
                        }
                        return null;
                      },
                      maxLines: 4,
                      maxLength: 1000,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Priority
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.priority_high),
                      ),
                      items: BugReportService.getPriorityOptions()
                          .map((priority) => DropdownMenuItem(
                                value: priority,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(
                                          BugReportService.getPriorityColor(priority)
                                              .replaceFirst('#', '0xFF'),
                                        )),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(priority.toUpperCase()),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Optional Fields Toggle
            Card(
              child: ListTile(
                leading: const Icon(Icons.expand_more),
                title: const Text('Additional Details (Optional)'),
                subtitle: const Text('Provide more context to help us debug'),
                trailing: Switch(
                  value: _showOptionalFields,
                  onChanged: (value) {
                    setState(() {
                      _showOptionalFields = value;
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _showOptionalFields = !_showOptionalFields;
                  });
                },
              ),
            ),
            
            // Optional Fields
            if (_showOptionalFields) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Steps to Reproduce
                      TextFormField(
                        controller: _stepsController,
                        decoration: const InputDecoration(
                          labelText: 'Steps to Reproduce',
                          hintText: '1. Go to...\n2. Click on...\n3. See error',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.list_alt),
                        ),
                        maxLines: 4,
                        maxLength: 500,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Expected Behavior
                      TextFormField(
                        controller: _expectedController,
                        decoration: const InputDecoration(
                          labelText: 'Expected Behavior',
                          hintText: 'What should have happened?',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.check_circle_outline),
                        ),
                        maxLines: 3,
                        maxLength: 300,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Actual Behavior
                      TextFormField(
                        controller: _actualController,
                        decoration: const InputDecoration(
                          labelText: 'Actual Behavior',
                          hintText: 'What actually happened?',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.error_outline),
                        ),
                        maxLines: 3,
                        maxLength: 300,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Error Logs
                      TextFormField(
                        controller: _errorLogsController,
                        decoration: const InputDecoration(
                          labelText: 'Error Logs/Messages',
                          hintText: 'Any error messages you saw',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.code),
                        ),
                        maxLines: 4,
                        maxLength: 1000,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitBugReport,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Bug Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'What happens next?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Your bug report will be reviewed by our development team\n'
                      '• We automatically collect device information to help with debugging\n'
                      '• You\'ll receive updates on the status of your report\n'
                      '• Critical bugs are prioritized for immediate attention',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBugReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final bugReport = await _bugReportService.submitBugReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        stepsToReproduce: _stepsController.text.trim().isEmpty 
            ? null 
            : _stepsController.text.trim(),
        expectedBehavior: _expectedController.text.trim().isEmpty 
            ? null 
            : _expectedController.text.trim(),
        actualBehavior: _actualController.text.trim().isEmpty 
            ? null 
            : _actualController.text.trim(),
        errorLogs: _errorLogsController.text.trim().isEmpty 
            ? null 
            : _errorLogsController.text.trim(),
        priority: _selectedPriority,
      );

      if (bugReport != null && mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Bug Report Submitted'),
              ],
            ),
            content: const Text(
              'Thank you for your bug report! Our development team will review it and get back to you soon.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting bug report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
