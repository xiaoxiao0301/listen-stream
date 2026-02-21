import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import 'layouts/home_mobile.dart';
import 'layouts/home_desktop.dart';

/// 首页 - 使用响应式布局
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
        centerTitle: false,
      ),
      body: ResponsiveBuilder(
        mobile: (context) => const HomeMobileLayout(),
        tablet: (context) => const HomeMobileLayout(),
        desktop: (context) => const HomeDesktopLayout(),
      ),
    );
  }
}
