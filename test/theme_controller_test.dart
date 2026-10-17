import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:final_project/ui/core/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to light and toggles light and dark', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ThemeController();
    await c.load();
    expect(c.mode, ThemeMode.light);

    await c.toggle();
    expect(c.mode, ThemeMode.dark);
    await c.toggle();
    expect(c.mode, ThemeMode.light);
  });

  test('persists the choice across instances', () async {
    SharedPreferences.setMockInitialValues({});
    final first = ThemeController();
    await first.load();
    await first.setMode(ThemeMode.dark);

    final second = ThemeController();
    await second.load();
    expect(second.mode, ThemeMode.dark);
  });
}
