import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 歌曲详情页 - 提供播放和收藏功能
class SongDetailPage extends ConsumerWidget {
  const SongDetailPage({super.key, required this.songMid});

  final String songMid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: 实现歌曲详情数据加载
    final coverUrl = 'https://y.gtimg.cn/music/photo_new/T002R300x300M000$songMid.jpg';

    return Scaffold(
      appBar: AppBar(
        title: const Text('歌曲详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 专辑封面
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                coverUrl,
                width: 250,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 250,
                  height: 250,
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.music_note, size: 80),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // 歌曲信息 - TODO: 从API获取
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    '歌曲名称',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '歌手名称',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 收藏按钮
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: 实现收藏功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('收藏功能开发中')),
                    );
                  },
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('收藏'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 48),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 播放按钮
                FilledButton.icon(
                  onPressed: () {
                    // TODO: 实现播放功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('播放功能开发中')),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('播放'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(120, 48),
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
