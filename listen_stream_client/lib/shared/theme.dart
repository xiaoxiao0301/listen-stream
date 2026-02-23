import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, glass, warm }

class AppTheme {
  // Neon accent colors (shared across themes except warm)
  static const neonPurple = Color(0xFF6C63FF);
  static const neonCyan = Color(0xFF4CE1F7);
  static const warmOrange = Color(0xFFFFB86C);
  static const warmGold = Color(0xFFFF9A3C);

  // Dark gradient colors
  static const darkBase = Color(0xFF0F0F15);
  static const darkSecondary = Color(0xFF1A1A2E);

  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return _lightTheme();
      case AppThemeMode.dark:
        return _darkTheme();
      case AppThemeMode.glass:
        return _glassTheme();
      case AppThemeMode.warm:
        return _warmTheme();
    }
  }

  // Light Theme - bright, clean white UI
  static ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: neonPurple,
      colorScheme: ColorScheme.light(
        primary: neonPurple,
        secondary: neonCyan,
        surface: Colors.white,
        surfaceContainerHighest: const Color(0xFFF5F5F7),
        onSurface: const Color(0xFF1C1C1E),
        outline: const Color(0xFFE5E5E7),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E5E7), width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: neonPurple.withOpacity(0.12),
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonPurple,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: neonPurple.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonPurple, width: 2),
        ),
      ),
    );
  }

  // Dark Theme - deep dark gradient with ambient lighting
  static ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBase,
      primaryColor: neonPurple,
      colorScheme: ColorScheme.dark(
        primary: neonPurple,
        secondary: neonCyan,
        surface: const Color(0xFF1C1C28),
        surfaceContainerHighest: const Color(0xFF25253A),
        onSurface: const Color(0xFFE6E7E9),
        outline: const Color(0xFF3A3A4F),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1C1C28),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1C1C28),
        indicatorColor: neonPurple.withOpacity(0.2),
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonPurple,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: neonPurple.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF25253A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonPurple, width: 2),
        ),
      ),
    );
  }

  // Glass Theme - macOS-style frosted glass
  static ThemeData _glassTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      primaryColor: neonPurple,
      colorScheme: ColorScheme.dark(
        primary: neonPurple,
        secondary: neonCyan,
        surface: const Color(0xFF1C1C28).withOpacity(0.6),
        surfaceContainerHighest: const Color(0xFF25253A).withOpacity(0.6),
        onSurface: const Color(0xFFE6E7E9),
        outline: Colors.white.withOpacity(0.1),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.08),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.black.withOpacity(0.3),
        indicatorColor: neonPurple.withOpacity(0.2),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonPurple.withOpacity(0.9),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonPurple, width: 2),
        ),
      ),
    );
  }

  // Warm Theme - warm orange-gold accents, cozy atmosphere
  static ThemeData _warmTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1410),
      primaryColor: warmOrange,
      colorScheme: ColorScheme.dark(
        primary: warmOrange,
        secondary: warmGold,
        surface: const Color(0xFF2A1F18),
        surfaceContainerHighest: const Color(0xFF3A2D22),
        onSurface: const Color(0xFFFFF8F0),
        outline: const Color(0xFF4A3A2F),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2A1F18),
        elevation: 6,
        shadowColor: warmOrange.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF2A1F18),
        indicatorColor: warmOrange.withOpacity(0.2),
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: warmOrange,
          foregroundColor: const Color(0xFF1A1410),
          elevation: 4,
          shadowColor: warmOrange.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF3A2D22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: warmOrange, width: 2),
        ),
      ),
    );
  }

  // Legacy support
  static final light = getTheme(AppThemeMode.light);
  static final dark = getTheme(AppThemeMode.dark);
}
