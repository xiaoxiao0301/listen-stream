import 'package:flutter/material.dart';

/// 应用颜色系统
/// 基于 Material Design 3，使用深紫色主题
class AppColors {
  // 主色调（深紫色系）
  static const Color primary = Color(0xFF6200EA);
  static const Color primaryVariant = Color(0xFF3700B3);
  static const Color primaryLight = Color(0xFF9D46FF);
  static const Color primaryDark = Color(0xFF0A00B6);
  
  // 辅助色
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryVariant = Color(0xFF018786);
  
  // 强调色
  static const Color accent = Color(0xFFFF6E40);
  
  // 深色模式背景
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);
  
  // 浅色模式背景
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF5F5F5);
  
  // 文本颜色（深色模式）
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xB3FFFFFF);
  static const Color textDisabledDark = Color(0x61FFFFFF);
  
  // 文本颜色（浅色模式）
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0x99000000);
  static const Color textDisabledLight = Color(0x61000000);
  
  // 语义颜色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFCF6679);
  static const Color info = Color(0xFF2196F3);
  
  // 分隔线
  static const Color dividerDark = Color(0x1FFFFFFF);
  static const Color dividerLight = Color(0x1F000000);
  
  // 遮罩
  static const Color scrimDark = Color(0x80000000);
  static const Color scrimLight = Color(0x52000000);
  
  // 播放器渐变色
  static const List<Color> playerGradient = [
    Color(0xFF1E1E1E),
    Color(0xFF121212),
  ];
  
  // 卡片渐变色
  static const List<Color> cardGradient = [
    Color(0xFF2C2C2C),
    Color(0xFF1E1E1E),
  ];
}

/// 根据 Brightness 获取对应的颜色
extension AppColorsExtension on AppColors {
  static Color background(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
  }
  
  static Color surface(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
  }
  
  static Color surfaceVariant(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
  }
  
  static Color textPrimary(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
  }
  
  static Color textSecondary(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
  }
  
  static Color divider(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors.dividerDark
        : AppColors.dividerLight;
  }
}
