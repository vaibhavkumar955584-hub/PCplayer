/// Represents a subtitle track stored in the SQLite database.
class DbSubtitleTrack {
  final int? id;
  final int videoId;
  final String languageCode;
  final String languageName;
  final String sourceType; // 'embedded', 'sidecar', 'external', 'ai_generated'
  final String? filePath;
  final bool isAiGenerated;
  final bool isTranslated;
  final int createdAt;
  final int updatedAt;

  const DbSubtitleTrack({
    this.id,
    required this.videoId,
    required this.languageCode,
    required this.languageName,
    required this.sourceType,
    this.filePath,
    this.isAiGenerated = false,
    this.isTranslated = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'video_id': videoId,
      'language_code': languageCode,
      'language_name': languageName,
      'source_type': sourceType,
      'file_path': filePath,
      'is_ai_generated': isAiGenerated ? 1 : 0,
      'is_translated': isTranslated ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory DbSubtitleTrack.fromMap(Map<String, dynamic> map) {
    return DbSubtitleTrack(
      id: map['id'] as int?,
      videoId: map['video_id'] as int,
      languageCode: map['language_code'] as String? ?? 'en',
      languageName: map['language_name'] as String? ?? 'English',
      sourceType: map['source_type'] as String? ?? 'sidecar',
      filePath: map['file_path'] as String?,
      isAiGenerated: (map['is_ai_generated'] as int? ?? 0) == 1,
      isTranslated: (map['is_translated'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as int? ?? 0,
      updatedAt: map['updated_at'] as int? ?? 0,
    );
  }
}

/// Represents a discrete subtitle cue/segment stored in SQLite.
class DbSubtitleSegment {
  final int? id;
  final int subtitleTrackId;
  final int startMs;
  final int endMs;
  final String text;
  final int sequence;

  const DbSubtitleSegment({
    this.id,
    required this.subtitleTrackId,
    required this.startMs,
    required this.endMs,
    required this.text,
    this.sequence = 0,
  });

  Duration get start => Duration(milliseconds: startMs);
  Duration get end => Duration(milliseconds: endMs);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subtitle_track_id': subtitleTrackId,
      'start_ms': startMs,
      'end_ms': endMs,
      'text': text,
      'sequence': sequence,
    };
  }

  factory DbSubtitleSegment.fromMap(Map<String, dynamic> map) {
    return DbSubtitleSegment(
      id: map['id'] as int?,
      subtitleTrackId: map['subtitle_track_id'] as int,
      startMs: map['start_ms'] as int,
      endMs: map['end_ms'] as int,
      text: map['text'] as String,
      sequence: map['sequence'] as int? ?? 0,
    );
  }
}

/// Result returned when searching spoken subtitle dialogues across the library.
class SubtitleSearchResult {
  final int videoId;
  final String videoTitle;
  final String videoPath;
  final int trackId;
  final String languageCode;
  final String languageName;
  final int segmentId;
  final int startMs;
  final int endMs;
  final String text;

  const SubtitleSearchResult({
    required this.videoId,
    required this.videoTitle,
    required this.videoPath,
    required this.trackId,
    required this.languageCode,
    required this.languageName,
    required this.segmentId,
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  Duration get timestamp => Duration(milliseconds: startMs);

  factory SubtitleSearchResult.fromMap(Map<String, dynamic> map) {
    return SubtitleSearchResult(
      videoId: map['video_id'] as int,
      videoTitle: map['title'] as String? ?? 'Untitled Video',
      videoPath: map['path'] as String? ?? '',
      trackId: map['track_id'] as int,
      languageCode: map['language_code'] as String? ?? 'en',
      languageName: map['language_name'] as String? ?? 'English',
      segmentId: map['segment_id'] as int,
      startMs: map['start_ms'] as int,
      endMs: map['end_ms'] as int,
      text: map['text'] as String,
    );
  }
}
