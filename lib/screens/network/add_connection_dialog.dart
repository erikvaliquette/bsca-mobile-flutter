import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/business_connection_provider.dart';
import '../../services/supabase/supabase_client.dart';
import '../../services/subscription_helper.dart';
import '../../widgets/upgrade_prompt_widget.dart';

class AddConnectionDialog extends StatefulWidget {
  const AddConnectionDialog({super.key});

  @override
  State<AddConnectionDialog> createState() => _AddConnectionDialogState();
}

class _AddConnectionDialogState extends State<AddConnectionDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _searchAndSendRequest() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty && name.isEmpty) {
      setState(() {
        _error = 'Please enter either an email or name to search';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = SupabaseService.client;
      final currentUserId = client.auth.currentUser?.id;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Search for user by email or name
      var query = client.from('profiles').select('id, first_name, last_name, email');

      if (email.isNotEmpty) {
        query = query.eq('email', email);
      } else {
        // Search by name (case insensitive)
        query = query.or('first_name.ilike.%$name%,last_name.ilike.%$name%');
      }

      final searchResults = await query.limit(10);

      if (searchResults.isEmpty) {
        setState(() {
          _error = 'No users found with the provided information';
          _isLoading = false;
        });
        return;
      }

      // If multiple results, show selection dialog
      if (searchResults.length > 1) {
        final selectedUser = await _showUserSelectionDialog(searchResults);
        if (selectedUser != null) {
          await _sendConnectionRequest(selectedUser['id']);
        }
      } else {
        // Single result, send request directly
        await _sendConnectionRequest(searchResults[0]['id']);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _showUserSelectionDialog(List<dynamic> users) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select User'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final fullName = '${user['first_name']} ${user['last_name']}';
                return ListTile(
                  title: Text(fullName),
                  subtitle: Text(user['email'] ?? ''),
                  onTap: () {
                    Navigator.of(context).pop(user);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendConnectionRequest(String targetUserId) async {
    try {
      final provider = Provider.of<BusinessConnectionProvider>(context, listen: false);
      await provider.sendConnectionRequest(targetUserId);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request sent successfully!')),
        );
      }
    } catch (e) {
      // Check if the error is due to connection limit
      if (e.toString().contains('CONNECTION_LIMIT_REACHED')) {
        if (mounted) {
          // Show upgrade prompt for connection limit
          showDialog(
            context: context,
            builder: (context) => UpgradePromptWidget(
              featureKey: SubscriptionHelper.FEATURE_UNLIMITED_CONNECTIONS,
              customMessage: 'Free tier is limited to 100 network connections. Upgrade to Professional tier for unlimited connections.',
              isDialog: true,
            ),
          );
        }
      } else {
        // Handle other errors
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Connection'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Search for users by email or name to send a connection request.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter user\'s email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          const Text(
            'OR',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter user\'s name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            enabled: !_isLoading,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _searchAndSendRequest,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Request'),
        ),
      ],
    );
  }
}
