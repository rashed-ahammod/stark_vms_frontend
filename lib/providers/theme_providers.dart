import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../repositories/prefs_store.dart';

/// The opened `hive_ce` box holding UI preferences. Overridden in `main()`.
final prefsBoxProvider = Provider<Box<dynamic>>((ref) {
  throw StateError(
    'prefsBoxProvider must be overridden with an opened Hive box in main().',
  );
});

final prefsStoreProvider = Provider<PrefsStore>((ref) {
  return PrefsStore(ref.watch(prefsBoxProvider));
});

/// The app's light/dark/system choice, restored on start and saved on change.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(prefsStoreProvider).themeMode;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    // Flip first; persisting is write-behind and must not hold up the repaint.
    state = mode;
    await ref.read(prefsStoreProvider).setThemeMode(mode);
  }

  /// Convenience for the toggle button: resolves `system` against what is
  /// currently on screen, so one tap always visibly switches.
  Future<void> toggle(Brightness current) {
    return setMode(
      current == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
