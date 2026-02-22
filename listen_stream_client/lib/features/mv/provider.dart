import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_policy.dart';
import '../../core/cache/ttl_constants.dart';
import '../../data/remote/api_service.dart';

/// Provider for MV detail by video ID.
final mvDetailFamily = StreamProvider.family<Map<String, dynamic>, String>(
  (ref, vid) {
    final policy = ref.read(cachePolicyProvider);
    final api = ref.read(apiServiceProvider);
    return policy.fetch(
      cacheKey: 'mv:detail:$vid',
      ttlSeconds: TtlConstants.singerMvs, // 1 hour - can be updated to dedicated constant
      networkFetch: () => api.getMVDetail(vid),
      fromJson: (j) => j,
    ).map((r) => (r.data['data'] as Map<String, dynamic>?) ?? {});
  },
);
