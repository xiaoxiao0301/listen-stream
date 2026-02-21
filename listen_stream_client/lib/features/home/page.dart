import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/app_error_widget.dart';
import '../../data/models/models.dart';
import 'provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _newSongsVisible  = false;
  bool _newAlbumsVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('发现')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bannerProvider);
          ref.invalidate(recommendPlaylistProvider);
          ref.invalidate(recommendNewSongsProvider);
          ref.invalidate(recommendNewAlbumsProvider);
        },
        child: ListView(
          children: [
            // ── Banner (auto-play PageView) ───────────────────────────────
            ref.watch(bannerProvider).when(
              data: (items) => _BannerSection(items: items),
              loading: () => const LoadingShimmer(height: 180),
              error: (e, _) => AppErrorWidget(onRetry: () => ref.invalidate(bannerProvider)),
            ),

            const SizedBox(height: 16),

            // ── Recommend Playlist ────────────────────────────────────────
            ref.watch(recommendPlaylistProvider).when(
              data: (items) => _PlaylistSection(title: '推荐歌单', items: items),
              loading: () => const LoadingShimmer(height: 120),
              error: (e, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 8),

            // ── New Songs (lazy via VisibilityDetector) ───────────────────
            VisibilityDetector(
              key: const Key('new_songs'),
              onVisibilityChanged: (info) {
                if (info.visibleFraction > 0 && !_newSongsVisible) {
                  setState(() => _newSongsVisible = true);
                }
              },
              child: _newSongsVisible
                  ? ref.watch(recommendNewSongsProvider).when(
                      data: (items) => _SongSection(title: '新歌首发', items: items),
                      loading: () => const LoadingShimmer(height: 120),
                      error: (e, _) => const SizedBox.shrink(),
                    )
                  : const LoadingShimmer(height: 120),
            ),

            // ── New Albums (lazy) ─────────────────────────────────────────
            VisibilityDetector(
              key: const Key('new_albums'),
              onVisibilityChanged: (info) {
                if (info.visibleFraction > 0 && !_newAlbumsVisible) {
                  setState(() => _newAlbumsVisible = true);
                }
              },
              child: _newAlbumsVisible
                  ? ref.watch(recommendNewAlbumsProvider).when(
                      data: (items) => _AlbumSection(title: '新碟上架', items: items),
                      loading: () => const LoadingShimmer(height: 120),
                      error: (e, _) => const SizedBox.shrink(),
                    )
                  : const LoadingShimmer(height: 120),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerSection extends StatefulWidget {
  const _BannerSection({required this.items});
  final List<BannerItem> items;
  @override
  State<_BannerSection> createState() => _BannerSectionState();
}
class _BannerSectionState extends State<_BannerSection> {
  final _controller = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_controller.hasClients && widget.items.isNotEmpty) {
        final next = ((_controller.page?.toInt() ?? 0) + 1) % widget.items.length;
        _controller.animateToPage(next,
            duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.items.length,
        itemBuilder: (_, i) {
          final item = widget.items[i];
          return Image.network(item.picUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1a1a2e)));
        },
      ),
    );
  }
}

// ── Playlist Section ────────────────────────────────────────────────────────
class _PlaylistSection extends StatelessWidget {
  const _PlaylistSection({required this.title, required this.items});
  final String title;
  final List<PlaylistItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return _CardItem(
                coverUrl: item.coverUrl,
                title: item.title,
                subtitle: item.creatorNick,
                onTap: () => context.push('/playlist/${item.tid}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Song Section ────────────────────────────────────────────────────────────
class _SongSection extends StatelessWidget {
  const _SongSection({required this.title, required this.items});
  final String title;
  final List<SongItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              // 歌曲使用专辑封面，通过 album.mid 构建
              final albumMid = item.mid; // 简化处理，实际应从 album 获取
              final coverUrl = 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$albumMid.jpg';
              return _CardItem(
                coverUrl: coverUrl,
                title: item.name,
                subtitle: item.displayArtist,
                onTap: () {
                  // TODO: 播放歌曲
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('播放: ${item.name}')),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Album Section ───────────────────────────────────────────────────────────
class _AlbumSection extends StatelessWidget {
  const _AlbumSection({required this.title, required this.items});
  final String title;
  final List<AlbumItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return _CardItem(
                coverUrl: item.coverUrl,
                title: item.name,
                subtitle: item.displayArtist,
                onTap: () => context.push('/album/${item.mid}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Card Item ───────────────────────────────────────────────────────────────
class _CardItem extends StatelessWidget {
  const _CardItem({
    required this.coverUrl,
    required this.title,
    this.subtitle,
    this.onTap,
  });
  
  final String coverUrl;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100, 
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                coverUrl, 
                width: 96, 
                height: 96, 
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 96, height: 96, 
                  child: ColoredBox(color: Color(0xFFe0e0e0))
                ),
              ),
            ),  
            const SizedBox(height: 4),
            Text(
              title, 
              maxLines: 2, 
              overflow: TextOverflow.ellipsis, 
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
