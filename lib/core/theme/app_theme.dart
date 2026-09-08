import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color _background = Color(0xFF0F1419);
  static const Color _surface = Color(0xFF1A2332);
  static const Color _primary = Color(0xFF7EB6FF);
  static const Color _onBackground = Color(0xFFE8EEF6);

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primary,
        onPrimary: Color(0xFF0B1A2E),
        surface: _surface,
        onSurface: _onBackground,
      ),
      scaffoldBackgroundColor: _background,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
