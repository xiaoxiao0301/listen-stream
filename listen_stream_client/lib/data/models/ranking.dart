/// 排行榜分组
class RankingGroup {
  const RankingGroup({
    required this.groupId,
    required this.groupName,
    required this.topList,
  });

  final int groupId;
  final String groupName;
  final List<RankingCategory> topList;

  factory RankingGroup.fromJson(Map<String, dynamic> json) {
    return RankingGroup(
      groupId: json['groupId'] as int? ?? 0,
      groupName: json['groupName'] as String? ?? '',
      topList: (json['toplist'] as List?)
              ?.map((e) => RankingCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 排行榜分类
class RankingCategory {
  const RankingCategory({
    required this.topId,
    required this.title,
    this.titleDetail,
    this.intro,
    this.period,
    this.updateTime,
    this.listenNum = 0,
    this.totalNum = 0,
    this.songs = const [],
  });

  final int topId;
  final String title;
  final String? titleDetail;
  final String? intro;
  final String? period;
  final String? updateTime;
  final int listenNum;
  final int totalNum;
  final List<RankingSong> songs;

  factory RankingCategory.fromJson(Map<String, dynamic> json) {
    return RankingCategory(
      topId: json['topId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      titleDetail: json['titleDetail'] as String?,
      intro: json['intro'] as String?,
      period: json['period'] as String?,
      updateTime: json['updateTime'] as String?,
      listenNum: json['listenNum'] as int? ?? 0,
      totalNum: json['totalNum'] as int? ?? 0,
      songs: (json['song'] as List?)
              ?.map((e) => RankingSong.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get coverUrl {
    if (songs.isEmpty) return '';
    return songs.first.cover;
  }

  String get listenNumText {
    if (listenNum >= 100000000) {
      return '${(listenNum / 100000000).toStringAsFixed(1)}亿';
    } else if (listenNum >= 10000) {
      return '${(listenNum / 10000).toStringAsFixed(1)}万';
    } else {
      return listenNum.toString();
    }
  }
}

/// 排行榜歌曲
class RankingSong {
  const RankingSong({
    required this.rank,
    required this.songId,
    required this.title,
    required this.singerName,
    required this.singerMid,
    required this.albumMid,
    required this.cover,
    this.rankType = 0,
    this.rankValue,
    this.mvid = 0,
  });

  final int rank;
  final int songId;
  final String title;
  final String singerName;
  final String singerMid;
  final String albumMid;
  final String cover;
  final int rankType; // 6: 上升, 1: 下降, 0: 持平, 2: 新上榜
  final String? rankValue; // 变化百分比或排名变化
  final int mvid;

  factory RankingSong.fromJson(Map<String, dynamic> json) {
    return RankingSong(
      rank: json['rank'] as int? ?? 0,
      songId: json['songId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      singerName: json['singerName'] as String? ?? '',
      singerMid: json['singerMid'] as String? ?? '',
      albumMid: json['albumMid'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      rankType: json['rankType'] as int? ?? 0,
      rankValue: json['rankValue'] as String?,
      mvid: json['mvid'] as int? ?? 0,
    );
  }

  String? get rankIcon {
    switch (rankType) {
      case 6:
        return '↑'; // 上升
      case 1:
        return '↓'; // 下降
      case 2:
        return 'NEW'; // 新上榜
      default:
        return null; // 持平
    }
  }
}
