import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

/// Persists UI preferences that outlive a session.
///
/// Kept in its own box rather than the session box, because signing out must
/// not reset the user's appearance choice.
class PrefsStore {
  const PrefsStore(this._box);

  final Box<dynamic> _box;

  static const String boxName = 'stark_vms_prefs';
  static const String _themeModeKey = 'theme_mode';

  ThemeMode get themeMode {
    return switch (_box.get(_themeModeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _box.put(_themeModeKey, mode.name);
  }
}
