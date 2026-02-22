import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/api_service.dart';

/// 歌手筛选条件Provider
final singerFilterOptionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(apiServiceProvider).getSingerFilterOptions();
});

/// Typed params for singer list requests. Using an immutable, comparable
/// key prevents Riverpod from recreating the provider on every rebuild
/// (which happens when passing a freshly created Map literal).
class SingerListParams {
  const SingerListParams({
    required this.area,
    required this.genre,
    required this.index,
    required this.sex,
    required this.page,
    required this.size,
  });

  final int area;
  final int genre;
  final int index;
  final int sex;
  final int page;
  final int size;

  Map<String, dynamic> toMap() => {
        'area': area,
        'genre': genre,
        'index': index,
        'sex': sex,
        'page': page,
        'size': size,
      };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SingerListParams &&
            other.area == area &&
            other.genre == genre &&
            other.index == index &&
            other.sex == sex &&
            other.page == page &&
            other.size == size);
  }

  @override
  int get hashCode => Object.hash(area, genre, index, sex, page, size);
}

/// 歌手列表Provider — keyed by a stable `SingerListParams` object.
final singerListProvider = FutureProvider.family<Map<String, dynamic>, SingerListParams>(
  (ref, params) async {
    return ref.read(apiServiceProvider).getSingerFilterList(params.toMap());
  },
);
