import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/radio.dart';
import '../../data/remote/api_service.dart';

// ── Radio List ──────────────────────────────────────────────────────────────
final radioListProvider = FutureProvider<List<RadioGroup>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.getRadioList();
  
  if (resp['code'] != 1) {
    throw Exception(resp['message'] ?? 'Failed to fetch radio list');
  }
  
  final data = resp['data'] as List?;
  if (data == null) return [];
  
  return data.map((json) => RadioGroup.fromJson(json as Map<String, dynamic>)).toList();
});

// ── Radio Songs ─────────────────────────────────────────────────────────────
final radioSongsProvider = FutureProvider.family<RadioDetail, String>((ref, radioId) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.getRadioSongs(radioId);
  
  if (resp['code'] != 1) {
    throw Exception(resp['message'] ?? 'Failed to fetch radio songs');
  }
  
  final data = resp['data'] as Map<String, dynamic>?;
  if (data == null) {
    throw Exception('No data in response');
  }
  
  return RadioDetail.fromJson(data);
});
