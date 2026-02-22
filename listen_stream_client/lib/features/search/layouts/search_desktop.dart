import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive.dart' hide ResponsiveGridView;
import '../../../shared/widgets/cover_image.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/media_card.dart';
import '../../../shared/widgets/responsive_grid_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../data/models/search_result.dart';
import '../provider.dart';

/// 搜索页面桌面端布局
class SearchDesktopLayout extends ConsumerStatefulWidget {
  const SearchDesktopLayout({super.key});

  @override
  ConsumerState<SearchDesktopLayout> createState() =>
      _SearchDesktopLayoutState();
}

class _SearchDesktopLayoutState extends ConsumerState<SearchDesktopLayout>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(searchStateProvider.notifier).setTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;
    ref.read(searchStateProvider.notifier).setKeyword(keyword);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchStateProvider);

    return AdaptiveContainer(
      maxWidthDesktop: 1280,
      maxWidthTv: 1600,
      padding: ResponsiveSpacing.horizontalPadding(context),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // 搜索框
          SizedBox(
            width: 600,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索歌曲、歌手、专辑、MV',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchStateProvider.notifier).setKeyword('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(height: 24),

          // 内容区域
          Expanded(
            child: searchState.keyword.isEmpty
                ? _buildHotKeys()
                : Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabs: const [
                          Tab(text: '歌曲'),
                          Tab(text: '歌手'),
                          Tab(text: '专辑'),
                          Tab(text: 'MV'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildSongsTab(searchState.keyword),
                            _buildSingersTab(searchState.keyword),
                            _buildAlbumsTab(searchState.keyword),
                            _buildMVsTab(searchState.keyword),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotKeys() {
    final hotKeysAsync = ref.watch(searchHotKeysProvider);

    return hotKeysAsync.when(
      data: (hotKeys) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
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
                    const SectionHeader(
                      title: '热门搜索',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: hotKeys.map((hotKey) {
                        return ActionChip(
                          label: Text(hotKey.keyword),
                          onPressed: () {
                            _searchController.text = hotKey.keyword;
                            _performSearch();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => EmptyState(
        icon: Icons.error_outline,
        title: '加载失败',
        message: err.toString(),
      ),
    );
  }

  Widget _buildSongsTab(String keyword) {
    final songsAsync =
        ref.watch(searchSongsProvider((keyword: keyword, page: 1)));

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return EmptySearchResult(keyword: keyword);
        }
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: '歌曲',
                padding: EdgeInsets.zero,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Card(
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
                  itemCount: songs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CoverImage(
                        imageUrl: song.coverUrl,
                        width: 48,
                        height: 48,
                        borderRadius: 6,
                      ),
                      title: Text(
                        song.songName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${song.singerName} · ${song.albumName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(song.durationText),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.play_circle_outline),
                            onPressed: () {
                              // TODO: Play song
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        // TODO: Play song
                      },
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => EmptyState(
        icon: Icons.error_outline,
        title: '搜索失败',
        message: err.toString(),
      ),
    );
  }

  Widget _buildSingersTab(String keyword) {
    final singersAsync =
        ref.watch(searchSingersProvider((keyword: keyword, page: 1)));

    return singersAsync.when(
      data: (singers) {
        if (singers.isEmpty) {
          return EmptySearchResult(keyword: keyword);
        }
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: '歌手',
                padding: EdgeInsets.zero,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 16),
              sliver: SliverResponsiveGridView(
                itemCount: singers.length,
                childAspectRatio: 0.9,
                mobileColumns: 2,
                tabletColumns: 3,
                desktopColumns: 5,
                tvColumns: 7,
                itemBuilder: (context, index) {
                  final singer = singers[index];
                  return ArtistCard(
                    imageUrl: singer.avatarUrl,
                    name: singer.singerName,
                    description: '${singer.songCount} 首歌曲',
                    onTap: () {
                      context.push('/singer/${singer.singerMid}');
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => EmptyState(
        icon: Icons.error_outline,
        title: '搜索失败',
        message: err.toString(),
      ),
    );
  }

  Widget _buildAlbumsTab(String keyword) {
    final albumsAsync =
        ref.watch(searchAlbumsProvider((keyword: keyword, page: 1)));

    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) {
          return EmptySearchResult(keyword: keyword);
        }
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: '专辑',
                padding: EdgeInsets.zero,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 16),
              sliver: SliverResponsiveGridView(
                itemCount: albums.length,
                childAspectRatio: 0.86,
                mobileColumns: 2,
                tabletColumns: 3,
                desktopColumns: 4,
                tvColumns: 6,
                itemBuilder: (context, index) {
                  final album = albums[index];
                  return AlbumCard(
                    imageUrl: album.coverUrl,
                    title: album.albumName,
                    artist: album.singerName,
                    onTap: () {
                      context.push('/album/${album.albumMid}');
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => EmptyState(
        icon: Icons.error_outline,
        title: '搜索失败',
        message: err.toString(),
      ),
    );
  }

  Widget _buildMVsTab(String keyword) {
    final mvsAsync = ref.watch(searchMVsProvider((keyword: keyword, page: 1)));

    return mvsAsync.when(
      data: (mvs) {
        if (mvs.isEmpty) {
          return EmptySearchResult(keyword: keyword);
        }
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'MV',
                padding: EdgeInsets.zero,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 16),
              sliver: SliverResponsiveGridView(
                itemCount: mvs.length,
                childAspectRatio: 1.3,
                mobileColumns: 1,
                tabletColumns: 2,
                desktopColumns: 3,
                tvColumns: 4,
                itemBuilder: (context, index) {
                  final mv = mvs[index];
                  return MvCard(
                    imageUrl: mv.coverUrl,
                    title: mv.mvName,
                    artist: mv.singerName,
                    onTap: () {
                      // TODO: Play MV
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => EmptyState(
        icon: Icons.error_outline,
        title: '搜索失败',
        message: err.toString(),
      ),
    );
  }
}
