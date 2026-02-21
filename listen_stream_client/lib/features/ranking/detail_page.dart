import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ranking.dart';
import 'provider.dart';

class RankingDetailPage extends ConsumerWidget {
  const RankingDetailPage({super.key, required this.topId});

  final String topId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingDetailProvider((topId: int.parse(topId), page: 1)));

    return Scaffold(
      body: rankingAsync.when(
        data: (ranking) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(ranking.title),
                background: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade700,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (ranking.period != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Text(
                            ranking.period!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '${ranking.listenNumText} 播放',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = ranking.songs[index];
                  return _buildSongTile(song);
                },
                childCount: ranking.songs.length,
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('加载失败: $err'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(rankingDetailProvider),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongTile(RankingSong song) {
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              song.rank.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: song.rank <= 3 ? FontWeight.bold : FontWeight.normal,
                color: song.rank <= 3 ? Colors.red : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (song.rankIcon != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                song.rankIcon!,
                style: TextStyle(
                  fontSize: 12,
                  color: song.rankType == 6
                      ? Colors.red
                      : song.rankType == 1
                          ? Colors.green
                          : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.singerName, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (song.rankValue != null)
            Text(
              song.rankValue!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(width: 8),
          if (song.mvid > 0)
            Icon(Icons.videocam, size: 16, color: Colors.grey[600]),
        ],
      ),
      onTap: () {
        // TODO: Play song
      },
    );
  }
}
