import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/vehicle.dart';
import 'vehicle_badges.dart';

Future<void> showVehicleDetailSheet({
  required BuildContext context,
  required Vehicle vehicle,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return showShadSheet<void>(
    context: context,
    side: ShadSheetSide.right,
    builder: (sheetContext) => _VehicleDetailSheet(
      vehicle: vehicle,
      onEdit: () {
        Navigator.of(sheetContext).pop();
        onEdit();
      },
      onDelete: () {
        Navigator.of(sheetContext).pop();
        onDelete();
      },
    ),
  );
}

class _VehicleDetailSheet extends StatelessWidget {
  const _VehicleDetailSheet({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('MMM d, yyyy • h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadSheet(
      constraints: const BoxConstraints(maxWidth: 440),
      title: Row(
        children: [
          VehicleTypeAvatar(type: vehicle.vehicleType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.vehicleNumber,
                  style: theme.textTheme.h4.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${vehicle.brand} ${vehicle.model}',
                  style: theme.textTheme.muted.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      description: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            VehicleStatusBadge(status: vehicle.status),
            VehicleTypeBadge(type: vehicle.vehicleType),
            if (vehicle.id != null)
              ShadBadge.outline(child: Text('ID #${vehicle.id}')),
          ],
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: onEdit,
          leading: const Icon(LucideIcons.pencil, size: 15),
          child: const Text('Edit Vehicle'),
        ),
        ShadButton.destructive(
          onPressed: onDelete,
          leading: const Icon(LucideIcons.trash2, size: 15),
          child: const Text('Delete'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailSection(
              title: 'Specifications',
              items: [
                _DetailItem('Brand', vehicle.brand),
                _DetailItem('Model', vehicle.model),
                _DetailItem(
                  'Manufacturing Year',
                  vehicle.manufacturingYear?.toString() ?? '—',
                ),
                _DetailItem(
                  'Color',
                  vehicle.color?.isNotEmpty == true ? vehicle.color! : '—',
                ),
                _DetailItem('Fuel Type', vehicle.fuelType.label),
                _DetailItem(
                  'Seating Capacity',
                  vehicle.seatingCapacity != null
                      ? '${vehicle.seatingCapacity} seats'
                      : '—',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailSection(
              title: 'Driver Assignment',
              items: [
                _DetailItem(
                  'Driver Name',
                  vehicle.driverName?.isNotEmpty == true
                      ? vehicle.driverName!
                      : 'Unassigned',
                ),
                _DetailItem(
                  'Driver Phone',
                  vehicle.driverPhone?.isNotEmpty == true
                      ? vehicle.driverPhone!
                      : '—',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailSection(
              title: 'Record Metadata',
              items: [
                _DetailItem('Created', _formatDate(vehicle.createdAt)),
                _DetailItem('Last Updated', _formatDate(vehicle.updatedAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.items});

  final String title;
  final List<_DetailItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.muted.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        items[i].label,
                        style: theme.textTheme.muted.copyWith(fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          items[i].value,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.p.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.border,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailItem {
  const _DetailItem(this.label, this.value);
  final String label;
  final String value;
}
