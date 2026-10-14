import 'package:flutter/material.dart';

/// EventHub tokens from the ui-ux-pro-max design system
/// (Minimalism/Swiss, event orange + map blue).
class EventHubTheme {
  static const primary = Color(0xFFEA580C);
  static const onPrimary = Colors.black;
  static const accent = Color(0xFF2563EB);
  static const background = Color(0xFFFFF7ED);
  static const foreground = Color(0xFF0F172A);
  static const card = Colors.white;
  static const muted = Color(0xFFFDF4F0);
  static const mutedFg = Color(0xFF475569);
  static const border = Color(0xFFFCEAE1);
  static const danger = Color(0xFFDC2626);

  static ThemeData light() {
    final scheme = const ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      secondary: accent,
      onSecondary: Colors.white,
      surface: card,
      onSurface: foreground,
      error: danger,
      onError: Colors.white,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: primary,
        secondarySelectedColor: primary,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData dark() {
    const bg = Color(0xFF0F172A);
    const surface = Color(0xFF1E293B);
    const text = Color(0xFFF8FAFC);
    const primaryDark = Color(0xFFFB923C);
    final scheme = const ColorScheme.dark(
      primary: primaryDark,
      onPrimary: Colors.black,
      secondary: Color(0xFF60A5FA),
      onSecondary: Colors.black,
      surface: surface,
      onSurface: text,
      error: Color(0xFFF87171),
      onError: Colors.black,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
    );
  }

  /// Display face for headlines. Uses the Material 3 default type
  /// ramp (google_fonts dropped: v9 binds a forked TextTheme type).
  static TextStyle? display(BuildContext context, TextStyle? base) =>
      base?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.25);
}
