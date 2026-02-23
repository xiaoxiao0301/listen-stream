import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/remote/api_service.dart';
import 'audio_handler.dart';

/// Exception thrown when song playback fails due to permission or availability issues.
class PlaybackException implements Exception {
  PlaybackException(this.message);
  final String message;

  @override
  String toString() => message;
}

final playbackServiceProvider = Provider<PlaybackService>((ref) {
  return PlaybackService(ref);
});

/// Immutable song model (populated from upstream JSON).
class Song {
  const Song({
    required this.mid,
    required this.name,
    required this.artist,
    required this.albumMid,
    this.albumName = '',
    this.coverUrl = '',
  });
  final String mid;
  final String name;
  final String artist;
  final String albumMid;
  final String albumName;
  final String coverUrl;

  MediaItem toMediaItem(String url) => MediaItem(
        id: url,
        title: name,
        artist: artist,
        album: albumName,
        artUri: coverUrl.isNotEmpty ? Uri.parse(coverUrl) : null,
      );
}

enum PlayMode { sequence, shuffle, repeat }

/// Current player state snapshot.
class PlaybackState {
  const PlaybackState({
    this.status = PlayStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });
  final PlayStatus status;
  final Duration position;
  final Duration duration;
}

enum PlayStatus { idle, loading, playing, paused, error }

/// Core audio playback service (C.6).
///
/// - Wraps just_audio + audio_service for system media controls.
/// - Reports progress every 10 s via POST /user/progress.
/// - Supports cross-device resume via GET /user/progress.
class PlaybackService {
  PlaybackService(this._ref) {
    // Begin AudioService initialization immediately; operations that need
    // the handler await [_ready] before proceeding.
    _ready = _initHandler();
  }
  final Ref _ref;

  late Future<void> _ready;
  ListenStreamAudioHandler? _handler;
  AudioPlayer get _player => _handler!.player;

  /// Public access to the audio handler (available after first [playSong]).
  ListenStreamAudioHandler get handler => _handler!;

  Future<void> _initHandler() async {
    _handler = await AudioService.init(
      builder: () => ListenStreamAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.listenstream.audio',
        androidNotificationChannelName: 'Listen Stream',
        androidNotificationOngoing: true,
      ),
    );
  }

  /// Public future that completes when the internal audio handler is ready.
  Future<void> get ready => _ready;

  PlayQueue _queue = const PlayQueue(songs: [], currentIndex: 0);
  PlayMode _mode = PlayMode.sequence;

  Timer? _progressTimer;
  int _lastReportedSeconds = 0;

  PlayQueue get queue => _queue;
  Song? get currentSong =>
      _queue.songs.isEmpty ? null : _queue.songs[_queue.currentIndex];

  /// Initialize (kept for API compatibility; init now happens in constructor).
  static Future<PlaybackService> create(Ref ref) async {
    final svc = PlaybackService(ref);
    await svc._ready;
    return svc;
  }

  // ── Playback control ────────────────────────────────────────────────────────

  Future<void> playSong(Song song) async {
    final idx = _queue.songs.indexWhere((s) => s.mid == song.mid);
    if (idx < 0) {
      _queue = _queue.copyWith(
        songs: [..._queue.songs, song],
        currentIndex: _queue.songs.length,
      );
    } else {
      _queue = _queue.copyWith(currentIndex: idx);
    }
    await _loadAndPlay(song);
  }

  void addToQueue(Song song, {bool playNow = false}) {
    _queue = _queue.copyWith(songs: [..._queue.songs, song]);
    if (playNow) _loadAndPlay(song);
  }

  void removeFromQueue(String mid) {
    final songs = _queue.songs.where((s) => s.mid != mid).toList();
    _queue = _queue.copyWith(songs: songs);
  }

  Future<void> playNext() async {
    if (_queue.songs.isEmpty) return;
    final next = _nextIndex();
    _queue = _queue.copyWith(currentIndex: next);
    await _loadAndPlay(_queue.songs[next]);
  }

  Future<void> playPrevious() async {
    if (_queue.songs.isEmpty) return;
    final prev = (_queue.currentIndex - 1).clamp(0, _queue.songs.length - 1);
    _queue = _queue.copyWith(currentIndex: prev);
    await _loadAndPlay(_queue.songs[prev]);
  }

  void setPlayMode(PlayMode mode) => _mode = mode;

  int _nextIndex() {
    if (_mode == PlayMode.shuffle) {
      // Simple random (no-repeat-last in production would use a smarter picker).
      return DateTime.now().millisecondsSinceEpoch % _queue.songs.length;
    }
    if (_mode == PlayMode.repeat) return _queue.currentIndex;
    return (_queue.currentIndex + 1) % _queue.songs.length;
  }

  Future<void> _loadAndPlay(Song song) async {
    await _ready; // ensure AudioService.init has completed
    _stopProgressTimer();
    final api = _ref.read(apiServiceProvider);
    
    // Always fetch fresh URL — never use cache.
    final resp = await api.getSongUrl(song.mid, song.name); // song.mid is the song ID
    final code = resp['code'] as int;
    
    if (code == 0) {
      // No playback permission
      final message = resp['message'] as String? ?? '暂无播放权限';
      throw PlaybackException(message);
    }
    
    final url = resp['url'] as String?;
    if (url == null || url.isEmpty) {
      throw PlaybackException('无法获取播放链接');
    }
    
    final mediaItem = song.toMediaItem(url);
    await _handler!.playMediaItem(mediaItem);
    _startProgressTimer(song.mid);
  }

  // ── Progress reporting ──────────────────────────────────────────────────────

  void _startProgressTimer(String mid) {
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final pos = _player.position.inSeconds;
      if (pos != _lastReportedSeconds) {
        _reportProgress(mid, pos);
        _lastReportedSeconds = pos;
      }
    });
  }

  void _stopProgressTimer() => _progressTimer?.cancel();

  void _reportProgress(String mid, int seconds) {
    _ref.read(apiServiceProvider).reportProgress(mid, seconds);
  }

  // ── Cross-device resume ─────────────────────────────────────────────────────

  Future<void> resumeFromLastProgress() async {
    final song = currentSong;
    if (song == null) return;
    final data = await _ref.read(apiServiceProvider).getProgress(song.mid);
    if (data != null) {
      final secs = (data['progress'] as num?)?.toInt() ?? 0;
      if (secs > 0) await _player.seek(Duration(seconds: secs));
    }
  }
}

/// Immutable play queue.
class PlayQueue {
  const PlayQueue({required this.songs, required this.currentIndex});
  final List<Song> songs;
  final int currentIndex;

  PlayQueue copyWith({List<Song>? songs, int? currentIndex}) => PlayQueue(
        songs: songs ?? this.songs,
        currentIndex: currentIndex ?? this.currentIndex,
      );
}
