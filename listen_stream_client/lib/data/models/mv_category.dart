import 'package:freezed_annotation/freezed_annotation.dart';

part 'mv_category.freezed.dart';
part 'mv_category.g.dart';

/// MV分类选项
@freezed
class MvCategoryOptions with _$MvCategoryOptions {
  const factory MvCategoryOptions({
    required List<MvFilterItem> area,
    required List<MvFilterItem> version,
  }) = _MvCategoryOptions;

  factory MvCategoryOptions.fromJson(Map<String, dynamic> json) =>
      _$MvCategoryOptionsFromJson(json);
}

/// MV筛选条件项
@freezed
class MvFilterItem with _$MvFilterItem {
  const factory MvFilterItem({
    required int id,
    required String name,
  }) = _MvFilterItem;

  factory MvFilterItem.fromJson(Map<String, dynamic> json) =>
      _$MvFilterItemFromJson(json);
}

/// MV信息
@freezed
class MvItem with _$MvItem {
  const factory MvItem({
    required int mvid,
    required String title,
    required String vid,
    required String picurl,
    required List<MvSinger> singers,
    required int playcnt,
    required int duration,
    @Default('') String subtitle,
    @JsonKey(name: 'pubdate') required int pubDate,
    @JsonKey(name: 'comment_cnt') @Default(0) int commentCount,
    @JsonKey(name: 'star_cnt') @Default(0) int starCount,
    @JsonKey(name: 'has_fav') @Default(0) int hasFav,
    @JsonKey(name: 'has_star') @Default(0) int hasStar,
    @JsonKey(name: 'mv_switch') @Default(0) int mvSwitch,
    @Default(0) int diff,
    @Default(0) double score,
  }) = _MvItem;

  factory MvItem.fromJson(Map<String, dynamic> json) =>
      _$MvItemFromJson(json);
}

/// MV歌手信息
@freezed
class MvSinger with _$MvSinger {
  const factory MvSinger({
    required int id,
    required String mid,
    required String name,
    required String picurl,
  }) = _MvSinger;

  factory MvSinger.fromJson(Map<String, dynamic> json) =>
      _$MvSingerFromJson(json);
}

/// MV列表响应
@freezed
class MvListResponse with _$MvListResponse {
  const factory MvListResponse({
    required List<MvItem> list,
    required int total,
    required int area,
    required int version,
    required int page,
    required int size,
  }) = _MvListResponse;

  factory MvListResponse.fromJson(Map<String, dynamic> json) =>
      _$MvListResponseFromJson(json);
}
