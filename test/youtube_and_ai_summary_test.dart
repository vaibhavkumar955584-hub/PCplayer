import 'package:flutter_test/flutter_test.dart';
import 'package:velo_player/core/models/models.dart';
import 'package:velo_player/features/youtube/utils/youtube_url_parser.dart';
import 'package:velo_player/features/ai_subtitles/domain/ai_subtitle_models.dart';
import 'package:velo_player/features/ai_subtitles/data/ai_summary_service.dart';
import 'package:velo_player/features/subtitles/domain/subtitle_models.dart';

void main() {
  group('YouTubeUrlParser URL Recognition & Extraction', () {
    test('extracts videoId from standard youtube.com watch URL', () {
      const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      expect(YouTubeUrlParser.isYouTubeUrl(url), isTrue);
      final info = YouTubeUrlParser.parse(url);
      expect(info, isNotNull);
      expect(info!.videoId, 'dQw4w9WgXcQ');
      expect(info.startSeconds, 0);
      expect(info.thumbnailUrl, 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg');
    });

    test('extracts videoId from short youtu.be URL', () {
      const url = 'https://youtu.be/dQw4w9WgXcQ';
      expect(YouTubeUrlParser.isYouTubeUrl(url), isTrue);
      final info = YouTubeUrlParser.parse(url);
      expect(info, isNotNull);
      expect(info!.videoId, 'dQw4w9WgXcQ');
      expect(info.startSeconds, 0);
    });

    test('extracts videoId and start timestamp ?t=120 from youtu.be URL', () {
      const url = 'https://youtu.be/dQw4w9WgXcQ?t=120';
      final info = YouTubeUrlParser.parse(url);
      expect(info, isNotNull);
      expect(info!.videoId, 'dQw4w9WgXcQ');
      expect(info.startSeconds, 120);
      expect(info.embedUrl, contains('start=120'));
    });

    test('extracts minute-second timestamp ?t=2m30s', () {
      const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=2m30s';
      final info = YouTubeUrlParser.parse(url);
      expect(info, isNotNull);
      expect(info!.startSeconds, 150);
    });

    test('extracts hour-minute-second timestamp ?t=1h2m3s', () {
      const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=1h2m3s';
      final info = YouTubeUrlParser.parse(url);
      expect(info, isNotNull);
      expect(info!.startSeconds, 3600 + 120 + 3);
    });

    test('extracts videoId from YouTube Shorts URL', () {
      const url = 'https://www.youtube.com/shorts/dQw4w9WgXcQ';
      expect(YouTubeUrlParser.isYouTubeUrl(url), isTrue);
      final info = YouTubeUrlParser.parse(url);
      expect(info, isNotNull);
      expect(info!.videoId, 'dQw4w9WgXcQ');
    });

    test('extracts videoId from mobile m.youtube.com URL', () {
      const url = 'https://m.youtube.com/watch?v=dQw4w9WgXcQ';
      expect(YouTubeUrlParser.isYouTubeUrl(url), isTrue);
      final info = YouTubeUrlParser.parse(url);
      expect(info, isNotNull);
      expect(info!.videoId, 'dQw4w9WgXcQ');
    });

    test('extracts videoId from direct 11-character videoId', () {
      const id = 'dQw4w9WgXcQ';
      expect(YouTubeUrlParser.isYouTubeUrl(id), isTrue);
      final info = YouTubeUrlParser.parse(id);
      expect(info, isNotNull);
      expect(info!.videoId, 'dQw4w9WgXcQ');
    });

    test('extracts videoId from YouTube URLs with tracking & share params', () {
      const url = 'https://youtu.be/dQw4w9WgXcQ?si=abc123xyz&feature=shared';
      expect(YouTubeUrlParser.isYouTubeUrl(url), isTrue);
      final info = YouTubeUrlParser.parse(url);
      expect(info, isNotNull);
      expect(info!.videoId, 'dQw4w9WgXcQ');
    });

    test('returns null for non-YouTube URLs and empty strings', () {
      expect(YouTubeUrlParser.isYouTubeUrl('https://example.com/video.mp4'), isFalse);
      expect(YouTubeUrlParser.parse('https://example.com/video.mp4'), isNull);
      expect(YouTubeUrlParser.isYouTubeUrl(''), isFalse);
      expect(YouTubeUrlParser.parse(''), isNull);
    });
  });

  group('AiSummaryService & AI Chapters', () {
    test('generates overview, key takeaways, and chapters from canonical Transcript', () {
      const transcript = Transcript(
        language: 'en',
        segments: [
          TranscriptSegment(startMs: 0, endMs: 4000, text: 'Welcome to this Flutter tutorial on video players.'),
          TranscriptSegment(startMs: 4500, endMs: 9000, text: 'Today we will discuss local media management and architectures.'),
          TranscriptSegment(startMs: 9500, endMs: 15000, text: 'We also implement offline AI subtitle generation and translations.'),
          TranscriptSegment(startMs: 15500, endMs: 22000, text: 'Finally we connect embedded YouTube playback and persistence.'),
        ],
        durationMs: 22000,
      );

      final summary = AiSummaryService.generateFromTranscript(transcript, videoTitle: 'Tutorial Video');
      expect(summary.overview, contains('Tutorial Video'));
      expect(summary.chapters.isNotEmpty, isTrue);
      expect(summary.keyPoints.isNotEmpty, isTrue);
      expect(summary.chapters.first.startMs, 0);
      expect(summary.chapters.first.formattedStartTime, '00:00');
    });

    test('generates summary from DbSubtitleSegment list', () {
      final List<DbSubtitleSegment> segments = [
        const DbSubtitleSegment(subtitleTrackId: 1, startMs: 1000, endMs: 5000, text: 'Machine learning powers intelligent transcription.', sequence: 1),
        const DbSubtitleSegment(subtitleTrackId: 1, startMs: 5500, endMs: 12000, text: 'This works completely offline on modern devices.', sequence: 2),
      ];

      final summary = AiSummaryService.generateFromSegments(segments, videoTitle: 'AI Overview');
      expect(summary.overview, contains('AI Overview'));
      expect(summary.chapters.isNotEmpty, isTrue);
    });

    test('handles empty transcript gracefully without crashing', () {
      const emptyTranscript = Transcript(language: 'en', segments: []);
      final summary = AiSummaryService.generateFromTranscript(emptyTranscript, videoTitle: 'Empty Video');
      expect(summary.chapters, isEmpty);
      expect(summary.overview, contains('No dialogue detected'));
    });
  });

  group('Unified Media Model (MediaSourceType)', () {
    test('instantiates and serializes local Video', () {
      const video = Video(
        id: 10,
        path: '/storage/emulated/0/Movies/sample.mp4',
        title: 'Sample Video',
        folderName: 'Movies',
        sourceType: MediaSourceType.local,
      );

      expect(video.isLocal, isTrue);
      expect(video.isYouTube, isFalse);

      final map = video.toMap();
      expect(map['source_type'], 'local');

      final restored = Video.fromMap(map);
      expect(restored.sourceType, MediaSourceType.local);
      expect(restored.title, 'Sample Video');
    });

    test('instantiates and serializes YouTube Video', () {
      const video = Video(
        id: 20,
        path: 'https://youtube.com/watch?v=dQw4w9WgXcQ',
        title: 'YouTube Video (dQw4w9WgXcQ)',
        folderName: 'YouTube',
        sourceType: MediaSourceType.youtube,
        externalUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        externalId: 'dQw4w9WgXcQ',
        thumbnailPath: 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      );

      expect(video.isYouTube, isTrue);
      expect(video.isLocal, isFalse);

      final map = video.toMap();
      expect(map['source_type'], 'youtube');
      expect(map['external_id'], 'dQw4w9WgXcQ');

      final restored = Video.fromMap(map);
      expect(restored.sourceType, MediaSourceType.youtube);
      expect(restored.externalId, 'dQw4w9WgXcQ');
      expect(restored.thumbnailPath, contains('img.youtube.com'));
    });
  });
}
