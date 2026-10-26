import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';

// ─── Playlists Provider ─────────────────────────────────────────

final _playlistRefreshProvider = StateProvider<int>((ref) => 0);

void refreshPlaylists(WidgetRef ref) {
  ref.read(_playlistRefreshProvider.notifier).state++;
}

final allPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  ref.watch(_playlistRefreshProvider);
  return AppDatabase.getAllPlaylists();
});

final playlistVideosProvider = FutureProvider.family<List<Video>, int>((ref, playlistId) async {
  ref.watch(_playlistRefreshProvider);
  return AppDatabase.getPlaylistVideos(playlistId);
});

final playlistVideoCountProvider = FutureProvider.family<int, int>((ref, playlistId) async {
  ref.watch(_playlistRefreshProvider);
  return AppDatabase.getPlaylistVideoCount(playlistId);
});

final searchPlaylistsProvider = FutureProvider.family<List<Playlist>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  return AppDatabase.searchPlaylists(query);
});

// ─── Playlist Actions ───────────────────────────────────────────

class PlaylistActions {
  static Future<int> createPlaylist(String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return AppDatabase.insertPlaylist(Playlist(
      name: name,
      createdAt: now,
      updatedAt: now,
    ));
  }

  static Future<void> renamePlaylist(int id, String newName) async {
    final playlist = Playlist(
      id: id,
      name: newName,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await AppDatabase.updatePlaylist(playlist);
  }

  static Future<void> deletePlaylist(int id) async {
    await AppDatabase.deletePlaylist(id);
  }

  static Future<void> addVideoToPlaylist(int playlistId, int videoId) async {
    await AppDatabase.addVideoToPlaylist(playlistId, videoId);
  }

  static Future<void> removeVideoFromPlaylist(int playlistId, int videoId) async {
    await AppDatabase.removeVideoFromPlaylist(playlistId, videoId);
  }

  static Future<void> reorderVideos(int playlistId, List<int> videoIds) async {
    await AppDatabase.reorderPlaylistVideos(playlistId, videoIds);
  }
}
