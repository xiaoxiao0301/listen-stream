// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'singer_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SingerFilterOptions _$SingerFilterOptionsFromJson(Map<String, dynamic> json) {
  return _SingerFilterOptions.fromJson(json);
}

/// @nodoc
mixin _$SingerFilterOptions {
  List<FilterItem> get area => throw _privateConstructorUsedError;
  List<FilterItem> get genre => throw _privateConstructorUsedError;
  List<FilterItem> get index => throw _privateConstructorUsedError;
  List<FilterItem> get sex => throw _privateConstructorUsedError;

  /// Serializes this SingerFilterOptions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SingerFilterOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SingerFilterOptionsCopyWith<SingerFilterOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SingerFilterOptionsCopyWith<$Res> {
  factory $SingerFilterOptionsCopyWith(
          SingerFilterOptions value, $Res Function(SingerFilterOptions) then) =
      _$SingerFilterOptionsCopyWithImpl<$Res, SingerFilterOptions>;
  @useResult
  $Res call(
      {List<FilterItem> area,
      List<FilterItem> genre,
      List<FilterItem> index,
      List<FilterItem> sex});
}

/// @nodoc
class _$SingerFilterOptionsCopyWithImpl<$Res, $Val extends SingerFilterOptions>
    implements $SingerFilterOptionsCopyWith<$Res> {
  _$SingerFilterOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SingerFilterOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? area = null,
    Object? genre = null,
    Object? index = null,
    Object? sex = null,
  }) {
    return _then(_value.copyWith(
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      genre: null == genre
          ? _value.genre
          : genre // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      sex: null == sex
          ? _value.sex
          : sex // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SingerFilterOptionsImplCopyWith<$Res>
    implements $SingerFilterOptionsCopyWith<$Res> {
  factory _$$SingerFilterOptionsImplCopyWith(_$SingerFilterOptionsImpl value,
          $Res Function(_$SingerFilterOptionsImpl) then) =
      __$$SingerFilterOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<FilterItem> area,
      List<FilterItem> genre,
      List<FilterItem> index,
      List<FilterItem> sex});
}

/// @nodoc
class __$$SingerFilterOptionsImplCopyWithImpl<$Res>
    extends _$SingerFilterOptionsCopyWithImpl<$Res, _$SingerFilterOptionsImpl>
    implements _$$SingerFilterOptionsImplCopyWith<$Res> {
  __$$SingerFilterOptionsImplCopyWithImpl(_$SingerFilterOptionsImpl _value,
      $Res Function(_$SingerFilterOptionsImpl) _then)
      : super(_value, _then);

  /// Create a copy of SingerFilterOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? area = null,
    Object? genre = null,
    Object? index = null,
    Object? sex = null,
  }) {
    return _then(_$SingerFilterOptionsImpl(
      area: null == area
          ? _value._area
          : area // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      genre: null == genre
          ? _value._genre
          : genre // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      index: null == index
          ? _value._index
          : index // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
      sex: null == sex
          ? _value._sex
          : sex // ignore: cast_nullable_to_non_nullable
              as List<FilterItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SingerFilterOptionsImpl implements _SingerFilterOptions {
  const _$SingerFilterOptionsImpl(
      {required final List<FilterItem> area,
      required final List<FilterItem> genre,
      required final List<FilterItem> index,
      required final List<FilterItem> sex})
      : _area = area,
        _genre = genre,
        _index = index,
        _sex = sex;

  factory _$SingerFilterOptionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SingerFilterOptionsImplFromJson(json);

  final List<FilterItem> _area;
  @override
  List<FilterItem> get area {
    if (_area is EqualUnmodifiableListView) return _area;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_area);
  }

  final List<FilterItem> _genre;
  @override
  List<FilterItem> get genre {
    if (_genre is EqualUnmodifiableListView) return _genre;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_genre);
  }

  final List<FilterItem> _index;
  @override
  List<FilterItem> get index {
    if (_index is EqualUnmodifiableListView) return _index;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_index);
  }

  final List<FilterItem> _sex;
  @override
  List<FilterItem> get sex {
    if (_sex is EqualUnmodifiableListView) return _sex;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sex);
  }

  @override
  String toString() {
    return 'SingerFilterOptions(area: $area, genre: $genre, index: $index, sex: $sex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SingerFilterOptionsImpl &&
            const DeepCollectionEquality().equals(other._area, _area) &&
            const DeepCollectionEquality().equals(other._genre, _genre) &&
            const DeepCollectionEquality().equals(other._index, _index) &&
            const DeepCollectionEquality().equals(other._sex, _sex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_area),
      const DeepCollectionEquality().hash(_genre),
      const DeepCollectionEquality().hash(_index),
      const DeepCollectionEquality().hash(_sex));

  /// Create a copy of SingerFilterOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SingerFilterOptionsImplCopyWith<_$SingerFilterOptionsImpl> get copyWith =>
      __$$SingerFilterOptionsImplCopyWithImpl<_$SingerFilterOptionsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SingerFilterOptionsImplToJson(
      this,
    );
  }
}

abstract class _SingerFilterOptions implements SingerFilterOptions {
  const factory _SingerFilterOptions(
      {required final List<FilterItem> area,
      required final List<FilterItem> genre,
      required final List<FilterItem> index,
      required final List<FilterItem> sex}) = _$SingerFilterOptionsImpl;

  factory _SingerFilterOptions.fromJson(Map<String, dynamic> json) =
      _$SingerFilterOptionsImpl.fromJson;

  @override
  List<FilterItem> get area;
  @override
  List<FilterItem> get genre;
  @override
  List<FilterItem> get index;
  @override
  List<FilterItem> get sex;

  /// Create a copy of SingerFilterOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SingerFilterOptionsImplCopyWith<_$SingerFilterOptionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FilterItem _$FilterItemFromJson(Map<String, dynamic> json) {
  return _FilterItem.fromJson(json);
}

/// @nodoc
mixin _$FilterItem {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this FilterItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FilterItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FilterItemCopyWith<FilterItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FilterItemCopyWith<$Res> {
  factory $FilterItemCopyWith(
          FilterItem value, $Res Function(FilterItem) then) =
      _$FilterItemCopyWithImpl<$Res, FilterItem>;
  @useResult
  $Res call({int id, String name});
}

/// @nodoc
class _$FilterItemCopyWithImpl<$Res, $Val extends FilterItem>
    implements $FilterItemCopyWith<$Res> {
  _$FilterItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FilterItem
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
abstract class _$$FilterItemImplCopyWith<$Res>
    implements $FilterItemCopyWith<$Res> {
  factory _$$FilterItemImplCopyWith(
          _$FilterItemImpl value, $Res Function(_$FilterItemImpl) then) =
      __$$FilterItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name});
}

/// @nodoc
class __$$FilterItemImplCopyWithImpl<$Res>
    extends _$FilterItemCopyWithImpl<$Res, _$FilterItemImpl>
    implements _$$FilterItemImplCopyWith<$Res> {
  __$$FilterItemImplCopyWithImpl(
      _$FilterItemImpl _value, $Res Function(_$FilterItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of FilterItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_$FilterItemImpl(
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
class _$FilterItemImpl implements _FilterItem {
  const _$FilterItemImpl({required this.id, required this.name});

  factory _$FilterItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$FilterItemImplFromJson(json);

  @override
  final int id;
  @override
  final String name;

  @override
  String toString() {
    return 'FilterItem(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FilterItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  /// Create a copy of FilterItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FilterItemImplCopyWith<_$FilterItemImpl> get copyWith =>
      __$$FilterItemImplCopyWithImpl<_$FilterItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FilterItemImplToJson(
      this,
    );
  }
}

abstract class _FilterItem implements FilterItem {
  const factory _FilterItem(
      {required final int id, required final String name}) = _$FilterItemImpl;

  factory _FilterItem.fromJson(Map<String, dynamic> json) =
      _$FilterItemImpl.fromJson;

  @override
  int get id;
  @override
  String get name;

  /// Create a copy of FilterItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FilterItemImplCopyWith<_$FilterItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SingerItem _$SingerItemFromJson(Map<String, dynamic> json) {
  return _SingerItem.fromJson(json);
}

/// @nodoc
mixin _$SingerItem {
  @JsonKey(name: 'singer_id')
  int get singerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'singer_name')
  String get singerName => throw _privateConstructorUsedError;
  @JsonKey(name: 'singer_mid')
  String get singerMid => throw _privateConstructorUsedError;
  @JsonKey(name: 'singer_pic')
  String get singerPic => throw _privateConstructorUsedError;
  @JsonKey(name: 'other_name')
  String get otherName => throw _privateConstructorUsedError;
  String get spell => throw _privateConstructorUsedError;
  @JsonKey(name: 'area_id')
  int get areaId => throw _privateConstructorUsedError;
  @JsonKey(name: 'country_id')
  int get countryId => throw _privateConstructorUsedError;
  String get country => throw _privateConstructorUsedError;
  @JsonKey(name: 'singer_pmid')
  String get singerPmid => throw _privateConstructorUsedError;
  @JsonKey(name: 'concernNum')
  int get concernNum => throw _privateConstructorUsedError;
  int get trend => throw _privateConstructorUsedError;

  /// Serializes this SingerItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SingerItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SingerItemCopyWith<SingerItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SingerItemCopyWith<$Res> {
  factory $SingerItemCopyWith(
          SingerItem value, $Res Function(SingerItem) then) =
      _$SingerItemCopyWithImpl<$Res, SingerItem>;
  @useResult
  $Res call(
      {@JsonKey(name: 'singer_id') int singerId,
      @JsonKey(name: 'singer_name') String singerName,
      @JsonKey(name: 'singer_mid') String singerMid,
      @JsonKey(name: 'singer_pic') String singerPic,
      @JsonKey(name: 'other_name') String otherName,
      String spell,
      @JsonKey(name: 'area_id') int areaId,
      @JsonKey(name: 'country_id') int countryId,
      String country,
      @JsonKey(name: 'singer_pmid') String singerPmid,
      @JsonKey(name: 'concernNum') int concernNum,
      int trend});
}

/// @nodoc
class _$SingerItemCopyWithImpl<$Res, $Val extends SingerItem>
    implements $SingerItemCopyWith<$Res> {
  _$SingerItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SingerItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? singerId = null,
    Object? singerName = null,
    Object? singerMid = null,
    Object? singerPic = null,
    Object? otherName = null,
    Object? spell = null,
    Object? areaId = null,
    Object? countryId = null,
    Object? country = null,
    Object? singerPmid = null,
    Object? concernNum = null,
    Object? trend = null,
  }) {
    return _then(_value.copyWith(
      singerId: null == singerId
          ? _value.singerId
          : singerId // ignore: cast_nullable_to_non_nullable
              as int,
      singerName: null == singerName
          ? _value.singerName
          : singerName // ignore: cast_nullable_to_non_nullable
              as String,
      singerMid: null == singerMid
          ? _value.singerMid
          : singerMid // ignore: cast_nullable_to_non_nullable
              as String,
      singerPic: null == singerPic
          ? _value.singerPic
          : singerPic // ignore: cast_nullable_to_non_nullable
              as String,
      otherName: null == otherName
          ? _value.otherName
          : otherName // ignore: cast_nullable_to_non_nullable
              as String,
      spell: null == spell
          ? _value.spell
          : spell // ignore: cast_nullable_to_non_nullable
              as String,
      areaId: null == areaId
          ? _value.areaId
          : areaId // ignore: cast_nullable_to_non_nullable
              as int,
      countryId: null == countryId
          ? _value.countryId
          : countryId // ignore: cast_nullable_to_non_nullable
              as int,
      country: null == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      singerPmid: null == singerPmid
          ? _value.singerPmid
          : singerPmid // ignore: cast_nullable_to_non_nullable
              as String,
      concernNum: null == concernNum
          ? _value.concernNum
          : concernNum // ignore: cast_nullable_to_non_nullable
              as int,
      trend: null == trend
          ? _value.trend
          : trend // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SingerItemImplCopyWith<$Res>
    implements $SingerItemCopyWith<$Res> {
  factory _$$SingerItemImplCopyWith(
          _$SingerItemImpl value, $Res Function(_$SingerItemImpl) then) =
      __$$SingerItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'singer_id') int singerId,
      @JsonKey(name: 'singer_name') String singerName,
      @JsonKey(name: 'singer_mid') String singerMid,
      @JsonKey(name: 'singer_pic') String singerPic,
      @JsonKey(name: 'other_name') String otherName,
      String spell,
      @JsonKey(name: 'area_id') int areaId,
      @JsonKey(name: 'country_id') int countryId,
      String country,
      @JsonKey(name: 'singer_pmid') String singerPmid,
      @JsonKey(name: 'concernNum') int concernNum,
      int trend});
}

/// @nodoc
class __$$SingerItemImplCopyWithImpl<$Res>
    extends _$SingerItemCopyWithImpl<$Res, _$SingerItemImpl>
    implements _$$SingerItemImplCopyWith<$Res> {
  __$$SingerItemImplCopyWithImpl(
      _$SingerItemImpl _value, $Res Function(_$SingerItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of SingerItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? singerId = null,
    Object? singerName = null,
    Object? singerMid = null,
    Object? singerPic = null,
    Object? otherName = null,
    Object? spell = null,
    Object? areaId = null,
    Object? countryId = null,
    Object? country = null,
    Object? singerPmid = null,
    Object? concernNum = null,
    Object? trend = null,
  }) {
    return _then(_$SingerItemImpl(
      singerId: null == singerId
          ? _value.singerId
          : singerId // ignore: cast_nullable_to_non_nullable
              as int,
      singerName: null == singerName
          ? _value.singerName
          : singerName // ignore: cast_nullable_to_non_nullable
              as String,
      singerMid: null == singerMid
          ? _value.singerMid
          : singerMid // ignore: cast_nullable_to_non_nullable
              as String,
      singerPic: null == singerPic
          ? _value.singerPic
          : singerPic // ignore: cast_nullable_to_non_nullable
              as String,
      otherName: null == otherName
          ? _value.otherName
          : otherName // ignore: cast_nullable_to_non_nullable
              as String,
      spell: null == spell
          ? _value.spell
          : spell // ignore: cast_nullable_to_non_nullable
              as String,
      areaId: null == areaId
          ? _value.areaId
          : areaId // ignore: cast_nullable_to_non_nullable
              as int,
      countryId: null == countryId
          ? _value.countryId
          : countryId // ignore: cast_nullable_to_non_nullable
              as int,
      country: null == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      singerPmid: null == singerPmid
          ? _value.singerPmid
          : singerPmid // ignore: cast_nullable_to_non_nullable
              as String,
      concernNum: null == concernNum
          ? _value.concernNum
          : concernNum // ignore: cast_nullable_to_non_nullable
              as int,
      trend: null == trend
          ? _value.trend
          : trend // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SingerItemImpl implements _SingerItem {
  const _$SingerItemImpl(
      {@JsonKey(name: 'singer_id') required this.singerId,
      @JsonKey(name: 'singer_name') required this.singerName,
      @JsonKey(name: 'singer_mid') required this.singerMid,
      @JsonKey(name: 'singer_pic') required this.singerPic,
      @JsonKey(name: 'other_name') required this.otherName,
      this.spell = '',
      @JsonKey(name: 'area_id') this.areaId = 0,
      @JsonKey(name: 'country_id') this.countryId = 0,
      this.country = '',
      @JsonKey(name: 'singer_pmid') this.singerPmid = '',
      @JsonKey(name: 'concernNum') this.concernNum = 0,
      this.trend = 0});

  factory _$SingerItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$SingerItemImplFromJson(json);

  @override
  @JsonKey(name: 'singer_id')
  final int singerId;
  @override
  @JsonKey(name: 'singer_name')
  final String singerName;
  @override
  @JsonKey(name: 'singer_mid')
  final String singerMid;
  @override
  @JsonKey(name: 'singer_pic')
  final String singerPic;
  @override
  @JsonKey(name: 'other_name')
  final String otherName;
  @override
  @JsonKey()
  final String spell;
  @override
  @JsonKey(name: 'area_id')
  final int areaId;
  @override
  @JsonKey(name: 'country_id')
  final int countryId;
  @override
  @JsonKey()
  final String country;
  @override
  @JsonKey(name: 'singer_pmid')
  final String singerPmid;
  @override
  @JsonKey(name: 'concernNum')
  final int concernNum;
  @override
  @JsonKey()
  final int trend;

  @override
  String toString() {
    return 'SingerItem(singerId: $singerId, singerName: $singerName, singerMid: $singerMid, singerPic: $singerPic, otherName: $otherName, spell: $spell, areaId: $areaId, countryId: $countryId, country: $country, singerPmid: $singerPmid, concernNum: $concernNum, trend: $trend)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SingerItemImpl &&
            (identical(other.singerId, singerId) ||
                other.singerId == singerId) &&
            (identical(other.singerName, singerName) ||
                other.singerName == singerName) &&
            (identical(other.singerMid, singerMid) ||
                other.singerMid == singerMid) &&
            (identical(other.singerPic, singerPic) ||
                other.singerPic == singerPic) &&
            (identical(other.otherName, otherName) ||
                other.otherName == otherName) &&
            (identical(other.spell, spell) || other.spell == spell) &&
            (identical(other.areaId, areaId) || other.areaId == areaId) &&
            (identical(other.countryId, countryId) ||
                other.countryId == countryId) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.singerPmid, singerPmid) ||
                other.singerPmid == singerPmid) &&
            (identical(other.concernNum, concernNum) ||
                other.concernNum == concernNum) &&
            (identical(other.trend, trend) || other.trend == trend));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      singerId,
      singerName,
      singerMid,
      singerPic,
      otherName,
      spell,
      areaId,
      countryId,
      country,
      singerPmid,
      concernNum,
      trend);

  /// Create a copy of SingerItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SingerItemImplCopyWith<_$SingerItemImpl> get copyWith =>
      __$$SingerItemImplCopyWithImpl<_$SingerItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SingerItemImplToJson(
      this,
    );
  }
}

abstract class _SingerItem implements SingerItem {
  const factory _SingerItem(
      {@JsonKey(name: 'singer_id') required final int singerId,
      @JsonKey(name: 'singer_name') required final String singerName,
      @JsonKey(name: 'singer_mid') required final String singerMid,
      @JsonKey(name: 'singer_pic') required final String singerPic,
      @JsonKey(name: 'other_name') required final String otherName,
      final String spell,
      @JsonKey(name: 'area_id') final int areaId,
      @JsonKey(name: 'country_id') final int countryId,
      final String country,
      @JsonKey(name: 'singer_pmid') final String singerPmid,
      @JsonKey(name: 'concernNum') final int concernNum,
      final int trend}) = _$SingerItemImpl;

  factory _SingerItem.fromJson(Map<String, dynamic> json) =
      _$SingerItemImpl.fromJson;

  @override
  @JsonKey(name: 'singer_id')
  int get singerId;
  @override
  @JsonKey(name: 'singer_name')
  String get singerName;
  @override
  @JsonKey(name: 'singer_mid')
  String get singerMid;
  @override
  @JsonKey(name: 'singer_pic')
  String get singerPic;
  @override
  @JsonKey(name: 'other_name')
  String get otherName;
  @override
  String get spell;
  @override
  @JsonKey(name: 'area_id')
  int get areaId;
  @override
  @JsonKey(name: 'country_id')
  int get countryId;
  @override
  String get country;
  @override
  @JsonKey(name: 'singer_pmid')
  String get singerPmid;
  @override
  @JsonKey(name: 'concernNum')
  int get concernNum;
  @override
  int get trend;

  /// Create a copy of SingerItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SingerItemImplCopyWith<_$SingerItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SingerListResponse _$SingerListResponseFromJson(Map<String, dynamic> json) {
  return _SingerListResponse.fromJson(json);
}

/// @nodoc
mixin _$SingerListResponse {
  List<SingerItem> get singerList => throw _privateConstructorUsedError;
  Map<String, dynamic> get tags => throw _privateConstructorUsedError;

  /// Serializes this SingerListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SingerListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SingerListResponseCopyWith<SingerListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SingerListResponseCopyWith<$Res> {
  factory $SingerListResponseCopyWith(
          SingerListResponse value, $Res Function(SingerListResponse) then) =
      _$SingerListResponseCopyWithImpl<$Res, SingerListResponse>;
  @useResult
  $Res call({List<SingerItem> singerList, Map<String, dynamic> tags});
}

/// @nodoc
class _$SingerListResponseCopyWithImpl<$Res, $Val extends SingerListResponse>
    implements $SingerListResponseCopyWith<$Res> {
  _$SingerListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SingerListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? singerList = null,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      singerList: null == singerList
          ? _value.singerList
          : singerList // ignore: cast_nullable_to_non_nullable
              as List<SingerItem>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SingerListResponseImplCopyWith<$Res>
    implements $SingerListResponseCopyWith<$Res> {
  factory _$$SingerListResponseImplCopyWith(_$SingerListResponseImpl value,
          $Res Function(_$SingerListResponseImpl) then) =
      __$$SingerListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<SingerItem> singerList, Map<String, dynamic> tags});
}

/// @nodoc
class __$$SingerListResponseImplCopyWithImpl<$Res>
    extends _$SingerListResponseCopyWithImpl<$Res, _$SingerListResponseImpl>
    implements _$$SingerListResponseImplCopyWith<$Res> {
  __$$SingerListResponseImplCopyWithImpl(_$SingerListResponseImpl _value,
      $Res Function(_$SingerListResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of SingerListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? singerList = null,
    Object? tags = null,
  }) {
    return _then(_$SingerListResponseImpl(
      singerList: null == singerList
          ? _value._singerList
          : singerList // ignore: cast_nullable_to_non_nullable
              as List<SingerItem>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SingerListResponseImpl implements _SingerListResponse {
  const _$SingerListResponseImpl(
      {required final List<SingerItem> singerList,
      final Map<String, dynamic> tags = const {}})
      : _singerList = singerList,
        _tags = tags;

  factory _$SingerListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$SingerListResponseImplFromJson(json);

  final List<SingerItem> _singerList;
  @override
  List<SingerItem> get singerList {
    if (_singerList is EqualUnmodifiableListView) return _singerList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_singerList);
  }

  final Map<String, dynamic> _tags;
  @override
  @JsonKey()
  Map<String, dynamic> get tags {
    if (_tags is EqualUnmodifiableMapView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_tags);
  }

  @override
  String toString() {
    return 'SingerListResponse(singerList: $singerList, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SingerListResponseImpl &&
            const DeepCollectionEquality()
                .equals(other._singerList, _singerList) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_singerList),
      const DeepCollectionEquality().hash(_tags));

  /// Create a copy of SingerListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SingerListResponseImplCopyWith<_$SingerListResponseImpl> get copyWith =>
      __$$SingerListResponseImplCopyWithImpl<_$SingerListResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SingerListResponseImplToJson(
      this,
    );
  }
}

abstract class _SingerListResponse implements SingerListResponse {
  const factory _SingerListResponse(
      {required final List<SingerItem> singerList,
      final Map<String, dynamic> tags}) = _$SingerListResponseImpl;

  factory _SingerListResponse.fromJson(Map<String, dynamic> json) =
      _$SingerListResponseImpl.fromJson;

  @override
  List<SingerItem> get singerList;
  @override
  Map<String, dynamic> get tags;

  /// Create a copy of SingerListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SingerListResponseImplCopyWith<_$SingerListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
