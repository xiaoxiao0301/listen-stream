// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mv_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MvCategoryOptions _$MvCategoryOptionsFromJson(Map<String, dynamic> json) {
  return _MvCategoryOptions.fromJson(json);
}

/// @nodoc
mixin _$MvCategoryOptions {
  List<MvFilterItem> get area => throw _privateConstructorUsedError;
  List<MvFilterItem> get version => throw _privateConstructorUsedError;

  /// Serializes this MvCategoryOptions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MvCategoryOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MvCategoryOptionsCopyWith<MvCategoryOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MvCategoryOptionsCopyWith<$Res> {
  factory $MvCategoryOptionsCopyWith(
          MvCategoryOptions value, $Res Function(MvCategoryOptions) then) =
      _$MvCategoryOptionsCopyWithImpl<$Res, MvCategoryOptions>;
  @useResult
  $Res call({List<MvFilterItem> area, List<MvFilterItem> version});
}

/// @nodoc
class _$MvCategoryOptionsCopyWithImpl<$Res, $Val extends MvCategoryOptions>
    implements $MvCategoryOptionsCopyWith<$Res> {
  _$MvCategoryOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MvCategoryOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? area = null,
    Object? version = null,
  }) {
    return _then(_value.copyWith(
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as List<MvFilterItem>,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as List<MvFilterItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MvCategoryOptionsImplCopyWith<$Res>
    implements $MvCategoryOptionsCopyWith<$Res> {
  factory _$$MvCategoryOptionsImplCopyWith(_$MvCategoryOptionsImpl value,
          $Res Function(_$MvCategoryOptionsImpl) then) =
      __$$MvCategoryOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<MvFilterItem> area, List<MvFilterItem> version});
}

/// @nodoc
class __$$MvCategoryOptionsImplCopyWithImpl<$Res>
    extends _$MvCategoryOptionsCopyWithImpl<$Res, _$MvCategoryOptionsImpl>
    implements _$$MvCategoryOptionsImplCopyWith<$Res> {
  __$$MvCategoryOptionsImplCopyWithImpl(_$MvCategoryOptionsImpl _value,
      $Res Function(_$MvCategoryOptionsImpl) _then)
      : super(_value, _then);

  /// Create a copy of MvCategoryOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? area = null,
    Object? version = null,
  }) {
    return _then(_$MvCategoryOptionsImpl(
      area: null == area
          ? _value._area
          : area // ignore: cast_nullable_to_non_nullable
              as List<MvFilterItem>,
      version: null == version
          ? _value._version
          : version // ignore: cast_nullable_to_non_nullable
              as List<MvFilterItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MvCategoryOptionsImpl implements _MvCategoryOptions {
  const _$MvCategoryOptionsImpl(
      {required final List<MvFilterItem> area,
      required final List<MvFilterItem> version})
      : _area = area,
        _version = version;

  factory _$MvCategoryOptionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$MvCategoryOptionsImplFromJson(json);

  final List<MvFilterItem> _area;
  @override
  List<MvFilterItem> get area {
    if (_area is EqualUnmodifiableListView) return _area;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_area);
  }

  final List<MvFilterItem> _version;
  @override
  List<MvFilterItem> get version {
    if (_version is EqualUnmodifiableListView) return _version;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_version);
  }

  @override
  String toString() {
    return 'MvCategoryOptions(area: $area, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MvCategoryOptionsImpl &&
            const DeepCollectionEquality().equals(other._area, _area) &&
            const DeepCollectionEquality().equals(other._version, _version));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_area),
      const DeepCollectionEquality().hash(_version));

  /// Create a copy of MvCategoryOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MvCategoryOptionsImplCopyWith<_$MvCategoryOptionsImpl> get copyWith =>
      __$$MvCategoryOptionsImplCopyWithImpl<_$MvCategoryOptionsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MvCategoryOptionsImplToJson(
      this,
    );
  }
}

abstract class _MvCategoryOptions implements MvCategoryOptions {
  const factory _MvCategoryOptions(
      {required final List<MvFilterItem> area,
      required final List<MvFilterItem> version}) = _$MvCategoryOptionsImpl;

  factory _MvCategoryOptions.fromJson(Map<String, dynamic> json) =
      _$MvCategoryOptionsImpl.fromJson;

  @override
  List<MvFilterItem> get area;
  @override
  List<MvFilterItem> get version;

  /// Create a copy of MvCategoryOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MvCategoryOptionsImplCopyWith<_$MvCategoryOptionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MvFilterItem _$MvFilterItemFromJson(Map<String, dynamic> json) {
  return _MvFilterItem.fromJson(json);
}

/// @nodoc
mixin _$MvFilterItem {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this MvFilterItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MvFilterItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MvFilterItemCopyWith<MvFilterItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MvFilterItemCopyWith<$Res> {
  factory $MvFilterItemCopyWith(
          MvFilterItem value, $Res Function(MvFilterItem) then) =
      _$MvFilterItemCopyWithImpl<$Res, MvFilterItem>;
  @useResult
  $Res call({int id, String name});
}

/// @nodoc
class _$MvFilterItemCopyWithImpl<$Res, $Val extends MvFilterItem>
    implements $MvFilterItemCopyWith<$Res> {
  _$MvFilterItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MvFilterItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MvFilterItemImplCopyWith<$Res>
    implements $MvFilterItemCopyWith<$Res> {
  factory _$$MvFilterItemImplCopyWith(
          _$MvFilterItemImpl value, $Res Function(_$MvFilterItemImpl) then) =
      __$$MvFilterItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name});
}

/// @nodoc
class __$$MvFilterItemImplCopyWithImpl<$Res>
    extends _$MvFilterItemCopyWithImpl<$Res, _$MvFilterItemImpl>
    implements _$$MvFilterItemImplCopyWith<$Res> {
  __$$MvFilterItemImplCopyWithImpl(
      _$MvFilterItemImpl _value, $Res Function(_$MvFilterItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of MvFilterItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_$MvFilterItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MvFilterItemImpl implements _MvFilterItem {
  const _$MvFilterItemImpl({required this.id, required this.name});

  factory _$MvFilterItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MvFilterItemImplFromJson(json);

  @override
  final int id;
  @override
  final String name;

  @override
  String toString() {
    return 'MvFilterItem(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MvFilterItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  /// Create a copy of MvFilterItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MvFilterItemImplCopyWith<_$MvFilterItemImpl> get copyWith =>
      __$$MvFilterItemImplCopyWithImpl<_$MvFilterItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MvFilterItemImplToJson(
      this,
    );
  }
}

abstract class _MvFilterItem implements MvFilterItem {
  const factory _MvFilterItem(
      {required final int id, required final String name}) = _$MvFilterItemImpl;

  factory _MvFilterItem.fromJson(Map<String, dynamic> json) =
      _$MvFilterItemImpl.fromJson;

  @override
  int get id;
  @override
  String get name;

  /// Create a copy of MvFilterItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MvFilterItemImplCopyWith<_$MvFilterItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MvItem _$MvItemFromJson(Map<String, dynamic> json) {
  return _MvItem.fromJson(json);
}

/// @nodoc
mixin _$MvItem {
  int get mvid => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get vid => throw _privateConstructorUsedError;
  String get picurl => throw _privateConstructorUsedError;
  List<MvSinger> get singers => throw _privateConstructorUsedError;
  int get playcnt => throw _privateConstructorUsedError;
  int get duration => throw _privateConstructorUsedError;
  String get subtitle => throw _privateConstructorUsedError;
  @JsonKey(name: 'pubdate')
  int get pubDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'comment_cnt')
  int get commentCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'star_cnt')
  int get starCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_fav')
  int get hasFav => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_star')
  int get hasStar => throw _privateConstructorUsedError;
  @JsonKey(name: 'mv_switch')
  int get mvSwitch => throw _privateConstructorUsedError;
  int get diff => throw _privateConstructorUsedError;
  double get score => throw _privateConstructorUsedError;

  /// Serializes this MvItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MvItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MvItemCopyWith<MvItem> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MvItemCopyWith<$Res> {
  factory $MvItemCopyWith(MvItem value, $Res Function(MvItem) then) =
      _$MvItemCopyWithImpl<$Res, MvItem>;
  @useResult
  $Res call(
      {int mvid,
      String title,
      String vid,
      String picurl,
      List<MvSinger> singers,
      int playcnt,
      int duration,
      String subtitle,
      @JsonKey(name: 'pubdate') int pubDate,
      @JsonKey(name: 'comment_cnt') int commentCount,
      @JsonKey(name: 'star_cnt') int starCount,
      @JsonKey(name: 'has_fav') int hasFav,
      @JsonKey(name: 'has_star') int hasStar,
      @JsonKey(name: 'mv_switch') int mvSwitch,
      int diff,
      double score});
}

/// @nodoc
class _$MvItemCopyWithImpl<$Res, $Val extends MvItem>
    implements $MvItemCopyWith<$Res> {
  _$MvItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MvItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mvid = null,
    Object? title = null,
    Object? vid = null,
    Object? picurl = null,
    Object? singers = null,
    Object? playcnt = null,
    Object? duration = null,
    Object? subtitle = null,
    Object? pubDate = null,
    Object? commentCount = null,
    Object? starCount = null,
    Object? hasFav = null,
    Object? hasStar = null,
    Object? mvSwitch = null,
    Object? diff = null,
    Object? score = null,
  }) {
    return _then(_value.copyWith(
      mvid: null == mvid
          ? _value.mvid
          : mvid // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      vid: null == vid
          ? _value.vid
          : vid // ignore: cast_nullable_to_non_nullable
              as String,
      picurl: null == picurl
          ? _value.picurl
          : picurl // ignore: cast_nullable_to_non_nullable
              as String,
      singers: null == singers
          ? _value.singers
          : singers // ignore: cast_nullable_to_non_nullable
              as List<MvSinger>,
      playcnt: null == playcnt
          ? _value.playcnt
          : playcnt // ignore: cast_nullable_to_non_nullable
              as int,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      subtitle: null == subtitle
          ? _value.subtitle
          : subtitle // ignore: cast_nullable_to_non_nullable
              as String,
      pubDate: null == pubDate
          ? _value.pubDate
          : pubDate // ignore: cast_nullable_to_non_nullable
              as int,
      commentCount: null == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int,
      starCount: null == starCount
          ? _value.starCount
          : starCount // ignore: cast_nullable_to_non_nullable
              as int,
      hasFav: null == hasFav
          ? _value.hasFav
          : hasFav // ignore: cast_nullable_to_non_nullable
              as int,
      hasStar: null == hasStar
          ? _value.hasStar
          : hasStar // ignore: cast_nullable_to_non_nullable
              as int,
      mvSwitch: null == mvSwitch
          ? _value.mvSwitch
          : mvSwitch // ignore: cast_nullable_to_non_nullable
              as int,
      diff: null == diff
          ? _value.diff
          : diff // ignore: cast_nullable_to_non_nullable
              as int,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MvItemImplCopyWith<$Res> implements $MvItemCopyWith<$Res> {
  factory _$$MvItemImplCopyWith(
          _$MvItemImpl value, $Res Function(_$MvItemImpl) then) =
      __$$MvItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int mvid,
      String title,
      String vid,
      String picurl,
      List<MvSinger> singers,
      int playcnt,
      int duration,
      String subtitle,
      @JsonKey(name: 'pubdate') int pubDate,
      @JsonKey(name: 'comment_cnt') int commentCount,
      @JsonKey(name: 'star_cnt') int starCount,
      @JsonKey(name: 'has_fav') int hasFav,
      @JsonKey(name: 'has_star') int hasStar,
      @JsonKey(name: 'mv_switch') int mvSwitch,
      int diff,
      double score});
}

/// @nodoc
class __$$MvItemImplCopyWithImpl<$Res>
    extends _$MvItemCopyWithImpl<$Res, _$MvItemImpl>
    implements _$$MvItemImplCopyWith<$Res> {
  __$$MvItemImplCopyWithImpl(
      _$MvItemImpl _value, $Res Function(_$MvItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of MvItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mvid = null,
    Object? title = null,
    Object? vid = null,
    Object? picurl = null,
    Object? singers = null,
    Object? playcnt = null,
    Object? duration = null,
    Object? subtitle = null,
    Object? pubDate = null,
    Object? commentCount = null,
    Object? starCount = null,
    Object? hasFav = null,
    Object? hasStar = null,
    Object? mvSwitch = null,
    Object? diff = null,
    Object? score = null,
  }) {
    return _then(_$MvItemImpl(
      mvid: null == mvid
          ? _value.mvid
          : mvid // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      vid: null == vid
          ? _value.vid
          : vid // ignore: cast_nullable_to_non_nullable
              as String,
      picurl: null == picurl
          ? _value.picurl
          : picurl // ignore: cast_nullable_to_non_nullable
              as String,
      singers: null == singers
          ? _value._singers
          : singers // ignore: cast_nullable_to_non_nullable
              as List<MvSinger>,
      playcnt: null == playcnt
          ? _value.playcnt
          : playcnt // ignore: cast_nullable_to_non_nullable
              as int,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      subtitle: null == subtitle
          ? _value.subtitle
          : subtitle // ignore: cast_nullable_to_non_nullable
              as String,
      pubDate: null == pubDate
          ? _value.pubDate
          : pubDate // ignore: cast_nullable_to_non_nullable
              as int,
      commentCount: null == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int,
      starCount: null == starCount
          ? _value.starCount
          : starCount // ignore: cast_nullable_to_non_nullable
              as int,
      hasFav: null == hasFav
          ? _value.hasFav
          : hasFav // ignore: cast_nullable_to_non_nullable
              as int,
      hasStar: null == hasStar
          ? _value.hasStar
          : hasStar // ignore: cast_nullable_to_non_nullable
              as int,
      mvSwitch: null == mvSwitch
          ? _value.mvSwitch
          : mvSwitch // ignore: cast_nullable_to_non_nullable
              as int,
      diff: null == diff
          ? _value.diff
          : diff // ignore: cast_nullable_to_non_nullable
              as int,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MvItemImpl implements _MvItem {
  const _$MvItemImpl(
      {required this.mvid,
      required this.title,
      required this.vid,
      required this.picurl,
      required final List<MvSinger> singers,
      required this.playcnt,
      required this.duration,
      this.subtitle = '',
      @JsonKey(name: 'pubdate') required this.pubDate,
      @JsonKey(name: 'comment_cnt') this.commentCount = 0,
      @JsonKey(name: 'star_cnt') this.starCount = 0,
      @JsonKey(name: 'has_fav') this.hasFav = 0,
      @JsonKey(name: 'has_star') this.hasStar = 0,
      @JsonKey(name: 'mv_switch') this.mvSwitch = 0,
      this.diff = 0,
      this.score = 0})
      : _singers = singers;

  factory _$MvItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MvItemImplFromJson(json);

  @override
  final int mvid;
  @override
  final String title;
  @override
  final String vid;
  @override
  final String picurl;
  final List<MvSinger> _singers;
  @override
  List<MvSinger> get singers {
    if (_singers is EqualUnmodifiableListView) return _singers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_singers);
  }

  @override
  final int playcnt;
  @override
  final int duration;
  @override
  @JsonKey()
  final String subtitle;
  @override
  @JsonKey(name: 'pubdate')
  final int pubDate;
  @override
  @JsonKey(name: 'comment_cnt')
  final int commentCount;
  @override
  @JsonKey(name: 'star_cnt')
  final int starCount;
  @override
  @JsonKey(name: 'has_fav')
  final int hasFav;
  @override
  @JsonKey(name: 'has_star')
  final int hasStar;
  @override
  @JsonKey(name: 'mv_switch')
  final int mvSwitch;
  @override
  @JsonKey()
  final int diff;
  @override
  @JsonKey()
  final double score;

  @override
  String toString() {
    return 'MvItem(mvid: $mvid, title: $title, vid: $vid, picurl: $picurl, singers: $singers, playcnt: $playcnt, duration: $duration, subtitle: $subtitle, pubDate: $pubDate, commentCount: $commentCount, starCount: $starCount, hasFav: $hasFav, hasStar: $hasStar, mvSwitch: $mvSwitch, diff: $diff, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MvItemImpl &&
            (identical(other.mvid, mvid) || other.mvid == mvid) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.vid, vid) || other.vid == vid) &&
            (identical(other.picurl, picurl) || other.picurl == picurl) &&
            const DeepCollectionEquality().equals(other._singers, _singers) &&
            (identical(other.playcnt, playcnt) || other.playcnt == playcnt) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            (identical(other.pubDate, pubDate) || other.pubDate == pubDate) &&
            (identical(other.commentCount, commentCount) ||
                other.commentCount == commentCount) &&
            (identical(other.starCount, starCount) ||
                other.starCount == starCount) &&
            (identical(other.hasFav, hasFav) || other.hasFav == hasFav) &&
            (identical(other.hasStar, hasStar) || other.hasStar == hasStar) &&
            (identical(other.mvSwitch, mvSwitch) ||
                other.mvSwitch == mvSwitch) &&
            (identical(other.diff, diff) || other.diff == diff) &&
            (identical(other.score, score) || other.score == score));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      mvid,
      title,
      vid,
      picurl,
      const DeepCollectionEquality().hash(_singers),
      playcnt,
      duration,
      subtitle,
      pubDate,
      commentCount,
      starCount,
      hasFav,
      hasStar,
      mvSwitch,
      diff,
      score);

  /// Create a copy of MvItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MvItemImplCopyWith<_$MvItemImpl> get copyWith =>
      __$$MvItemImplCopyWithImpl<_$MvItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MvItemImplToJson(
      this,
    );
  }
}

abstract class _MvItem implements MvItem {
  const factory _MvItem(
      {required final int mvid,
      required final String title,
      required final String vid,
      required final String picurl,
      required final List<MvSinger> singers,
      required final int playcnt,
      required final int duration,
      final String subtitle,
      @JsonKey(name: 'pubdate') required final int pubDate,
      @JsonKey(name: 'comment_cnt') final int commentCount,
      @JsonKey(name: 'star_cnt') final int starCount,
      @JsonKey(name: 'has_fav') final int hasFav,
      @JsonKey(name: 'has_star') final int hasStar,
      @JsonKey(name: 'mv_switch') final int mvSwitch,
      final int diff,
      final double score}) = _$MvItemImpl;

  factory _MvItem.fromJson(Map<String, dynamic> json) = _$MvItemImpl.fromJson;

  @override
  int get mvid;
  @override
  String get title;
  @override
  String get vid;
  @override
  String get picurl;
  @override
  List<MvSinger> get singers;
  @override
  int get playcnt;
  @override
  int get duration;
  @override
  String get subtitle;
  @override
  @JsonKey(name: 'pubdate')
  int get pubDate;
  @override
  @JsonKey(name: 'comment_cnt')
  int get commentCount;
  @override
  @JsonKey(name: 'star_cnt')
  int get starCount;
  @override
  @JsonKey(name: 'has_fav')
  int get hasFav;
  @override
  @JsonKey(name: 'has_star')
  int get hasStar;
  @override
  @JsonKey(name: 'mv_switch')
  int get mvSwitch;
  @override
  int get diff;
  @override
  double get score;

  /// Create a copy of MvItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MvItemImplCopyWith<_$MvItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MvSinger _$MvSingerFromJson(Map<String, dynamic> json) {
  return _MvSinger.fromJson(json);
}

/// @nodoc
mixin _$MvSinger {
  int get id => throw _privateConstructorUsedError;
  String get mid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get picurl => throw _privateConstructorUsedError;

  /// Serializes this MvSinger to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MvSinger
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MvSingerCopyWith<MvSinger> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MvSingerCopyWith<$Res> {
  factory $MvSingerCopyWith(MvSinger value, $Res Function(MvSinger) then) =
      _$MvSingerCopyWithImpl<$Res, MvSinger>;
  @useResult
  $Res call({int id, String mid, String name, String picurl});
}

/// @nodoc
class _$MvSingerCopyWithImpl<$Res, $Val extends MvSinger>
    implements $MvSingerCopyWith<$Res> {
  _$MvSingerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MvSinger
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mid = null,
    Object? name = null,
    Object? picurl = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      mid: null == mid
          ? _value.mid
          : mid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      picurl: null == picurl
          ? _value.picurl
          : picurl // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MvSingerImplCopyWith<$Res>
    implements $MvSingerCopyWith<$Res> {
  factory _$$MvSingerImplCopyWith(
          _$MvSingerImpl value, $Res Function(_$MvSingerImpl) then) =
      __$$MvSingerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String mid, String name, String picurl});
}

/// @nodoc
class __$$MvSingerImplCopyWithImpl<$Res>
    extends _$MvSingerCopyWithImpl<$Res, _$MvSingerImpl>
    implements _$$MvSingerImplCopyWith<$Res> {
  __$$MvSingerImplCopyWithImpl(
      _$MvSingerImpl _value, $Res Function(_$MvSingerImpl) _then)
      : super(_value, _then);

  /// Create a copy of MvSinger
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mid = null,
    Object? name = null,
    Object? picurl = null,
  }) {
    return _then(_$MvSingerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      mid: null == mid
          ? _value.mid
          : mid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      picurl: null == picurl
          ? _value.picurl
          : picurl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MvSingerImpl implements _MvSinger {
  const _$MvSingerImpl(
      {required this.id,
      required this.mid,
      required this.name,
      required this.picurl});

  factory _$MvSingerImpl.fromJson(Map<String, dynamic> json) =>
      _$$MvSingerImplFromJson(json);

  @override
  final int id;
  @override
  final String mid;
  @override
  final String name;
  @override
  final String picurl;

  @override
  String toString() {
    return 'MvSinger(id: $id, mid: $mid, name: $name, picurl: $picurl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MvSingerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.mid, mid) || other.mid == mid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.picurl, picurl) || other.picurl == picurl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, mid, name, picurl);

  /// Create a copy of MvSinger
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MvSingerImplCopyWith<_$MvSingerImpl> get copyWith =>
      __$$MvSingerImplCopyWithImpl<_$MvSingerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MvSingerImplToJson(
      this,
    );
  }
}

abstract class _MvSinger implements MvSinger {
  const factory _MvSinger(
      {required final int id,
      required final String mid,
      required final String name,
      required final String picurl}) = _$MvSingerImpl;

  factory _MvSinger.fromJson(Map<String, dynamic> json) =
      _$MvSingerImpl.fromJson;

  @override
  int get id;
  @override
  String get mid;
  @override
  String get name;
  @override
  String get picurl;

  /// Create a copy of MvSinger
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MvSingerImplCopyWith<_$MvSingerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MvListResponse _$MvListResponseFromJson(Map<String, dynamic> json) {
  return _MvListResponse.fromJson(json);
}

/// @nodoc
mixin _$MvListResponse {
  List<MvItem> get list => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get area => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  int get size => throw _privateConstructorUsedError;

  /// Serializes this MvListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MvListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MvListResponseCopyWith<MvListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MvListResponseCopyWith<$Res> {
  factory $MvListResponseCopyWith(
          MvListResponse value, $Res Function(MvListResponse) then) =
      _$MvListResponseCopyWithImpl<$Res, MvListResponse>;
  @useResult
  $Res call(
      {List<MvItem> list,
      int total,
      int area,
      int version,
      int page,
      int size});
}

/// @nodoc
class _$MvListResponseCopyWithImpl<$Res, $Val extends MvListResponse>
    implements $MvListResponseCopyWith<$Res> {
  _$MvListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MvListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? list = null,
    Object? total = null,
    Object? area = null,
    Object? version = null,
    Object? page = null,
    Object? size = null,
  }) {
    return _then(_value.copyWith(
      list: null == list
          ? _value.list
          : list // ignore: cast_nullable_to_non_nullable
              as List<MvItem>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as int,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MvListResponseImplCopyWith<$Res>
    implements $MvListResponseCopyWith<$Res> {
  factory _$$MvListResponseImplCopyWith(_$MvListResponseImpl value,
          $Res Function(_$MvListResponseImpl) then) =
      __$$MvListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<MvItem> list,
      int total,
      int area,
      int version,
      int page,
      int size});
}

/// @nodoc
class __$$MvListResponseImplCopyWithImpl<$Res>
    extends _$MvListResponseCopyWithImpl<$Res, _$MvListResponseImpl>
    implements _$$MvListResponseImplCopyWith<$Res> {
  __$$MvListResponseImplCopyWithImpl(
      _$MvListResponseImpl _value, $Res Function(_$MvListResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of MvListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? list = null,
    Object? total = null,
    Object? area = null,
    Object? version = null,
    Object? page = null,
    Object? size = null,
  }) {
    return _then(_$MvListResponseImpl(
      list: null == list
          ? _value._list
          : list // ignore: cast_nullable_to_non_nullable
              as List<MvItem>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as int,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MvListResponseImpl implements _MvListResponse {
  const _$MvListResponseImpl(
      {required final List<MvItem> list,
      required this.total,
      required this.area,
      required this.version,
      required this.page,
      required this.size})
      : _list = list;

  factory _$MvListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$MvListResponseImplFromJson(json);

  final List<MvItem> _list;
  @override
  List<MvItem> get list {
    if (_list is EqualUnmodifiableListView) return _list;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_list);
  }

  @override
  final int total;
  @override
  final int area;
  @override
  final int version;
  @override
  final int page;
  @override
  final int size;

  @override
  String toString() {
    return 'MvListResponse(list: $list, total: $total, area: $area, version: $version, page: $page, size: $size)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MvListResponseImpl &&
            const DeepCollectionEquality().equals(other._list, _list) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.area, area) || other.area == area) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.size, size) || other.size == size));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_list),
      total,
      area,
      version,
      page,
      size);

  /// Create a copy of MvListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MvListResponseImplCopyWith<_$MvListResponseImpl> get copyWith =>
      __$$MvListResponseImplCopyWithImpl<_$MvListResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MvListResponseImplToJson(
      this,
    );
  }
}

abstract class _MvListResponse implements MvListResponse {
  const factory _MvListResponse(
      {required final List<MvItem> list,
      required final int total,
      required final int area,
      required final int version,
      required final int page,
      required final int size}) = _$MvListResponseImpl;

  factory _MvListResponse.fromJson(Map<String, dynamic> json) =
      _$MvListResponseImpl.fromJson;

  @override
  List<MvItem> get list;
  @override
  int get total;
  @override
  int get area;
  @override
  int get version;
  @override
  int get page;
  @override
  int get size;

  /// Create a copy of MvListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MvListResponseImplCopyWith<_$MvListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
