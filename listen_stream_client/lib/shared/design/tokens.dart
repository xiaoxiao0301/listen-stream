import 'package:flutter/material.dart';

enum AppThemeStyle { apple, netease, qq }

class DesignTokens {
  // Spacing
  static const double spaceXS = 8.0;
  static const double space = 16.0;
  static const double spaceM = 24.0;
  static const double spaceL = 32.0;
  static const double spaceXL = 48.0;

  // Radii
  static const double rSmall = 8.0;
  static const double rMed = 12.0;
  static const double rLarge = 16.0;

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.06), blurRadius: 20, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> hoverShadow = [
    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 28, offset: Offset(0, 6)),
  ];

  // Typography
  static TextStyle h1(BuildContext c) => TextStyle(fontSize: 28, fontWeight: FontWeight.w600);
  static TextStyle h2(BuildContext c) => TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static TextStyle body(BuildContext c) => TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle caption(BuildContext c) => TextStyle(fontSize: 12, color: Colors.grey[600]);

  // Theme builder
  static ThemeData themeFor(AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.netease:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Color(0xFF0F0F12),
          primaryColor: Color(0xFFEA3A3A),
          cardColor: Color(0xFF111214),
          textTheme: TextTheme(bodyMedium: TextStyle(color: Color(0xFFE6E7E9))),
        );
      case AppThemeStyle.qq:
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Color(0xFFF7FBFF),
          primaryColor: Color(0xFF09B26B),
          cardColor: Colors.white,
          textTheme: TextTheme(bodyMedium: TextStyle(color: Color(0xFF0F1724))),
        );
      case AppThemeStyle.apple:
      default:
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          primaryColor: Color(0xFF0070C9),
          cardColor: Colors.white,
          textTheme: TextTheme(bodyMedium: TextStyle(color: Color(0xFF0B0B0B))),
        );
    }
  }
}
