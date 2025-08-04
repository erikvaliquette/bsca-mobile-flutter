import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/action_provider.dart';
import '../providers/auth_provider.dart';
import 'dart:developer' as developer;

class FunctionalAddActionDialog extends StatefulWidget {
  final int sdgId;

  const FunctionalAddActionDialog({
    super.key,
    required this.sdgId,
  });

  @override
  State<FunctionalAddActionDialog> createState() => _FunctionalAddActionDialogState();
}

class _FunctionalAddActionDialogState extends State<FunctionalAddActionDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Action'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SDG ID: ${widget.sdgId}'),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createAction,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createAction() async {
    if (_titleController.text.trim().isEmpty || 
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      developer.log('Creating action for SDG ${widget.sdgId}');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final actionProvider = Provider.of<ActionProvider>(context, listen: false);
      
      final userId = authProvider.user?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      developer.log('User ID: $userId');

      final action = await actionProvider.createAction(
        userId: userId,
        sdgId: widget.sdgId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: 'personal', // Default category
        priority: 'medium', // Default priority
      );

      developer.log('Action created: ${action != null}');

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      developer.log('Error creating action: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
