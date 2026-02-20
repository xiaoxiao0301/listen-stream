/// Client-side TTL map — mirrors proxy-svc ProxyTTL to avoid stale UI.
/// Values in seconds.
class TtlConstants {
  const TtlConstants._();

  static const recommendBanner    = 300;
  static const recommendPlaylist  = 600;
  static const recommendNewSongs  = 600;
  static const recommendNewAlbums = 600;
  static const recommendDaily     = 86400;

  static const playlistDetail     = 1800;
  static const singerDetail       = 86400;
  static const singerSongs        = 3600;
  static const singerAlbums       = 3600;
  static const singerMvs          = 3600;
  static const albumDetail        = 86400;
  static const albumSongs         = 86400;
  static const lyric              = 86400 * 30;  // 30 days

  static const rankingList        = 3600;
  static const rankingDetail      = 3600;
  static const radioList          = 86400;
  static const mvCategoryList     = 86400;
  static const searchHotKey       = 3600;

  /// TTL for search results (shorter — results change frequently).
  static const searchResults       = 300;
}
