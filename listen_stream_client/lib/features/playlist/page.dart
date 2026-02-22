import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../data/models/models.dart';
import '../../data/local/user_data_service.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/app_error_widget.dart';
import '../../shared/widgets/cover_image.dart';
import '../library/providers.dart';
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

class _PlaylistContent extends ConsumerWidget {
  const _PlaylistContent({required this.playlist});

  final PlaylistDetail playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            _buildSongList(context, ref, isMobile),
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

  Widget _buildSongList(BuildContext context, WidgetRef ref, bool isMobile) {
    return SliverPadding(
      padding: isMobile
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 32),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final song = playlist.songlist[index];
            final songMid = song.mid; // Capture mid to avoid closure issue
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: _SongListTile(
                  song: song,
                  songMid: songMid,
                  index: index,
                  isMobile: isMobile,
                  onAddToPlaylist: (songDetail) => _showAddToPlaylistDialog(context, ref, songDetail),
                  onShowMobileMenu: (songDetail) => _showMobileMenu(context, ref, songDetail),
                ),
              ),
            );
          },
          childCount: playlist.songlist.length,
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref, SongDetail song) {
    showDialog(
      context: context,
      builder: (context) => _AddToPlaylistDialog(
        song: {
          'song_mid': song.mid,
          'song_name': song.name,
          'singer_name': song.singerName,
          'album_name': song.albumName,
          'cover_url': song.coverUrl,
        },
      ),
    );
  }

  void _showMobileMenu(BuildContext context, WidgetRef ref, SongDetail song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('收藏歌曲'),
              onTap: () async {
                Navigator.pop(context);
                await UserDataService.addFavoriteSong(
                  songMid: song.mid,
                  songName: song.name,
                  singerName: song.singerName,
                  albumName: song.albumName,
                  coverUrl: song.coverUrl,
                );
                ref.invalidate(isSongFavoritedProvider(song.mid));
                ref.invalidate(favoriteSongsProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('添加到歌单'),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylistDialog(context, ref, song);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SongListTile extends ConsumerWidget {
  const _SongListTile({
    required this.song,
    required this.songMid,
    required this.index,
    required this.isMobile,
    required this.onAddToPlaylist,
    required this.onShowMobileMenu,
  });

  final SongDetail song;
  final String songMid;
  final int index;
  final bool isMobile;
  final Function(SongDetail) onAddToPlaylist;
  final Function(SongDetail) onShowMobileMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorited = ref.watch(isSongFavoritedProvider(songMid)).valueOrNull ?? false;

    return ListTile(
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
              icon: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
              ),
              color: isFavorited ? Colors.red : null,
              onPressed: () async {
                if (isFavorited) {
                  await UserDataService.removeFavoriteSong(songMid);
                } else {
                  await UserDataService.addFavoriteSong(
                    songMid: songMid,
                    songName: song.name,
                    singerName: song.singerName,
                    albumName: song.albumName,
                    coverUrl: song.coverUrl,
                  );
                }
                ref.invalidate(isSongFavoritedProvider(songMid));
                ref.invalidate(favoriteSongsProvider);
              },
            ),
            IconButton(
              icon: const Icon(Icons.playlist_add),
              onPressed: () => onAddToPlaylist(song),
            ),
          ],
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: () => onShowMobileMenu(song),
            ),
        ],
      ),
      onTap: () {
        if (songMid.isNotEmpty) {
          context.push('/song/$songMid');
        }
      },
    );
  }
}

class _AddToPlaylistDialog extends ConsumerWidget {
  const _AddToPlaylistDialog({required this.song});
  final Map<String, dynamic> song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userPlaylistsProvider);
    
    return AlertDialog(
      title: const Text('添加到歌单'),
      content: async.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('加载失败: $e'),
        data: (playlists) {
          if (playlists.isEmpty) {
            return const Text('暂无歌单，请先在"我的音乐"中创建歌单');
          }

          return SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length,
              itemBuilder: (_, i) {
                final playlist = playlists[i];
                final id = playlist['id'] as int;
                final name = playlist['name'] as String;

                return ListTile(
                  leading: const Icon(Icons.playlist_play),
                  title: Text(name),
                  onTap: () async {
                    await UserDataService.addSongToPlaylist(
                      playlistId: id,
                      songMid: song['song_mid'] as String,
                      songName: song['song_name'] as String,
                      singerName: song['singer_name'] as String,
                      albumName: song['album_name'] as String? ?? '',
                      coverUrl: song['cover_url'] as String? ?? '',
                    );
                    ref.invalidate(playlistSongsProvider(id));
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已添加到"$name"')),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
