import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/search_result.dart';
import '../../data/remote/api_service.dart';

// ── Search Hot Keys ─────────────────────────────────────────────────────────
final searchHotKeysProvider = FutureProvider<List<SearchHotKey>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.getSearchHotKeys();
  
  if (resp['code'] != 1) {
    throw Exception(resp['message'] ?? 'Failed to fetch hot keys');
  }
  
  final data = resp['data'] as List?;
  if (data == null) return [];
  
  return data.map((json) => SearchHotKey.fromJson(json as Map<String, dynamic>)).toList();
});

// ── Search Songs ────────────────────────────────────────────────────────────
final searchSongsProvider = FutureProvider.family<List<SearchResultSong>, ({String keyword, int page})>((ref, params) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.searchSongs(params.keyword, page: params.page);
  
  if (resp['code'] != 1) {
    throw Exception(resp['message'] ?? 'Failed to search songs');
  }
  
  final data = resp['data'] as Map<String, dynamic>?;
  final list = data?['list'] as List?;
  if (list == null) return [];
  
  return list.map((json) => SearchResultSong.fromJson(json as Map<String, dynamic>)).toList();
});

// ── Search Singers ──────────────────────────────────────────────────────────
final searchSingersProvider = FutureProvider.family<List<SearchResultSinger>, ({String keyword, int page})>((ref, params) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.searchSingers(params.keyword, page: params.page);
  
  if (resp['code'] != 1) {
    throw Exception(resp['message'] ?? 'Failed to search singers');
  }
  
  final data = resp['data'] as Map<String, dynamic>?;
  final list = data?['list'] as List?;
  if (list == null) return [];
  
  return list.map((json) => SearchResultSinger.fromJson(json as Map<String, dynamic>)).toList();
});

// ── Search Albums ───────────────────────────────────────────────────────────
final searchAlbumsProvider = FutureProvider.family<List<SearchResultAlbum>, ({String keyword, int page})>((ref, params) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.searchAlbums(params.keyword, page: params.page);
  
  if (resp['code'] != 1) {
    throw Exception(resp['message'] ?? 'Failed to search albums');
  }
  
  final data = resp['data'] as Map<String, dynamic>?;
  final list = data?['list'] as List?;
  if (list == null) return [];
  
  return list.map((json) => SearchResultAlbum.fromJson(json as Map<String, dynamic>)).toList();
});

// ── Search MVs ──────────────────────────────────────────────────────────────
final searchMVsProvider = FutureProvider.family<List<SearchResultMV>, ({String keyword, int page})>((ref, params) async {
  final api = ref.read(apiServiceProvider);
  final resp = await api.searchMvs(params.keyword, page: params.page);
  
  if (resp['code'] != 1) {
    throw Exception(resp['message'] ?? 'Failed to search MVs');
  }
  
  final data = resp['data'] as Map<String, dynamic>?;
  final list = data?['list'] as List?;
  if (list == null) return [];
  
  return list.map((json) => SearchResultMV.fromJson(json as Map<String, dynamic>)).toList();
});

// ── Current Search State ────────────────────────────────────────────────────
class SearchState {
  const SearchState({
    this.keyword = '',
    this.selectedTab = 0,
    this.page = 1,
  });

  final String keyword;
  final int selectedTab;
  final int page;

  SearchState copyWith({String? keyword, int? selectedTab, int? page}) {
    return SearchState(
      keyword: keyword ?? this.keyword,
      selectedTab: selectedTab ?? this.selectedTab,
      page: page ?? this.page,
    );
  }
}

class SearchStateNotifier extends StateNotifier<SearchState> {
  SearchStateNotifier() : super(const SearchState());

  void setKeyword(String keyword) {
    state = state.copyWith(keyword: keyword, page: 1);
  }

  void setTab(int tab) {
    state = state.copyWith(selectedTab: tab, page: 1);
  }

  void nextPage() {
    state = state.copyWith(page: state.page + 1);
  }

  void reset() {
    state = const SearchState();
  }
}

final searchStateProvider = StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
  return SearchStateNotifier();
});
