/// 搜索热词
class SearchHotKey {
  const SearchHotKey({
    required this.keyword,
    required this.searchCount,
  });

  final String keyword;
  final int searchCount;

  factory SearchHotKey.fromJson(Map<String, dynamic> json) {
    return SearchHotKey(
      keyword: json['k'] as String? ?? '',
      searchCount: json['n'] as int? ?? 0,
    );
  }
}

/// 搜索结果（歌曲）
class SearchResultSong {
  const SearchResultSong({
    required this.songId,
    required this.songMid,
    required this.songName,
    required this.singerName,
    required this.albumName,
    required this.albumMid,
    this.interval = 0,
  });

  final int songId;
  final String songMid;
  final String songName;
  final String singerName;
  final String albumName;
  final String albumMid;
  final int interval;

  factory SearchResultSong.fromJson(Map<String, dynamic> json) {
    final singers = json['singer'] as List?;
    final singerName = singers?.map((s) => 
      (s['name'] as String? ?? '').replaceAll(RegExp(r'</?em>'), '')
    ).join('、') ?? '';

    return SearchResultSong(
      songId: json['albumid'] as int? ?? 0,
      songMid: json['media_mid'] as String? ?? json['mid'] as String? ?? '',
      songName: (json['songname'] as String? ?? json['name'] as String? ?? '').replaceAll(RegExp(r'</?em>'), ''),
      singerName: singerName,
      albumName: (json['albumname'] as String? ?? '').replaceAll(RegExp(r'</?em>'), ''),
      albumMid: json['albummid'] as String? ?? '',
      interval: json['interval'] as int? ?? 0,
    );
  }

  String get coverUrl => 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg';
  
  String get durationText {
    final min = interval ~/ 60;
    final sec = interval % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}

/// 搜索结果（歌手）
class SearchResultSinger {
  const SearchResultSinger({
    required this.singerId,
    required this.singerMid,
    required this.singerName,
    this.albumCount = 0,
    this.songCount = 0,
  });

  final int singerId;
  final String singerMid;
  final String singerName;
  final int albumCount;
  final int songCount;

  factory SearchResultSinger.fromJson(Map<String, dynamic> json) {
    return SearchResultSinger(
      singerId: json['singer_id'] as int? ?? json['id'] as int? ?? 0,
      singerMid: json['singer_mid'] as String? ?? json['mid'] as String? ?? '',
      singerName: (json['singer_name'] as String? ?? json['name'] as String? ?? '').replaceAll(RegExp(r'</?em>'), ''),
      albumCount: json['albumNum'] as int? ?? 0,
      songCount: json['songNum'] as int? ?? 0,
    );
  }

  String get avatarUrl => 'https://y.gtimg.cn/music/photo_new/T001R300x300M000$singerMid.jpg';
}

/// 搜索结果（专辑）
class SearchResultAlbum {
  const SearchResultAlbum({
    required this.albumId,
    required this.albumMid,
    required this.albumName,
    required this.singerName,
    this.publishTime,
  });

  final int albumId;
  final String albumMid;
  final String albumName;
  final String singerName;
  final String? publishTime;

  factory SearchResultAlbum.fromJson(Map<String, dynamic> json) {
    return SearchResultAlbum(
      albumId: json['albumID'] as int? ?? json['id'] as int? ?? 0,
      albumMid: json['albumMid'] as String? ?? json['mid'] as String? ?? '',
      albumName: (json['albumName'] as String? ?? json['name'] as String? ?? '').replaceAll(RegExp(r'</?em>'), ''),
      singerName: (json['singer_name'] as String? ?? '').replaceAll(RegExp(r'</?em>'), ''),
      publishTime: json['publicTime'] as String?,
    );
  }

  String get coverUrl => 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg';
}

/// 搜索结果（MV）
class SearchResultMV {
  const SearchResultMV({
    required this.vid,
    required this.mvName,
    required this.singerName,
    this.duration = 0,
  });

  final String vid;
  final String mvName;
  final String singerName;
  final int duration;

  factory SearchResultMV.fromJson(Map<String, dynamic> json) {
    final singers = json['singer_list'] as List?;
    final singerName = singers?.map((s) => 
      (s['name'] as String? ?? '').replaceAll(RegExp(r'</?em>'), '')
    ).join('、') ?? '';

    return SearchResultMV(
      vid: json['vid'] as String? ?? '',
      mvName: (json['mv_name'] as String? ?? json['title'] as String? ?? '').replaceAll(RegExp(r'</?em>'), ''),
      singerName: singerName,
      duration: json['duration'] as int? ?? 0,
    );
  }

  String get coverUrl => 'https://y.gtimg.cn/music/photo_new/T015R640x360M000$vid.jpg';
  
  String get durationText {
    final min = duration ~/ 60;
    final sec = duration % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
