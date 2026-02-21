import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/api_service.dart';

/// MV分类选项Provider
final mvCategoriesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(apiServiceProvider).getMVCategories();
});

/// MV列表Provider
/// 参数: areaId, typeId, page
final mvListProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
  (ref, params) async {
    final api = ref.read(apiServiceProvider);
    return api.getMVList(
      areaId: params['areaId'] as String?,
      typeId: params['typeId'] as String?,
      page: params['page'] as int? ?? 1,
    );
  },
);
