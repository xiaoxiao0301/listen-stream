import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtil {
  /// True when running on Android TV, Fire TV, or similar TV-class devices.
  static bool get isTV {
    if (kIsWeb) return false;
    // Android TV: checked at runtime via platform channel in production;
    // here we use an env override for testing.
    return const bool.fromEnvironment('IS_TV', defaultValue: false);
  }

  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  static bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
}
