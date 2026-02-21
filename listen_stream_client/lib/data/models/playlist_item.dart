/// 推荐歌单项，只包含显示需要的字段
class PlaylistItem {
  const PlaylistItem({
    required this.tid,
    required this.title,
    required this.coverUrl,
    this.creatorNick,
    this.desc,
    this.songCount = 0,
  });

  final int tid;
  final String title;
  final String coverUrl;
  final String? creatorNick;
  final String? desc;
  final int songCount;

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    final creator = json['creator_info'] as Map<String, dynamic>?;
    final songIds = json['song_ids'] as List?;
    
    return PlaylistItem(
      tid: json['tid'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      coverUrl: json['cover_url_big'] as String? ?? 
                json['cover_url_medium'] as String? ?? 
                json['cover_url_small'] as String? ?? '',
      creatorNick: creator?['nick'] as String?,
      desc: json['desc'] as String?,
      songCount: songIds?.length ?? 0,
    );
  }
}
