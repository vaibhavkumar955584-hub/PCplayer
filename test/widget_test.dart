import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:velo_player/core/database/app_database.dart';
import 'package:velo_player/core/models/models.dart';
import 'package:velo_player/core/providers/playlist_providers.dart';
import 'package:velo_player/core/services/settings_service.dart';
import 'package:velo_player/core/widgets/velo_components.dart';
import 'package:velo_player/main.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({
      'remember_position': true,
      'auto_play_next': false,
      'playback_speed': 1.0,
    });
    await SettingsService.init();
  });

  group('Database & Model Tests', () {
    test('Insert and retrieve video', () async {
      final video = Video(
        path: '/storage/test/sample_video.mp4',
        title: 'Sample Video',
        folderName: 'Movies',
        durationMs: 120000,
        sizeBytes: 10485760,
        width: 1920,
        height: 1080,
      );

      final id = await AppDatabase.upsertVideo(video);
      expect(id, greaterThan(0));

      final fetched = await AppDatabase.getVideoByPath('/storage/test/sample_video.mp4');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Sample Video');
      expect(fetched.resolutionLabel, '1080P');
      expect(fetched.durationMs, 120000);
    });

    test('Watch history persistence and completion tracking', () async {
      final video = await AppDatabase.getVideoByPath('/storage/test/sample_video.mp4');
      expect(video, isNotNull);

      // Save watch position at 50%
      final history = WatchHistory(
        videoId: video!.id!,
        positionMs: 60000,
        durationMs: 120000,
        completionPercentage: 0.5,
        lastWatchedTimestamp: DateTime.now().millisecondsSinceEpoch,
      );
      await AppDatabase.upsertWatchHistory(history);

      final loaded = await AppDatabase.getWatchHistory(video.id!);
      expect(loaded, isNotNull);
      expect(loaded!.positionMs, 60000);
      expect(loaded.isCompleted, isFalse);

      // Verify Continue Watching query returns this item
      final continueItems = await AppDatabase.getContinueWatching();
      expect(continueItems.any((item) => item['id'] == video.id), isTrue);

      // Mark as completed (>= 95%)
      final completedHistory = history.copyWith(
        positionMs: 120000,
        completionPercentage: 1.0,
      );
      await AppDatabase.upsertWatchHistory(completedHistory);

      final completedCheck = await AppDatabase.getWatchHistory(video.id!);
      expect(completedCheck!.isCompleted, isTrue);

      // Should no longer appear in Continue Watching
      final continueAfter = await AppDatabase.getContinueWatching();
      expect(continueAfter.any((item) => item['id'] == video.id), isFalse);
    });

    test('Playlist creation, adding videos, and reordering', () async {
      final video = await AppDatabase.getVideoByPath('/storage/test/sample_video.mp4');
      expect(video, isNotNull);

      // Create playlist
      final playlistId = await PlaylistActions.createPlaylist('Favorites Collection');
      expect(playlistId, greaterThan(0));

      // Add video to playlist
      await PlaylistActions.addVideoToPlaylist(playlistId, video!.id!);

      final count = await AppDatabase.getPlaylistVideoCount(playlistId);
      expect(count, 1);

      final videos = await AppDatabase.getPlaylistVideos(playlistId);
      expect(videos.length, 1);
      expect(videos.first.id, video.id);

      // Rename playlist
      await PlaylistActions.renamePlaylist(playlistId, 'Best Movies');
      final allPlaylists = await AppDatabase.getAllPlaylists();
      final renamed = allPlaylists.firstWhere((p) => p.id == playlistId);
      expect(renamed.name, 'Best Movies');

      // Delete playlist
      await PlaylistActions.deletePlaylist(playlistId);
      final remaining = await AppDatabase.getAllPlaylists();
      expect(remaining.any((p) => p.id == playlistId), isFalse);
    });

    test('Search videos by title and folder name', () async {
      // Search exact match
      final results1 = await AppDatabase.searchVideos('Sample');
      expect(results1.isNotEmpty, isTrue);
      expect(results1.first.title, 'Sample Video');

      // Search case-insensitive partial
      final results2 = await AppDatabase.searchVideos('sample');
      expect(results2.isNotEmpty, isTrue);

      // Search by folder name
      final results3 = await AppDatabase.searchVideos('Movies');
      expect(results3.isNotEmpty, isTrue);

      // Non-existent search
      final results4 = await AppDatabase.searchVideos('NonExistentVideoQueryXYZ');
      expect(results4.isEmpty, isTrue);
    });

    test('Favorites toggling and persistence', () async {
      final video = await AppDatabase.getVideoByPath('/storage/test/sample_video.mp4');
      expect(video, isNotNull);

      // Set favorite
      await AppDatabase.setFavorite(video!.id!, true);
      var favorites = await AppDatabase.getFavoriteVideos();
      expect(favorites.any((v) => v.id == video.id), isTrue);

      // Unfavorite
      await AppDatabase.setFavorite(video.id!, false);
      favorites = await AppDatabase.getFavoriteVideos();
      expect(favorites.any((v) => v.id == video.id), isFalse);
    });

    test('Folder grouping and retrieval', () async {
      final folders = await AppDatabase.getVideoFolders();
      expect(folders.any((f) => f.name == 'Movies'), isTrue);

      final folderVideos = await AppDatabase.getVideosByFolder('Movies');
      expect(folderVideos.isNotEmpty, isTrue);
      expect(folderVideos.first.folderName, 'Movies');
    });

    test('Settings persistence across modifications', () {
      SettingsService.rememberPosition = true;
      expect(SettingsService.rememberPosition, isTrue);
      SettingsService.rememberPosition = false;
      expect(SettingsService.rememberPosition, isFalse);
      SettingsService.rememberPosition = true; // reset

      SettingsService.autoPlayNext = true;
      expect(SettingsService.autoPlayNext, isTrue);
      SettingsService.autoPlayNext = false;
      expect(SettingsService.autoPlayNext, isFalse);

      SettingsService.defaultPlaybackSpeed = 1.5;
      expect(SettingsService.defaultPlaybackSpeed, 1.5);
      SettingsService.defaultPlaybackSpeed = 1.0; // reset
    });
  });

  group('Velo Player UI Tests', () {
    testWidgets('App boots with VeloBottomNav and navigation items', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: VeloPlayerApp(),
        ),
      );

      // Initial frame
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));

      // Verify VeloBottomNav exists with 4 navigation items
      expect(find.byType(VeloBottomNav), findsOneWidget);
      expect(find.text('Library'), findsWidgets);
      expect(find.text('Playlists'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);

      // Verify default Home screen is showing
      expect(find.text('LOCAL PLAYER'), findsOneWidget);
    });
  });
}
