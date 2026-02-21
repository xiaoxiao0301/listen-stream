/// 响应式断点配置
/// 定义不同设备类型的屏幕宽度阈值
class Breakpoints {
  // 断点值（以 dp 为单位）
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1280;
  
  // 判断是否为移动设备
  static bool isMobile(double width) => width < mobile;
  
  // 判断是否为平板设备
  static bool isTablet(double width) => width >= mobile && width < desktop;
  
  // 判断是否为桌面设备
  static bool isDesktop(double width) => width >= desktop;
  
  // 判断是否为 TV 设备（大屏桌面）
  static bool isTV(double width) => width >= desktop && width > 1440;
  
  // 获取当前设备类型
  static DeviceType getDeviceType(double width) {
    if (width < mobile) {
      return DeviceType.mobile;
    } else if (width < desktop) {
      return DeviceType.tablet;
    } else if (width > 1440) {
      return DeviceType.tv;
    } else {
      return DeviceType.desktop;
    }
  }
}

/// 设备类型枚举
enum DeviceType {
  mobile,
  tablet,
  desktop,
  tv,
}
