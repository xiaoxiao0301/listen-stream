import 'song.dart';

/// 电台分组
class RadioGroup {
  const RadioGroup({
    required this.id,
    required this.title,
    required this.radios,
  });

  final int id;
  final String title;
  final List<RadioStation> radios;

  factory RadioGroup.fromJson(Map<String, dynamic> json) {
    return RadioGroup(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      radios: (json['list'] as List?)
              ?.map((e) => RadioStation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 电台
class RadioStation {
  const RadioStation({
    required this.id,
    required this.title,
    required this.picUrl,
    this.listenDesc,
    this.listenNum = 0,
  });

  final int id;
  final String title;
  final String picUrl;
  final String? listenDesc;
  final int listenNum;

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      picUrl: json['pic_url'] as String? ?? '',
      listenDesc: json['listenDesc'] as String?,
      listenNum: json['listenNum'] as int? ?? 0,
    );
  }

  String get listenNumText {
    if (listenNum >= 10000) {
      return '${(listenNum / 10000).toStringAsFixed(1)}万';
    } else {
      return listenNum.toString();
    }
  }
}

/// 电台详情（包含歌曲列表）
class RadioDetail {
  const RadioDetail({
    required this.id,
    required this.name,
    required this.tracks,
  });

  final int id;
  final String name;
  final List<Song> tracks;

  factory RadioDetail.fromJson(Map<String, dynamic> json) {
    return RadioDetail(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      tracks: (json['tracks'] as List?)
              ?.map((e) => Song.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
