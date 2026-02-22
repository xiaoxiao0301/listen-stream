import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart' hide ResponsiveGridView;
import '../../data/local/user_data_service.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/app_error_widget.dart';
import '../../shared/widgets/cover_image.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/responsive_grid_view.dart';
import '../library/providers.dart';
import 'provider.dart';

class SingerDetailPage extends ConsumerWidget {
  const SingerDetailPage({super.key, required this.mid});
  final String mid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(singerDetailFamily(mid));
    return detailAsync.when(
      loading: () =>
          const Scaffold(body: LoadingShimmer(height: double.infinity)),
      error: (e, _) => Scaffold(
        body: AppErrorWidget(
          onRetry: () => ref.invalidate(singerDetailFamily(mid)),
        ),
      ),
      data: (detail) => _SingerDetail(mid: mid, detail: detail),
    );
  }
}

class _SingerDetail extends ConsumerStatefulWidget {
  const _SingerDetail({required this.mid, required this.detail});
  final String mid;
  final Map<String, dynamic> detail;
  @override
  ConsumerState<_SingerDetail> createState() => _SingerDetailState();
}

class _SingerDetailState extends ConsumerState<_SingerDetail> {
  // Track which tabs have been loaded (lazy init).
  // [intro, songs, mvs, albums]
  final _tabsLoaded = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    // Load Intro and Songs tabs immediately so the initial view is populated.
    _tabsLoaded[0] = true; // Intro tab loaded immediately.
    _tabsLoaded[1] = true; // Songs tab loaded immediately.
  }

  @override
  Widget build(BuildContext context) {
    // Ensure _tabsLoaded length matches the number of tabs (4).
    // This guards against hot-reload state where the old list length
    // may be different and would cause RangeError when indexing.
    const tabCount = 4;
    if (_tabsLoaded.length < tabCount) {
      _tabsLoaded.addAll(List<bool>.filled(tabCount - _tabsLoaded.length, false));
      // ensure songs tab is considered loaded
      if (_tabsLoaded.length > 1) _tabsLoaded[1] = true;
    }
    final singer = (widget.detail['singer'] as Map<String, dynamic>?)
      ?? (widget.detail['singer_info'] as Map<String, dynamic>?)
      ?? {};

    // Generate fallback picture URL if not provided
    final singerPic = singer['pic'] as String? ?? 
        (widget.mid.isNotEmpty 
          ? 'https://y.gtimg.cn/music/photo_new/T001R300x300M000${widget.mid}.jpg'
          : null);

    return ResponsiveBuilderWithInfo(
      builder: (context, deviceType, constraints) {
        final isMobile = deviceType == DeviceType.mobile ||
            deviceType == DeviceType.tablet;

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (_, __) => [
                SliverAppBar(
                  expandedHeight: isMobile ? 240 : 320,
                  pinned: true,
                  stretch: true,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: false,
                    titlePadding: const EdgeInsetsDirectional.only(
                      start: 16,
                      bottom: 16,
                    ),
                    title: Text(
                      singer['name'] as String? ?? '',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3.0,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                    background: singerPic != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                singerPic,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[900],
                                  child: const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.white24,
                                  ),
                                ),
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black87,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            color: Colors.grey[900],
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white24,
                            ),
                          ),
                  ),
                  bottom: TabBar(
                    onTap: (i) {
                      if (!_tabsLoaded[i]) {
                        setState(() => _tabsLoaded[i] = true);
                      }
                    },
                    tabs: const [
                      Tab(text: '简介'),
                      Tab(text: '歌曲'),
                      Tab(text: 'MV'),
                      Tab(text: '专辑'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _tabsLoaded[0]
                      ? _IntroTab(detail: widget.detail)
                      : const SizedBox.shrink(),
                  _tabsLoaded[1]
                      ? _SongsList(mid: widget.mid, isMobile: isMobile)
                      : const SizedBox.shrink(),
                  _tabsLoaded[2]
                      ? _MvsList(mid: widget.mid, isMobile: isMobile)
                      : const SizedBox.shrink(),
                  _tabsLoaded[3]
                      ? _AlbumsList(mid: widget.mid, isMobile: isMobile)
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IntroTab extends StatelessWidget {
  const _IntroTab({required this.detail});
  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context) {
    final brief = (detail['singer_brief'] as String?) ??
        (detail['brief'] as String?) ??
        (detail['desc'] as String?) ??
        '';

    if (brief.isEmpty) {
      return const Center(child: Text('无简介'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(brief, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _SongsList extends ConsumerWidget {
  const _SongsList({required this.mid, required this.isMobile});
  final String mid;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(singerSongsFamily(mid)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(
        onRetry: () => ref.invalidate(singerSongsFamily(mid)),
      ),
      data: (data) {
        final raw = data['list'] ?? data['songlist'] ?? data['data'] ?? [];
        final songs = (raw is List ? raw : []).cast<Map<String, dynamic>>();

        if (songs.isEmpty) {
          return const EmptyState(
            icon: Icons.music_note,
            title: '暂无歌曲',
          );
        }

        return AdaptiveContainer(
          maxWidthDesktop: 1280,
          maxWidthTv: 1600,
          padding: isMobile ? EdgeInsets.zero : null,
          child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (_, i) {
                final s = songs[i];
                final songName = s['name'] as String? ?? '';
                String singerName = '';
                final sv = s['singer'];
                if (sv is List) {
                  singerName = sv.map((e) => (e['name'] as String? ?? '')).where((n) => n.isNotEmpty).join('/');
                } else if (sv is String) {
                  singerName = sv;
                }
                final songMid = s['mid'] as String? ?? '';

                return Consumer(
                  builder: (context, ref, _) => ListTile(
                    leading: isMobile
                        ? SizedBox(
                            width: 40,
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(color: Colors.grey),
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
                                    '${i + 1}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                              if (!isMobile && songMid.isNotEmpty)
                                CoverImage(
                                  imageUrl:
                                      'https://y.gtimg.cn/music/photo_new/T002R150x150M000$songMid.jpg',
                                  width: 48,
                                  height: 48,
                                  borderRadius: 4,
                                ),
                            ],
                          ),
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
                    trailing: !isMobile
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  ref.watch(isSongFavoritedProvider(songMid)).valueOrNull == true
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                                color: ref.watch(isSongFavoritedProvider(songMid)).valueOrNull == true
                                    ? Colors.red
                                    : null,
                                onPressed: () async {
                                  final isFavorited = ref.read(isSongFavoritedProvider(songMid)).valueOrNull == true;
                                  if (isFavorited) {
                                    await UserDataService.removeFavoriteSong(songMid);
                                  } else {
                                    await UserDataService.addFavoriteSong(
                                      songMid: songMid,
                                      songName: songName,
                                      singerName: singerName,
                                      albumName: s['album']?['name'] as String? ?? '',
                                      coverUrl: 'https://y.gtimg.cn/music/photo_new/T002R150x150M000$songMid.jpg',
                                    );
                                  }
                                  ref.invalidate(isSongFavoritedProvider(songMid));
                                  ref.invalidate(favoriteSongsProvider);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.playlist_add),
                                onPressed: () {
                                  _showAddToPlaylistDialog(context, ref, s, songMid, songName, singerName);
                                },
                              ),
                            ],
                          )
                        : null,
                    onTap: () {
                      if (songMid.isNotEmpty) {
                        context.push('/song/$songMid');
                      }
                    },
                  ),
                );
              },
            ),
          );
      },
    );
  }

  void _showAddToPlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> songData,
    String songMid,
    String songName,
    String singerName,
  ) {
    showDialog(
      context: context,
      builder: (context) => _AddToPlaylistDialog(
        song: {
          'song_mid': songMid,
          'song_name': songName,
          'singer_name': singerName,
          'album_name': songData['album']?['name'] as String? ?? '',
          'cover_url': 'https://y.gtimg.cn/music/photo_new/T002R150x150M000$songMid.jpg',
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

class _AlbumsList extends ConsumerWidget {
  const _AlbumsList({required this.mid, required this.isMobile});
  final String mid;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(singerAlbumsFamily(mid)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(
        onRetry: () => ref.invalidate(singerAlbumsFamily(mid)),
      ),
      data: (data) {
        final albums =
            (data['list'] as List? ?? []).cast<Map<String, dynamic>>();

        if (albums.isEmpty) {
          return const EmptyState(
            icon: Icons.album,
            title: '暂无专辑',
          );
        }

        return ResponsiveGridView(
          itemCount: albums.length,
            itemBuilder: (_, i) {
            final a = albums[i];
            final albumName = (a['album_name'] as String?) ?? (a['name'] as String?) ?? '';
            final picUrl = (a['picurl'] as String?) ?? (a['picUrl'] as String?) ?? (a['pic'] as String?) ?? '';
            final albumMid = (a['album_mid'] as String?) ?? (a['mid'] as String?) ?? (a['albumMid'] as String?) ?? '';
            final publishTime = (a['pub_time'] as String?) ?? (a['time'] as String?) ?? (a['pubtime'] as String?) ?? (a['time_public'] as String?) ?? '';

            return Card(
              key: ValueKey('album_$albumMid'),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  if (albumMid.isNotEmpty) {
                    context.push('/album/$albumMid');
                  }
                },
                hoverColor: Colors.transparent,
                splashColor: Colors.grey.withOpacity(0.2),
                highlightColor: Colors.grey.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: picUrl.isNotEmpty
                          ? CoverImage(
                              imageUrl: picUrl,
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: 0,
                            )
                          : Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: const Color(0xFFe0e0e0),
                              child: const Icon(
                                Icons.album,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            albumName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (publishTime.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              publishTime,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          mobileColumns: 2,
          tabletColumns: 3,
          desktopColumns: 4,
          tvColumns: 6,
          childAspectRatio: 0.8,
        );
      },
    );
  }
}

  class _MvsList extends ConsumerWidget {
    const _MvsList({required this.mid, required this.isMobile});
    final String mid;
    final bool isMobile;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return ref.watch(singerMvsFamily(mid)).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          onRetry: () => ref.invalidate(singerMvsFamily(mid)),
        ),
        data: (data) {
          final raw = data['list'] ?? data['data'] ?? [];
          final mvs = (raw is List ? raw : []).cast<Map<String, dynamic>>();

          if (mvs.isEmpty) {
            return const EmptyState(icon: Icons.videocam, title: '暂无 MV');
          }

          return ResponsiveGridView(
            itemCount: mvs.length,
              itemBuilder: (_, i) {
                final mv = mvs[i];
                final title = (mv['title'] as String?) ?? (mv['name'] as String?) ?? '';
                final pic = (mv['picurl'] as String?) ?? (mv['picUrl'] as String?) ?? (mv['pic'] as String?) ?? '';
                final vid = (mv['vid'] as String?) ?? (mv['video_id'] as String?) ?? '';

                return Card(
                  key: ValueKey('mv_$vid'),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      if (vid.isNotEmpty) {
                        context.push('/mv/$vid');
                      }
                    },
                    hoverColor: Colors.transparent,
                    splashColor: Colors.grey.withOpacity(0.2),
                    highlightColor: Colors.grey.withOpacity(0.1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: CoverImage(
                            imageUrl: pic,
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: 0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              mobileColumns: 2,
              tabletColumns: 3,
              desktopColumns: 4,
            tvColumns: 6,
            childAspectRatio: 0.8,
          );
        },
      );
    }
  }
