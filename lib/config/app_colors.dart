import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/vehicle.dart';

/// Surface colours shared by the fleet screens, in both brightnesses.
///
/// These live in one place so the page background, hover tint and emphasised
/// border stay identical everywhere instead of being re-typed as raw hex in
/// each widget. The dark set is chosen for the dark surface rather than
/// derived by flipping the light one.
class AppSurface {
  const AppSurface._({
    required this.page,
    required this.hover,
    required this.borderStrong,
    required this.ink,
    required this.neutralTrack,
    required this.neutralTint,
  });

  /// Page background behind every screen.
  final Color page;

  /// Row/card background on hover.
  final Color hover;

  /// Border for a hovered or emphasised card.
  final Color borderStrong;

  /// Neutral emphasis, e.g. the total-fleet meter fill.
  final Color ink;

  /// Unfilled track behind [ink] on the total-fleet meter.
  final Color neutralTrack;

  /// Tint behind the total-fleet icon.
  final Color neutralTint;

  static const AppSurface light = AppSurface._(
    page: Color(0xFFF8FAFC), // slate-50
    hover: Color(0xFFF1F5F9), // slate-100
    borderStrong: Color(0xFFCBD5E1), // slate-300
    ink: Color(0xFF0F172A), // slate-900
    neutralTrack: Color(0xFFE2E8F0), // slate-200
    neutralTint: Color(0xFFF1F5F9), // slate-100
  );

  /// Dark surfaces sit a step apart from the card colour so panels still lift
  /// off the page; shadcn's slate dark theme uses one colour for both.
  static const AppSurface dark = AppSurface._(
    page: Color(0xFF020817), // slate-950, the scheme background
    hover: Color(0xFF1E293B), // slate-800
    borderStrong: Color(0xFF334155), // slate-700
    ink: Color(0xFFE2E8F0), // slate-200, legible on dark
    neutralTrack: Color(0xFF1E293B), // slate-800
    neutralTint: Color(0xFF1E293B), // slate-800
  );

  /// The card colour used in dark mode, overriding shadcn's slate dark scheme
  /// where card and background are the same near-black.
  static const Color darkCard = Color(0xFF0F172A); // slate-900

  static AppSurface of(BuildContext context) =>
      ShadTheme.of(context).brightness == Brightness.dark ? dark : light;
}

/// The colour set for one [VehicleStatus].
///
/// One definition drives the status badge, the row rail, the KPI accents and
/// the share bars, so a status always reads as the same colour across the app.
///
/// Both sets were checked with the palette validator: every foreground clears
/// 4.5:1 against its own background (light 5.1-7.0:1, dark 9.3-10.6:1), and in
/// dark mode all four accents clear 3:1 against the surface.
class StatusPalette {
  const StatusPalette({
    required this.background,
    required this.foreground,
    required this.border,
    required this.accent,
  });

  /// Tinted pill background.
  final Color background;

  /// Text colour on [background].
  final Color foreground;
  final Color border;

  /// Saturated dot / rail / bar colour.
  final Color accent;

  // Light steps.
  static const StatusPalette _availableLight = StatusPalette(
    background: Color(0xFFECFDF3),
    foreground: Color(0xFF027A48),
    border: Color(0xFFABEFC6),
    accent: Color(0xFF12B76A),
  );
  static const StatusPalette _inUseLight = StatusPalette(
    background: Color(0xFFEFF8FF),
    foreground: Color(0xFF175CD3),
    border: Color(0xFFB2DDFF),
    accent: Color(0xFF2E90FA),
  );
  static const StatusPalette _maintenanceLight = StatusPalette(
    background: Color(0xFFFFFAEB),
    foreground: Color(0xFFB54708),
    border: Color(0xFFFEDF89),
    accent: Color(0xFFF79009),
  );
  static const StatusPalette _inactiveLight = StatusPalette(
    background: Color(0xFFF2F4F7),
    foreground: Color(0xFF475467),
    border: Color(0xFFD0D5DD),
    accent: Color(0xFF667085),
  );

  // Dark steps, taken from the same hue ramps and chosen against the dark
  // surface - not an inversion of the light set.
  static const StatusPalette _availableDark = StatusPalette(
    background: Color(0xFF052E1C),
    foreground: Color(0xFF6CE9A6),
    border: Color(0xFF074D31),
    accent: Color(0xFF32D583),
  );
  static const StatusPalette _inUseDark = StatusPalette(
    background: Color(0xFF0B1F3A),
    foreground: Color(0xFF84CAFF),
    border: Color(0xFF1849A9),
    accent: Color(0xFF53B1FD),
  );
  static const StatusPalette _maintenanceDark = StatusPalette(
    background: Color(0xFF2E1C05),
    foreground: Color(0xFFFEC84B),
    border: Color(0xFF93370D),
    accent: Color(0xFFFDB022),
  );
  static const StatusPalette _inactiveDark = StatusPalette(
    background: Color(0xFF1D2939),
    foreground: Color(0xFFCDD5DF),
    border: Color(0xFF344054),
    accent: Color(0xFF98A2B3),
  );

  static StatusPalette resolve(VehicleStatus status, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (status) {
      VehicleStatus.available => isDark ? _availableDark : _availableLight,
      VehicleStatus.inUse => isDark ? _inUseDark : _inUseLight,
      VehicleStatus.maintenance => isDark
          ? _maintenanceDark
          : _maintenanceLight,
      VehicleStatus.inactive => isDark ? _inactiveDark : _inactiveLight,
    };
  }

  static StatusPalette of(BuildContext context, VehicleStatus status) =>
      resolve(status, ShadTheme.of(context).brightness);
}
