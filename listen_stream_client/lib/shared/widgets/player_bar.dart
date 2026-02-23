import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/theme.dart';
import '../design/tokens.dart';
import 'cover_image.dart';
import '../../core/player/playback_service.dart';

class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(playbackServiceProvider);
    final themeMode = ref.watch(themeProvider);
    final isGlass = themeMode == AppThemeMode.glass;

    return FutureBuilder<void>(
      future: svc.ready,
      builder: (context, readySnap) {
        // Not ready: show disabled placeholder bar
        if (readySnap.connectionState != ConnectionState.done) {
          return _buildPlayerBar(
            context,
            isGlass,
            coverUrl: '',
            title: '—',
            artist: '',
            playing: false,
            position: Duration.zero,
            duration: Duration.zero,
            onToggle: null,
            onPrevious: null,
            onNext: null,
            onSeek: null,
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

            return _buildPlayerBar(
              context,
              isGlass,
              coverUrl: item?.artUri?.toString() ?? '',
              title: item?.title ?? '—',
              artist: item?.artist ?? '—',
              playing: playing,
              position: position,
              duration: duration,
              onToggle: () => playing ? svc.handler.pause() : svc.handler.play(),
              onPrevious: svc.playPrevious,
              onNext: svc.playNext,
              onSeek: (v) => svc.handler.player.seek(Duration(milliseconds: v.toInt())),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerBar(
    BuildContext context,
    bool isGlass, {
    required String coverUrl,
    required String title,
    required String artist,
    required bool playing,
    required Duration position,
    required Duration duration,
    required VoidCallback? onToggle,
    required VoidCallback? onPrevious,
    required VoidCallback? onNext,
    required void Function(double)? onSeek,
  }) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: isGlass
            ? Colors.black.withOpacity(0.3)
            : Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: isGlass ? ImageFilter.blur(sigmaX: 30, sigmaY: 30) : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                // Album art
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CoverImage(
                      imageUrl: coverUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Song info
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 24),
                
                // Playback controls (center)
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ControlButton(
                            icon: Icons.skip_previous_rounded,
                            onPressed: onPrevious,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          _PlayButton(
                            playing: playing,
                            onToggle: onToggle,
                          ),
                          const SizedBox(width: 16),
                          _ControlButton(
                            icon: Icons.skip_next_rounded,
                            onPressed: onNext,
                            size: 32,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ProgressBar(
                        position: position,
                        duration: duration,
                        onSeek: onSeek,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 24),
                
                // Right controls
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ControlButton(
                        icon: Icons.favorite_border_rounded,
                        onPressed: () {},
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      _ControlButton(
                        icon: Icons.queue_music_rounded,
                        onPressed: () {},
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      _VolumeControl(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool playing;
  final VoidCallback? onToggle;
  const _PlayButton({required this.playing, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onToggle != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  
  const _ControlButton({
    required this.icon,
    this.onPressed,
    this.size = 24,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.onPressed != null
                ? (_isHovered
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyMedium?.color)
                : Theme.of(context).disabledColor,
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final void Function(double)? onSeek;
  
  const _ProgressBar({
    required this.position,
    required this.duration,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final value = position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();
    
    return Row(
      children: [
        Text(
          _formatDuration(position),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              thumbColor: Theme.of(context).primaryColor,
              overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              onChanged: onSeek != null ? (v) => onSeek!(v) : null,
              min: 0,
              max: maxMs,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _formatDuration(duration),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  String _formatDuration(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}

class _VolumeControl extends StatefulWidget {
  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  double _volume = 0.7;
  bool _showSlider = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _showSlider = true),
      onExit: (_) => setState(() => _showSlider = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _showSlider ? 80 : 0,
            child: _showSlider
                ? SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: _volume,
                      onChanged: (v) => setState(() => _volume = v),
                      min: 0,
                      max: 1,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          _ControlButton(
            icon: _volume > 0.5
                ? Icons.volume_up_rounded
                : _volume > 0
                    ? Icons.volume_down_rounded
                    : Icons.volume_off_rounded,
            onPressed: () {},
            size: 24,
          ),
        ],
      ),
    );
  }
}
