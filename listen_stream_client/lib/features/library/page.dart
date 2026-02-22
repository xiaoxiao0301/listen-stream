import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../data/local/user_data_service.dart';
import '../../data/remote/api_service.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/app_error_widget.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/cover_image.dart';
import 'providers.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveBuilderWithInfo(
      builder: (context, deviceType, constraints) {
        final isMobile = deviceType == DeviceType.mobile ||
            deviceType == DeviceType.tablet;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('我的音乐'),
              centerTitle: false,
              bottom: TabBar(
                isScrollable: !isMobile,
                tabs: const [
                  Tab(text: '收藏歌曲'),
                  Tab(text: '我的歌单'),
                  Tab(text: '历史'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _FavoriteSongsTab(isMobile: isMobile),
                _PlaylistsTab(isMobile: isMobile),
                _HistoryTab(isMobile: isMobile),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FavoriteSongsTab extends ConsumerWidget {
  const _FavoriteSongsTab({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoriteSongsProvider);
    
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (songs) {
        if (songs.isEmpty) {
          return const EmptyState(
            icon: Icons.favorite_border,
            title: '暂无收藏歌曲',
            message: '收藏的歌曲会显示在这里',
          );
        }

        return AdaptiveContainer(
          maxWidthDesktop: 1280,
          maxWidthTv: 1600,
          padding: isMobile ? EdgeInsets.zero : null,
          child: Column(
            children: [
              // Action bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '共 ${songs.length} 首歌曲',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showClearConfirmDialog(context, ref),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('清空'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              // Songs list
              Expanded(
                child: ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (_, i) {
                    final song = songs[i];
                    final songMid = song['song_mid'] as String;
                    final songName = song['song_name'] as String;
                    final singerName = song['singer_name'] as String;
                    final coverUrl = song['cover_url'] as String;

                    return ListTile(
                      leading: coverUrl.isNotEmpty
                          ? CoverImage(
                              imageUrl: coverUrl,
                              width: 48,
                              height: 48,
                              borderRadius: 4,
                            )
                          : const Icon(Icons.music_note),
                      title: Text(
                        songName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        singerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.playlist_add),
                            onPressed: () => _showAddToPlaylistDialog(context, ref, song),
                            tooltip: '添加到歌单',
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite),
                            color: Colors.red,
                            onPressed: () async {
                              await UserDataService.removeFavoriteSong(songMid);
                              ref.invalidate(favoriteSongsProvider);
                            },
                            tooltip: '取消收藏',
                          ),
                        ],
                      ),
                      onTap: () => context.push('/song/$songMid'),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空收藏'),
        content: const Text('确定要清空所有收藏的歌曲吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await UserDataService.clearAllFavorites();
              ref.invalidate(favoriteSongsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> song) {
    showDialog(
      context: context,
      builder: (context) => _AddToPlaylistDialog(song: song),
    );
  }
}

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userPlaylistsProvider);
    
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (playlists) {
        return AdaptiveContainer(
          maxWidthDesktop: 1280,
          maxWidthTv: 1600,
          padding: isMobile ? EdgeInsets.zero : null,
          child: Column(
            children: [
              // Action bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '共 ${playlists.length} 个歌单',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showCreatePlaylistDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('创建歌单'),
                    ),
                    if (playlists.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _showClearAllPlaylistsDialog(context, ref),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('清空'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
              // Playlists list
              Expanded(
                child: playlists.isEmpty
                    ? const EmptyState(
                        icon: Icons.playlist_play,
                        title: '暂无歌单',
                        message: '点击上方按钮创建歌单',
                      )
                    : ListView.builder(
                        itemCount: playlists.length,
                        itemBuilder: (_, i) {
                          final playlist = playlists[i];
                          final id = playlist['id'] as int;
                          final name = playlist['name'] as String;
                          final description = playlist['description'] as String;

                          return ListTile(
                            leading: const Icon(Icons.playlist_play, size: 40),
                            title: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: description.isNotEmpty
                                ? Text(
                                    description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'delete':
                                    _showDeletePlaylistDialog(context, ref, id, name);
                                    break;
                                  case 'clear':
                                    _showClearPlaylistDialog(context, ref, id, name);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'clear',
                                  child: Text('清空歌曲'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('删除歌单'),
                                ),
                              ],
                            ),
                            onTap: () {
                              // TODO: Navigate to playlist detail page
                              _showPlaylistSongsDialog(context, ref, id, name);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建歌单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '歌单名称',
                hintText: '请输入歌单名称',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '请输入歌单描述',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              await UserDataService.createPlaylist(
                name: name,
                description: descController.text.trim(),
              );
              ref.invalidate(userPlaylistsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showDeletePlaylistDialog(BuildContext context, WidgetRef ref, int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除歌单'),
        content: Text('确定要删除歌单"$name"吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await UserDataService.deletePlaylist(id);
              ref.invalidate(userPlaylistsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showClearPlaylistDialog(BuildContext context, WidgetRef ref, int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空歌单'),
        content: Text('确定要清空歌单"$name"中的所有歌曲吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await UserDataService.clearPlaylistSongs(id);
              ref.invalidate(playlistSongsProvider(id));
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  void _showClearAllPlaylistsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有歌单'),
        content: const Text('确定要删除所有歌单吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await UserDataService.clearAllPlaylists();
              ref.invalidate(userPlaylistsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistSongsDialog(BuildContext context, WidgetRef ref, int id, String name) {
    showDialog(
      context: context,
      builder: (context) => _PlaylistSongsDialog(playlistId: id, playlistName: name),
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
            return const Text('暂无歌单，请先创建歌单');
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

class _PlaylistSongsDialog extends ConsumerWidget {
  const _PlaylistSongsDialog({
    required this.playlistId,
    required this.playlistName,
  });
  
  final int playlistId;
  final String playlistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playlistSongsProvider(playlistId));
    
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    playlistName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('加载失败: $e')),
                data: (songs) {
                  if (songs.isEmpty) {
                    return const EmptyState(
                      icon: Icons.music_note,
                      title: '歌单为空',
                      message: '从收藏中添加歌曲到此歌单',
                    );
                  }

                  return ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (_, i) {
                      final song = songs[i];
                      final songMid = song['song_mid'] as String;
                      final songName = song['song_name'] as String;
                      final singerName = song['singer_name'] as String;

                      return ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(
                          songName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          singerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () async {
                            await UserDataService.removeSongFromPlaylist(
                              playlistId: playlistId,
                              songMid: songMid,
                            );
                            ref.invalidate(playlistSongsProvider(playlistId));
                          },
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/song/$songMid');
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return AdaptiveContainer(
      maxWidthDesktop: 1280,
      maxWidthTv: 1600,
      child: const EmptyState(
        icon: Icons.history,
        title: '最近播放',
        message: '播放历史功能开发中',
      ),
    );
  }
}
