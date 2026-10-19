import 'package:flutter/material.dart';

class EventHubTheme {
  static const primary = Color(0xFFEA580C);
  static const onPrimary = Color(0xFF1A1206);
  static const softOrange = Color(0xFFF97316);
  static const golden = Color(0xFFFDBA74);
  static const paleYellow = Color(0xFFFFE4D0);
  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF1A1A1A);
  static const card = Colors.white;
  static const muted = Color(0xFFF5F5F5);
  static const mutedFg = Color(0xFF6B7280);
  static const border = Color(0xFFE5E5E5);
  static const danger = Color(0xFFB3261E);
  static const onDanger = Colors.white;
  static const success = Color(0xFF2E7D32);
  static const onSuccess = Colors.white;

  static const _darkBg = Color(0xFF1B130C);
  static const _darkSurface = Color(0xFF2A1F14);
  static const _darkText = Color(0xFFFFF3E0);
  static const _darkPrimary = Color(0xFFFFA94D);
  static const _darkOnPrimary = Color(0xFF1A1206);
  static const _darkSecondary = Color(0xFFFFD166);
  static const _darkBorder = Color(0xFF4A3826);

  static InputDecorationTheme _inputs(ColorScheme scheme) =>
      InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      );

  static ThemeData light() {
    final scheme = const ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: paleYellow,
      onPrimaryContainer: foreground,
      secondary: softOrange,
      onSecondary: onPrimary,
      secondaryContainer: paleYellow,
      onSecondaryContainer: foreground,
      tertiary: golden,
      onTertiary: foreground,
      surface: card,
      onSurface: foreground,
      surfaceContainerHighest: muted,
      onSurfaceVariant: mutedFg,
      outline: border,
      outlineVariant: border,
      error: danger,
      onError: onDanger,
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
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: border),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: primary,
        secondarySelectedColor: primary,
        checkmarkColor: onPrimary,
        labelStyle: base.textTheme.labelLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: base.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: base.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: foreground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: background,
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: paleYellow,
      ),
      inputDecorationTheme: _inputs(scheme),
      dividerColor: border,
    );
  }

  static ThemeData dark() {
    final scheme = const ColorScheme.dark(
      primary: _darkPrimary,
      onPrimary: _darkOnPrimary,
      primaryContainer: _darkSurface,
      onPrimaryContainer: _darkText,
      secondary: _darkSecondary,
      onSecondary: _darkOnPrimary,
      tertiary: _darkSecondary,
      onTertiary: _darkOnPrimary,
      surface: _darkSurface,
      onSurface: _darkText,
      surfaceContainerHighest: Color(0xFF3A2C1D),
      onSurfaceVariant: Color(0xFFD9C3A5),
      outline: _darkBorder,
      outlineVariant: Color(0xFF3A2C1D),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkBg,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: _darkText,
        displayColor: _darkText,
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: _darkSecondary,
        secondarySelectedColor: _darkSecondary,
        checkmarkColor: _darkOnPrimary,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: _darkBg,
        indicatorColor: const Color(0xFF3A2C1D),
      ),
      inputDecorationTheme: _inputs(scheme),
    );
  }  static TextStyle? display(BuildContext context, TextStyle? base) =>
      base?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.25);
}
