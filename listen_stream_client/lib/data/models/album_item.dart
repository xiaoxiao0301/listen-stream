/// 专辑项，只包含显示需要的字段
class AlbumItem {
  const AlbumItem({
    required this.id,
    required this.mid,
    required this.name,
    this.singerNames = const [],
  });

  final int id;
  final String mid;
  final String name;
  final List<String> singerNames;

  factory AlbumItem.fromJson(Map<String, dynamic> json) {
    final singers = json['singers'] as List?;
    final singerNames = singers
        ?.map((s) => s['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList() ?? <String>[];

    return AlbumItem(
      id: json['id'] as int? ?? 0,
      mid: json['mid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      singerNames: singerNames,
    );
  }

  String get displayName => name;
  String get displayArtist => singerNames.join('、');
  
  /// 通过 mid 构建专辑封面 URL
  String get coverUrl => mid.isNotEmpty
      ? 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$mid.jpg'
      : '';
}
