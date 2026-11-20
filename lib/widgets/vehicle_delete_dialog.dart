import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/vehicle.dart';

/// Displays a shadcn confirmation dialog for deleting [vehicle].
/// Returns `true` if the user confirms deletion, `false` or `null` otherwise.
Future<bool?> showVehicleDeleteDialog(
  BuildContext context,
  Vehicle vehicle,
) {
  return showShadDialog<bool>(
    context: context,
    builder: (dialogContext) => ShadDialog.alert(
      title: const Text('Delete Vehicle'),
      description: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'Are you sure you want to delete ${vehicle.vehicleNumber} '
          '(${vehicle.brand} ${vehicle.model})? This action cannot be undone.',
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        ShadButton.destructive(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete Vehicle'),
        ),
      ],
    ),
  );
}
