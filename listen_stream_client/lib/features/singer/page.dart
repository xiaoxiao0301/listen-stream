import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/app_error_widget.dart';
import 'provider.dart';

class SingerDetailPage extends ConsumerWidget {
  const SingerDetailPage({super.key, required this.mid});
  final String mid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(singerDetailFamily(mid));
    return detailAsync.when(
      loading: () => const Scaffold(body: LoadingShimmer(height: double.infinity)),
      error: (e, _) => Scaffold(body: AppErrorWidget(onRetry: () => ref.invalidate(singerDetailFamily(mid)))),
      data: (detail) => _SingerDetail(mid: mid, detail: detail),
    );
  }
}

class _SingerDetail extends ConsumerStatefulWidget {
  const _SingerDetail({required this.mid, required this.detail});
  final String mid;
  final Map<String, dynamic> detail;
  @override
  ConsumerState<_SingerDetail> createState() => _SingerDetailState();
}

class _SingerDetailState extends ConsumerState<_SingerDetail> {
  // Track which tabs have been loaded (lazy init via IndexedStack).
  final _tabsLoaded = [false, false]; // [songs, albums]

  @override
  void initState() {
    super.initState();
    _tabsLoaded[0] = true; // Songs tab loaded immediately.
  }

  @override
  Widget build(BuildContext context) {
    final singer = widget.detail['singer'] as Map<String, dynamic>? ?? {};
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              expandedHeight: 240,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(singer['name'] as String? ?? ''),
                background: singer['pic'] != null
                    ? Image.network(singer['pic'] as String, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1a1a2e)))
                    : null,
              ),
              bottom: TabBar(
                onTap: (i) {
                  if (!_tabsLoaded[i]) setState(() => _tabsLoaded[i] = true);
                },
                tabs: const [Tab(text: '歌曲'), Tab(text: '专辑')],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              // IndexedStack gives lazy tab loading
              _tabsLoaded[0]
                  ? _SongsList(mid: widget.mid)
                  : const SizedBox.shrink(),
              _tabsLoaded[1]
                  ? _AlbumsList(mid: widget.mid)
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongsList extends ConsumerWidget {
  const _SongsList({required this.mid});
  final String mid;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(singerSongsFamily(mid)).when(
      loading: () => const LoadingShimmer(height: 400),
      error: (e, _) => AppErrorWidget(onRetry: () => ref.invalidate(singerSongsFamily(mid))),
      data: (data) {
        final songs = (data['list'] as List? ?? []).cast<Map<String, dynamic>>();
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (_, i) {
            final s = songs[i];
            return ListTile(
              leading: Text('${i + 1}', style: const TextStyle(color: Colors.grey)),
              title: Text(s['name'] as String? ?? ''),
              subtitle: Text(s['singer']?.toString() ?? ''),
            );
          },
        );
      },
    );
  }
}

class _AlbumsList extends ConsumerWidget {
  const _AlbumsList({required this.mid});
  final String mid;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(singerAlbumsFamily(mid)).when(
      loading: () => const LoadingShimmer(height: 400),
      error: (e, _) => AppErrorWidget(onRetry: () => ref.invalidate(singerAlbumsFamily(mid))),
      data: (data) {
        final albums = (data['list'] as List? ?? []).cast<Map<String, dynamic>>();
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.2),
          itemCount: albums.length,
          itemBuilder: (_, i) {
            final a = albums[i];
            return Card(child: Column(children: [
              Expanded(child: Image.network(a['picUrl'] as String? ?? '', fit: BoxFit.cover)),
              Padding(padding: const EdgeInsets.all(4), child: Text(a['name'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]));
          },
        );
      },
    );
  }
}
