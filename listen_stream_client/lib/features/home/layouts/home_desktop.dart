import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../data/models/models.dart';
import '../../../core/responsive/responsive.dart';
import '../provider.dart';
import '../widgets/banner_section.dart';
import '../widgets/nav_item.dart';
import '../widgets/card_item.dart';

/// 首页桌面端布局 - 多列网格布局
class HomeDesktopLayout extends ConsumerWidget {
  const HomeDesktopLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(bannerProvider);
        ref.invalidate(recommendPlaylistProvider);
        ref.invalidate(recommendNewSongsProvider);
        ref.invalidate(recommendNewAlbumsProvider);
      },
      child: AdaptiveContainer(
        maxWidthDesktop: 1280,
        maxWidthTv: 1600,
        padding: ResponsiveSpacing.horizontalPadding(context),
        child: ListView(
          children: [
            const SizedBox(height: 24),

            // ── Banner + Quick Navigation (Side by Side) ─────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner (左侧，占据 2/3 宽度)
                Expanded(
                  flex: 2,
                  child: ref.watch(bannerProvider).when(
                    data: (items) => BannerSection(items: items),
                    loading: () => const LoadingShimmer(height: 240),
                    error: (e, _) => AppErrorWidget(
                      onRetry: () => ref.invalidate(bannerProvider),
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // Quick Navigation (右侧，占据 1/3 宽度)
                Expanded(
                  flex: 1,
                  child: _QuickNavGrid(context),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Recommend Playlist (Grid) ─────────────────────────────────
            ref.watch(recommendPlaylistProvider).when(
              data: (items) => _PlaylistGridSection(
                title: '推荐歌单',
                items: items,
              ),
              loading: () => const LoadingShimmer(height: 280),
              error: (e, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // ── New Songs + New Albums (Side by Side) ─────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // New Songs (左侧)
                Expanded(
                  child: ref.watch(recommendNewSongsProvider).when(
                    data: (items) => _SongGridSection(
                      title: '新歌首发',
                      items: items.take(6).toList(),
                    ),
                    loading: () => const LoadingShimmer(height: 280),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                ),

                const SizedBox(width: 24),

                // New Albums (右侧)
                Expanded(
                  child: ref.watch(recommendNewAlbumsProvider).when(
                    data: (items) => _AlbumGridSection(
                      title: '新碟上架',
                      items: items.take(6).toList(),
                    ),
                    loading: () => const LoadingShimmer(height: 280),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Quick Navigation Grid ───────────────────────────────────────────────────
Widget _QuickNavGrid(BuildContext context) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快速入口',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
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
        ],
      ),
    ),
  );
}

// ── Playlist Grid Section ───────────────────────────────────────────────────
class _PlaylistGridSection extends StatelessWidget {
  const _PlaylistGridSection({required this.title, required this.items});
  final String title;
  final List<PlaylistItem> items;

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveGrid.playlistColumns(context);
    final displayItems = items.take(columns * 2).toList(); // 显示2行

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: () {
                  // TODO: 跳转到更多页面
                },
                child: const Text('更多'),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: ResponsiveSpacing.gridSpacing(context),
            mainAxisSpacing: ResponsiveSpacing.gridSpacing(context),
            childAspectRatio: 0.8,
          ),
          itemCount: displayItems.length,
          itemBuilder: (_, i) {
            final item = displayItems[i];
            return CardItem(
              coverUrl: item.coverUrl,
              title: item.title,
              subtitle: item.creatorNick,
              width: double.infinity,
              imageSize: double.infinity,
              onTap: () => context.push('/playlist/${item.id}'),
            );
          },
        ),
      ],
    );
  }
}

// ── Song Grid Section ───────────────────────────────────────────────────────
class _SongGridSection extends StatelessWidget {
  const _SongGridSection({required this.title, required this.items});
  final String title;
  final List<SongItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final item = items[i];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    item.coverUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 48,
                      height: 48,
                      child: ColoredBox(color: Color(0xFFe0e0e0)),
                    ),
                  ),
                ),
                title: Text(item.name),
                subtitle: Text(item.displayArtist),
                trailing: IconButton(
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: () => context.push('/song/${item.mid}'),
                ),
                onTap: () => context.push('/song/${item.mid}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Album Grid Section ──────────────────────────────────────────────────────
class _AlbumGridSection extends StatelessWidget {
  const _AlbumGridSection({required this.title, required this.items});
  final String title;
  final List<AlbumItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final item = items[i];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    item.coverUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 48,
                      height: 48,
                      child: ColoredBox(color: Color(0xFFe0e0e0)),
                    ),
                  ),
                ),
                title: Text(item.name),
                subtitle: Text(item.displayArtist),
                trailing: IconButton(
                  icon: const Icon(Icons.album_outlined),
                  onPressed: () => context.push('/album/${item.mid}'),
                ),
                onTap: () => context.push('/album/${item.mid}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
