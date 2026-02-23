import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/player/playback_service.dart';
import '../../shared/utils/playback_helper.dart';

/// Example: How to add play functionality to a song list item
/// 
/// This example shows the recommended pattern for implementing
/// playback in various contexts (playlists, search results, etc.)

class SongListItemExample extends ConsumerWidget {
  const SongListItemExample({
    super.key,
    required this.songMid,
    required this.songName,
    required this.artistName,
    this.albumMid,
    this.albumName,
    this.coverUrl,
  });

  final String songMid;
  final String songName;
  final String artistName;
  final String? albumMid;
  final String? albumName;
  final String? coverUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: coverUrl != null
          ? Image.network(coverUrl!, width: 48, height: 48, fit: BoxFit.cover)
          : const Icon(Icons.music_note),
      title: Text(songName),
      subtitle: Text(artistName),
      trailing: IconButton(
        icon: const Icon(Icons.play_circle_outline),
        onPressed: () async {
          // Create Song object
          final song = Song(
            mid: songMid,
            name: songName,
            artist: artistName,
            albumMid: albumMid ?? songMid,
            albumName: albumName ?? '',
            coverUrl: coverUrl ?? '',
          );

          // Play with automatic error handling
          await playSongWithErrorHandling(context, ref, song);
        },
      ),
    );
  }
}

/// Example: Play button in a card layout
class SongCardExample extends ConsumerWidget {
  const SongCardExample({
    super.key,
    required this.songMid,
    required this.songName,
    required this.artistName,
    this.albumMid,
    this.coverUrl,
  });

  final String songMid;
  final String songName;
  final String artistName;
  final String? albumMid;
  final String? coverUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          if (coverUrl != null)
            Image.network(coverUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
          ListTile(
            title: Text(songName),
            subtitle: Text(artistName),
          ),
          ButtonBar(
            children: [
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => _playSong(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  // Add to favorites
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _playSong(BuildContext context, WidgetRef ref) async {
    final song = Song(
      mid: songMid,
      name: songName,
      artist: artistName,
      albumMid: albumMid ?? songMid,
      albumName: '',
      coverUrl: coverUrl ?? '',
    );

    await playSongWithErrorHandling(context, ref, song);
  }
}

/// Example: Batch play all songs in a playlist
class PlayAllButtonExample extends ConsumerWidget {
  const PlayAllButtonExample({
    super.key,
    required this.songs,
  });

  final List<Map<String, String>> songs; // [{mid, name, artist, ...}, ...]

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.play_arrow),
      label: const Text('播放全部'),
      onPressed: songs.isEmpty
          ? null
          : () async {
              final svc = ref.read(playbackServiceProvider);

              // Add all songs to queue
              for (final songData in songs) {
                final song = Song(
                  mid: songData['mid']!,
                  name: songData['name']!,
                  artist: songData['artist'] ?? '未知歌手',
                  albumMid: songData['albumMid'] ?? songData['mid']!,
                  albumName: songData['albumName'] ?? '',
                  coverUrl: songData['coverUrl'] ?? '',
                );
                svc.addToQueue(song);
              }

              // Play first song
              if (songs.isNotEmpty) {
                final firstSong = Song(
                  mid: songs[0]['mid']!,
                  name: songs[0]['name']!,
                  artist: songs[0]['artist'] ?? '未知歌手',
                  albumMid: songs[0]['albumMid'] ?? songs[0]['mid']!,
                  albumName: songs[0]['albumName'] ?? '',
                  coverUrl: songs[0]['coverUrl'] ?? '',
                );

                // Use helper to play with error handling
                await playSongWithErrorHandling(context, ref, firstSong);
              }
            },
    );
  }
}
