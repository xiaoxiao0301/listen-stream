import 'package:freezed_annotation/freezed_annotation.dart';

part 'singer_filter.freezed.dart';
part 'singer_filter.g.dart';

/// 歌手筛选条件
@freezed
class SingerFilterOptions with _$SingerFilterOptions {
  const factory SingerFilterOptions({
    required List<FilterItem> area,
    required List<FilterItem> genre,
    required List<FilterItem> index,
    required List<FilterItem> sex,
  }) = _SingerFilterOptions;

  factory SingerFilterOptions.fromJson(Map<String, dynamic> json) =>
      _$SingerFilterOptionsFromJson(json);
}

/// 筛选条件项
@freezed
class FilterItem with _$FilterItem {
  const factory FilterItem({
    required int id,
    required String name,
  }) = _FilterItem;

  factory FilterItem.fromJson(Map<String, dynamic> json) =>
      _$FilterItemFromJson(json);
}

/// 歌手信息
@freezed
class SingerItem with _$SingerItem {
  const factory SingerItem({
    @JsonKey(name: 'singer_id') required int singerId,
    @JsonKey(name: 'singer_name') required String singerName,
    @JsonKey(name: 'singer_mid') required String singerMid,
    @JsonKey(name: 'singer_pic') required String singerPic,
    @JsonKey(name: 'other_name') required String otherName,
    @Default('') String spell,
    @JsonKey(name: 'area_id') @Default(0) int areaId,
    @JsonKey(name: 'country_id') @Default(0) int countryId,
    @Default('') String country,
    @JsonKey(name: 'singer_pmid') @Default('') String singerPmid,
    @JsonKey(name: 'concernNum') @Default(0) int concernNum,
    @Default(0) int trend,
  }) = _SingerItem;

  factory SingerItem.fromJson(Map<String, dynamic> json) =>
      _$SingerItemFromJson(json);
}

/// 歌手列表响应
@freezed
class SingerListResponse with _$SingerListResponse {
  const factory SingerListResponse({
    required List<SingerItem> singerList,
    @Default({}) Map<String, dynamic> tags,
  }) = _SingerListResponse;

  factory SingerListResponse.fromJson(Map<String, dynamic> json) =>
      _$SingerListResponseFromJson(json);
}
