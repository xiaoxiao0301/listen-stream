import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_policy.dart';
import '../../core/cache/ttl_constants.dart';
import '../../data/remote/api_service.dart';

final singerDetailFamily = StreamProvider.family<Map<String, dynamic>, String>((ref, mid) {
  final policy = ref.read(cachePolicyProvider);
  final api = ref.read(apiServiceProvider);
  return policy.fetch(
    cacheKey: 'singer:detail:$mid',
    ttlSeconds: TtlConstants.singerDetail,
    networkFetch: () => api.getSingerDetail(mid),
    fromJson: (j) => j,
  ).map((r) => (r.data['data'] as Map<String, dynamic>?) ?? {});
});

final singerSongsFamily = StreamProvider.family<Map<String, dynamic>, String>((ref, mid) {
  final policy = ref.read(cachePolicyProvider);
  final api = ref.read(apiServiceProvider);
  return policy.fetch(
    cacheKey: 'singer:songs:$mid',
    ttlSeconds: TtlConstants.singerSongs,
    networkFetch: () => api.getSingerSongs(mid),
    fromJson: (j) => j,
  ).map((r) => (r.data['data'] as Map<String, dynamic>?) ?? {});
});

final singerAlbumsFamily = StreamProvider.family<Map<String, dynamic>, String>((ref, mid) {
  final policy = ref.read(cachePolicyProvider);
  final api = ref.read(apiServiceProvider);
  return policy.fetch(
    cacheKey: 'singer:albums:$mid',
    ttlSeconds: TtlConstants.singerAlbums,
    networkFetch: () => api.getSingerAlbums(mid),
    fromJson: (j) => j,
  ).map((r) => (r.data['data'] as Map<String, dynamic>?) ?? {});
});

final singerMvsFamily = StreamProvider.family<Map<String, dynamic>, String>((ref, mid) {
  final policy = ref.read(cachePolicyProvider);
  final api = ref.read(apiServiceProvider);
  return policy.fetch(
    cacheKey: 'singer:mvs:$mid',
    ttlSeconds: TtlConstants.singerMvs,
    networkFetch: () => api.getSingerMvs(mid),
    fromJson: (j) => j,
  ).map((r) => (r.data['data'] as Map<String, dynamic>?) ?? {});
});
