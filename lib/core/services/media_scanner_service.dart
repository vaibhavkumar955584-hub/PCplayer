import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../database/app_database.dart';
import '../models/models.dart';
import 'settings_service.dart';

/// Scans device storage for video files using platform MediaStore (Android)
/// or directory walking as a fallback.
class MediaScannerService {
  static const _channel = MethodChannel('com.example.veloplayer/media_scanner');

  static const _videoExtensions = {
    '.mp4', '.mkv', '.mov', '.avi', '.webm', '.m4v', '.3gp', '.ts', '.flv', '.wmv',
  };

  /// Request media/storage permissions. Returns true if granted.
  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if media permission is granted.
  static Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>('hasPermission');
      return result ?? false;
    } catch (_) {
      return true;
    }
  }

  /// Scan device for video files. Returns the count of newly found videos.
  static Future<int> scanDevice({
    void Function(int current, int total)? onProgress,
  }) async {
    final existingPaths = await AppDatabase.getAllVideoPaths();
    final List<Video> newVideos = [];

    try {
      // Try platform MediaStore query first (Android)
      final List<dynamic>? mediaStoreResults =
          await _channel.invokeMethod<List<dynamic>>('queryVideos');

      if (mediaStoreResults != null) {
        final scannedPaths = <String>{};
        for (final item in mediaStoreResults) {
          final map = Map<String, dynamic>.from(item as Map);
          final path = map['path'] as String? ?? '';
          if (path.isEmpty) continue;

          scannedPaths.add(path);

          if (!existingPaths.contains(path)) {
            final folderName = p.basename(p.dirname(path));

            newVideos.add(Video(
              path: path,
              title: _cleanTitle(map['title'] as String? ?? p.basename(path)),
              folderName: folderName,
              durationMs: (map['duration'] as num?)?.toInt() ?? 0,
              sizeBytes: (map['size'] as num?)?.toInt() ?? 0,
              width: (map['width'] as num?)?.toInt() ?? 0,
              height: (map['height'] as num?)?.toInt() ?? 0,
              mimeType: map['mimeType'] as String? ?? 'video/mp4',
              dateAdded: (map['dateAdded'] as num?)?.toInt() ?? 0,
            ));
          }

          onProgress?.call(scannedPaths.length, mediaStoreResults.length);
        }

        // Remove videos that no longer exist on disk
        final deletedPaths = existingPaths.difference(scannedPaths).toList();
        if (deletedPaths.isNotEmpty) {
          await AppDatabase.deleteVideosByPaths(deletedPaths);
        }
      }
    } on PlatformException {
      // Fallback: walk common directories
      await _scanDirectories(existingPaths, newVideos, onProgress);
    } on MissingPluginException {
      // Platform channel not available (e.g. running on desktop)
      await _scanDirectories(existingPaths, newVideos, onProgress);
    }

    // Insert new videos into database
    for (final video in newVideos) {
      await AppDatabase.insertVideo(video);
    }

    SettingsService.lastScanTimestamp = DateTime.now().millisecondsSinceEpoch;
    return newVideos.length;
  }

  /// Fallback directory scanning for platforms without MediaStore.
  static Future<void> _scanDirectories(
    Set<String> existingPaths,
    List<Video> newVideos,
    void Function(int, int)? onProgress,
  ) async {
    final dirsToScan = <String>[];

    if (Platform.isAndroid) {
      final externalDirs = [
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Videos',
        '/storage/emulated/0/Camera',
      ];
      for (final d in externalDirs) {
        if (await Directory(d).exists()) {
          dirsToScan.add(d);
        }
      }
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        for (final sub in ['Videos', 'Downloads', 'Desktop', 'Documents', 'Movies']) {
          final dir = p.join(userProfile, sub);
          if (await Directory(dir).exists()) {
            dirsToScan.add(dir);
          }
        }
      }

      // Auto-detect common video folders on all available drive letters (C:, D:, E:, etc.)
      for (var charCode = 67; charCode <= 90; charCode++) {
        final driveLetter = String.fromCharCode(charCode);
        final driveRoot = '$driveLetter:\\';
        try {
          if (Directory(driveRoot).existsSync()) {
            for (final sub in ['Videos', 'Movies', 'Media', 'Downloads', 'Films', 'Video', 'Cinema']) {
              final cand = p.join(driveRoot, sub);
              if (Directory(cand).existsSync()) {
                dirsToScan.add(cand);
              }
            }
          }
        } catch (_) {}
      }

      // Include all user-configured custom folders from settings
      for (final customDir in SettingsService.customScanFolders) {
        if (!dirsToScan.contains(customDir) && await Directory(customDir).exists()) {
          dirsToScan.add(customDir);
        }
      }
    }

    int count = 0;
    for (final dirPath in dirsToScan) {
      await _scanDirectoryPath(dirPath, existingPaths, newVideos, onProgress, (c) => count += c);
    }
  }

  /// Internal recursive directory scanner
  static Future<void> _scanDirectoryPath(
    String dirPath,
    Set<String> existingPaths,
    List<Video> newVideos,
    void Function(int, int)? onProgress,
    void Function(int)? onCountAdded,
  ) async {
    try {
      await for (final entity in Directory(dirPath).list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final pLower = entity.path.toLowerCase();
          if (pLower.contains(r'\build\') ||
              pLower.contains('/build/') ||
              pLower.contains(r'\.dart_tool\') ||
              pLower.contains('/.dart_tool/') ||
              pLower.contains(r'\.gradle\') ||
              pLower.contains('/.gradle/') ||
              pLower.contains(r'\.git\') ||
              pLower.contains('/.git/') ||
              pLower.contains(r'\$recycle.bin\') ||
              pLower.contains(r'\system volume information\') ||
              pLower.contains(r'\windows\') ||
              pLower.contains(r'\program files\') ||
              pLower.contains(r'\appdata\')) {
            continue;
          }
          final ext = p.extension(entity.path).toLowerCase();
          if (_videoExtensions.contains(ext) && !existingPaths.contains(entity.path)) {
            final stat = await entity.stat();
            final folderName = p.basename(entity.parent.path);
            newVideos.add(Video(
              path: entity.path,
              title: _cleanTitle(p.basename(entity.path)),
              folderName: folderName,
              sizeBytes: stat.size,
              dateAdded: stat.modified.millisecondsSinceEpoch ~/ 1000,
              mimeType: _getMimeType(ext),
            ));
            onCountAdded?.call(1);
            onProgress?.call(newVideos.length, -1);
          }
        }
      }
    } catch (_) {
      // Permission denied or inaccessible directory
    }
  }

  /// Opens native file picker to select a video file and imports it into the database.
  /// Returns the registered Video object (with database id) or null if cancelled.
  static Future<Video?> pickAndImportSingleFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mkv', 'mov', 'avi', 'webm', 'm4v', '3gp', 'ts', 'flv', 'wmv'],
      );

      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        return null;
      }

      final filePath = result.files.single.path!;
      return await importFileByPath(filePath);
    } catch (_) {
      return null;
    }
  }

  /// Registers a video file into the database if not already present.
  static Future<Video?> importFileByPath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final existing = await AppDatabase.getVideoByPath(filePath);
    if (existing != null) return existing;

    final stat = await file.stat();
    final ext = p.extension(filePath).toLowerCase();
    final folderName = p.basename(file.parent.path);

    final video = Video(
      path: filePath,
      title: _cleanTitle(p.basename(filePath)),
      folderName: folderName,
      sizeBytes: stat.size,
      dateAdded: stat.modified.millisecondsSinceEpoch ~/ 1000,
      mimeType: _getMimeType(ext),
    );

    final id = await AppDatabase.insertVideo(video);
    return video.copyWith(id: id);
  }

  /// Opens native directory picker, saves the folder to custom scan folders, and scans it.
  /// Returns count of new videos found, or null if cancelled.
  static Future<int?> pickAndScanFolder({void Function(int, int)? onProgress}) async {
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Folder with Videos',
      );

      if (selectedDirectory == null || selectedDirectory.isEmpty) {
        return null;
      }

      SettingsService.addScanFolder(selectedDirectory);

      final existingPaths = await AppDatabase.getAllVideoPaths();
      final List<Video> newVideos = [];

      await _scanDirectoryPath(
        selectedDirectory,
        existingPaths,
        newVideos,
        onProgress,
        null,
      );

      for (final video in newVideos) {
        await AppDatabase.insertVideo(video);
      }

      SettingsService.lastScanTimestamp = DateTime.now().millisecondsSinceEpoch;
      return newVideos.length;
    } catch (_) {
      return null;
    }
  }

  static String _cleanTitle(String filename) {
    // Remove file extension
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex > 0) {
      filename = filename.substring(0, dotIndex);
    }
    // Replace underscores/dots with spaces
    return filename.replaceAll(RegExp(r'[_.]'), ' ').trim();
  }

  static String _getMimeType(String ext) {
    switch (ext) {
      case '.mp4': return 'video/mp4';
      case '.mkv': return 'video/x-matroska';
      case '.mov': return 'video/quicktime';
      case '.avi': return 'video/x-msvideo';
      case '.webm': return 'video/webm';
      case '.m4v': return 'video/x-m4v';
      case '.3gp': return 'video/3gpp';
      case '.ts': return 'video/mp2t';
      case '.flv': return 'video/x-flv';
      case '.wmv': return 'video/x-ms-wmv';
      default: return 'video/mp4';
    }
  }
}
