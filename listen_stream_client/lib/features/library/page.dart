import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/api_service.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/app_error_widget.dart';

final favoritesPageProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, page) {
  return ref.read(apiServiceProvider).getFavorites(page: page);
});

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的'),
          bottom: const TabBar(tabs: [Tab(text: '收藏'), Tab(text: '历史')]),
        ),
        body: const TabBarView(
          children: [_FavoritesTab(), _HistoryTab()],
        ),
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoritesPageProvider(1));
    return async.when(
      loading: () => const LoadingShimmer(height: 400),
      error: (e, _) => AppErrorWidget(onRetry: () => ref.invalidate(favoritesPageProvider(1))),
      data: (data) {
        final items = (data['data'] as List? ?? []).cast<Map<String, dynamic>>();
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            final type = item['type'] as String? ?? '';
            final targetId = item['targetId'] as String? ?? '';
            return ListTile(
              leading: _typeIcon(type),
              title: Text('$type • $targetId'),
            );
          },
        );
      },
    );
  }

  Widget _typeIcon(String type) {
    return Icon(switch (type) {
      'song'   => Icons.music_note,
      'album'  => Icons.album,
      'singer' => Icons.person,
      _        => Icons.star,
    });
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('最近播放（接入播放器历史）'));
  }
}
