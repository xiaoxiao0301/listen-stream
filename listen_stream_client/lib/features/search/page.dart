import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import 'layouts/search_mobile.dart';
import 'layouts/search_desktop.dart';

/// 搜索页面 - 使用响应式布局
class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索'),
        centerTitle: false,
      ),
      body: ResponsiveBuilder(
        mobile: (context) => const SearchMobileLayout(),
        tablet: (context) => const SearchMobileLayout(),
        desktop: (context) => const SearchDesktopLayout(),
      ),
    );
  }
}
