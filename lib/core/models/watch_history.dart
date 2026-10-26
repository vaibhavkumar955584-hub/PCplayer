/// Watch history entry tracking playback position for a video.
class WatchHistory {
  final int? id;
  final int videoId;
  final int positionMs;
  final int durationMs;
  final double completionPercentage;
  final int lastWatchedTimestamp; // epoch millis

  const WatchHistory({
    this.id,
    required this.videoId,
    this.positionMs = 0,
    this.durationMs = 0,
    this.completionPercentage = 0.0,
    this.lastWatchedTimestamp = 0,
  });

  WatchHistory copyWith({
    int? id,
    int? videoId,
    int? positionMs,
    int? durationMs,
    double? completionPercentage,
    int? lastWatchedTimestamp,
  }) {
    return WatchHistory(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      lastWatchedTimestamp: lastWatchedTimestamp ?? this.lastWatchedTimestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'video_id': videoId,
      'position_ms': positionMs,
      'duration_ms': durationMs,
      'completion_percentage': completionPercentage,
      'last_watched_timestamp': lastWatchedTimestamp,
    };
  }

  factory WatchHistory.fromMap(Map<String, dynamic> map) {
    return WatchHistory(
      id: map['id'] as int?,
      videoId: map['video_id'] as int? ?? 0,
      positionMs: map['position_ms'] as int? ?? 0,
      durationMs: map['duration_ms'] as int? ?? 0,
      completionPercentage: (map['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      lastWatchedTimestamp: map['last_watched_timestamp'] as int? ?? 0,
    );
  }

  /// Formatted position string (e.g., "01:14:28")
  String get formattedPosition {
    final d = Duration(milliseconds: positionMs);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Whether the video is considered completed (>= 95%)
  bool get isCompleted => completionPercentage >= 0.95;
}
