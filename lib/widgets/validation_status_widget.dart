import 'package:flutter/material.dart';
import 'package:bsca_mobile_flutter/models/organization_membership_model.dart';
import 'package:bsca_mobile_flutter/services/validation_service.dart';

class ValidationStatusWidget extends StatefulWidget {
  final String userId;
  final String? organizationId;
  final String? organizationName;
  final VoidCallback? onValidationRequested;
  final VoidCallback? onValidationCancelled;

  const ValidationStatusWidget({
    super.key,
    required this.userId,
    this.organizationId,
    this.organizationName,
    this.onValidationRequested,
    this.onValidationCancelled,
  });

  @override
  State<ValidationStatusWidget> createState() => _ValidationStatusWidgetState();
}

class _ValidationStatusWidgetState extends State<ValidationStatusWidget> {
  final ValidationService _validationService = ValidationService.instance;
  OrganizationMembership? _membership;
  bool _isLoading = false;
  bool _canRequestValidation = false;

  @override
  void initState() {
    super.initState();
    if (widget.organizationId != null) {
      _checkValidationStatus();
    }
  }

  @override
  void didUpdateWidget(ValidationStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.organizationId != oldWidget.organizationId) {
      if (widget.organizationId != null) {
        _checkValidationStatus();
      } else {
        setState(() {
          _membership = null;
          _canRequestValidation = false;
        });
      }
    }
  }

  Future<void> _checkValidationStatus() async {
    if (widget.organizationId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check current validation status
      final membership = await _validationService.getValidationStatus(
        userId: widget.userId,
        organizationId: widget.organizationId!,
      );

      // Check if user can request validation
      final canRequest = await _validationService.canRequestValidation(
        userId: widget.userId,
        organizationId: widget.organizationId!,
      );

      setState(() {
        _membership = membership;
        _canRequestValidation = canRequest;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error checking validation status: $e');
    }
  }

  Future<void> _requestValidation() async {
    if (widget.organizationId == null || widget.organizationName == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final membership = await _validationService.requestEmploymentValidation(
        userId: widget.userId,
        organizationId: widget.organizationId!,
        role: 'member',
      );

      if (membership != null) {
        setState(() {
          _membership = membership;
          _canRequestValidation = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation request sent to ${widget.organizationName}'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onValidationRequested?.call();
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to send validation request');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error sending validation request: $e');
    }
  }

  Future<void> _cancelValidation() async {
    if (widget.organizationId == null) return;

    final confirmed = await _showConfirmationDialog(
      title: 'Cancel Validation Request',
      content: 'Are you sure you want to cancel your validation request for ${widget.organizationName}?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _validationService.cancelValidationRequest(
        userId: widget.userId,
        organizationId: widget.organizationId!,
      );

      if (success) {
        setState(() {
          _membership = null;
          _canRequestValidation = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Validation request cancelled'),
            backgroundColor: Colors.orange,
          ),
        );

        widget.onValidationCancelled?.call();
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to cancel validation request');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error cancelling validation request: $e');
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.organizationId == null) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 6),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }

    // If user has approved membership, show verified badge
    if (_membership?.isApproved == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              size: 14,
              color: Colors.green,
            ),
            SizedBox(width: 4),
            Text(
              'Verified',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // If user has pending membership, show pending status with cancel option
    if (_membership?.isPending == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hourglass_empty,
              size: 14,
              color: Colors.orange,
            ),
            const SizedBox(width: 4),
            const Text(
              'Pending',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _cancelValidation,
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      );
    }

    // If user has rejected membership, show rejected status
    if (_membership?.isRejected == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.close,
              size: 14,
              color: Colors.red,
            ),
            SizedBox(width: 4),
            Text(
              'Rejected',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // If user can request validation, show request button
    if (_canRequestValidation) {
      return OutlinedButton.icon(
        onPressed: _requestValidation,
        icon: const Icon(Icons.verified_user, size: 16),
        label: const Text(
          'Request Validation',
          style: TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    // Default: no validation available
    return const SizedBox.shrink();
  }
}
