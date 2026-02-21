import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/api_service.dart';

/// 歌手筛选条件Provider
final singerFilterOptionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(apiServiceProvider).getSingerFilterOptions();
});

/// 歌手列表Provider
/// 参数: area, genre, index, sex, page, size
final singerListProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
  (ref, params) async {
    return ref.read(apiServiceProvider).getSingerFilterList(params);
  },
);
