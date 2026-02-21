import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/breakpoints.dart';

/// 设备类型状态 - 包含设备类型和屏幕宽度信息
class DeviceTypeState {
  final DeviceType deviceType;
  final double screenWidth;
  final double screenHeight;

  const DeviceTypeState({
    required this.deviceType,
    required this.screenWidth,
    required this.screenHeight,
  });

  /// 是否为移动设备
  bool get isMobile => deviceType == DeviceType.mobile;

  /// 是否为平板设备
  bool get isTablet => deviceType == DeviceType.tablet;

  /// 是否为桌面设备
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// 是否为电视设备
  bool get isTv => deviceType == DeviceType.tv;

  /// 是否为小屏设备（移动端）
  bool get isSmallScreen => deviceType == DeviceType.mobile;

  /// 是否为大屏设备（桌面端或电视）
  bool get isLargeScreen =>
      deviceType == DeviceType.desktop || deviceType == DeviceType.tv;

  /// 是否为横屏
  bool get isLandscape => screenWidth > screenHeight;

  /// 是否为竖屏
  bool get isPortrait => screenHeight > screenWidth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceTypeState &&
          runtimeType == other.runtimeType &&
          deviceType == other.deviceType &&
          screenWidth == other.screenWidth &&
          screenHeight == other.screenHeight;

  @override
  int get hashCode =>
      deviceType.hashCode ^ screenWidth.hashCode ^ screenHeight.hashCode;

  @override
  String toString() {
    return 'DeviceTypeState(deviceType: $deviceType, screenWidth: $screenWidth, screenHeight: $screenHeight)';
  }

  DeviceTypeState copyWith({
    DeviceType? deviceType,
    double? screenWidth,
    double? screenHeight,
  }) {
    return DeviceTypeState(
      deviceType: deviceType ?? this.deviceType,
      screenWidth: screenWidth ?? this.screenWidth,
      screenHeight: screenHeight ?? this.screenHeight,
    );
  }
}

/// 设备类型 Provider - 提供当前设备类型信息
///
/// 使用示例:
/// ```dart
/// final deviceState = ref.watch(deviceTypeProvider);
/// if (deviceState.isMobile) {
///   return MobileLayout();
/// } else {
///   return DesktopLayout();
/// }
/// ```
final deviceTypeProvider = Provider<DeviceTypeState>((ref) {
  // 默认移动端，实际值由 DeviceTypeObserver 更新
  return const DeviceTypeState(
    deviceType: DeviceType.mobile,
    screenWidth: 375,
    screenHeight: 667,
  );
});

/// 设备类型状态 Provider - 可变状态
final deviceTypeStateProvider =
    StateProvider<DeviceTypeState>((ref) {
  return const DeviceTypeState(
    deviceType: DeviceType.mobile,
    screenWidth: 375,
    screenHeight: 667,
  );
});

/// 设备类型观察器 - 监听屏幕尺寸变化并更新设备类型
///
/// 使用示例:
/// ```dart
/// void main() {
///   runApp(
///     ProviderScope(
///       child: DeviceTypeObserver(
///         child: MyApp(),
///       ),
///     ),
///   );
/// }
/// ```
class DeviceTypeObserver extends ConsumerStatefulWidget {
  final Widget child;

  const DeviceTypeObserver({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<DeviceTypeObserver> createState() => _DeviceTypeObserverState();
}

class _DeviceTypeObserverState extends ConsumerState<DeviceTypeObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 初始化时更新设备类型
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDeviceType();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _updateDeviceType();
  }

  void _updateDeviceType() {
    if (!mounted) return;

    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    final deviceType = Breakpoints.getDeviceType(width);

    final newState = DeviceTypeState(
      deviceType: deviceType,
      screenWidth: width,
      screenHeight: height,
    );

    final currentState = ref.read(deviceTypeStateProvider);
    if (currentState != newState) {
      ref.read(deviceTypeStateProvider.notifier).state = newState;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听屏幕尺寸变化
    return LayoutBuilder(
      builder: (context, constraints) {
        // 每次布局变化时更新设备类型
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateDeviceType();
        });
        return widget.child;
      },
    );
  }
}

/// 设备类型扩展 - 为 BuildContext 添加便捷方法
extension DeviceTypeContext on BuildContext {
  /// 获取当前设备类型状态
  DeviceTypeState get deviceTypeState {
    final mediaQuery = MediaQuery.of(this);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    final deviceType = Breakpoints.getDeviceType(width);

    return DeviceTypeState(
      deviceType: deviceType,
      screenWidth: width,
      screenHeight: height,
    );
  }

  /// 是否为移动设备
  bool get isMobile => deviceTypeState.isMobile;

  /// 是否为平板设备
  bool get isTablet => deviceTypeState.isTablet;

  /// 是否为桌面设备
  bool get isDesktop => deviceTypeState.isDesktop;

  /// 是否为电视设备
  bool get isTv => deviceTypeState.isTv;

  /// 是否为小屏设备
  bool get isSmallScreen => deviceTypeState.isSmallScreen;

  /// 是否为大屏设备
  bool get isLargeScreen => deviceTypeState.isLargeScreen;

  /// 是否为横屏
  bool get isLandscape => deviceTypeState.isLandscape;

  /// 是否为竖屏
  bool get isPortrait => deviceTypeState.isPortrait;
}
