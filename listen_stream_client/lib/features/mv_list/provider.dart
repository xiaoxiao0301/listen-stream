import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/api_service.dart';

/// MV分类选项Provider
final mvCategoriesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(apiServiceProvider).getMVCategories();
});

/// MV列表Provider
/// 参数: area, version, page, size
final mvListProvider = FutureProvider.family<Map<String, dynamic>, Map<String, int>>(
  (ref, params) async {
    final api = ref.read(apiServiceProvider);
    return api.getMVList(
      area: params['area'] ?? 15,
      version: params['version'] ?? 7,
      page: params['page'] ?? 1,
      size: params['size'] ?? 20,
    );
  },
);
