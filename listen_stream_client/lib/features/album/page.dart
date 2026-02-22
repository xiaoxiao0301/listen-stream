import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/app_error_widget.dart';
import '../../shared/widgets/cover_image.dart';
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
    return ResponsiveBuilderWithInfo(
      builder: (context, deviceType, constraints) {
        final isMobile = deviceType == DeviceType.mobile ||
            deviceType == DeviceType.tablet;

        return CustomScrollView(
          primary: true,
          slivers: [
            _buildAppBar(context, isMobile),
            _buildAlbumInfo(context, isMobile),
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
          album.albumName,
          style: TextStyle(
            fontSize: isMobile ? 16 : 20,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            CoverImage(
              imageUrl: album.coverUrl,
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
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
    );
  }

  Widget _buildAlbumInfo(BuildContext context, bool isMobile) {
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
                  width: isMobile ? double.infinity : 200,
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
            final song = album.songList[index];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: SongListTile(
                  index: index,
                  songMid: song.songMid,
                  songName: song.songName,
                  artistName: song.singerName ?? '',
                  albumMid: album.albumMid,
                  duration: song.interval,
                  showCover: !isMobile,
                ),
              ),
            );
          },
          childCount: album.songList.length,
        ),
      ),
    );
  }
}
