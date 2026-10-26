import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';
import '../../features/subtitles/domain/subtitle_models.dart';
import '../../features/ai_subtitles/domain/ai_subtitle_models.dart';

/// Central SQLite database for Velo Player.
class AppDatabase {
  static const _dbName = 'velo_player.db';
  static const _dbVersion = 3;

  static Database? _database;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        folder_name TEXT NOT NULL DEFAULT '',
        duration_ms INTEGER NOT NULL DEFAULT 0,
        size_bytes INTEGER NOT NULL DEFAULT 0,
        width INTEGER NOT NULL DEFAULT 0,
        height INTEGER NOT NULL DEFAULT 0,
        mime_type TEXT NOT NULL DEFAULT 'video/mp4',
        date_added INTEGER NOT NULL DEFAULT 0,
        thumbnail_path TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        source_type TEXT NOT NULL DEFAULT 'local',
        external_url TEXT,
        external_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE watch_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        video_id INTEGER NOT NULL UNIQUE,
        position_ms INTEGER NOT NULL DEFAULT 0,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        completion_percentage REAL NOT NULL DEFAULT 0.0,
        last_watched_timestamp INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (video_id) REFERENCES videos(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        video_id INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
        FOREIGN KEY (video_id) REFERENCES videos(id) ON DELETE CASCADE,
        UNIQUE(playlist_id, video_id)
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX idx_videos_folder ON videos(folder_name)');
    await db.execute('CREATE INDEX idx_videos_favorite ON videos(is_favorite)');
    await db.execute('CREATE INDEX idx_videos_date ON videos(date_added)');
    await db.execute('CREATE INDEX idx_videos_source ON videos(source_type)');
    await db.execute('CREATE INDEX idx_videos_external_id ON videos(external_id)');
    await db.execute('CREATE INDEX idx_history_video ON watch_history(video_id)');
    await db.execute('CREATE INDEX idx_history_timestamp ON watch_history(last_watched_timestamp)');
    await db.execute('CREATE INDEX idx_playlist_videos_playlist ON playlist_videos(playlist_id)');

    // Version 2 & 3 tables
    await _createV2Tables(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createV2Tables(db);
    }
    if (oldVersion < 3) {
      await _migrateToV3(db);
    }
  }

  static Future<void> _migrateToV3(Database db) async {
    // Add columns if they don't exist yet
    final tableInfo = await db.rawQuery('PRAGMA table_info(videos)');
    final existingCols = tableInfo.map((c) => c['name'] as String).toSet();

    if (!existingCols.contains('source_type')) {
      await db.execute("ALTER TABLE videos ADD COLUMN source_type TEXT NOT NULL DEFAULT 'local'");
    }
    if (!existingCols.contains('external_url')) {
      await db.execute('ALTER TABLE videos ADD COLUMN external_url TEXT');
    }
    if (!existingCols.contains('external_id')) {
      await db.execute('ALTER TABLE videos ADD COLUMN external_id TEXT');
    }

    await db.execute('CREATE INDEX IF NOT EXISTS idx_videos_source ON videos(source_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_videos_external_id ON videos(external_id)');
  }

  static Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subtitle_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        video_id INTEGER NOT NULL,
        language_code TEXT NOT NULL,
        language_name TEXT NOT NULL,
        source_type TEXT NOT NULL,
        file_path TEXT,
        is_ai_generated INTEGER NOT NULL DEFAULT 0,
        is_translated INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (video_id) REFERENCES videos(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS subtitle_segments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subtitle_track_id INTEGER NOT NULL,
        start_ms INTEGER NOT NULL,
        end_ms INTEGER NOT NULL,
        text TEXT NOT NULL,
        sequence INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (subtitle_track_id) REFERENCES subtitle_tracks(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS subtitle_jobs (
        id TEXT PRIMARY KEY,
        video_id INTEGER NOT NULL,
        source_language TEXT NOT NULL,
        target_language TEXT NOT NULL,
        status TEXT NOT NULL,
        progress REAL NOT NULL DEFAULT 0.0,
        error TEXT,
        created_at INTEGER NOT NULL,
        completed_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS subtitle_preferences (
        video_id INTEGER PRIMARY KEY,
        selected_track_id INTEGER,
        preset TEXT NOT NULL DEFAULT 'cinema',
        font_size REAL NOT NULL DEFAULT 16.0,
        text_color INTEGER NOT NULL DEFAULT 4294967295,
        background_color INTEGER NOT NULL DEFAULT 3221225472,
        FOREIGN KEY (video_id) REFERENCES videos(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS playback_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        video_id INTEGER NOT NULL,
        position_ms INTEGER NOT NULL DEFAULT 0,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        repeat_mode TEXT NOT NULL DEFAULT 'none',
        is_shuffled INTEGER NOT NULL DEFAULT 0,
        last_active_timestamp INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (video_id) REFERENCES videos(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_sub_tracks_video ON subtitle_tracks(video_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sub_segments_track ON subtitle_segments(subtitle_track_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sub_segments_time ON subtitle_segments(start_ms, end_ms)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sub_segments_text ON subtitle_segments(text)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sub_jobs_video ON subtitle_jobs(video_id)');
  }

  // ─── Video Operations ──────────────────────────────────────────

  static Future<int> insertVideo(Video video) async {
    final db = await database;
    return db.insert('videos', video.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<int> upsertVideo(Video video) async {
    final db = await database;
    return db.insert('videos', video.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Video>> getAllVideos() async {
    final db = await database;
    final maps = await db.query('videos', orderBy: 'date_added DESC');
    return maps.map((m) => Video.fromMap(m)).toList();
  }

  static Future<Video?> getVideoById(int id) async {
    final db = await database;
    final maps = await db.query('videos', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Video.fromMap(maps.first);
  }

  static Future<Video?> getVideoByPath(String path) async {
    final db = await database;
    final maps = await db.query('videos', where: 'path = ?', whereArgs: [path]);
    if (maps.isEmpty) return null;
    return Video.fromMap(maps.first);
  }

  static Future<Video?> getVideoByExternalId(String externalId) async {
    final db = await database;
    final maps = await db.query('videos', where: 'external_id = ?', whereArgs: [externalId]);
    if (maps.isEmpty) return null;
    return Video.fromMap(maps.first);
  }

  static Future<int> insertOrUpdateExternalVideo(Video video) async {
    final db = await database;
    if (video.externalId != null) {
      final existing = await getVideoByExternalId(video.externalId!);
      if (existing != null && existing.id != null) {
        await db.update('videos', video.toMap(), where: 'id = ?', whereArgs: [existing.id]);
        return existing.id!;
      }
    }
    return db.insert('videos', video.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Video>> searchVideos(String query) async {
    final db = await database;
    final maps = await db.query(
      'videos',
      where: 'title LIKE ? OR folder_name LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'title ASC',
    );
    return maps.map((m) => Video.fromMap(m)).toList();
  }

  static Future<List<Video>> getFavoriteVideos() async {
    final db = await database;
    final maps = await db.query('videos', where: 'is_favorite = 1', orderBy: 'title ASC');
    return maps.map((m) => Video.fromMap(m)).toList();
  }

  static Future<List<Video>> getVideosByFolder(String folderName) async {
    final db = await database;
    final maps = await db.query('videos', where: 'folder_name = ?', whereArgs: [folderName], orderBy: 'title ASC');
    return maps.map((m) => Video.fromMap(m)).toList();
  }

  static Future<List<VideoFolder>> getVideoFolders() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT folder_name, COUNT(*) as video_count
      FROM videos
      WHERE folder_name != ''
      GROUP BY folder_name
      ORDER BY folder_name ASC
    ''');
    return maps.map((m) => VideoFolder(
      name: m['folder_name'] as String,
      path: m['folder_name'] as String,
      videoCount: m['video_count'] as int,
    )).toList();
  }

  static Future<void> setFavorite(int videoId, bool isFavorite) async {
    final db = await database;
    await db.update('videos', {'is_favorite': isFavorite ? 1 : 0}, where: 'id = ?', whereArgs: [videoId]);
  }

  static Future<void> updateVideoThumbnail(int videoId, String thumbPath) async {
    final db = await database;
    await db.update('videos', {'thumbnail_path': thumbPath}, where: 'id = ?', whereArgs: [videoId]);
  }

  static Future<void> deleteVideo(int videoId) async {
    final db = await database;
    await db.delete('videos', where: 'id = ?', whereArgs: [videoId]);
  }

  static Future<Set<String>> getAllVideoPaths() async {
    final db = await database;
    final maps = await db.query('videos', columns: ['path']);
    return maps.map((m) => m['path'] as String).toSet();
  }

  static Future<void> deleteVideosByPaths(List<String> paths) async {
    if (paths.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(paths.length, '?').join(',');
    await db.delete('videos', where: 'path IN ($placeholders)', whereArgs: paths);
  }

  static Future<int> getVideoCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM videos');
    return result.first['count'] as int? ?? 0;
  }

  // ─── Watch History Operations ──────────────────────────────────

  static Future<void> upsertWatchHistory(WatchHistory history) async {
    final db = await database;
    await db.insert('watch_history', history.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<WatchHistory?> getWatchHistory(int videoId) async {
    final db = await database;
    final maps = await db.query('watch_history', where: 'video_id = ?', whereArgs: [videoId]);
    if (maps.isEmpty) return null;
    return WatchHistory.fromMap(maps.first);
  }

  static Future<List<Map<String, dynamic>>> getContinueWatching({int limit = 20}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT v.*, wh.position_ms as wh_position_ms, wh.duration_ms as wh_duration_ms,
             wh.completion_percentage, wh.last_watched_timestamp
      FROM videos v
      INNER JOIN watch_history wh ON v.id = wh.video_id
      WHERE wh.completion_percentage < 0.95 AND wh.position_ms > 0
      ORDER BY wh.last_watched_timestamp DESC
      LIMIT ?
    ''', [limit]);
  }

  static Future<List<Map<String, dynamic>>> getRecentlyWatched({int limit = 20}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT v.*, wh.position_ms as wh_position_ms, wh.duration_ms as wh_duration_ms,
             wh.completion_percentage, wh.last_watched_timestamp
      FROM videos v
      INNER JOIN watch_history wh ON v.id = wh.video_id
      ORDER BY wh.last_watched_timestamp DESC
      LIMIT ?
    ''', [limit]);
  }

  static Future<void> deleteWatchHistory(int videoId) async {
    final db = await database;
    await db.delete('watch_history', where: 'video_id = ?', whereArgs: [videoId]);
  }

  // ─── Playlist Operations ──────────────────────────────────────

  static Future<int> insertPlaylist(Playlist playlist) async {
    final db = await database;
    return db.insert('playlists', playlist.toMap());
  }

  static Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    final maps = await db.query('playlists', orderBy: 'updated_at DESC');
    return maps.map((m) => Playlist.fromMap(m)).toList();
  }

  static Future<void> updatePlaylist(Playlist playlist) async {
    final db = await database;
    await db.update('playlists', playlist.toMap(), where: 'id = ?', whereArgs: [playlist.id]);
  }

  static Future<void> deletePlaylist(int playlistId) async {
    final db = await database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
  }

  static Future<void> addVideoToPlaylist(int playlistId, int videoId) async {
    final db = await database;
    final countResult = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 as next_order FROM playlist_videos WHERE playlist_id = ?',
      [playlistId],
    );
    final nextOrder = countResult.first['next_order'] as int? ?? 0;
    await db.insert(
      'playlist_videos',
      PlaylistVideo(playlistId: playlistId, videoId: videoId, sortOrder: nextOrder).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await db.update(
      'playlists',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  static Future<void> removeVideoFromPlaylist(int playlistId, int videoId) async {
    final db = await database;
    await db.delete('playlist_videos', where: 'playlist_id = ? AND video_id = ?', whereArgs: [playlistId, videoId]);
  }

  static Future<List<Video>> getPlaylistVideos(int playlistId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT v.* FROM videos v
      INNER JOIN playlist_videos pv ON v.id = pv.video_id
      WHERE pv.playlist_id = ?
      ORDER BY pv.sort_order ASC
    ''', [playlistId]);
    return maps.map((m) => Video.fromMap(m)).toList();
  }

  static Future<int> getPlaylistVideoCount(int playlistId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM playlist_videos WHERE playlist_id = ?',
      [playlistId],
    );
    return result.first['count'] as int? ?? 0;
  }

  static Future<void> reorderPlaylistVideos(int playlistId, List<int> videoIds) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < videoIds.length; i++) {
      batch.update(
        'playlist_videos',
        {'sort_order': i},
        where: 'playlist_id = ? AND video_id = ?',
        whereArgs: [playlistId, videoIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Playlist>> searchPlaylists(String query) async {
    final db = await database;
    final maps = await db.query(
      'playlists',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Playlist.fromMap(m)).toList();
  }

  // ─── Subtitle Tracks Operations ──────────────────────────────

  static Future<int> insertSubtitleTrack(DbSubtitleTrack track) async {
    final db = await database;
    return db.insert('subtitle_tracks', track.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<DbSubtitleTrack>> getSubtitleTracksForVideo(int videoId) async {
    final db = await database;
    final maps = await db.query(
      'subtitle_tracks',
      where: 'video_id = ?',
      whereArgs: [videoId],
      orderBy: 'is_ai_generated ASC, language_name ASC',
    );
    return maps.map((m) => DbSubtitleTrack.fromMap(m)).toList();
  }

  static Future<DbSubtitleTrack?> getSubtitleTrackById(int trackId) async {
    final db = await database;
    final maps = await db.query('subtitle_tracks', where: 'id = ?', whereArgs: [trackId]);
    if (maps.isEmpty) return null;
    return DbSubtitleTrack.fromMap(maps.first);
  }

  static Future<void> deleteSubtitleTrack(int trackId) async {
    final db = await database;
    await db.delete('subtitle_tracks', where: 'id = ?', whereArgs: [trackId]);
  }

  // ─── Subtitle Segments Operations ────────────────────────────

  static Future<void> insertSubtitleSegments(int trackId, List<DbSubtitleSegment> segments) async {
    final db = await database;
    final batch = db.batch();
    for (final seg in segments) {
      batch.insert('subtitle_segments', seg.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<DbSubtitleSegment>> getSubtitleSegmentsForTrack(int trackId) async {
    final db = await database;
    final maps = await db.query(
      'subtitle_segments',
      where: 'subtitle_track_id = ?',
      whereArgs: [trackId],
      orderBy: 'start_ms ASC',
    );
    return maps.map((m) => DbSubtitleSegment.fromMap(m)).toList();
  }

  // ─── Subtitle Jobs Operations ────────────────────────────────

  static Future<void> insertSubtitleJob(SubtitleJobRecord job) async {
    final db = await database;
    await db.insert('subtitle_jobs', job.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateSubtitleJob(SubtitleJobRecord job) async {
    final db = await database;
    await db.update('subtitle_jobs', job.toMap(), where: 'id = ?', whereArgs: [job.id]);
  }

  static Future<SubtitleJobRecord?> getSubtitleJob(String jobId) async {
    final db = await database;
    final maps = await db.query('subtitle_jobs', where: 'id = ?', whereArgs: [jobId]);
    if (maps.isEmpty) return null;
    return SubtitleJobRecord.fromMap(maps.first);
  }

  static Future<List<SubtitleJobRecord>> getSubtitleJobsForVideo(int videoId) async {
    final db = await database;
    final maps = await db.query(
      'subtitle_jobs',
      where: 'video_id = ?',
      whereArgs: [videoId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => SubtitleJobRecord.fromMap(m)).toList();
  }

  // ─── Subtitle Preferences Operations ─────────────────────────

  static Future<void> saveSubtitlePreferences(int videoId, Map<String, dynamic> prefs) async {
    final db = await database;
    final data = Map<String, dynamic>.from(prefs);
    data['video_id'] = videoId;
    await db.insert('subtitle_preferences', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getSubtitlePreferences(int videoId) async {
    final db = await database;
    final maps = await db.query('subtitle_preferences', where: 'video_id = ?', whereArgs: [videoId]);
    if (maps.isEmpty) return null;
    return maps.first;
  }

  // ─── Spoken Subtitle Dialogue Search ─────────────────────────

  static Future<List<SubtitleSearchResult>> searchSubtitles(String query) async {
    if (query.trim().isEmpty) return [];
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT v.id as video_id, v.title, v.path, st.id as track_id,
             st.language_code, st.language_name,
             ss.id as segment_id, ss.start_ms, ss.end_ms, ss.text
      FROM subtitle_segments ss
      INNER JOIN subtitle_tracks st ON ss.subtitle_track_id = st.id
      INNER JOIN videos v ON st.video_id = v.id
      WHERE ss.text LIKE ?
      ORDER BY v.title ASC, ss.start_ms ASC
      LIMIT 50
    ''', ['%$query%']);

    return maps.map((m) => SubtitleSearchResult.fromMap(m)).toList();
  }
}
