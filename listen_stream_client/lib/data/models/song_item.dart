/// 歌曲项，只包含显示需要的字段
class SongItem {
  const SongItem({
    required this.id,
    required this.mid,
    required this.name,
    this.singerNames = const [],
    this.albumName,
  });

  final int id;
  final String mid;
  final String name;
  final List<String> singerNames;
  final String? albumName;

  factory SongItem.fromJson(Map<String, dynamic> json) {
    final singers = json['singer'] as List?;
    final singerNames = singers
        ?.map((s) => s['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList() ?? <String>[];
    
    final album = json['album'] as Map<String, dynamic>?;

    return SongItem(
      id: json['id'] as int? ?? 0,
      mid: json['mid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      singerNames: singerNames,
      albumName: album?['name'] as String?,
    );
  }

  String get displayName => name;
  String get displayArtist => singerNames.join('、');
}
