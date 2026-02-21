import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/app_error_widget.dart';
import '../../shared/widgets/cover_image.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/responsive_grid_view.dart';
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
  final _tabsLoaded = [false, false]; // [songs, albums]

  @override
  void initState() {
    super.initState();
    _tabsLoaded[0] = true; // Songs tab loaded immediately.
  }

  @override
  Widget build(BuildContext context) {
    final singer = widget.detail['singer'] as Map<String, dynamic>? ?? {};

    return ResponsiveBuilderWithInfo(
      builder: (context, deviceType, constraints) {
        final isMobile = deviceType == DeviceType.mobile ||
            deviceType == DeviceType.tablet;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (_, __) => [
                SliverAppBar(
                  expandedHeight: isMobile ? 240 : 320,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      singer['name'] as String? ?? '',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                      ),
                    ),
                    background: singer['pic'] != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              CoverImage(
                                imageUrl: singer['pic'] as String,
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: 0,
                              ),
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
                          )
                        : null,
                  ),
                  bottom: TabBar(
                    onTap: (i) {
                      if (!_tabsLoaded[i]) {
                        setState(() => _tabsLoaded[i] = true);
                      }
                    },
                    tabs: const [
                      Tab(text: '歌曲'),
                      Tab(text: '专辑'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _tabsLoaded[0]
                      ? _SongsList(mid: widget.mid, isMobile: isMobile)
                      : const SizedBox.shrink(),
                  _tabsLoaded[1]
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
        final songs =
            (data['list'] as List? ?? []).cast<Map<String, dynamic>>();

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
              final singerName = s['singer']?.toString() ?? '';
              final songMid = s['mid'] as String? ?? '';

              return ListTile(
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
                    ? IconButton(
                        icon: const Icon(Icons.play_circle_outline),
                        onPressed: () {
                          if (songMid.isNotEmpty) {
                            context.push('/song/$songMid');
                          }
                        },
                      )
                    : null,
                onTap: () {
                  if (songMid.isNotEmpty) {
                    context.push('/song/$songMid');
                  }
                },
              );
            },
          ),
        );
      },
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
            final albumName = a['name'] as String? ?? '';
            final picUrl = a['picUrl'] as String? ?? '';
            final albumMid = a['mid'] as String? ?? '';
            final publishTime = a['time'] as String? ?? '';

            return InkWell(
              onTap: () {
                if (albumMid.isNotEmpty) {
                  context.push('/album/$albumMid');
                }
              },
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: CoverImage(
                        imageUrl: picUrl,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
