import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/services/media_scanner_service.dart';
import '../../core/services/thumbnail_service.dart';
import '../../features/subtitles/domain/subtitle_models.dart';

// ─── Scanning State ─────────────────────────────────────────────

enum ScanStatus { idle, scanning, completed, error }

class ScanState {
  final ScanStatus status;
  final int newCount;
  final int totalCount;
  final String? error;

  const ScanState({
    this.status = ScanStatus.idle,
    this.newCount = 0,
    this.totalCount = 0,
    this.error,
  });

  ScanState copyWith({ScanStatus? status, int? newCount, int? totalCount, String? error}) {
    return ScanState(
      status: status ?? this.status,
      newCount: newCount ?? this.newCount,
      totalCount: totalCount ?? this.totalCount,
      error: error ?? this.error,
    );
  }
}

class ScanNotifier extends StateNotifier<ScanState> {
  ScanNotifier() : super(const ScanState());

  Future<void> scanDevice() async {
    state = state.copyWith(status: ScanStatus.scanning, newCount: 0);
    try {
      final count = await MediaScannerService.scanDevice(
        onProgress: (current, total) {
          state = state.copyWith(totalCount: total > 0 ? total : current);
        },
      );
      state = state.copyWith(status: ScanStatus.completed, newCount: count);
    } catch (e) {
      state = state.copyWith(status: ScanStatus.error, error: e.toString());
    }
  }

  void reset() => state = const ScanState();
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) => ScanNotifier());

// ─── All Videos ─────────────────────────────────────────────────

final allVideosProvider = FutureProvider<List<Video>>((ref) async {
  // Watch scan state to refresh after scans
  ref.watch(scanProvider);
  return AppDatabase.getAllVideos();
});

// ─── Video Count ────────────────────────────────────────────────

final videoCountProvider = FutureProvider<int>((ref) async {
  ref.watch(scanProvider);
  return AppDatabase.getVideoCount();
});

// ─── Folders ────────────────────────────────────────────────────

final videoFoldersProvider = FutureProvider<List<VideoFolder>>((ref) async {
  ref.watch(scanProvider);
  return AppDatabase.getVideoFolders();
});

// ─── Favorites ──────────────────────────────────────────────────

final favoritesProvider = FutureProvider<List<Video>>((ref) async {
  ref.watch(scanProvider);
  ref.watch(_favoritesRefreshProvider);
  return AppDatabase.getFavoriteVideos();
});

final _favoritesRefreshProvider = StateProvider<int>((ref) => 0);

void refreshFavorites(WidgetRef ref) {
  ref.read(_favoritesRefreshProvider.notifier).state++;
}

void refreshFavoritesFromContainer(ProviderContainer container) {
  container.read(_favoritesRefreshProvider.notifier).state++;
}

// ─── Search ─────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Video>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  return AppDatabase.searchVideos(query);
});

final subtitleSearchResultsProvider = FutureProvider<List<SubtitleSearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  return AppDatabase.searchSubtitles(query);
});

// ─── Sort ───────────────────────────────────────────────────────

final sortOptionProvider = StateProvider<VideoSortOption>((ref) => VideoSortOption.dateAdded);

final sortedVideosProvider = FutureProvider<List<Video>>((ref) async {
  final videos = await ref.watch(allVideosProvider.future);
  final sort = ref.watch(sortOptionProvider);
  final sorted = List<Video>.from(videos);

  switch (sort) {
    case VideoSortOption.name:
      sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    case VideoSortOption.dateAdded:
      sorted.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    case VideoSortOption.duration:
      sorted.sort((a, b) => b.durationMs.compareTo(a.durationMs));
    case VideoSortOption.fileSize:
      sorted.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    case VideoSortOption.recentlyWatched:
      // This needs history data, so keep dateAdded as fallback
      sorted.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
  }
  return sorted;
});

// ─── Filter Category ────────────────────────────────────────────

final filterCategoryProvider = StateProvider<VideoFilterCategory>((ref) => VideoFilterCategory.all);

// ─── Grid/List View ─────────────────────────────────────────────

final isGridViewProvider = StateProvider<bool>((ref) => true);

// ─── Folder Videos ──────────────────────────────────────────────

final folderVideosProvider = FutureProvider.family<List<Video>, String>((ref, folderName) async {
  ref.watch(scanProvider);
  return AppDatabase.getVideosByFolder(folderName);
});

// ─── Watch History ──────────────────────────────────────────────

final _historyRefreshProvider = StateProvider<int>((ref) => 0);

void refreshHistory(WidgetRef ref) {
  ref.read(_historyRefreshProvider.notifier).state++;
}

final continueWatchingProvider = FutureProvider<List<MapEntry<Video, WatchHistory>>>((ref) async {
  ref.watch(_historyRefreshProvider);
  final rows = await AppDatabase.getContinueWatching(limit: 10);
  return rows.map((row) {
    final video = Video.fromMap(row);
    final history = WatchHistory(
      videoId: video.id ?? 0,
      positionMs: row['wh_position_ms'] as int? ?? 0,
      durationMs: row['wh_duration_ms'] as int? ?? 0,
      completionPercentage: (row['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      lastWatchedTimestamp: row['last_watched_timestamp'] as int? ?? 0,
    );
    return MapEntry(video, history);
  }).toList();
});

final recentlyWatchedProvider = FutureProvider<List<MapEntry<Video, WatchHistory>>>((ref) async {
  ref.watch(_historyRefreshProvider);
  final rows = await AppDatabase.getRecentlyWatched(limit: 20);
  return rows.map((row) {
    final video = Video.fromMap(row);
    final history = WatchHistory(
      videoId: video.id ?? 0,
      positionMs: row['wh_position_ms'] as int? ?? 0,
      durationMs: row['wh_duration_ms'] as int? ?? 0,
      completionPercentage: (row['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      lastWatchedTimestamp: row['last_watched_timestamp'] as int? ?? 0,
    );
    return MapEntry(video, history);
  }).toList();
});

// ─── Recently Added ─────────────────────────────────────────────

final recentlyAddedProvider = FutureProvider<List<Video>>((ref) async {
  final videos = await ref.watch(allVideosProvider.future);
  final sorted = List<Video>.from(videos);
  sorted.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
  return sorted.take(20).toList();
});

// ─── Single Video ───────────────────────────────────────────────

final videoByIdProvider = FutureProvider.family<Video?, int>((ref, id) async {
  return AppDatabase.getVideoById(id);
});

final watchHistoryForVideoProvider = FutureProvider.family<WatchHistory?, int>((ref, videoId) async {
  ref.watch(_historyRefreshProvider);
  return AppDatabase.getWatchHistory(videoId);
});

// ─── Thumbnails ─────────────────────────────────────────────────

final thumbnailProvider = FutureProvider.family<String?, String>((ref, videoPath) async {
  return ThumbnailService.getThumbnail(videoPath);
});

// ─── Permission ─────────────────────────────────────────────────

final hasPermissionProvider = FutureProvider<bool>((ref) async {
  return MediaScannerService.hasPermission();
});
