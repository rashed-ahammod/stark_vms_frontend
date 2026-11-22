import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/vehicle.dart';

/// Displays a shadcn confirmation dialog for deleting [vehicle].
///
/// [onConfirm] performs the delete and reports whether it succeeded. The dialog
/// stays open and shows progress while it runs, so the user gets feedback
/// instead of a frozen screen, and cannot fire a second delete by
/// double-clicking. Returns `true` when the vehicle was deleted.
Future<bool?> showVehicleDeleteDialog(
  BuildContext context,
  Vehicle vehicle, {
  required Future<bool> Function() onConfirm,
}) {
  return showShadDialog<bool>(
    context: context,
    // Closing mid-request would leave the user with no idea what happened.
    barrierDismissible: false,
    builder: (dialogContext) =>
        _DeleteDialog(vehicle: vehicle, onConfirm: onConfirm),
  );
}

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({required this.vehicle, required this.onConfirm});

  final Vehicle vehicle;
  final Future<bool> Function() onConfirm;

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    final ok = await widget.onConfirm();
    if (!mounted) return;
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog.alert(
      title: const Text('Delete Vehicle'),
      description: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'Are you sure you want to delete ${widget.vehicle.vehicleNumber} '
          '(${widget.vehicle.brand} ${widget.vehicle.model})? '
          'This action cannot be undone.',
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: _isDeleting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ShadButton.destructive(
          onPressed: _isDeleting ? null : _handleDelete,
          leading: _isDeleting
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.trash2, size: 15),
          child: Text(_isDeleting ? 'Deleting...' : 'Delete Vehicle'),
        ),
      ],
    );
  }
}
