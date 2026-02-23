import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/player/playback_service.dart';

/// Helper function to play a song with error handling and user feedback.
/// Shows a SnackBar if playback fails due to permission issues.
Future<void> playSongWithErrorHandling(
  BuildContext context,
  WidgetRef ref,
  Song song,
) async {
  final svc = ref.read(playbackServiceProvider);
  
  try {
    await svc.playSong(song);
    
    // Optional: Show success feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('正在播放: ${song.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } on PlaybackException catch (e) {
    // Playback permission error
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange[700],
        ),
      );
    }
  } catch (e) {
    // Other errors (network, parsing, etc.)
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('播放失败: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }
}
