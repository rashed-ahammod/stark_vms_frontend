import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/vehicle.dart';

class VehicleStatusBadge extends StatelessWidget {
  const VehicleStatusBadge({super.key, required this.status});

  final VehicleStatus status;

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, borderColor, dotColor) = switch (status) {
      VehicleStatus.available => (
          const Color(0xFFECFDF3),
          const Color(0xFF027A48),
          const Color(0xFFABEFC6),
          const Color(0xFF12B76A),
        ),
      VehicleStatus.inUse => (
          const Color(0xFFEFF8FF),
          const Color(0xFF175CD3),
          const Color(0xFFB2DDFF),
          const Color(0xFF2E90FA),
        ),
      VehicleStatus.maintenance => (
          const Color(0xFFFFFAEB),
          const Color(0xFFB54708),
          const Color(0xFFFEDF89),
          const Color(0xFFF79009),
        ),
      VehicleStatus.inactive => (
          const Color(0xFFF2F4F7),
          const Color(0xFF475467),
          const Color(0xFFD0D5DD),
          const Color(0xFF667085),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fgColor,
              height: 1.1,
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
