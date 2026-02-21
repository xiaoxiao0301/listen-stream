import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/player/playback_service.dart';

/// Global D-pad / media key handler for TV (C.8).
///
/// Wrap the root of your TV widget tree with this widget.
class TvKeyHandler extends ConsumerWidget {
  const TvKeyHandler({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        final player = ref.read(playbackServiceProvider);
        final key = event.logicalKey;

        if (key == LogicalKeyboardKey.mediaPlayPause) {
          final p = player.handler.player;
          p.playing ? p.pause() : p.play();
        } else if (key == LogicalKeyboardKey.mediaTrackNext) {
          player.playNext();
        } else if (key == LogicalKeyboardKey.mediaTrackPrevious) {
          player.playPrevious();
        } else if (key == LogicalKeyboardKey.escape ||
                   key == LogicalKeyboardKey.goBack) {
          Navigator.of(context, rootNavigator: false).maybePop();
        }
      },
      child: child,
    );
  }
}
