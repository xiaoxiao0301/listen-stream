import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../shared/widgets/app_error_widget.dart';
import '../../shared/widgets/song_list_tile.dart';
import 'provider.dart';

class AlbumDetailPage extends ConsumerWidget {
  const AlbumDetailPage({super.key, required this.albumMid});
  
  final String albumMid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = albumDetailProvider(albumMid);
    
    return Scaffold(
      body: ref.watch(provider).when(
        data: (album) => _AlbumContent(album: album),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: '加载专辑失败',
          onRetry: () => ref.invalidate(provider),
        ),
      ),
    );
  }
}

class _AlbumContent extends StatelessWidget {
  const _AlbumContent({required this.album});
  
  final AlbumDetail album;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              album.albumName,
              style: const TextStyle(fontSize: 16),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  album.coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFF1a1a2e),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (album.singerName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        album.singerName!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Text(
                        album.publishDate,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (album.desc.isNotEmpty) ...[
                  Text(
                    album.desc,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      // TODO: 播放全部
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('播放全部'),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final song = album.songList[index];
              return SongListTile(
                index: index,
                songMid: song.songMid,
                songName: song.songName,
                artistName: song.singerName ?? '',
                albumMid: album.albumMid,
                duration: song.interval,
              );
            },
            childCount: album.songList.length,
          ),
        ),
      ],
    );
  }
}
