/// 完整的歌曲模型
class Song {
  const Song({
    required this.id,
    required this.mid,
    required this.name,
    required this.singerName,
    required this.albumName,
    this.albumMid,
    this.interval = 0,
    this.mvid = 0,
  });

  final int id;
  final String mid;
  final String name;
  final String singerName;
  final String albumName;
  final String? albumMid;
  final int interval; // 时长（秒）
  final int mvid; // MV ID，0 表示无 MV

  factory Song.fromJson(Map<String, dynamic> json) {
    // 处理歌手信息
    final singers = json['singer'] as List?;
    final singerName = singers
            ?.map((s) => s['name'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .join('、') ??
        '';

    // 处理专辑信息
    final album = json['album'] as Map<String, dynamic>?;
    final albumName = album?['name'] as String? ?? album?['title'] as String? ?? '';
    final albumMid = album?['mid'] as String?;

    return Song(
      id: json['id'] as int? ?? json['songId'] as int? ?? 0,
      mid: json['mid'] as String? ?? json['media_mid'] as String? ?? '',
      name: json['name'] as String? ?? json['title'] as String? ?? '',
      singerName: singerName,
      albumName: albumName,
      albumMid: albumMid,
      interval: json['interval'] as int? ?? json['duration'] as int? ?? 0,
      mvid: (json['mv'] as Map<String, dynamic>?)?['id'] as int? ?? json['mvid'] as int? ?? 0,
    );
  }

  String get coverUrl {
    if (albumMid != null && albumMid!.isNotEmpty) {
      return 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg';
    }
    return '';
  }

  String get durationText {
    final min = interval ~/ 60;
    final sec = interval % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  bool get hasMV => mvid > 0;
}
