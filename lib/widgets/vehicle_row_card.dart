import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/vehicle.dart';
import 'vehicle_badges.dart';

class VehicleRowCard extends StatefulWidget {
  const VehicleRowCard({
    super.key,
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  static const Vehicle placeholderVehicle = Vehicle(
    id: 0,
    vehicleNumber: 'DHA-METRO-GA-11-1234',
    vehicleType: VehicleType.car,
    brand: 'Toyota',
    model: 'Corolla Cross',
    manufacturingYear: 2023,
    color: 'Pearl White',
    fuelType: FuelType.hybrid,
    seatingCapacity: 5,
    driverName: 'Kamrul Hasan',
    driverPhone: '+8801711000000',
    status: VehicleStatus.available,
  );

  @override
  State<VehicleRowCard> createState() => _VehicleRowCardState();
}

class _VehicleRowCardState extends State<VehicleRowCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 960;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFFF8FAFC)
                : theme.colorScheme.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFFCBD5E1)
                  : theme.colorScheme.border,
            ),
          ),
          child: isWide
              ? _DesktopVehicleRow(
                  vehicle: widget.vehicle,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                )
              : _TabletVehicleRow(
                  vehicle: widget.vehicle,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                ),
        ),
      ),
    );
  }
}

class _DesktopVehicleRow extends StatelessWidget {
  const _DesktopVehicleRow({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final mutedStyle = theme.textTheme.muted.copyWith(fontSize: 13);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Registration & Type Icon
        Expanded(
          flex: 3,
          child: Row(
            children: [
              VehicleTypeAvatar(type: vehicle.vehicleType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.vehicleNumber,
                      style: theme.textTheme.p.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        VehicleStatusBadge(status: vehicle.status),
                        Text(
                          vehicle.vehicleType.label,
                          style: mutedStyle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Brand, Model, Year, Color
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${vehicle.brand} ${vehicle.model}',
                style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (vehicle.manufacturingYear != null)
                    '${vehicle.manufacturingYear}',
                  if (vehicle.color != null && vehicle.color!.isNotEmpty)
                    vehicle.color!,
                ].join(' • ').ifEmpty('No year/color specified'),
                style: mutedStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Fuel & Capacity
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.fuel,
                    size: 14,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  const SizedBox(width: 6),
                  Text(vehicle.fuelType.label, style: theme.textTheme.p),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                vehicle.seatingCapacity != null
                    ? '${vehicle.seatingCapacity} seats'
                    : 'Seats: —',
                style: mutedStyle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Driver Info
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.user,
                    size: 14,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      vehicle.driverName?.isNotEmpty == true
                          ? vehicle.driverName!
                          : 'Unassigned',
                      style: theme.textTheme.p.copyWith(
                        color: vehicle.driverName?.isNotEmpty == true
                            ? theme.colorScheme.foreground
                            : theme.colorScheme.mutedForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                vehicle.driverPhone?.isNotEmpty == true
                    ? vehicle.driverPhone!
                    : 'No phone',
                style: mutedStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Compact Actions with Tooltips
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShadTooltip(
              builder: (_) => const Text('Edit vehicle'),
              child: ShadIconButton.outline(
                onPressed: onEdit,
                icon: const Icon(LucideIcons.pencil, size: 15),
              ),
            ),
            const SizedBox(width: 8),
            ShadTooltip(
              builder: (_) => const Text('Delete vehicle'),
              child: ShadIconButton.destructive(
                onPressed: onDelete,
                icon: const Icon(LucideIcons.trash2, size: 15),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TabletVehicleRow extends StatelessWidget {
  const _TabletVehicleRow({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VehicleTypeAvatar(type: vehicle.vehicleType),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.vehicleNumber,
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vehicle.brand} ${vehicle.model}',
                    style: theme.textTheme.muted,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            VehicleStatusBadge(status: vehicle.status),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            VehicleTypeBadge(type: vehicle.vehicleType),
            _MetaChip(icon: LucideIcons.fuel, label: vehicle.fuelType.label),
            if (vehicle.manufacturingYear != null)
              _MetaChip(
                icon: LucideIcons.calendar,
                label: '${vehicle.manufacturingYear}',
              ),
            if (vehicle.color != null && vehicle.color!.isNotEmpty)
              _MetaChip(icon: LucideIcons.palette, label: vehicle.color!),
            if (vehicle.seatingCapacity != null)
              _MetaChip(
                icon: LucideIcons.users,
                label: '${vehicle.seatingCapacity} seats',
              ),
            _MetaChip(
              icon: LucideIcons.user,
              label: vehicle.driverName?.isNotEmpty == true
                  ? '${vehicle.driverName}${vehicle.driverPhone?.isNotEmpty == true ? ' (${vehicle.driverPhone})' : ''}'
                  : 'Unassigned',
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: onEdit,
              leading: const Icon(LucideIcons.pencil, size: 14),
              child: const Text('Edit'),
            ),
            const SizedBox(width: 8),
            ShadButton.destructive(
              size: ShadButtonSize.sm,
              onPressed: onDelete,
              leading: const Icon(LucideIcons.trash2, size: 14),
              child: const Text('Delete'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.colorScheme.mutedForeground),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.muted.copyWith(fontSize: 13),
        ),
      ],
    );
  }
}

extension _StringFallback on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
