import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_policy.dart';
import '../../core/cache/ttl_constants.dart';
import '../../data/remote/api_service.dart';
import '../../data/models/models.dart';

// ── Banner ──────────────────────────────────────────────────────────────────
final bannerProvider = StreamProvider<List<BannerItem>>((ref) {
  final policy = ref.read(cachePolicyProvider);
  final api = ref.read(apiServiceProvider);
  return policy.fetch(
    cacheKey: 'recommend:banner',
    ttlSeconds: TtlConstants.recommendBanner,
    networkFetch: api.getRecommendBanner,
    fromJson: (j) => j,
  ).map((r) {
    final data = r.data;
    final list = data['data'] as List? ?? [];
    return list.map((item) => BannerItem.fromJson(item as Map<String, dynamic>)).toList();
  });
});

// ── Recommend Playlist ────────────────────────────────────────────────────
final recommendPlaylistProvider = StreamProvider<List<PlaylistItem>>((ref) {
  final policy = ref.read(cachePolicyProvider);
  final api = ref.read(apiServiceProvider);
  return policy.fetch(
    cacheKey: 'recommend:playlist',
    ttlSeconds: TtlConstants.recommendPlaylist,
    networkFetch: api.getRecommendPlaylist,
    fromJson: (j) => j,
  ).map((r) {
    final data = r.data;
    final dataObj = data['data'] as Map<String, dynamic>? ?? {};
    final list = dataObj['list'] as List? ?? [];
    return list.map((item) => PlaylistItem.fromJson(item as Map<String, dynamic>)).toList();
  });
});

// ── New Songs (lazy) ───────────────────────────────────────────────────────
final recommendNewSongsProvider = StreamProvider<List<SongItem>>((ref) {
  final policy = ref.read(cachePolicyProvider);
  final api = ref.read(apiServiceProvider);
  return policy.fetch(
    cacheKey: 'recommend:new_songs',
    ttlSeconds: TtlConstants.recommendNewSongs,
    networkFetch: api.getRecommendNewSongs,
    fromJson: (j) => j,
  ).map((r) {
    final data = r.data;
    final dataObj = data['data'] as Map<String, dynamic>? ?? {};
    final list = dataObj['list'] as List? ?? [];
    return list.map((item) => SongItem.fromJson(item as Map<String, dynamic>)).toList();
  });
});

// ── New Albums (lazy) ─────────────────────────────────────────────────────
final recommendNewAlbumsProvider = StreamProvider<List<AlbumItem>>((ref) {
  final policy = ref.read(cachePolicyProvider);
  final api = ref.read(apiServiceProvider);
  return policy.fetch(
    cacheKey: 'recommend:new_albums',
    ttlSeconds: TtlConstants.recommendNewAlbums,
    networkFetch: api.getRecommendNewAlbums,
    fromJson: (j) => j,
  ).map((r) {
    final data = r.data;
    final dataObj = data['data'] as Map<String, dynamic>? ?? {};
    final list = dataObj['list'] as List? ?? [];
    return list.map((item) => AlbumItem.fromJson(item as Map<String, dynamic>)).toList();
  });
});
