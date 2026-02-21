import 'package:flutter/material.dart';
import '../design_system/breakpoints.dart';

/// 响应式构建器 - 根据不同设备类型构建不同布局
///
/// 使用示例:
/// ```dart
/// ResponsiveBuilder(
///   mobile: (context) => MobileLayout(),
///   tablet: (context) => TabletLayout(),
///   desktop: (context) => DesktopLayout(),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  /// 移动端布局构建器（<600px）
  final WidgetBuilder mobile;

  /// 平板布局构建器（600-1024px），如果为null则使用mobile
  final WidgetBuilder? tablet;

  /// 桌面布局构建器（1024-1440px），如果为null则使用tablet或mobile
  final WidgetBuilder? desktop;

  /// 电视布局构建器（>1440px），如果为null则使用desktop、tablet或mobile
  final WidgetBuilder? tv;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.tv,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = Breakpoints.getDeviceType(constraints.maxWidth);

        switch (deviceType) {
          case DeviceType.mobile:
            return mobile(context);

          case DeviceType.tablet:
            return (tablet ?? mobile)(context);

          case DeviceType.desktop:
            return (desktop ?? tablet ?? mobile)(context);

          case DeviceType.tv:
            return (tv ?? desktop ?? tablet ?? mobile)(context);
        }
      },
    );
  }
}

/// 响应式构建器 - 提供设备类型和约束信息
///
/// 使用示例:
/// ```dart
/// ResponsiveBuilderWithInfo(
///   builder: (context, deviceType, constraints) {
///     if (deviceType == DeviceType.mobile) {
///       return SingleColumnLayout();
///     } else {
///       return TwoColumnLayout();
///     }
///   },
/// )
/// ```
class ResponsiveBuilderWithInfo extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    DeviceType deviceType,
    BoxConstraints constraints,
  ) builder;

  const ResponsiveBuilderWithInfo({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = Breakpoints.getDeviceType(constraints.maxWidth);
        return builder(context, deviceType, constraints);
      },
    );
  }
}

/// 自适应容器 - 根据设备类型自动调整最大宽度
///
/// 使用示例:
/// ```dart
/// AdaptiveContainer(
///   child: ListView(...),
/// )
/// ```
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidthMobile;
  final double? maxWidthTablet;
  final double? maxWidthDesktop;
  final double? maxWidthTv;
  final bool centerContent;

  const AdaptiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidthMobile,
    this.maxWidthTablet = 768,
    this.maxWidthDesktop = 1280,
    this.maxWidthTv = 1600,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = Breakpoints.getDeviceType(constraints.maxWidth);

        double? maxWidth;
        switch (deviceType) {
          case DeviceType.mobile:
            maxWidth = maxWidthMobile;
            break;
          case DeviceType.tablet:
            maxWidth = maxWidthTablet;
            break;
          case DeviceType.desktop:
            maxWidth = maxWidthDesktop;
            break;
          case DeviceType.tv:
            maxWidth = maxWidthTv;
            break;
        }

        Widget content = child;

        if (maxWidth != null) {
          content = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: content,
          );
        }

        if (centerContent) {
          content = Center(child: content);
        }

        if (padding != null) {
          content = Padding(
            padding: padding!,
            child: content,
          );
        }

        return content;
      },
    );
  }
}

/// 响应式网格 - 根据设备类型自动调整列数
///
/// 使用示例:
/// ```dart
/// ResponsiveGrid(
///   children: [
///     Card(...),
///     Card(...),
///     Card(...),
///   ],
/// )
/// ```
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? tvColumns;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.tvColumns = 4,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = Breakpoints.getDeviceType(constraints.maxWidth);

        int columns;
        switch (deviceType) {
          case DeviceType.mobile:
            columns = mobileColumns ?? 1;
            break;
          case DeviceType.tablet:
            columns = tabletColumns ?? 2;
            break;
          case DeviceType.desktop:
            columns = desktopColumns ?? 3;
            break;
          case DeviceType.tv:
            columns = tvColumns ?? 4;
            break;
        }

        final content = GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: 1.0,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );

        return content;
      },
    );
  }
}

/// 响应式填充 - 根据设备类型自动调整内边距
///
/// 使用示例:
/// ```dart
/// ResponsivePadding(
///   child: Column(...),
/// )
/// ```
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? mobile;
  final EdgeInsetsGeometry? tablet;
  final EdgeInsetsGeometry? desktop;
  final EdgeInsetsGeometry? tv;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
    this.tv,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = Breakpoints.getDeviceType(constraints.maxWidth);

        EdgeInsetsGeometry? padding;
        switch (deviceType) {
          case DeviceType.mobile:
            padding = mobile ?? const EdgeInsets.all(16);
            break;
          case DeviceType.tablet:
            padding = tablet ?? mobile ?? const EdgeInsets.all(24);
            break;
          case DeviceType.desktop:
            padding =
                desktop ?? tablet ?? mobile ?? const EdgeInsets.all(32);
            break;
          case DeviceType.tv:
            padding = tv ??
                desktop ??
                tablet ??
                mobile ??
                const EdgeInsets.all(40);
            break;
        }

        return Padding(
          padding: padding,
          child: child,
        );
      },
    );
  }
}
