import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/search_result.dart';
import 'provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> with SingleTickerProviderStateMixin {
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
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索歌曲、歌手、专辑',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _performSearch,
            ),
          ),
          onSubmitted: (_) => _performSearch(),
        ),
      ),
      body: Column(
        children: [
          if (searchState.keyword.isEmpty) 
            _buildHotKeys()
          else
            Expanded(
              child: Column(
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
      ),
    );
  }

  Widget _buildHotKeys() {
    final hotKeysAsync = ref.watch(searchHotKeysProvider);
    
    return Expanded(
      child: hotKeysAsync.when(
        data: (hotKeys) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('热门搜索', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        error: (err, stack) => Center(child: Text('加载失败: $err')),
      ),
    );
  }

  Widget _buildSongsTab(String keyword) {
    final songsAsync = ref.watch(searchSongsProvider((keyword: keyword, page: 1)));
    
    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(child: Text('暂无结果'));
        }
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  song.coverUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[300],
                    child: const Icon(Icons.music_note),
                  ),
                ),
              ),
              title: Text(song.songName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${song.singerName} · ${song.albumName}', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(song.durationText),
              onTap: () {
                // TODO: Play song
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('搜索失败: $err')),
    );
  }

  Widget _buildSingersTab(String keyword) {
    final singersAsync = ref.watch(searchSingersProvider((keyword: keyword, page: 1)));
    
    return singersAsync.when(
      data: (singers) {
        if (singers.isEmpty) {
          return const Center(child: Text('暂无结果'));
        }
        return ListView.builder(
          itemCount: singers.length,
          itemBuilder: (context, index) {
            final singer = singers[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  singer.avatarUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[300],
                    child: const Icon(Icons.person),
                  ),
                ),
              ),
              title: Text(singer.singerName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${singer.songCount} 首歌曲 · ${singer.albumCount} 张专辑'),
              onTap: () {
                context.push('/singer/${singer.singerMid}');
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('搜索失败: $err')),
    );
  }

  Widget _buildAlbumsTab(String keyword) {
    final albumsAsync = ref.watch(searchAlbumsProvider((keyword: keyword, page: 1)));
    
    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) {
          return const Center(child: Text('暂无结果'));
        }
        return ListView.builder(
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  album.coverUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[300],
                    child: const Icon(Icons.album),
                  ),
                ),
              ),
              title: Text(album.albumName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(album.singerName, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: album.publishTime != null ? Text(album.publishTime!) : null,
              onTap: () {
                context.push('/album/${album.albumMid}');
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('搜索失败: $err')),
    );
  }

  Widget _buildMVsTab(String keyword) {
    final mvsAsync = ref.watch(searchMVsProvider((keyword: keyword, page: 1)));
    
    return mvsAsync.when(
      data: (mvs) {
        if (mvs.isEmpty) {
          return const Center(child: Text('暂无结果'));
        }
        return ListView.builder(
          itemCount: mvs.length,
          itemBuilder: (context, index) {
            final mv = mvs[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  mv.coverUrl,
                  width: 72,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 48,
                    color: Colors.grey[300],
                    child: const Icon(Icons.videocam),
                  ),
                ),
              ),
              title: Text(mv.mvName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(mv.singerName, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(mv.durationText),
              onTap: () {
                // TODO: Play MV
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('搜索失败: $err')),
    );
  }
}
