import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_policy.dart';
import '../../core/cache/ttl_constants.dart';
import '../../data/remote/api_service.dart';
import '../../data/models/models.dart';

/// 歌单详情 Provider
final playlistDetailProvider = StreamProvider.family<PlaylistDetail, String>((ref, id) {
  final policy = ref.read(cachePolicyProvider);
  final api = ref.read(apiServiceProvider);
  
  return policy.fetch(
    cacheKey: 'playlist:detail:$id',
    ttlSeconds: TtlConstants.playlistDetail,
    networkFetch: () => api.getPlaylistDetail(id),
    fromJson: (j) => j,
  ).map((r) {
    final data = r.data;
    if (data['data'] is List && (data['data'] as List).isNotEmpty) {
      return PlaylistDetail.fromJson((data['data'] as List).first as Map<String, dynamic>);
    }
    throw Exception('Playlist not found');
  });
});
