import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ranking.dart';
import '../../data/remote/api_service.dart';

// ── Ranking List ────────────────────────────────────────────────────────────
final rankingListProvider = FutureProvider<List<RankingGroup>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.getRankingList();
  
  if (resp['code'] != 1) {
    throw Exception(resp['message'] ?? 'Failed to fetch ranking list');
  }
  
  final data = resp['data'] as Map<String, dynamic>?;
  final groups = data?['group'] as List?;
  if (groups == null) return [];
  
  return groups.map((json) => RankingGroup.fromJson(json as Map<String, dynamic>)).toList();
});

// ── Ranking Detail ──────────────────────────────────────────────────────────
final rankingDetailProvider = FutureProvider.family<RankingCategory, ({int topId, int page})>((ref, params) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.getRankingDetail(params.topId.toString(), page: params.page);
  
  if (resp['code'] != 1) {
    throw Exception(resp['message'] ?? 'Failed to fetch ranking detail');
  }
  
  final data = resp['data'] as Map<String, dynamic>?;
  if (data == null) {
    throw Exception('No data in response');
  }
  
  return RankingCategory.fromJson(data);
});
