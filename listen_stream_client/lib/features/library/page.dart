import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../data/remote/api_service.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/app_error_widget.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/cover_image.dart';

final favoritesPageProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, page) {
  return ref.read(apiServiceProvider).getFavorites(page: page);
});

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveBuilderWithInfo(
      builder: (context, deviceType, constraints) {
        final isMobile = deviceType == DeviceType.mobile ||
            deviceType == DeviceType.tablet;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('我的'),
              centerTitle: false,
              bottom: TabBar(
                isScrollable: !isMobile,
                tabs: const [
                  Tab(text: '收藏'),
                  Tab(text: '历史'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _FavoritesTab(isMobile: isMobile),
                _HistoryTab(isMobile: isMobile),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoritesPageProvider(1));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(
        onRetry: () => ref.invalidate(favoritesPageProvider(1)),
      ),
      data: (data) {
        final items =
            (data['data'] as List? ?? []).cast<Map<String, dynamic>>();

        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.favorite_border,
            title: '暂无收藏',
            message: '收藏的内容会显示在这里',
          );
        }

        return AdaptiveContainer(
          maxWidthDesktop: 1280,
          maxWidthTv: 1600,
          padding: isMobile ? EdgeInsets.zero : null,
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final type = item['type'] as String? ?? '';
              final targetId = item['targetId'] as String? ?? '';
              final title = item['title'] as String? ?? '$type • $targetId';
              final coverUrl = item['coverUrl'] as String? ?? '';

              return ListTile(
                leading: coverUrl.isNotEmpty
                    ? CoverImage(
                        imageUrl: coverUrl,
                        width: 48,
                        height: 48,
                        borderRadius: type == 'singer' ? 24 : 4,
                        shape: type == 'singer'
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                      )
                    : _typeIcon(type, isMobile),
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_typeLabel(type)),
                trailing: !isMobile
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_circle_outline),
                            onPressed: () => _navigateToItem(context, type, targetId),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite),
                            color: Colors.red,
                            onPressed: () {
                              // TODO: 取消收藏
                            },
                          ),
                        ],
                      )
                    : null,
                onTap: () => _navigateToItem(context, type, targetId),
              );
            },
          ),
        );
      },
    );
  }

  Widget _typeIcon(String type, bool isMobile) {
    final iconSize = isMobile ? 24.0 : 32.0;
    return Icon(
      switch (type) {
        'song' => Icons.music_note,
        'album' => Icons.album,
        'singer' => Icons.person,
        'playlist' => Icons.playlist_play,
        _ => Icons.star,
      },
      size: iconSize,
    );
  }

  String _typeLabel(String type) {
    return switch (type) {
      'song' => '歌曲',
      'album' => '专辑',
      'singer' => '歌手',
      'playlist' => '歌单',
      _ => '收藏',
    };
  }

  void _navigateToItem(BuildContext context, String type, String targetId) {
    if (targetId.isEmpty) return;

    switch (type) {
      case 'song':
        context.push('/song/$targetId');
        break;
      case 'album':
        context.push('/album/$targetId');
        break;
      case 'singer':
        context.push('/singer/$targetId');
        break;
      case 'playlist':
        context.push('/playlist/$targetId');
        break;
    }
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return AdaptiveContainer(
      maxWidthDesktop: 1280,
      maxWidthTv: 1600,
      child: const EmptyState(
        icon: Icons.history,
        title: '最近播放',
        message: '播放历史功能开发中',
      ),
    );
  }
}
