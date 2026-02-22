import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../shared/widgets/cover_image.dart';
import '../../data/remote/api_service.dart';
import '../../data/local/user_data_service.dart';
import '../library/providers.dart';

/// 歌曲详情页 - 提供播放和收藏功能
class SongDetailPage extends ConsumerWidget {
  const SongDetailPage({super.key, required this.songMid});

  final String songMid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger song URL load when the page is built
    final api = ref.read(apiServiceProvider);
    final coverUrl = 'https://y.gtimg.cn/music/photo_new/T002R300x300M000${songMid}.jpg';

    return Scaffold(
      appBar: AppBar(
        title: const Text('歌曲详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveBuilderWithInfo(
        builder: (context, deviceType, constraints) {
          final isMobile = deviceType == DeviceType.mobile ||
              deviceType == DeviceType.tablet;

          // 根据设备类型调整封面大小
          final coverSize = responsiveValue(
            context: context,
            mobile: 250.0,
            tablet: 300.0,
            desktop: 400.0,
            tv: 500.0,
          );

          // 根据设备类型调整按钮尺寸
          final buttonMinWidth = responsiveValue(
            context: context,
            mobile: 120.0,
            tablet: 140.0,
            desktop: 160.0,
            tv: 180.0,
          );

          final buttonHeight = ResponsiveSize.buttonHeight(context);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: ResponsiveSpacing.pagePadding(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),

                    // 专辑封面 — 使用歌单/专辑 mid 优先显示专辑封面
                    FutureBuilder<String>(
                      future: api
                          .getSongDetail(songMid)
                          .catchError((_) => <String, dynamic>{})
                          .then((detailResp) {
                        try {
                          final d = detailResp['data'] ?? detailResp;
                          if (d is Map) {
                            final track = d['track_info'];
                            if (track is Map && track['album'] is Map) {
                              final al = track['album'];
                              final mid = (al['mid'] ?? '').toString();
                              if (mid.isNotEmpty) return 'https://y.gtimg.cn/music/photo_new/T002R300x300M000${mid}.jpg';
                            }
                          }
                        } catch (_) {}
                        // fallback to songMid
                        return coverUrl;
                      }),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return Container(
                            width: coverSize,
                            height: coverSize,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        }
                        final img = snap.data ?? coverUrl;
                        return Column(
                          children: [
                            CoverImage(
                              imageUrl: img,
                              width: coverSize,
                              height: coverSize,
                              borderRadius: 16,
                            ),
                            SizedBox(height: isMobile ? 32 : 48),
                          ],
                        );
                      },
                    ),

                    // Load song detail + URL + lyric in parallel
                    FutureBuilder<Map<String, dynamic>>(
                      future: api.getSongDetail(songMid).catchError((_) => <String, dynamic>{}).then((detailResp) {
                        final d = detailResp['data'] ?? detailResp;
                        String title = '歌曲名称';
                        String artist = '歌手名称';
                        String album = '';
                        String pubTime = '';
                        String company = '';
                        String intro = '';
                        try {
                          if (d is Map) {
                            // prefer track_info.name, then extras.name
                            final track = d['track_info'];
                            if (track is Map && track['name'] != null) title = track['name'].toString();
                            if ((title == '歌曲名称') && d['extras'] is Map && d['extras']['name'] != null) {
                              title = d['extras']['name'].toString();
                            }

                            // artist
                            if (track is Map && track['singer'] is List && track['singer'].isNotEmpty) {
                              final s = track['singer'][0];
                              if (s is Map && s['name'] != null) artist = s['name'].toString();
                            }

                            // album & pub time
                            if (track is Map && track['album'] is Map) {
                              final al = track['album'];
                              album = (al['name'] ?? '').toString();
                              pubTime = (al['time_public'] ?? '').toString();
                            }

                            // company
                            if (d['info'] is Map && d['info']['company'] is Map) {
                              final comp = d['info']['company'];
                              if (comp['content'] is List && comp['content'].isNotEmpty) {
                                final c = comp['content'][0];
                                if (c is Map && c['value'] != null) company = c['value'].toString();
                              }
                            }

                            // intro
                            if (d['info'] is Map && d['info']['intro'] is Map) {
                              final introBlock = d['info']['intro'];
                              if (introBlock['content'] is List && introBlock['content'].isNotEmpty) {
                                final item = introBlock['content'][0];
                                if (item is Map && item['value'] != null) intro = item['value'].toString();
                              }
                            }
                          }
                        } catch (_) {}
                        return {
                          'title': title,
                          'artist': artist,
                          'album': album,
                          'pubTime': pubTime,
                          'company': company,
                          'intro': intro,
                        };
                      }),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text('加载歌曲信息失败：${snapshot.error}'),
                          );
                        }

                        final data = snapshot.data ?? {};
                        final title = data['title'] as String? ?? '歌曲名称';
                        final artist = data['artist'] as String? ?? '歌手名称';
                        final album = data['album'] as String? ?? '';
                        final pubTime = data['pubTime'] as String? ?? '';
                        final company = data['company'] as String? ?? '';
                        final intro = data['intro'] as String? ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontSize: isMobile ? 24 : 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                artist,
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (album.isNotEmpty)
                                    Chip(label: Text(album)),
                                  if (pubTime.isNotEmpty)
                                    Chip(label: Text(pubTime)),
                                  if (company.isNotEmpty)
                                    Chip(label: Text(company)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (intro.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    intro,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(height: isMobile ? 48 : 64),

                    // 操作按钮
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        // 收藏按钮
                        Consumer(
                          builder: (context, ref, _) {
                            final isFavorited = ref.watch(isSongFavoritedProvider(songMid)).valueOrNull ?? false;
                            
                            return ElevatedButton.icon(
                              onPressed: () async {
                                // Get song details from the outer FutureBuilder if possible
                                final api = ref.read(apiServiceProvider);
                                try {
                                  final detailResp = await api.getSongDetail(songMid);
                                  final d = detailResp['data'] ?? detailResp;
                                  String title = '未知歌曲';
                                  String artist = '未知歌手';
                                  String coverUrl = 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$songMid.jpg';

                                  if (d is Map) {
                                    final track = d['track_info'];
                                    if (track is Map) {
                                      title = track['name']?.toString() ?? title;
                                      if (track['singer'] is List && track['singer'].isNotEmpty) {
                                        final s = track['singer'][0];
                                        if (s is Map && s['name'] != null) {
                                          artist = s['name'].toString();
                                        }
                                      }
                                      if (track['album'] is Map) {
                                        final albumMid = track['album']['mid']?.toString();
                                        if (albumMid != null && albumMid.isNotEmpty) {
                                          coverUrl = 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg';
                                        }
                                      }
                                    }
                                  }

                                  if (isFavorited) {
                                    await UserDataService.removeFavoriteSong(songMid);
                                    ref.invalidate(isSongFavoritedProvider(songMid));
                                    ref.invalidate(favoriteSongsProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('已取消收藏')),
                                      );
                                    }
                                  } else {
                                    await UserDataService.addFavoriteSong(
                                      songMid: songMid,
                                      songName: title,
                                      singerName: artist,
                                      coverUrl: coverUrl,
                                    );
                                    ref.invalidate(isSongFavoritedProvider(songMid));
                                    ref.invalidate(favoriteSongsProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('已添加到收藏')),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('操作失败: $e')),
                                    );
                                  }
                                }
                              },
                              icon: Icon(isFavorited ? Icons.favorite : Icons.favorite_border),
                              label: Text(isFavorited ? '已收藏' : '收藏'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(buttonMinWidth, buttonHeight),
                                foregroundColor: isFavorited ? Colors.red : null,
                              ),
                            );
                          },
                        ),

                        // 播放按钮
                        FilledButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('播放功能开发中')),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('播放'),
                          style: FilledButton.styleFrom(
                            minimumSize: Size(buttonMinWidth, buttonHeight),
                          ),
                        ),

                        // 添加到歌单按钮
                        if (!isMobile)
                          OutlinedButton.icon(
                            onPressed: () async {
                              // Get song details
                              final api = ref.read(apiServiceProvider);
                              try {
                                final detailResp = await api.getSongDetail(songMid);
                                final d = detailResp['data'] ?? detailResp;
                                String title = '未知歌曲';
                                String artist = '未知歌手';
                                String coverUrl = 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$songMid.jpg';

                                if (d is Map) {
                                  final track = d['track_info'];
                                  if (track is Map) {
                                    title = track['name']?.toString() ?? title;
                                    if (track['singer'] is List && track['singer'].isNotEmpty) {
                                      final s = track['singer'][0];
                                      if (s is Map && s['name'] != null) {
                                        artist = s['name'].toString();
                                      }
                                    }
                                    if (track['album'] is Map) {
                                      final albumMid = track['album']['mid']?.toString();
                                      if (albumMid != null && albumMid.isNotEmpty) {
                                        coverUrl = 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg';
                                      }
                                    }
                                  }
                                }

                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => _AddToPlaylistDialog(
                                      song: {
                                        'song_mid': songMid,
                                        'song_name': title,
                                        'singer_name': artist,
                                        'cover_url': coverUrl,
                                      },
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('操作失败: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.playlist_add),
                            label: const Text('添加到歌单'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(buttonMinWidth, buttonHeight),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          );
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
