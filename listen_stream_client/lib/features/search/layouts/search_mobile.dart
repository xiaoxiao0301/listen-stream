import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/cover_image.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../data/models/search_result.dart';
import '../provider.dart';

/// 搜索页面移动端布局
class SearchMobileLayout extends ConsumerStatefulWidget {
  const SearchMobileLayout({super.key});

  @override
  ConsumerState<SearchMobileLayout> createState() => _SearchMobileLayoutState();
}

class _SearchMobileLayoutState extends ConsumerState<SearchMobileLayout>
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

    return Column(
      children: [
        // 搜索框
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索歌曲、歌手、专辑',
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _performSearch(),
            onChanged: (_) => setState(() {}),
          ),
        ),

        // 内容区域
        Expanded(
          child: searchState.keyword.isEmpty
              ? _buildHotKeys()
              : Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: '歌曲'),
                        Tab(text: '歌手'),
                        Tab(text: '专辑'),
                        Tab(text: 'MV'),
                      ],
                    ),
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
    );
  }

  Widget _buildHotKeys() {
    final hotKeysAsync = ref.watch(searchHotKeysProvider);

    return hotKeysAsync.when(
      data: (hotKeys) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '热门搜索',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return ListTile(
              leading: CoverImage(
                imageUrl: song.coverUrl,
                width: 48,
                height: 48,
                borderRadius: 4,
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
              trailing: Text(song.durationText),
              onTap: () {
                // TODO: Play song
              },
            );
          },
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
        return ListView.builder(
          itemCount: singers.length,
          itemBuilder: (context, index) {
            final singer = singers[index];
            return ListTile(
              leading: AvatarImage(
                imageUrl: singer.avatarUrl,
                size: 48,
              ),
              title: Text(
                singer.singerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('${singer.songCount} 首歌曲 · ${singer.albumCount} 张专辑'),
              onTap: () {
                context.push('/singer/${singer.singerMid}');
              },
            );
          },
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
        return ListView.builder(
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return ListTile(
              leading: CoverImage(
                imageUrl: album.coverUrl,
                width: 48,
                height: 48,
                borderRadius: 4,
              ),
              title: Text(
                album.albumName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                album.singerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing:
                  album.publishTime != null ? Text(album.publishTime!) : null,
              onTap: () {
                context.push('/album/${album.albumMid}');
              },
            );
          },
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
        return ListView.builder(
          itemCount: mvs.length,
          itemBuilder: (context, index) {
            final mv = mvs[index];
            return ListTile(
              leading: CoverImage(
                imageUrl: mv.coverUrl,
                width: 72,
                height: 48,
                borderRadius: 4,
              ),
              title: Text(
                mv.mvName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                mv.singerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(mv.durationText),
              onTap: () {
                // TODO: Play MV
              },
            );
          },
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
