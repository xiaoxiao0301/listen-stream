import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/user_data_service.dart';

/// Provider for user playlists
final userPlaylistsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  yield await UserDataService.getPlaylists();
  
  // Watch for changes by polling (simple approach)
  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    yield await UserDataService.getPlaylists();
  }
});

/// Provider for favorite songs
final favoriteSongsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  yield await UserDataService.getFavoriteSongs();
  
  // Watch for changes by polling
  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    yield await UserDataService.getFavoriteSongs();
  }
});

/// Provider for checking if a song is favorited
final isSongFavoritedProvider = FutureProvider.family<bool, String>((ref, songMid) async {
  return await UserDataService.isSongFavorited(songMid);
});

/// Provider for playlist songs
final playlistSongsProvider = StreamProvider.family<List<Map<String, dynamic>>, int>((ref, playlistId) async* {
  yield await UserDataService.getPlaylistSongs(playlistId);
  
  // Watch for changes by polling
  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    yield await UserDataService.getPlaylistSongs(playlistId);
  }
});

/// Provider for playlist song count
final playlistSongCountProvider = FutureProvider.family<int, int>((ref, playlistId) async {
  return await UserDataService.getPlaylistSongCount(playlistId);
});
