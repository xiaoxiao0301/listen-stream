import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/media_card.dart';
import '../../../shared/widgets/responsive_grid_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../data/models/models.dart';
import '../../../core/responsive/responsive.dart' hide ResponsiveGridView;
import '../provider.dart';
import '../widgets/banner_section.dart';
import '../widgets/nav_item.dart';

/// 首页桌面端布局 - 多列网格布局
class HomeDesktopLayout extends ConsumerWidget {
  const HomeDesktopLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gridSpacing = ResponsiveSpacing.gridSpacing(context);

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
          padding: const EdgeInsets.only(top: 24, bottom: 32),
          children: [
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
            const SectionHeader(
              title: '推荐歌单',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            ref.watch(recommendPlaylistProvider).when(
              data: (items) => ResponsiveGridView(
                itemCount: items.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                childAspectRatio: 0.78,
                mobileColumns: 2,
                tabletColumns: 3,
                desktopColumns: ResponsiveGrid.playlistColumns(context),
                tvColumns: 6,
                itemBuilder: (_, index) {
                  final item = items[index];
                  return PlaylistCard(
                    imageUrl: item.coverUrl,
                    title: item.title,
                    creator: item.creatorNick,
                    onTap: () => context.push('/playlist/${item.id}'),
                  );
                },
              ),
              loading: () => const LoadingShimmer(height: 280),
              error: (e, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 32),

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

                SizedBox(width: gridSpacing),

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
          ],
        ),
      ),
    );
  }
}

// ── Quick Navigation Grid ───────────────────────────────────────────────────
Widget _QuickNavGrid(BuildContext context) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
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
        SectionHeader(
          title: title,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final item = items[i];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        SectionHeader(
          title: title,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final item = items[i];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
