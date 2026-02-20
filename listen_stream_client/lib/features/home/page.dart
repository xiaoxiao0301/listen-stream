import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/app_error_widget.dart';
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
              data: (data) => _BannerSection(items: (data['data'] as List? ?? []).cast()),
              loading: () => const LoadingShimmer(height: 180),
              error: (e, _) => AppErrorWidget(onRetry: () => ref.invalidate(bannerProvider)),
            ),

            const SizedBox(height: 16),

            // ── Recommend Playlist ────────────────────────────────────────
            ref.watch(recommendPlaylistProvider).when(
              data: (d) => _Section(title: '推荐歌单', items: (d['data'] as List? ?? []).cast()),
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
                      data: (d) => _Section(title: '新歌首发', items: (d['data'] as List? ?? []).cast()),
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
                      data: (d) => _Section(title: '新碟上架', items: (d['data'] as List? ?? []).cast()),
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
  final List<Map<String, dynamic>> items;
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
          final url = item['picUrl'] as String? ?? '';
          return Image.network(url, fit: BoxFit.cover);
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});
  final String title;
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (_, i) => _CardItem(data: items[i]),
          ),
        ),
      ],
    );
  }
}

class _CardItem extends StatelessWidget {
  const _CardItem({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final url = data['picUrl'] as String? ?? '';
    final name = data['title'] as String? ?? data['name'] as String? ?? '';
    return Container(
      width: 100, margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8),
          child: Image.network(url, width: 96, height: 96, fit: BoxFit.cover)),
        const SizedBox(height: 4),
        Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}
