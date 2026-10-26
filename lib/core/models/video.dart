enum MediaSourceType {
  local,
  youtube,
}

/// Video entity representing a local or online media item (e.g. YouTube).
class Video {
  final int? id;
  final String path;
  final String title;
  final String folderName;
  final int durationMs;
  final int sizeBytes;
  final int width;
  final int height;
  final String mimeType;
  final int dateAdded; // epoch seconds
  final String? thumbnailPath;
  final bool isFavorite;
  final MediaSourceType sourceType;
  final String? externalUrl;
  final String? externalId;

  const Video({
    this.id,
    required this.path,
    required this.title,
    required this.folderName,
    this.durationMs = 0,
    this.sizeBytes = 0,
    this.width = 0,
    this.height = 0,
    this.mimeType = 'video/mp4',
    this.dateAdded = 0,
    this.thumbnailPath,
    this.isFavorite = false,
    this.sourceType = MediaSourceType.local,
    this.externalUrl,
    this.externalId,
  });

  bool get isYouTube => sourceType == MediaSourceType.youtube;
  bool get isLocal => sourceType == MediaSourceType.local;

  Video copyWith({
    int? id,
    String? path,
    String? title,
    String? folderName,
    int? durationMs,
    int? sizeBytes,
    int? width,
    int? height,
    String? mimeType,
    int? dateAdded,
    String? thumbnailPath,
    bool? isFavorite,
    MediaSourceType? sourceType,
    String? externalUrl,
    String? externalId,
  }) {
    return Video(
      id: id ?? this.id,
      path: path ?? this.path,
      title: title ?? this.title,
      folderName: folderName ?? this.folderName,
      durationMs: durationMs ?? this.durationMs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      mimeType: mimeType ?? this.mimeType,
      dateAdded: dateAdded ?? this.dateAdded,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isFavorite: isFavorite ?? this.isFavorite,
      sourceType: sourceType ?? this.sourceType,
      externalUrl: externalUrl ?? this.externalUrl,
      externalId: externalId ?? this.externalId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'path': path,
      'title': title,
      'folder_name': folderName,
      'duration_ms': durationMs,
      'size_bytes': sizeBytes,
      'width': width,
      'height': height,
      'mime_type': mimeType,
      'date_added': dateAdded,
      'thumbnail_path': thumbnailPath,
      'is_favorite': isFavorite ? 1 : 0,
      'source_type': sourceType.name,
      'external_url': externalUrl,
      'external_id': externalId,
    };
  }

  factory Video.fromMap(Map<String, dynamic> map) {
    MediaSourceType parsedSourceType = MediaSourceType.local;
    final rawSource = map['source_type'] as String?;
    if (rawSource != null && rawSource.toLowerCase() == 'youtube') {
      parsedSourceType = MediaSourceType.youtube;
    }

    return Video(
      id: map['id'] as int?,
      path: map['path'] as String? ?? '',
      title: map['title'] as String? ?? '',
      folderName: map['folder_name'] as String? ?? '',
      durationMs: map['duration_ms'] as int? ?? 0,
      sizeBytes: map['size_bytes'] as int? ?? 0,
      width: map['width'] as int? ?? 0,
      height: map['height'] as int? ?? 0,
      mimeType: map['mime_type'] as String? ?? 'video/mp4',
      dateAdded: map['date_added'] as int? ?? 0,
      thumbnailPath: map['thumbnail_path'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      sourceType: parsedSourceType,
      externalUrl: map['external_url'] as String?,
      externalId: map['external_id'] as String?,
    );
  }

  /// Human-readable duration string (e.g., "1h 23m" or "4:32")
  String get formattedDuration {
    final total = Duration(milliseconds: durationMs);
    final hours = total.inHours;
    final minutes = total.inMinutes.remainder(60);
    final seconds = total.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Human-readable file size (e.g., "1.4 GB", "320 MB")
  String get formattedSize {
    if (sizeBytes >= 1073741824) {
      return '${(sizeBytes / 1073741824).toStringAsFixed(1)} GB';
    } else if (sizeBytes >= 1048576) {
      return '${(sizeBytes / 1048576).toStringAsFixed(0)} MB';
    } else if (sizeBytes >= 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$sizeBytes B';
  }

  /// Resolution label (e.g., "4K", "1080P", "720P")
  String get resolutionLabel {
    if (width >= 3840 || height >= 2160) return '4K';
    if (width >= 2560 || height >= 1440) return '2K';
    if (width >= 1920 || height >= 1080) return '1080P';
    if (width >= 1280 || height >= 720) return '720P';
    if (width >= 854 || height >= 480) return '480P';
    if (width > 0) return '${height}P';
    return '';
  }

  /// Format extension label (e.g., "MP4", "MKV")
  String get formatLabel {
    final ext = path.split('.').last.toUpperCase();
    return ext;
  }

  /// Resolution string (e.g., "3840 × 2160")
  String get resolutionString {
    if (width > 0 && height > 0) return '$width × $height';
    return 'Unknown';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Video && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;
}
