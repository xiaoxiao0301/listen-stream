/// 歌单详情
class PlaylistDetail {
  const PlaylistDetail({
    required this.dissid,
    required this.dissname,
    required this.logo,
    required this.desc,
    required this.nick,
    required this.songnum,
    this.songlist = const [],
  });

  final int dissid;
  final String dissname;
  final String logo;
  final String desc;
  final String nick;
  final int songnum;
  final List<SongDetail> songlist;

  factory PlaylistDetail.fromJson(Map<String, dynamic> json) {
    final songs = json['songlist'] as List?;
    return PlaylistDetail(
      dissid: json['dissid'] as int? ?? 0,
      dissname: json['dissname'] as String? ?? '',
      logo: json['logo'] as String? ?? json['dir_pic_url2'] as String? ?? '',
      desc: json['desc'] as String? ?? '',
      nick: json['nick'] as String? ?? json['nickname'] as String? ?? '',
      songnum: json['songnum'] as int? ?? json['total_song_num'] as int? ?? 0,
      songlist: songs?.map((s) => SongDetail.fromJson(s as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

/// 歌曲详情（完整信息）
class SongDetail {
  const SongDetail({
    required this.id,
    required this.mid,
    required this.name,
    required this.singerName,
    required this.albumName,
    this.albumMid,
    this.interval = 0,
  });

  final int id;
  final String mid;
  final String name;
  final String singerName;
  final String albumName;
  final String? albumMid;
  final int interval; // 时长（秒）

  factory SongDetail.fromJson(Map<String, dynamic> json) {
    final singers = json['singer'] as List?;
    final singerName = singers?.map((s) => s['name'] as String? ?? '').join('、') ?? '';
    
    final album = json['album'] as Map<String, dynamic>?;
    final albumName = album?['name'] as String? ?? json['albumname'] as String? ?? '';
    final albumMid = album?['mid'] as String? ?? json['albummid'] as String?;

    return SongDetail(
      id: json['id'] as int? ?? 0,
      mid: json['mid'] as String? ?? '',
      name: json['name'] as String? ?? json['title'] as String? ?? '',
      singerName: singerName,
      albumName: albumName,
      albumMid: albumMid,
      interval: json['interval'] as int? ?? 0,
    );
  }

  String get durationText {
    final min = interval ~/ 60;
    final sec = interval % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  String get coverUrl => albumMid != null && albumMid!.isNotEmpty
      ? 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg'
      : '';
}
