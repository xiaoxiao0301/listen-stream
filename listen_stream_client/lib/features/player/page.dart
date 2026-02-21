import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/player/playback_service.dart';

class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(playbackServiceProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<PlaybackEvent>(
        stream: svc.handler.player.playbackEventStream,
        builder: (context, snap) {
          final item = svc.handler.mediaItem.value;
          final playing = svc.handler.player.playing;
          final position = svc.handler.player.position;
          final duration = svc.handler.player.duration ?? Duration.zero;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cover art
              if (item?.artUri != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(item!.artUri.toString(), width: 280, height: 280, fit: BoxFit.cover),
                )
              else
                const Icon(Icons.music_note, size: 120, color: Colors.white54),

              const SizedBox(height: 32),
              Text(item?.title ?? '未在播放', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(item?.artist ?? '', style: const TextStyle(color: Colors.white54, fontSize: 15)),

              const SizedBox(height: 20),
              // Progress
              Slider(
                value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                max: duration.inSeconds.toDouble().clamp(1, double.infinity),
                onChanged: (v) => svc.handler.player.seek(Duration(seconds: v.toInt())),
                activeColor: Colors.white,
                inactiveColor: Colors.white30,
              ),

              const SizedBox(height: 8),
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                      onPressed: svc.playPrevious),
                  IconButton(
                    icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: Colors.white, size: 64),
                    onPressed: () => playing ? svc.handler.pause() : svc.handler.play(),
                  ),
                  IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                      onPressed: svc.playNext),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
