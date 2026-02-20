import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF1DB954),
    brightness: Brightness.light,
  );
  static final dark = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF1DB954),
    brightness: Brightness.dark,
  );
}
