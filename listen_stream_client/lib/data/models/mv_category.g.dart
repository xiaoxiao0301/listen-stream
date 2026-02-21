// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mv_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MvCategoryOptionsImpl _$$MvCategoryOptionsImplFromJson(
        Map<String, dynamic> json) =>
    _$MvCategoryOptionsImpl(
      area: (json['area'] as List<dynamic>)
          .map((e) => MvFilterItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      version: (json['version'] as List<dynamic>)
          .map((e) => MvFilterItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$MvCategoryOptionsImplToJson(
        _$MvCategoryOptionsImpl instance) =>
    <String, dynamic>{
      'area': instance.area,
      'version': instance.version,
    };

_$MvFilterItemImpl _$$MvFilterItemImplFromJson(Map<String, dynamic> json) =>
    _$MvFilterItemImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$$MvFilterItemImplToJson(_$MvFilterItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

_$MvItemImpl _$$MvItemImplFromJson(Map<String, dynamic> json) => _$MvItemImpl(
      mvid: (json['mvid'] as num).toInt(),
      title: json['title'] as String,
      vid: json['vid'] as String,
      picurl: json['picurl'] as String,
      singers: (json['singers'] as List<dynamic>)
          .map((e) => MvSinger.fromJson(e as Map<String, dynamic>))
          .toList(),
      playcnt: (json['playcnt'] as num).toInt(),
      duration: (json['duration'] as num).toInt(),
      subtitle: json['subtitle'] as String? ?? '',
      pubDate: (json['pubdate'] as num).toInt(),
      commentCount: (json['comment_cnt'] as num?)?.toInt() ?? 0,
      starCount: (json['star_cnt'] as num?)?.toInt() ?? 0,
      hasFav: (json['has_fav'] as num?)?.toInt() ?? 0,
      hasStar: (json['has_star'] as num?)?.toInt() ?? 0,
      mvSwitch: (json['mv_switch'] as num?)?.toInt() ?? 0,
      diff: (json['diff'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$$MvItemImplToJson(_$MvItemImpl instance) =>
    <String, dynamic>{
      'mvid': instance.mvid,
      'title': instance.title,
      'vid': instance.vid,
      'picurl': instance.picurl,
      'singers': instance.singers,
      'playcnt': instance.playcnt,
      'duration': instance.duration,
      'subtitle': instance.subtitle,
      'pubdate': instance.pubDate,
      'comment_cnt': instance.commentCount,
      'star_cnt': instance.starCount,
      'has_fav': instance.hasFav,
      'has_star': instance.hasStar,
      'mv_switch': instance.mvSwitch,
      'diff': instance.diff,
      'score': instance.score,
    };

_$MvSingerImpl _$$MvSingerImplFromJson(Map<String, dynamic> json) =>
    _$MvSingerImpl(
      id: (json['id'] as num).toInt(),
      mid: json['mid'] as String,
      name: json['name'] as String,
      picurl: json['picurl'] as String,
    );

Map<String, dynamic> _$$MvSingerImplToJson(_$MvSingerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mid': instance.mid,
      'name': instance.name,
      'picurl': instance.picurl,
    };

_$MvListResponseImpl _$$MvListResponseImplFromJson(Map<String, dynamic> json) =>
    _$MvListResponseImpl(
      list: (json['list'] as List<dynamic>)
          .map((e) => MvItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      area: (json['area'] as num).toInt(),
      version: (json['version'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      size: (json['size'] as num).toInt(),
    );

Map<String, dynamic> _$$MvListResponseImplToJson(
        _$MvListResponseImpl instance) =>
    <String, dynamic>{
      'list': instance.list,
      'total': instance.total,
      'area': instance.area,
      'version': instance.version,
      'page': instance.page,
      'size': instance.size,
    };
