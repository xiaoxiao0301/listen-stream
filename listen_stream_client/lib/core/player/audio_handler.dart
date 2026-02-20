import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// AudioHandler bridges just_audio with audio_service for system media controls.
///
/// This allows playback to be controlled from:
///   - iOS lock screen / Control Center
///   - Android notification media controls
///   - Desktop media keys
class ListenStreamAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  ListenStreamAudioHandler() {
    // Forward just_audio playback state to audio_service.
    _player.playbackEventStream.listen(_broadcastState);
  }

  final AudioPlayer player = AudioPlayer();

  Future<void> playMediaItem(MediaItem item) async {
    mediaItem.add(item);
    await player.setUrl(item.id);
    await player.play();
  }

  @override
  Future<void> play()  => player.play();
  @override
  Future<void> pause() => player.pause();
  @override
  Future<void> stop()  => player.stop();
  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext()     async { /* Delegate to PlaybackService */ }
  @override
  Future<void> skipToPrevious() async { /* Delegate to PlaybackService */ }

  void _broadcastState(PlaybackEvent event) {
    final isPlaying = player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        isPlaying ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _mapProcessingState(player.processingState),
      playing: isPlaying,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
    ));
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    return switch (state) {
      ProcessingState.idle     => AudioProcessingState.idle,
      ProcessingState.loading  => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready    => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };
  }
}
