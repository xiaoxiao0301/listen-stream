import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../data/models/models.dart';
import '../provider.dart';
import '../widgets/banner_section.dart';
import '../widgets/nav_item.dart';
import '../widgets/card_item.dart';

/// 首页移动端布局 - 垂直滚动单列布局
class HomeMobileLayout extends ConsumerStatefulWidget {
  const HomeMobileLayout({super.key});

  @override
  ConsumerState<HomeMobileLayout> createState() => _HomeMobileLayoutState();
}

class _HomeMobileLayoutState extends ConsumerState<HomeMobileLayout> {
  bool _newSongsVisible = false;
  bool _newAlbumsVisible = false;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(bannerProvider);
        ref.invalidate(recommendPlaylistProvider);
        ref.invalidate(recommendNewSongsProvider);
        ref.invalidate(recommendNewAlbumsProvider);
      },
      child: ListView(
        children: [
          // ── Banner ──────────────────────────────────────────────────────
          ref.watch(bannerProvider).when(
            data: (items) => BannerSection(items: items),
            loading: () => const LoadingShimmer(height: 180),
            error: (e, _) =>
                AppErrorWidget(onRetry: () => ref.invalidate(bannerProvider)),
          ),

          const SizedBox(height: 16),

          // ── Quick Navigation ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NavItem(
                  icon: Icons.trending_up,
                  label: '排行榜',
                  onTap: () => context.push('/ranking'),
                ),
                NavItem(
                  icon: Icons.radio,
                  label: '电台',
                  onTap: () => context.push('/radio'),
                ),
                NavItem(
                  icon: Icons.person,
                  label: '歌手',
                  onTap: () => context.push('/singer-list'),
                ),
                NavItem(
                  icon: Icons.video_library,
                  label: 'MV',
                  onTap: () => context.push('/mv-list'),
                ),
              ],
            ),
          ),

          // ── Recommend Playlist ──────────────────────────────────────────
          ref.watch(recommendPlaylistProvider).when(
            data: (items) => _PlaylistSection(title: '推荐歌单', items: items),
            loading: () => const LoadingShimmer(height: 120),
            error: (e, _) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),

          // ── New Songs ───────────────────────────────────────────────────
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

          // ── New Albums ──────────────────────────────────────────────────
          VisibilityDetector(
            key: const Key('new_albums'),
            onVisibilityChanged: (info) {
              if (info.visibleFraction > 0 && !_newAlbumsVisible) {
                setState(() => _newAlbumsVisible = true);
              }
            },
            child: _newAlbumsVisible
                ? ref.watch(recommendNewAlbumsProvider).when(
                      data: (items) =>
                          _AlbumSection(title: '新碟上架', items: items),
                      loading: () => const LoadingShimmer(height: 120),
                      error: (e, _) => const SizedBox.shrink(),
                    )
                : const LoadingShimmer(height: 120),
          ),
        ],
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return CardItem(
                coverUrl: item.coverUrl,
                title: item.title,
                subtitle: item.creatorNick,
                onTap: () => context.push('/playlist/${item.id}'),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return CardItem(
                coverUrl: item.coverUrl,
                title: item.name,
                subtitle: item.displayArtist,
                onTap: () => context.push('/song/${item.mid}'),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return CardItem(
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
