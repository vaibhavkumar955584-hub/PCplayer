import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/app_database.dart';

/// Manages video thumbnail generation and caching.
class ThumbnailService {
  static const _channel = MethodChannel('com.example.veloplayer/thumbnails');
  static String? _cacheDir;

  static Future<String> get _thumbnailDir async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationCacheDirectory();
    _cacheDir = p.join(appDir.path, 'thumbnails');
    await Directory(_cacheDir!).create(recursive: true);
    return _cacheDir!;
  }

  /// Generate a thumbnail for a video file. Returns the cached thumbnail path.
  static Future<String?> getThumbnail(String videoPath, {int videoId = 0}) async {
    try {
      final dir = await _thumbnailDir;
      final hash = videoPath.hashCode.toRadixString(16);
      final thumbPath = p.join(dir, 'thumb_$hash.jpg');

      // Return cached if exists
      if (await File(thumbPath).exists()) {
        return thumbPath;
      }

      // Try platform channel for native thumbnail extraction
      try {
        final result = await _channel.invokeMethod<String>('generateThumbnail', {
          'videoPath': videoPath,
          'outputPath': thumbPath,
          'width': 480,
          'height': 270,
        });
        if (result != null && await File(result).exists()) {
          if (videoId > 0) {
            await AppDatabase.updateVideoThumbnail(videoId, result);
          }
          return result;
        }
      } on PlatformException {
        // Platform thumbnail generation failed
      } on MissingPluginException {
        // Channel not available
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Generate thumbnails for all videos that don't have one.
  static Future<void> generateMissingThumbnails(List<Map<String, dynamic>> videos) async {
    for (final v in videos) {
      final id = v['id'] as int?;
      final path = v['path'] as String?;
      final existing = v['thumbnail_path'] as String?;

      if (id == null || path == null) continue;
      if (existing != null && await File(existing).exists()) continue;

      await getThumbnail(path, videoId: id);
    }
  }

  /// Clear the thumbnail cache.
  static Future<void> clearCache() async {
    final dir = await _thumbnailDir;
    final thumbDir = Directory(dir);
    if (await thumbDir.exists()) {
      await thumbDir.delete(recursive: true);
      await thumbDir.create(recursive: true);
    }
    _cacheDir = null;
  }

  /// Get size of thumbnail cache in bytes.
  static Future<int> getCacheSize() async {
    final dir = await _thumbnailDir;
    final thumbDir = Directory(dir);
    if (!await thumbDir.exists()) return 0;

    int totalSize = 0;
    await for (final entity in thumbDir.list()) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }
}
