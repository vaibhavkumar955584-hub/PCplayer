/// Status of an asynchronous subtitle generation or translation job.
enum SubtitleJobStatus {
  queued,
  extractingAudio,
  transcribing,
  translating,
  completed,
  failed;

  String get label {
    switch (this) {
      case SubtitleJobStatus.queued:
        return 'Queued';
      case SubtitleJobStatus.extractingAudio:
        return 'Extracting audio...';
      case SubtitleJobStatus.transcribing:
        return 'Transcribing speech...';
      case SubtitleJobStatus.translating:
        return 'Translating subtitles...';
      case SubtitleJobStatus.completed:
        return 'Completed';
      case SubtitleJobStatus.failed:
        return 'Failed';
    }
  }
}

/// Persistent record of an AI subtitle background task.
class SubtitleJobRecord {
  final String id;
  final int videoId;
  final String sourceLanguage;
  final String targetLanguage;
  final SubtitleJobStatus status;
  final double progress; // 0.0 to 1.0
  final String? error;
  final int createdAt;
  final int? completedAt;

  const SubtitleJobRecord({
    required this.id,
    required this.videoId,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.status,
    this.progress = 0.0,
    this.error,
    required this.createdAt,
    this.completedAt,
  });

  bool get isFinished => status == SubtitleJobStatus.completed || status == SubtitleJobStatus.failed;

  SubtitleJobRecord copyWith({
    SubtitleJobStatus? status,
    double? progress,
    String? error,
    int? completedAt,
  }) {
    return SubtitleJobRecord(
      id: id,
      videoId: videoId,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'video_id': videoId,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'status': status.name,
      'progress': progress,
      'error': error,
      'created_at': createdAt,
      'completed_at': completedAt,
    };
  }

  factory SubtitleJobRecord.fromMap(Map<String, dynamic> map) {
    return SubtitleJobRecord(
      id: map['id'] as String,
      videoId: map['video_id'] as int,
      sourceLanguage: map['source_language'] as String? ?? 'en',
      targetLanguage: map['target_language'] as String? ?? 'en',
      status: SubtitleJobStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SubtitleJobStatus.queued,
      ),
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      error: map['error'] as String?,
      createdAt: map['created_at'] as int? ?? 0,
      completedAt: map['completed_at'] as int?,
    );
  }
}

/// A timed utterance generated from speech recognition.
class TranscriptSegment {
  final int startMs;
  final int endMs;
  final String text;
  final double confidence;

  const TranscriptSegment({
    required this.startMs,
    required this.endMs,
    required this.text,
    this.confidence = 1.0,
  });

  Duration get start => Duration(milliseconds: startMs);
  Duration get end => Duration(milliseconds: endMs);

  Map<String, dynamic> toMap() {
    return {
      'start_ms': startMs,
      'end_ms': endMs,
      'text': text,
      'confidence': confidence,
    };
  }

  factory TranscriptSegment.fromMap(Map<String, dynamic> map) {
    return TranscriptSegment(
      startMs: map['start_ms'] as int,
      endMs: map['end_ms'] as int,
      text: map['text'] as String,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Complete speech recognition transcript representing canonical spoken content of a video.
class Transcript {
  final String language;
  final List<TranscriptSegment> segments;
  final int durationMs;

  const Transcript({
    required this.language,
    required this.segments,
    this.durationMs = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'segments': segments.map((s) => s.toMap()).toList(),
      'duration_ms': durationMs,
    };
  }
}
