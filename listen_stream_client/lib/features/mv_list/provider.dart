import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/api_service.dart';

/// MV分类选项Provider
final mvCategoriesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(apiServiceProvider).getMVCategories();
});

/// MV列表Provider
/// 参数: areaId, typeId, page
class MvListParams {
  const MvListParams({this.areaId, this.typeId, this.page = 1});

  final String? areaId;
  final String? typeId;
  final int page;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MvListParams &&
            runtimeType == other.runtimeType &&
            areaId == other.areaId &&
            typeId == other.typeId &&
            page == other.page;
  }

  @override
  int get hashCode => Object.hash(areaId, typeId, page);
}

final mvListProvider = FutureProvider.family<Map<String, dynamic>, MvListParams>(
  (ref, params) async {
    final api = ref.read(apiServiceProvider);
    return api.getMVList(
      areaId: params.areaId,
      typeId: params.typeId,
      page: params.page,
    );
  },
);
