import '../domain/ai_chapter_model.dart';
import '../domain/ai_subtitle_models.dart';
import '../../subtitles/domain/subtitle_models.dart';

/// Service for generating AI chapters and summaries directly from existing transcripts or subtitle segments.
/// Operates 100% locally and never requires re-transcription.
class AiSummaryService {
  /// Generates a structured summary from a canonical [Transcript].
  static AiSummaryResult generateFromTranscript(Transcript transcript, {String videoTitle = 'Video'}) {
    if (transcript.segments.isEmpty) {
      return AiSummaryResult(
        overview: 'No dialogue detected for $videoTitle.',
        keyPoints: ['No spoken content available to summarize.'],
        chapters: [],
      );
    }

    final chapters = _buildChaptersFromSegments(
      transcript.segments.map((s) => (startMs: s.startMs, endMs: s.endMs, text: s.text)).toList(),
      videoTitle: videoTitle,
    );

    final keyPoints = _extractKeyPoints(transcript.segments.map((s) => s.text).toList(), videoTitle);

    final overview = 'Summary of $videoTitle containing ${transcript.segments.length} dialogue segments '
        'across ${chapters.length} topical section${chapters.length == 1 ? '' : 's'}.';

    return AiSummaryResult(
      overview: overview,
      keyPoints: keyPoints,
      chapters: chapters,
    );
  }

  /// Generates a structured summary from existing SQLite [DbSubtitleSegment] list.
  static AiSummaryResult generateFromSegments(List<DbSubtitleSegment> segments, {String videoTitle = 'Video'}) {
    if (segments.isEmpty) {
      return AiSummaryResult(
        overview: 'No subtitle dialogue available for $videoTitle.',
        keyPoints: ['Generate subtitles first to unlock AI Chapters and Summaries.'],
        chapters: [],
      );
    }

    final chapters = _buildChaptersFromSegments(
      segments.map((s) => (startMs: s.startMs, endMs: s.endMs, text: s.text)).toList(),
      videoTitle: videoTitle,
    );

    final keyPoints = _extractKeyPoints(segments.map((s) => s.text).toList(), videoTitle);

    final overview = 'Overview of $videoTitle detailing key themes and ${chapters.length} highlighted chapter markers.';

    return AiSummaryResult(
      overview: overview,
      keyPoints: keyPoints,
      chapters: chapters,
    );
  }

  static List<AiChapter> _buildChaptersFromSegments(
    List<({int startMs, int endMs, String text})> items, {
    required String videoTitle,
  }) {
    if (items.isEmpty) return [];

    final List<AiChapter> chapters = [];
    final int totalCount = items.length;

    // Group segments into logical chapters based on segment count or time chunks
    const int targetChapterCount = 4;
    final int chunkSize = (totalCount / targetChapterCount).ceil().clamp(1, 50);

    for (int i = 0; i < totalCount; i += chunkSize) {
      final chunk = items.sublist(i, (i + chunkSize).clamp(0, totalCount));
      final startMs = chunk.first.startMs;
      final endMs = chunk.last.endMs;

      final chunkText = chunk.map((c) => c.text).join(' ');
      final title = _synthesizeChapterTitle(i ~/ chunkSize, chunkText, videoTitle);
      final summary = _truncateSummary(chunkText);

      chapters.add(AiChapter(
        startMs: startMs,
        endMs: endMs,
        title: title,
        summary: summary,
      ));
    }

    return chapters;
  }

  static String _synthesizeChapterTitle(int index, String text, String videoTitle) {
    if (index == 0) return 'Introduction & Overview';
    final words = text.split(RegExp(r'\s+')).where((w) => w.length > 3).toList();
    if (words.length >= 3) {
      final sample = words.take(3).map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
      return 'Topic $index: $sample';
    }
    return 'Chapter ${index + 1}';
  }

  static String _truncateSummary(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length > 140) {
      return '${cleaned.substring(0, 137)}...';
    }
    return cleaned;
  }

  static List<String> _extractKeyPoints(List<String> texts, String videoTitle) {
    final List<String> points = [];
    final combined = texts.join(' ');
    final sentences = combined
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 15 && s.length < 160)
        .toList();

    if (sentences.isNotEmpty) {
      // Pick representative sentences across the timeline
      final step = (sentences.length / 4).ceil().clamp(1, 20);
      for (int i = 0; i < sentences.length && points.length < 4; i += step) {
        points.add(sentences[i]);
      }
    }

    if (points.isEmpty) {
      points.add('Contains ${texts.length} spoken dialogue segments.');
      points.add('Audio and subtitle tracks mapped for $videoTitle.');
    }

    return points;
  }
}
