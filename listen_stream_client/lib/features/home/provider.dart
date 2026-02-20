import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_policy.dart';
import '../../core/cache/ttl_constants.dart';
import '../../data/remote/api_service.dart';

// ── Banner ──────────────────────────────────────────────────────────────────
final bannerProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final policy = ref.read(cachePolicyProvider);
  final api = ref.read(apiServiceProvider);
  return policy.fetch(
    cacheKey: 'recommend:banner',
    ttlSeconds: TtlConstants.recommendBanner,
    networkFetch: api.getRecommendBanner,
    fromJson: (j) => j,
  ).map((r) => r.data);
});

// ── Recommend Playlist ────────────────────────────────────────────────────
final recommendPlaylistProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final policy = ref.read(cachePolicyProvider);
  final api = ref.read(apiServiceProvider);
  return policy.fetch(
    cacheKey: 'recommend:playlist',
    ttlSeconds: TtlConstants.recommendPlaylist,
    networkFetch: api.getRecommendPlaylist,
    fromJson: (j) => j,
  ).map((r) => r.data);
});

// ── New Songs (lazy) ───────────────────────────────────────────────────────
final recommendNewSongsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final policy = ref.read(cachePolicyProvider);
  final api = ref.read(apiServiceProvider);
  return policy.fetch(
    cacheKey: 'recommend:new_songs',
    ttlSeconds: TtlConstants.recommendNewSongs,
    networkFetch: api.getRecommendNewSongs,
    fromJson: (j) => j,
  ).map((r) => r.data);
});

// ── New Albums (lazy) ─────────────────────────────────────────────────────
final recommendNewAlbumsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final policy = ref.read(cachePolicyProvider);
  final api = ref.read(apiServiceProvider);
  return policy.fetch(
    cacheKey: 'recommend:new_albums',
    ttlSeconds: TtlConstants.recommendNewAlbums,
    networkFetch: api.getRecommendNewAlbums,
    fromJson: (j) => j,
  ).map((r) => r.data);
});
