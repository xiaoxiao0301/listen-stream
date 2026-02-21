/// MV 分类选项
class MVCategoryOption {
  const MVCategoryOption({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory MVCategoryOption.fromJson(Map<String, dynamic> json) {
    return MVCategoryOption(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

/// MV 分类
class MVCategories {
  const MVCategories({
    required this.areas,
    required this.versions,
  });

  final List<MVCategoryOption> areas;
  final List<MVCategoryOption> versions;

  factory MVCategories.fromJson(Map<String, dynamic> json) {
    return MVCategories(
      areas: (json['area'] as List?)
              ?.map((e) => MVCategoryOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      versions: (json['version'] as List?)
              ?.map((e) => MVCategoryOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// MV 条目
class MVItem {
  const MVItem({
    required this.mvid,
    required this.vid,
    required this.title,
    required this.picUrl,
    required this.singers,
    this.duration = 0,
    this.playCount = 0,
  });

  final int mvid;
  final String vid;
  final String title;
  final String picUrl;
  final List<MVSinger> singers;
  final int duration;
  final int playCount;

  factory MVItem.fromJson(Map<String, dynamic> json) {
    return MVItem(
      mvid: json['mvid'] as int? ?? 0,
      vid: json['vid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      picUrl: json['picurl'] as String? ?? '',
      singers: (json['singers'] as List?)
              ?.map((e) => MVSinger.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      duration: json['duration'] as int? ?? 0,
      playCount: json['playcnt'] as int? ?? 0,
    );
  }

  String get singerNames => singers.map((s) => s.name).join('、');

  String get durationText {
    final min = duration ~/ 60;
    final sec = duration % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  String get playCountText {
    if (playCount >= 100000000) {
      return '${(playCount / 100000000).toStringAsFixed(1)}亿';
    } else if (playCount >= 10000) {
      return '${(playCount / 10000).toStringAsFixed(1)}万';
    } else {
      return playCount.toString();
    }
  }
}

/// MV 歌手
class MVSinger {
  const MVSinger({
    required this.id,
    required this.mid,
    required this.name,
    this.picUrl,
  });

  final int id;
  final String mid;
  final String name;
  final String? picUrl;

  factory MVSinger.fromJson(Map<String, dynamic> json) {
    return MVSinger(
      id: json['id'] as int? ?? 0,
      mid: json['mid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      picUrl: json['picurl'] as String?,
    );
  }
}

/// MV 详情
class MVDetail {
  const MVDetail({
    required this.vid,
    required this.title,
    required this.singers,
    required this.picUrl,
    this.desc,
    this.playCount = 0,
    this.duration = 0,
  });

  final String vid;
  final String title;
  final List<MVSinger> singers;
  final String picUrl;
  final String? desc;
  final int playCount;
  final int duration;

  factory MVDetail.fromJson(Map<String, dynamic> json) {
    return MVDetail(
      vid: json['vid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      singers: (json['singers'] as List?)
              ?.map((e) => MVSinger.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      picUrl: json['picurl'] as String? ?? '',
      desc: json['desc'] as String?,
      playCount: json['playcnt'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
    );
  }
}
