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
import '../../../shared/widgets/media_card.dart';
import '../../../shared/widgets/section_header.dart';

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
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ── Banner ──────────────────────────────────────────────────────
          ref.watch(bannerProvider).when(
            data: (items) => BannerSection(items: items),
            loading: () => const LoadingShimmer(height: 180),
            error: (e, _) =>
                AppErrorWidget(onRetry: () => ref.invalidate(bannerProvider)),
          ),

          const SizedBox(height: 20),

          // ── Quick Navigation ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _QuickNavCard(
                        context,
                        icon: Icons.trending_up,
                        label: '排行榜',
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                        ),
                        onTap: () => context.push('/ranking'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickNavCard(
                        context,
                        icon: Icons.radio,
                        label: '电台',
                        gradient: LinearGradient(
                          colors: [Color(0xFF4E9FFF), Color(0xFF6BB6FF)],
                        ),
                        onTap: () => context.push('/radio'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickNavCard(
                        context,
                        icon: Icons.person,
                        label: '歌手',
                        gradient: LinearGradient(
                          colors: [Color(0xFF9B7EFF), Color(0xFFB89FFF)],
                        ),
                        onTap: () => context.push('/singer-list'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickNavCard(
                        context,
                        icon: Icons.video_library,
                        label: 'MV',
                        gradient: LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                        ),
                        onTap: () => context.push('/mv-list'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

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

// ── Quick Nav Card ──────────────────────────────────────────────────────────
Widget _QuickNavCard(
  BuildContext context, {
  required IconData icon,
  required String label,
  required Gradient gradient,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
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
        SectionHeader(
          title: title,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return SizedBox(
                width: 140,
                child: PlaylistCard(
                  imageUrl: item.coverUrl,
                  title: item.title,
                  creator: item.creatorNick,
                  onTap: () => context.push('/playlist/${item.id}'),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
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
        SectionHeader(
          title: title,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return SizedBox(
                width: 140,
                child: MediaCard(
                  imageUrl: item.coverUrl,
                  title: item.name,
                  subtitle: item.displayArtist,
                  onTap: () => context.push('/song/${item.mid}'),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
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
        SectionHeader(
          title: title,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return SizedBox(
                width: 140,
                child: AlbumCard(
                  imageUrl: item.coverUrl,
                  title: item.name,
                  artist: item.displayArtist,
                  onTap: () => context.push('/album/${item.mid}'),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
