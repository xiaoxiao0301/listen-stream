import 'package:flutter/material.dart';
import '../design_system/breakpoints.dart';

/// 响应式值 - 根据设备类型返回不同的值
///
/// 使用示例:
/// ```dart
/// final padding = responsiveValue(
///   context,
///   mobile: 16.0,
///   tablet: 24.0,
///   desktop: 32.0,
///   tv: 40.0,
/// );
/// ```
T responsiveValue<T>({
  required BuildContext context,
  required T mobile,
  T? tablet,
  T? desktop,
  T? tv,
}) {
  final width = MediaQuery.of(context).size.width;
  final deviceType = Breakpoints.getDeviceType(width);

  switch (deviceType) {
    case DeviceType.mobile:
      return mobile;
    case DeviceType.tablet:
      return tablet ?? mobile;
    case DeviceType.desktop:
      return desktop ?? tablet ?? mobile;
    case DeviceType.tv:
      return tv ?? desktop ?? tablet ?? mobile;
  }
}

/// 响应式值（使用宽度） - 根据指定宽度返回不同的值
///
/// 使用示例:
/// ```dart
/// final columns = responsiveValueByWidth(
///   width: constraints.maxWidth,
///   mobile: 1,
///   tablet: 2,
///   desktop: 3,
///   tv: 4,
/// );
/// ```
T responsiveValueByWidth<T>({
  required double width,
  required T mobile,
  T? tablet,
  T? desktop,
  T? tv,
}) {
  final deviceType = Breakpoints.getDeviceType(width);

  switch (deviceType) {
    case DeviceType.mobile:
      return mobile;
    case DeviceType.tablet:
      return tablet ?? mobile;
    case DeviceType.desktop:
      return desktop ?? tablet ?? mobile;
    case DeviceType.tv:
      return tv ?? desktop ?? tablet ?? mobile;
  }
}

/// 响应式值（使用设备类型） - 根据设备类型返回不同的值
///
/// 使用示例:
/// ```dart
/// final iconSize = responsiveValueByDeviceType(
///   deviceType: DeviceType.mobile,
///   mobile: 24.0,
///   tablet: 28.0,
///   desktop: 32.0,
///   tv: 40.0,
/// );
/// ```
T responsiveValueByDeviceType<T>({
  required DeviceType deviceType,
  required T mobile,
  T? tablet,
  T? desktop,
  T? tv,
}) {
  switch (deviceType) {
    case DeviceType.mobile:
      return mobile;
    case DeviceType.tablet:
      return tablet ?? mobile;
    case DeviceType.desktop:
      return desktop ?? tablet ?? mobile;
    case DeviceType.tv:
      return tv ?? desktop ?? tablet ?? mobile;
  }
}

/// 响应式间距辅助类
class ResponsiveSpacing {
  /// 根据设备类型返回页面内边距
  static EdgeInsets pagePadding(BuildContext context) {
    return EdgeInsets.all(
      responsiveValue(
        context: context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
        tv: 40.0,
      ),
    );
  }

  /// 根据设备类型返回水平内边距
  static EdgeInsets horizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: responsiveValue(
        context: context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
        tv: 40.0,
      ),
    );
  }

  /// 根据设备类型返回垂直内边距
  static EdgeInsets verticalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      vertical: responsiveValue(
        context: context,
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
        tv: 32.0,
      ),
    );
  }

  /// 根据设备类型返回卡片内边距
  static EdgeInsets cardPadding(BuildContext context) {
    return EdgeInsets.all(
      responsiveValue(
        context: context,
        mobile: 12.0,
        tablet: 16.0,
        desktop: 20.0,
        tv: 24.0,
      ),
    );
  }

  /// 根据设备类型返回列表项间距
  static double listItemSpacing(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
      tv: 20.0,
    );
  }

  /// 根据设备类型返回网格间距
  static double gridSpacing(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
      tv: 24.0,
    );
  }
}

/// 响应式尺寸辅助类
class ResponsiveSize {
  /// 根据设备类型返回图标尺寸
  static double iconSize(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
      tv: 40.0,
    );
  }

  /// 根据设备类型返回小图标尺寸
  static double smallIconSize(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
      tv: 24.0,
    );
  }

  /// 根据设备类型返回大图标尺寸
  static double largeIconSize(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 32.0,
      tablet: 40.0,
      desktop: 48.0,
      tv: 64.0,
    );
  }

  /// 根据设备类型返回按钮高度
  static double buttonHeight(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 48.0,
      tablet: 52.0,
      desktop: 56.0,
      tv: 64.0,
    );
  }

  /// 根据设备类型返回应用栏高度
  static double appBarHeight(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 56.0,
      tablet: 64.0,
      desktop: 72.0,
      tv: 80.0,
    );
  }

  /// 根据设备类型返回底部导航栏高度
  static double bottomNavBarHeight(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 56.0,
      tablet: 64.0,
      desktop: 72.0,
      tv: 80.0,
    );
  }

  /// 根据设备类型返回列表项高度
  static double listItemHeight(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 64.0,
      tablet: 72.0,
      desktop: 80.0,
      tv: 96.0,
    );
  }

  /// 根据设备类型返回卡片封面尺寸
  static double coverSize(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 56.0,
      tablet: 64.0,
      desktop: 72.0,
      tv: 88.0,
    );
  }

  /// 根据设备类型返回内容最大宽度
  static double contentMaxWidth(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: double.infinity,
      tablet: 768.0,
      desktop: 1280.0,
      tv: 1600.0,
    );
  }
}

/// 响应式网格列数辅助类
class ResponsiveGrid {
  /// 根据设备类型返回网格列数
  static int columns(BuildContext context, {int? mobile, int? tablet, int? desktop, int? tv}) {
    return responsiveValue(
      context: context,
      mobile: mobile ?? 2,
      tablet: tablet ?? 3,
      desktop: desktop ?? 4,
      tv: tv ?? 6,
    );
  }

  /// 专辑网格列数
  static int albumColumns(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
      tv: 6,
    );
  }

  /// 歌手网格列数
  static int singerColumns(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 2,
      tablet: 3,
      desktop: 5,
      tv: 7,
    );
  }

  /// 歌单网格列数
  static int playlistColumns(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
      tv: 6,
    );
  }

  /// MV网格列数
  static int mvColumns(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      tv: 4,
    );
  }

  /// 搜索结果网格列数
  static int searchColumns(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      tv: 4,
    );
  }
}

/// 响应式字体缩放辅助类
class ResponsiveFontScale {
  /// 根据设备类型返回字体缩放比例
  static double scale(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.15,
      tv: 1.3,
    );
  }

  /// 应用字体缩放到文字样式
  static TextStyle applyScale(BuildContext context, TextStyle style) {
    final scale = ResponsiveFontScale.scale(context);
    return style.copyWith(
      fontSize: (style.fontSize ?? 14) * scale,
      height: style.height, // 保持行高比例不变
    );
  }
}
