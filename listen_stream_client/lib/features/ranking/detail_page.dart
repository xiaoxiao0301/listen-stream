import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/ranking.dart';
import '../../data/local/user_data_service.dart';
import '../library/providers.dart';
import 'provider.dart';

class RankingDetailPage extends ConsumerWidget {
  const RankingDetailPage({super.key, required this.topId});

  final String topId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingDetailProvider((topId: int.parse(topId), page: 1, period: null)));

    return Scaffold(
      body: rankingAsync.when(
        data: (ranking) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(ranking.title),
                background: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade700,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (ranking.period != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Text(
                            ranking.period!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '${ranking.listenNumText} 播放',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = ranking.songs[index];
                  return _buildSongTile(song);
                },
                childCount: ranking.songs.length,
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('加载失败: $err'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(rankingDetailProvider),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongTile(RankingSong song) {
    return Builder(
      builder: (context) => Consumer(
        builder: (context, ref, _) => ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  song.rank.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: song.rank <= 3 ? FontWeight.bold : FontWeight.normal,
                    color: song.rank <= 3 ? Colors.red : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (song.rankIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    song.rankIcon!,
                    style: TextStyle(
                      fontSize: 12,
                      color: song.rankType == 6
                          ? Colors.red
                          : song.rankType == 1
                              ? Colors.green
                              : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(song.singerName, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (song.rankValue != null)
                Text(
                  song.rankValue!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(width: 4),
              if (song.mvid > 0)
                Icon(Icons.videocam, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  ref.watch(isSongFavoritedProvider(song.albumMid)).valueOrNull == true
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
                color: ref.watch(isSongFavoritedProvider(song.albumMid)).valueOrNull == true
                    ? Colors.red
                    : null,
                iconSize: 20,
                onPressed: () async {
                  final isFavorited = ref.read(isSongFavoritedProvider(song.albumMid)).valueOrNull == true;
                  if (isFavorited) {
                    await UserDataService.removeFavoriteSong(song.albumMid);
                  } else {
                    await UserDataService.addFavoriteSong(
                      songMid: song.albumMid,
                      songName: song.title,
                      singerName: song.singerName,
                      albumName: '',
                      coverUrl: song.cover,
                    );
                  }
                  ref.invalidate(isSongFavoritedProvider(song.albumMid));
                  ref.invalidate(favoriteSongsProvider);
                },
              ),
              IconButton(
                icon: const Icon(Icons.playlist_add),
                iconSize: 20,
                onPressed: () => _showAddToPlaylistDialog(context, ref, song),
              ),
            ],
          ),
          onTap: () {
            context.push('/song/${song.albumMid}');
          },
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref, RankingSong song) {
    showDialog(
      context: context,
      builder: (context) => _AddToPlaylistDialog(
        song: {
          'song_mid': song.albumMid,
          'song_name': song.title,
          'singer_name': song.singerName,
          'album_name': '',
          'cover_url': song.cover,
        },
      ),
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
