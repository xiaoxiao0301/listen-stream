/// 推荐歌单项，只包含显示需要的字段
class PlaylistItem {
  const PlaylistItem({
    required this.id,
    required this.title,
    required this.coverUrl,
    this.creatorNick,
    this.desc,
    this.songCount = 0,
  });

  final String id;  // Unified ID field (can be tid or dissid from API)
  final String title;
  final String coverUrl;
  final String? creatorNick;
  final String? desc;
  final int songCount;

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    final creator = json['creator_info'] as Map<String, dynamic>?;
    final songIds = json['song_ids'] as List?;
    
    // Support multiple ID field names from different APIs
    String playlistId;
    if (json['dissid'] != null) {
      playlistId = json['dissid'].toString();  // From recommend_daily or playlist_information
    } else if (json['tid'] != null) {
      playlistId = json['tid'].toString();  // From recommend_playlist
    } else if (json['disstid'] != null) {
      playlistId = json['disstid'].toString();  // Alternative field in recommend_daily
    } else {
      playlistId = '0';
    }
    
    return PlaylistItem(
      id: playlistId,
      title: json['title'] as String? ?? 
             json['dissname'] as String? ?? '',  // Support both field names
      coverUrl: json['cover_url_big'] as String? ?? 
                json['cover_url_medium'] as String? ?? 
                json['cover_url_small'] as String? ?? 
                json['imgurl'] as String? ??  // From playlist_information
                json['logo'] as String? ?? '',  // From recommend_daily
      creatorNick: creator?['nick'] as String? ?? 
                   json['nickname'] as String?,  // From recommend_daily
      desc: json['desc'] as String? ?? 
            json['introduction'] as String?,  // From playlist_information
      songCount: songIds?.length ?? 0,
    );
  }
}
