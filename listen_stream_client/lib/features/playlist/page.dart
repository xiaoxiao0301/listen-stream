import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/app_error_widget.dart';
import 'provider.dart';

class PlaylistDetailPage extends ConsumerWidget {
  const PlaylistDetailPage({super.key, required this.playlistId});
  
  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = playlistDetailProvider(playlistId);
    
    return Scaffold(
      body: ref.watch(provider).when(
        data: (playlist) => _PlaylistContent(playlist: playlist),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: '加载歌单失败',
          onRetry: () => ref.invalidate(provider),
        ),
      ),
    );
  }
}

class _PlaylistContent extends StatelessWidget {
  const _PlaylistContent({required this.playlist});
  
  final PlaylistDetail playlist;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // 折叠的头部
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              playlist.dissname,
              style: const TextStyle(fontSize: 16),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  playlist.logo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFF1a1a2e),
                  ),
                ),
                // 渐变遮罩
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black54,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 歌单信息
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      playlist.nick,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      '${playlist.songnum} 首',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (playlist.desc.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    playlist.desc,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                // 播放全部按钮
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      // TODO: 播放全部歌曲
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('播放全部'),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 歌曲列表
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final song = playlist.songlist[index];
              return ListTile(
                leading: SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                title: Text(
                  song.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${song.singerName} · ${song.albumName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.durationText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: () {
                        // TODO: 显示更多选项
                      },
                    ),
                  ],
                ),
                onTap: () {
                  // TODO: 播放歌曲
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('播放: ${song.name}')),
                  );
                },
              );
            },
            childCount: playlist.songlist.length,
          ),
        ),
      ],
    );
  }
}
