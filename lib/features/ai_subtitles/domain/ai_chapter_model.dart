/// An AI-generated chapter marker derived from the canonical transcript.
class AiChapter {
  final int startMs;
  final int endMs;
  final String title;
  final String summary;

  const AiChapter({
    required this.startMs,
    required this.endMs,
    required this.title,
    this.summary = '',
  });

  Duration get start => Duration(milliseconds: startMs);
  Duration get end => Duration(milliseconds: endMs);

  String get formattedStartTime {
    final dur = Duration(milliseconds: startMs);
    final minutes = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (dur.inHours > 0) {
      return '${dur.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Map<String, dynamic> toMap() => {
        'start_ms': startMs,
        'end_ms': endMs,
        'title': title,
        'summary': summary,
      };

  factory AiChapter.fromMap(Map<String, dynamic> map) => AiChapter(
        startMs: map['start_ms'] as int? ?? 0,
        endMs: map['end_ms'] as int? ?? 0,
        title: map['title'] as String? ?? '',
        summary: map['summary'] as String? ?? '',
      );
}

/// Structured AI summary containing an overview, key takeaways, and chapter breakdown.
class AiSummaryResult {
  final String overview;
  final List<String> keyPoints;
  final List<AiChapter> chapters;

  const AiSummaryResult({
    required this.overview,
    required this.keyPoints,
    required this.chapters,
  });

  Map<String, dynamic> toMap() => {
        'overview': overview,
        'key_points': keyPoints,
        'chapters': chapters.map((c) => c.toMap()).toList(),
      };

  factory AiSummaryResult.fromMap(Map<String, dynamic> map) => AiSummaryResult(
        overview: map['overview'] as String? ?? '',
        keyPoints: (map['key_points'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        chapters: (map['chapters'] as List<dynamic>?)
                ?.map((c) => AiChapter.fromMap(c as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
