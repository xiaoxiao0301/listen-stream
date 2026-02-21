// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'singer_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SingerFilterOptionsImpl _$$SingerFilterOptionsImplFromJson(
        Map<String, dynamic> json) =>
    _$SingerFilterOptionsImpl(
      area: (json['area'] as List<dynamic>)
          .map((e) => FilterItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      genre: (json['genre'] as List<dynamic>)
          .map((e) => FilterItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      index: (json['index'] as List<dynamic>)
          .map((e) => FilterItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      sex: (json['sex'] as List<dynamic>)
          .map((e) => FilterItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$SingerFilterOptionsImplToJson(
        _$SingerFilterOptionsImpl instance) =>
    <String, dynamic>{
      'area': instance.area,
      'genre': instance.genre,
      'index': instance.index,
      'sex': instance.sex,
    };

_$FilterItemImpl _$$FilterItemImplFromJson(Map<String, dynamic> json) =>
    _$FilterItemImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$$FilterItemImplToJson(_$FilterItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

_$SingerItemImpl _$$SingerItemImplFromJson(Map<String, dynamic> json) =>
    _$SingerItemImpl(
      singerId: (json['singer_id'] as num).toInt(),
      singerName: json['singer_name'] as String,
      singerMid: json['singer_mid'] as String,
      singerPic: json['singer_pic'] as String,
      otherName: json['other_name'] as String,
      spell: json['spell'] as String? ?? '',
      areaId: (json['area_id'] as num?)?.toInt() ?? 0,
      countryId: (json['country_id'] as num?)?.toInt() ?? 0,
      country: json['country'] as String? ?? '',
      singerPmid: json['singer_pmid'] as String? ?? '',
      concernNum: (json['concernNum'] as num?)?.toInt() ?? 0,
      trend: (json['trend'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$SingerItemImplToJson(_$SingerItemImpl instance) =>
    <String, dynamic>{
      'singer_id': instance.singerId,
      'singer_name': instance.singerName,
      'singer_mid': instance.singerMid,
      'singer_pic': instance.singerPic,
      'other_name': instance.otherName,
      'spell': instance.spell,
      'area_id': instance.areaId,
      'country_id': instance.countryId,
      'country': instance.country,
      'singer_pmid': instance.singerPmid,
      'concernNum': instance.concernNum,
      'trend': instance.trend,
    };

_$SingerListResponseImpl _$$SingerListResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$SingerListResponseImpl(
      singerList: (json['singerList'] as List<dynamic>)
          .map((e) => SingerItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: json['tags'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$SingerListResponseImplToJson(
        _$SingerListResponseImpl instance) =>
    <String, dynamic>{
      'singerList': instance.singerList,
      'tags': instance.tags,
    };
