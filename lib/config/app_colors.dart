import 'package:flutter/material.dart';

import '../models/vehicle.dart';

/// Surface colours shared by the fleet screens.
///
/// These live in one place so the page background, hover tint and emphasised
/// border stay identical everywhere instead of being re-typed as raw hex in
/// each widget.
class AppSurface {
  AppSurface._();

  /// Page background behind every screen (slate-50).
  static const Color page = Color(0xFFF8FAFC);

  /// Row/card background on hover (slate-50 over white).
  static const Color hover = Color(0xFFF1F5F9);

  /// Border for a hovered or emphasised card (slate-300).
  static const Color borderStrong = Color(0xFFCBD5E1);

  /// Ink used for neutral emphasis, e.g. the total-fleet accent (slate-900).
  static const Color ink = Color(0xFF0F172A);
}

/// The colour set for one [VehicleStatus].
///
/// One definition drives the status badge, the KPI accents and the share bars,
/// so a status always reads as the same colour across the whole app.
class StatusPalette {
  const StatusPalette({
    required this.background,
    required this.foreground,
    required this.border,
    required this.accent,
  });

  /// Tinted pill background.
  final Color background;

  /// Text colour on [background], and the accent for solid treatments.
  final Color foreground;
  final Color border;

  /// Saturated dot / bar colour.
  final Color accent;

  static const StatusPalette available = StatusPalette(
    background: Color(0xFFECFDF3),
    foreground: Color(0xFF027A48),
    border: Color(0xFFABEFC6),
    accent: Color(0xFF12B76A),
  );

  static const StatusPalette inUse = StatusPalette(
    background: Color(0xFFEFF8FF),
    foreground: Color(0xFF175CD3),
    border: Color(0xFFB2DDFF),
    accent: Color(0xFF2E90FA),
  );

  static const StatusPalette maintenance = StatusPalette(
    background: Color(0xFFFFFAEB),
    foreground: Color(0xFFB54708),
    border: Color(0xFFFEDF89),
    accent: Color(0xFFF79009),
  );

  static const StatusPalette inactive = StatusPalette(
    background: Color(0xFFF2F4F7),
    foreground: Color(0xFF475467),
    border: Color(0xFFD0D5DD),
    accent: Color(0xFF667085),
  );

  static StatusPalette of(VehicleStatus status) => switch (status) {
    VehicleStatus.available => available,
    VehicleStatus.inUse => inUse,
    VehicleStatus.maintenance => maintenance,
    VehicleStatus.inactive => inactive,
  };
}
