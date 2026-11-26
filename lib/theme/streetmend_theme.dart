import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand.dart';

class StreetMendTheme {
  static ThemeData get light => _build(false);
  static ThemeData get dark => _build(true);
  static ThemeData _build(bool dark) {
    final c = StreetMendColors(dark);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: kOceanNavy,
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: dark ? c.accent : kOceanNavy,
          onPrimary: dark ? kOceanNavy : Colors.white,
          secondary: c.accent,
          onSecondary: dark ? kOceanNavy : Colors.white,
          surface: c.surface,
          onSurface: c.ink,
          onSurfaceVariant: c.body,
          surfaceContainerHighest: c.soft,
          outline: c.border,
          error: c.error,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      appBarTheme: AppBarTheme(
        backgroundColor: c.panel,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: c.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        labelStyle: TextStyle(color: c.body),
        hintStyle: TextStyle(color: c.muted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kFreshTeal,
          foregroundColor: kOceanNavy,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kFreshTeal,
          foregroundColor: kOceanNavy,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.accent),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.soft,
        labelStyle: TextStyle(color: c.ink),
        checkmarkColor: c.accent,
        side: BorderSide(color: c.border),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.panel,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      dividerColor: c.border,
    );
  }
}
