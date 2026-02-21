import 'package:flutter/material.dart';
import '../../core/responsive/responsive.dart';

/// 响应式网格视图组件 - 根据设备类型自动调整列数
class ResponsiveGridView extends StatelessWidget {
  const ResponsiveGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.tvColumns = 6,
    this.childAspectRatio = 1.0,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final int tvColumns;
  final double childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final columns = responsiveValue(
      context: context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
      tv: tvColumns,
    );

    final spacing = ResponsiveSpacing.gridSpacing(context);

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding ?? ResponsiveSpacing.pagePadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// 响应式网格视图构建器 - 使用 SliverGridDelegate
class ResponsiveGridViewBuilder extends StatelessWidget {
  const ResponsiveGridViewBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.tvColumns = 6,
    this.childAspectRatio = 1.0,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.scrollDirection = Axis.vertical,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final int tvColumns;
  final double childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context) {
    return ResponsiveGridView(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      mobileColumns: mobileColumns,
      tabletColumns: tabletColumns,
      desktopColumns: desktopColumns,
      tvColumns: tvColumns,
      childAspectRatio: childAspectRatio,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
    );
  }
}

/// Sliver 响应式网格视图
class SliverResponsiveGridView extends StatelessWidget {
  const SliverResponsiveGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.tvColumns = 6,
    this.childAspectRatio = 1.0,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final int tvColumns;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final columns = responsiveValue(
      context: context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
      tv: tvColumns,
    );

    final spacing = ResponsiveSpacing.gridSpacing(context);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        itemBuilder,
        childCount: itemCount,
      ),
    );
  }
}
