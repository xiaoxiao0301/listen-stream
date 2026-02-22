import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/tokens.dart';
import 'cover_image.dart';
import '../../core/player/playback_service.dart';

class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(playbackServiceProvider);

    return FutureBuilder<void>(
      future: svc.ready,
      builder: (context, readySnap) {
        // Not ready: show disabled placeholder bar
        if (readySnap.connectionState != ConnectionState.done) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: DesignTokens.cardShadow),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CoverImage(imageUrl: '', width: 48, height: 48, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text('—', style: DesignTokens.body(context).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('', style: DesignTokens.caption(context)),
                  ]),
                ),
                IconButton(onPressed: null, icon: const Icon(Icons.skip_previous)),
                GestureDetector(
                  onTap: null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Theme.of(context).disabledColor, borderRadius: BorderRadius.circular(16), boxShadow: DesignTokens.cardShadow),
                    child: const Icon(Icons.play_arrow, color: Colors.white),
                  ),
                ),
                IconButton(onPressed: null, icon: const Icon(Icons.skip_next)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 200,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Slider(value: 0, onChanged: null, min: 0, max: 1),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(onPressed: null, icon: const Icon(Icons.queue_music)),
              ],
            ),
          );
        }

        // Ready: safe to access handler/player
        return StreamBuilder(
          stream: svc.handler.player.playbackEventStream,
          builder: (context, snap) {
            final item = svc.handler.mediaItem.value;
            final playing = svc.handler.player.playing;
            final position = svc.handler.player.position;
            final duration = svc.handler.player.duration ?? Duration.zero;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: DesignTokens.cardShadow),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CoverImage(
                      imageUrl: item?.artUri?.toString() ?? '',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(item?.title ?? '—', style: DesignTokens.body(context).copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(item?.artist ?? '—', style: DesignTokens.caption(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  IconButton(onPressed: svc.playPrevious, icon: const Icon(Icons.skip_previous)),
                  _PlayButton(playing: playing, onToggle: () => playing ? svc.handler.pause() : svc.handler.play()),
                  IconButton(onPressed: svc.playNext, icon: const Icon(Icons.skip_next)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 200,
                    child: Material(
                      type: MaterialType.transparency,
                      child: _Progress(position: position, duration: duration, onSeek: (v) => svc.handler.player.seek(Duration(milliseconds: v.toInt()))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.queue_music)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool playing;
  final VoidCallback onToggle;
  const _PlayButton({required this.playing, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(16), boxShadow: DesignTokens.cardShadow),
        child: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final void Function(double milliseconds) onSeek;
  const _Progress({required this.position, required this.duration, required this.onSeek});

  @override
  Widget build(BuildContext context) {
    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final value = position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
      child: Slider(value: value, onChanged: (v) => onSeek(v), min: 0, max: maxMs),
    );
  }
}
