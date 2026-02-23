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
            // ── Banner (Full Width) ───────────────────────────────────────
            ref.watch(bannerProvider).when(
              data: (items) => BannerSection(items: items),
              loading: () => const LoadingShimmer(height: 280),
              error: (e, _) => AppErrorWidget(
                onRetry: () => ref.invalidate(bannerProvider),
              ),
            ),

            const SizedBox(height: 32),

            // ── Quick Navigation ──────────────────────────────────────────
            _QuickNavRow(context),

            const SizedBox(height: 40),

            // ── Featured Content (3 Column) ───────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recommend Playlists
                Expanded(
                  child: ref.watch(recommendPlaylistProvider).when(
                    data: (items) => _PlaylistGridSection(
                      title: '推荐歌单',
                      items: items.take(6).toList(),
                    ),
                    loading: () => const LoadingShimmer(height: 320),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                ),
                
                SizedBox(width: gridSpacing),
                
                // New Songs
                Expanded(
                  child: ref.watch(recommendNewSongsProvider).when(
                    data: (items) => _SongGridSection(
                      title: '新歌首发',
                      items: items.take(6).toList(),
                    ),
                    loading: () => const LoadingShimmer(height: 320),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                ),
                
                SizedBox(width: gridSpacing),
                
                // New Albums
                Expanded(
                  child: ref.watch(recommendNewAlbumsProvider).when(
                    data: (items) => _AlbumGridSection(
                      title: '新碟上架',
                      items: items.take(6).toList(),
                    ),
                    loading: () => const LoadingShimmer(height: 320),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ── More Playlists (Grid View) ────────────────────────────────
            const SectionHeader(
              title: '更多推荐歌单',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            ref.watch(recommendPlaylistProvider).when(
              data: (items) => items.length <= 6 ? const SizedBox.shrink() : ResponsiveGridView(
                itemCount: items.length > 6 ? items.skip(6).length : 0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                childAspectRatio: 0.78,
                mobileColumns: 2,
                tabletColumns: 3,
                desktopColumns: ResponsiveGrid.playlistColumns(context),
                tvColumns: 6,
                itemBuilder: (_, index) {
                  final item = items[index + 6];
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
          ],
        ),
      ),
    );
  }
}

// ── Quick Navigation Row ────────────────────────────────────────────────────
Widget _QuickNavRow(BuildContext context) {
  return Row(
    children: [
      Expanded(
        child: _QuickNavCard(
          context,
          icon: Icons.trending_up,
          label: '排行榜',
          description: '热门音乐排行',
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
          ),
          onTap: () => context.push('/ranking'),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _QuickNavCard(
          context,
          icon: Icons.radio,
          label: '电台',
          description: '精选电台节目',
          gradient: LinearGradient(
            colors: [Color(0xFF4E9FFF), Color(0xFF6BB6FF)],
          ),
          onTap: () => context.push('/radio'),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _QuickNavCard(
          context,
          icon: Icons.person,
          label: '歌手',
          description: '发现优秀歌手',
          gradient: LinearGradient(
            colors: [Color(0xFF9B7EFF), Color(0xFFB89FFF)],
          ),
          onTap: () => context.push('/singer-list'),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _QuickNavCard(
          context,
          icon: Icons.video_library,
          label: 'MV',
          description: '精彩视频推荐',
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          ),
          onTap: () => context.push('/mv-list'),
        ),
      ),
    ],
  );
}

Widget _QuickNavCard(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String description,
  required Gradient gradient,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            return PlaylistCard(
              imageUrl: item.coverUrl,
              title: item.title,
              creator: item.creatorNick,
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
                title: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item.displayArtist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
                title: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item.displayArtist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
