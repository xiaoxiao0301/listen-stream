import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/app_error_widget.dart';
import '../../shared/widgets/cover_image.dart';
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
    return ResponsiveBuilderWithInfo(
      builder: (context, deviceType, constraints) {
        final isMobile = deviceType == DeviceType.mobile ||
            deviceType == DeviceType.tablet;

        return CustomScrollView(
          slivers: [
            // 折叠的头部
            _buildAppBar(context, isMobile),

            // 歌单信息
            _buildPlaylistInfo(context, isMobile),

            // 歌曲列表
            _buildSongList(context, isMobile),
          ],
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, bool isMobile) {
    return SliverAppBar(
      expandedHeight: isMobile ? 300 : 400,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          playlist.dissname,
          style: TextStyle(
            fontSize: isMobile ? 16 : 20,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            CoverImage(
              imageUrl: playlist.logo,
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
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
    );
  }

  Widget _buildPlaylistInfo(BuildContext context, bool isMobile) {
    return SliverToBoxAdapter(
      child: ResponsivePadding(
        mobile: const EdgeInsets.all(16),
        desktop: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
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
                  width: isMobile ? double.infinity : 200,
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
      ),
    );
  }

  Widget _buildSongList(BuildContext context, bool isMobile) {
    return SliverPadding(
      padding: isMobile
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 32),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final song = playlist.songlist[index];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: ListTile(
                  leading: isMobile
                      ? SizedBox(
                          width: 40,
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40,
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                            CoverImage(
                              imageUrl: song.coverUrl,
                              width: 48,
                              height: 48,
                              borderRadius: 4,
                            ),
                          ],
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
                      if (!isMobile) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () {
                            // TODO: 收藏歌曲
                          },
                        ),
                      ],
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onPressed: () {
                          // TODO: 显示更多选项
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    context.push('/song/${song.mid}');
                  },
                ),
              ),
            );
          },
          childCount: playlist.songlist.length,
        ),
      ),
    );
  }
}
