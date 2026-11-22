import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../config/app_colors.dart';
import '../models/vehicle.dart';

class VehicleStatusBadge extends StatelessWidget {
  const VehicleStatusBadge({super.key, required this.status});

  final VehicleStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = StatusPalette.of(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: palette.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.foreground,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleTypeBadge extends StatelessWidget {
  const VehicleTypeBadge({super.key, required this.type});

  final VehicleType type;

  static IconData iconFor(VehicleType type) {
    return switch (type) {
      VehicleType.car || VehicleType.suv => LucideIcons.car,
      VehicleType.van || VehicleType.microbus => LucideIcons.carFront,
      VehicleType.bus => LucideIcons.bus,
      VehicleType.truck || VehicleType.pickup => LucideIcons.truck,
      VehicleType.motorcycle => LucideIcons.bike,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ShadBadge.secondary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconFor(type), size: 12),
          const SizedBox(width: 4),
          Text(type.label),
        ],
      ),
    );
  }
}

class VehicleTypeAvatar extends StatelessWidget {
  const VehicleTypeAvatar({super.key, required this.type});

  final VehicleType type;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Icon(
        VehicleTypeBadge.iconFor(type),
        size: 18,
        color: theme.colorScheme.foreground,
      ),
    );
  }
}
