import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide light/dark mode state. Defaults to the system setting;
/// the toggle switches explicitly between light and dark, and the
/// choice persists across restarts.
class ThemeController extends ChangeNotifier {
  ThemeController([this._mode = ThemeMode.system]);

  static const _prefsKey = 'eventhub_theme_mode';

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  /// Icon reflecting what tapping will switch to (or auto when systemic).
  IconData get toggleIcon => switch (_mode) {
        ThemeMode.dark => Icons.light_mode_outlined,
        ThemeMode.light => Icons.dark_mode_outlined,
        ThemeMode.system => Icons.brightness_auto_outlined,
      };

  String get toggleTooltip => switch (_mode) {
        ThemeMode.dark => 'Switch to light mode',
        ThemeMode.light => 'Switch to dark mode',
        ThemeMode.system => 'Switch theme (following system)',
      };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final next = ThemeMode.values.asNameMap()[raw];
    if (next != null && next != _mode) {
      _mode = next;
      notifyListeners();
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

  /// Toggles explicit light ↔ dark (system counts as light-side).
  Future<void> toggle() =>
      setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
