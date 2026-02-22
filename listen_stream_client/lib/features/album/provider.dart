import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_policy.dart';
import '../../core/cache/ttl_constants.dart';
import '../../data/remote/api_service.dart';
import '../../data/models/models.dart';

/// 专辑详情 Provider
final albumDetailProvider = StreamProvider.family<AlbumDetail, String>((ref, mid) {
  final policy = ref.read(cachePolicyProvider);
  final api = ref.read(apiServiceProvider);
  
  return policy.fetch(
    cacheKey: 'album:detail:$mid',
    ttlSeconds: TtlConstants.albumDetail,
    networkFetch: () async {
      final detail = await api.getAlbumDetail(mid);
      // fetch songs separately and merge into detail.data.songList
      final songs = await api.getAlbumSongs(mid);
      final merged = Map<String, dynamic>.from(detail);
      final data = Map<String, dynamic>.from(merged['data'] as Map<String, dynamic>);
      data['songList'] = (songs['data'] as Map<String, dynamic>)['list'] ?? [];
      merged['data'] = data;
      return merged;
    },
    fromJson: (j) => j,
  ).map((r) {
    final data = r.data;
    return AlbumDetail.fromJson(data['data'] as Map<String, dynamic>);
  });
});
