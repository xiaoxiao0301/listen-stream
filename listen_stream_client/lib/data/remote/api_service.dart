import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_client.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.read(networkClientProvider));
});

/// Central wrapper for all REST endpoints.
/// Feature providers should call through ApiService rather than Dio directly.
class ApiService {
  ApiService(this._dio);
  final Dio _dio;

  // ── Auth ────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> sendSmsCode(String phone) async {
    final r = await _dio.post<Map<String, dynamic>>('/auth/sms/send', data: {'phone': phone});
    return r.data!;
  }

  // ── Proxy: Recommend ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getRecommendBanner() async =>
      (await _dio.get<Map<String, dynamic>>('/api/recommend/banner')).data!;
  Future<Map<String, dynamic>> getRecommendPlaylist() async =>
      (await _dio.get<Map<String, dynamic>>('/api/recommend/playlist')).data!;
  Future<Map<String, dynamic>> getRecommendNewSongs() async =>
      (await _dio.get<Map<String, dynamic>>('/api/recommend/new-songs')).data!;
  Future<Map<String, dynamic>> getRecommendNewAlbums() async =>
      (await _dio.get<Map<String, dynamic>>('/api/recommend/new-albums')).data!;
  Future<Map<String, dynamic>> getRecommendDaily() async =>
      (await _dio.get<Map<String, dynamic>>('/api/recommend/daily')).data!;

  // ── Proxy: Playlist ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getPlaylistCategories() async =>
      (await _dio.get<Map<String, dynamic>>('/api/playlist/categories')).data!;
  Future<Map<String, dynamic>> getPlaylistDetail(String id) async =>
      (await _dio.get<Map<String, dynamic>>('/api/playlist/detail', queryParameters: {'id': id})).data!;

  // ── Proxy: Singer ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSingerFilterOptions() async =>
      (await _dio.get<Map<String, dynamic>>('/api/singer/filter')).data!;
  Future<Map<String, dynamic>> getSingerFilterList(Map<String, dynamic> params) async =>
      (await _dio.get<Map<String, dynamic>>('/api/singer/list', queryParameters: params)).data!;
  Future<Map<String, dynamic>> getSingerDetail(String mid) async =>
      (await _dio.get<Map<String, dynamic>>('/api/singer/detail', queryParameters: {'mid': mid})).data!;
  Future<Map<String, dynamic>> getSingerSongs(String mid, {int page = 1, int size = 20}) async =>
      (await _dio.get<Map<String, dynamic>>('/api/singer/songs', queryParameters: {'mid': mid, 'page': page, 'size': size})).data!;
  Future<Map<String, dynamic>> getSingerAlbums(String mid, {int page = 1, int size = 20}) async =>
      (await _dio.get<Map<String, dynamic>>('/api/singer/albums', queryParameters: {'mid': mid, 'page': page, 'size': size})).data!;
  Future<Map<String, dynamic>> getSingerMvs(String mid, {int page = 1, int size = 20}) async =>
      (await _dio.get<Map<String, dynamic>>('/api/singer/mvs', queryParameters: {'mid': mid, 'page': page, 'size': size})).data!;

  // ── Proxy: Album ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getAlbumDetail(String mid) async =>
      (await _dio.get<Map<String, dynamic>>('/api/album/detail', queryParameters: {'mid': mid})).data!;
  Future<Map<String, dynamic>> getAlbumSongs(String mid) async =>
      (await _dio.get<Map<String, dynamic>>('/api/album/songs', queryParameters: {'mid': mid})).data!;

  // ── Proxy: Search ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSearchHotKeys() async =>
      (await _dio.get<Map<String, dynamic>>('/api/search/hotkey')).data!;
  Future<Map<String, dynamic>> searchSongs(String q, {int page = 1, int size = 20}) async =>
      (await _dio.get<Map<String, dynamic>>('/api/search/songs', queryParameters: {'keyword': q, 'page': page, 'size': size})).data!;
  Future<Map<String, dynamic>> searchSingers(String q, {int page = 1, int size = 20}) async =>
      (await _dio.get<Map<String, dynamic>>('/api/search/singers', queryParameters: {'keyword': q, 'page': page, 'size': size})).data!;
  Future<Map<String, dynamic>> searchAlbums(String q, {int page = 1, int size = 20}) async =>
      (await _dio.get<Map<String, dynamic>>('/api/search/albums', queryParameters: {'keyword': q, 'page': page, 'size': size})).data!;
  Future<Map<String, dynamic>> searchMvs(String q, {int page = 1, int size = 20}) async =>
      (await _dio.get<Map<String, dynamic>>('/api/search/mvs', queryParameters: {'keyword': q, 'page': page, 'size': size})).data!;

  // ── Proxy: Song URL (no-cache) ──────────────────────────────────────────────
  Future<String> getSongUrl(String mid) async {
    final r = await _dio.get<Map<String, dynamic>>('/api/song/url',
        queryParameters: {'mid': mid},
        options: Options(extra: {'noCache': true}));
    return r.data!['url'] as String;
  }

  // ── Proxy: Lyric ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getLyric(String mid) async =>
      (await _dio.get<Map<String, dynamic>>('/api/lyric', queryParameters: {'mid': mid})).data!;

  // ── Proxy: Ranking ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getRankingList() async =>
      (await _dio.get<Map<String, dynamic>>('/api/ranking/list')).data!;
  Future<Map<String, dynamic>> getRankingDetail(String id, {int page = 1}) async =>
      (await _dio.get<Map<String, dynamic>>('/api/ranking/detail', queryParameters: {'id': id, 'page': page})).data!;

  // ── Proxy: Radio ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getRadioList() async =>
      (await _dio.get<Map<String, dynamic>>('/api/radio/list')).data!;
  Future<Map<String, dynamic>> getRadioSongs(String radioId) async =>
      (await _dio.get<Map<String, dynamic>>('/api/radio/songs', queryParameters: {'id': radioId})).data!;

  // ── Proxy: MV ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMVCategories() async =>
      (await _dio.get<Map<String, dynamic>>('/api/mv/categories')).data!;
  Future<Map<String, dynamic>> getMVList({String? areaId, String? typeId, int page = 1}) async =>
      (await _dio.get<Map<String, dynamic>>('/api/mv/list', queryParameters: {
        if (areaId != null) 'area': areaId,
        if (typeId != null) 'type': typeId,
        'page': page,
      })).data!;
  Future<Map<String, dynamic>> getMVDetail(String vid) async =>
      (await _dio.get<Map<String, dynamic>>('/api/mv/detail', queryParameters: {'vid': vid})).data!;

  // ── Sync: User data ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getUserSync({DateTime? since}) async {
    final params = since != null ? {'since': since.toIso8601String()} : null;
    return (await _dio.get<Map<String, dynamic>>('/user/sync', queryParameters: params)).data!;
  }

  Future<void> addFavorite(String type, String targetId) =>
      _dio.post<void>('/user/favorites', data: {'type': type, 'targetId': targetId});
  Future<void> removeFavorite(String favoriteId) =>
      _dio.delete<void>('/user/favorites/$favoriteId');
  Future<Map<String, dynamic>> getFavorites({int page = 1, int size = 20}) async =>
      (await _dio.get<Map<String, dynamic>>('/user/favorites', queryParameters: {'page': page, 'size': size})).data!;

  Future<void> reportProgress(String songMid, int seconds) =>
      _dio.post<void>('/user/progress', data: {'songMid': songMid, 'progress': seconds});
  Future<Map<String, dynamic>?> getProgress(String songMid) async {
    try {
      return (await _dio.get<Map<String, dynamic>>('/user/progress', queryParameters: {'songMid': songMid})).data;
    } catch (_) { return null; }
  }
}
