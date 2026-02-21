/// 间距系统
/// 基于 8dp 网格系统，提供统一的间距常量
class AppSpacing {
  // 基准单位
  static const double unit = 8.0;
  
  // 常用间距值
  static const double xxxs = unit * 0.5; // 4
  static const double xxs = unit;        // 8
  static const double xs = unit * 1.5;   // 12
  static const double sm = unit * 2;     // 16
  static const double md = unit * 3;     // 24
  static const double lg = unit * 4;     // 32
  static const double xl = unit * 5;     // 40
  static const double xxl = unit * 6;    // 48
  static const double xxxl = unit * 8;   // 64
  
  // 特定场景间距
  static const double pageHorizontal = sm; // 页面水平边距
  static const double pageVertical = md;   // 页面垂直边距
  static const double sectionGap = lg;     // 模块间距
  static const double cardPadding = sm;    // 卡片内边距
  static const double listItemGap = xs;    // 列表项间距
}

/// 圆角系统
class AppRadius {
  static const double none = 0;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double full = 9999; // 完全圆角
}

/// 阴影/高度系统
class AppElevation {
  static const double none = 0;
  static const double sm = 2;
  static const double md = 4;
  static const double lg = 8;
  static const double xl = 12;
  static const double xxl = 16;
}
