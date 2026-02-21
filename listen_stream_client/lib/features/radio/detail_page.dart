import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'provider.dart';

class RadioDetailPage extends ConsumerWidget {
  const RadioDetailPage({super.key, required this.radioId});

  final String radioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioAsync = ref.watch(radioSongsProvider(radioId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('电台'),
      ),
      body: radioAsync.when(
        data: (radio) {
          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.radio,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            radio.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${radio.tracks.length} 首歌曲',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Play all
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('播放全部'),
                    ),
                  ],
                ),
              ),
              // Song list
              Expanded(
                child: ListView.builder(
                  itemCount: radio.tracks.length,
                  itemBuilder: (context, index) {
                    final song = radio.tracks[index];
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
                      title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('加载失败: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(radioSongsProvider(radioId)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
