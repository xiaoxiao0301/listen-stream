import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 通用歌曲列表项组件
class SongListTile extends StatelessWidget {
  const SongListTile({
    super.key,
    required this.index,
    required this.songMid,
    required this.songName,
    required this.artistName,
    this.albumMid,
    this.duration,
    this.showCover = false,
  });

  final int index;
  final String songMid;
  final String songName;
  final String artistName;
  final String? albumMid;
  final int? duration;
  final bool showCover;

  String get _coverUrl {
    if (albumMid == null || albumMid!.isEmpty) {
      return '';
    }
    return 'https://y.gtimg.cn/music/photo_new/T002R150x150M000$albumMid.jpg';
  }

  String get _durationText {
    if (duration == null || duration == 0) return '';
    final min = duration! ~/ 60;
    final sec = duration! % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: showCover && _coverUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                _coverUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.music_note, size: 24),
                ),
              ),
            )
          : SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
      title: Text(
        songName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        artistName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _durationText.isNotEmpty
          ? Text(
              _durationText,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      onTap: () => context.push('/song/$songMid'),
    );
  }
}
