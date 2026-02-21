/// 专辑详情
class AlbumDetail {
  const AlbumDetail({
    required this.albumMid,
    required this.albumName,
    required this.publishDate,
    required this.desc,
    this.singerName,
    this.singerMid,
    this.songList = const [],
  });

  final String albumMid;
  final String albumName;
  final String publishDate;
  final String desc;
  final String? singerName;
  final String? singerMid;
  final List<AlbumSong> songList;

  factory AlbumDetail.fromJson(Map<String, dynamic> json) {
    final basicInfo = json['basicInfo'] as Map<String, dynamic>?;
    final singerInfo = json['singerInfo'] as Map<String, dynamic>?;
    final songList = json['songList'] as List?;

    return AlbumDetail(
      albumMid: basicInfo?['albumMid'] as String? ?? '',
      albumName: basicInfo?['albumName'] as String? ?? '',
      publishDate: basicInfo?['publishDate'] as String? ?? '',
      desc: basicInfo?['desc'] as String? ?? '',
      singerName: singerInfo?['name'] as String?,
      singerMid: singerInfo?['mid'] as String?,
      songList: songList?.map((s) => AlbumSong.fromJson(s as Map<String, dynamic>)).toList() ?? [],
    );
  }

  String get coverUrl => 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg';
}

/// 专辑歌曲
class AlbumSong {
  const AlbumSong({
    required this.songMid,
    required this.songName,
    required this.interval,
    this.singerName,
  });

  final String songMid;
  final String songName;
  final int interval;
  final String? singerName;

  factory AlbumSong.fromJson(Map<String, dynamic> json) {
    final songInfo = json['songInfo'] as Map<String, dynamic>?;
    final singers = json['singer'] as List?;
    final singerName = singers?.map((s) => s['name'] as String? ?? '').join('、');

    return AlbumSong(
      songMid: songInfo?['mid'] as String? ?? '',
      songName: songInfo?['name'] as String? ?? '',
      interval: songInfo?['interval'] as int? ?? 0,
      singerName: singerName,
    );
  }

  String get durationText {
    final min = interval ~/ 60;
    final sec = interval % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
