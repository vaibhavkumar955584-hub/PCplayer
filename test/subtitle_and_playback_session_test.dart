import 'package:flutter_test/flutter_test.dart';
import 'package:velo_player/core/models/models.dart';
import 'package:velo_player/core/services/subtitle_service.dart';
import 'package:velo_player/features/player/player_state.dart';
import 'package:velo_player/features/subtitles/domain/subtitle_appearance.dart';
import 'package:velo_player/features/ai_subtitles/domain/ai_subtitle_models.dart';

void main() {
  group('SubtitleService Binary Search & Synchronization', () {
    final entries = [
      const SubtitleEntry(
        start: Duration(seconds: 1),
        end: Duration(seconds: 4),
        text: 'Hello world',
      ),
      const SubtitleEntry(
        start: Duration(seconds: 6),
        end: Duration(seconds: 9),
        text: 'Welcome to VDO Player',
      ),
      const SubtitleEntry(
        start: Duration(seconds: 10),
        end: Duration(seconds: 14),
        text: 'Local first playback engine',
      ),
    ];

    test('returns null when position is before the first cue', () {
      final active = SubtitleService.findActive(entries, const Duration(milliseconds: 500));
      expect(active, isNull);
    });

    test('finds cue when position is inside the first cue', () {
      final active = SubtitleService.findActive(entries, const Duration(seconds: 2));
      expect(active, isNotNull);
      expect(active!.text, 'Hello world');
    });

    test('finds cue at exact start timestamp boundary', () {
      final active = SubtitleService.findActive(entries, const Duration(seconds: 1));
      expect(active, isNotNull);
      expect(active!.text, 'Hello world');
    });

    test('finds cue at exact end timestamp boundary', () {
      final active = SubtitleService.findActive(entries, const Duration(seconds: 4));
      expect(active, isNotNull);
      expect(active!.text, 'Hello world');
    });

    test('returns null when position falls in a gap between cues', () {
      final active = SubtitleService.findActive(entries, const Duration(seconds: 5));
      expect(active, isNull);
    });

    test('finds second cue accurately', () {
      final active = SubtitleService.findActive(entries, const Duration(seconds: 7));
      expect(active, isNotNull);
      expect(active!.text, 'Welcome to VDO Player');
    });

    test('finds third cue accurately', () {
      final active = SubtitleService.findActive(entries, const Duration(seconds: 12));
      expect(active, isNotNull);
      expect(active!.text, 'Local first playback engine');
    });

    test('returns null when position is after the last cue', () {
      final active = SubtitleService.findActive(entries, const Duration(seconds: 20));
      expect(active, isNull);
    });
  });

  group('Subtitle Exporting (.srt)', () {
    test('exports formatted SubRip text with proper numbering and timestamps', () {
      final entries = [
        const SubtitleEntry(
          start: Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 450),
          end: Duration(hours: 1, minutes: 2, seconds: 7, milliseconds: 800),
          text: 'Spoken dialogue line',
        ),
      ];

      final srt = SubtitleService.exportToSrt(entries);
      expect(srt, contains('1\n'));
      expect(srt, contains('01:02:03,450 --> 01:02:07,800\n'));
      expect(srt, contains('Spoken dialogue line\n'));
    });
  });

  group('PlaybackSession Entity', () {
    final video1 = Video(id: 1, title: 'Video 1', path: '/path/1.mp4', folderName: 'Movies');
    final video2 = Video(id: 2, title: 'Video 2', path: '/path/2.mp4', folderName: 'Movies');
    final queue = PlaybackQueue.fromVideos(videos: [video1, video2], initialIndex: 0);

    test('maintains session parameters correctly', () {
      final session = PlaybackSession(
        currentVideo: video1,
        queue: queue,
        repeatMode: PlaybackRepeatMode.all,
        isShuffled: false,
        scaleMode: VideoScaleMode.fill,
      );

      expect(session.currentVideo?.title, 'Video 1');
      expect(session.hasNext, isTrue);
      expect(session.hasPrevious, isFalse);
      expect(session.repeatMode, PlaybackRepeatMode.all);
      expect(session.scaleMode, VideoScaleMode.fill);
    });
  });

  group('Subtitle Appearance Presets', () {
    test('loads distinct styling attributes for each preset', () {
      final cinema = SubtitleAppearance.fromPreset(SubtitlePreset.cinema);
      expect(cinema.preset, SubtitlePreset.cinema);
      expect(cinema.backgroundOpacity, greaterThan(0.0));

      final netflix = SubtitleAppearance.fromPreset(SubtitlePreset.netflix);
      expect(netflix.preset, SubtitlePreset.netflix);
      expect(netflix.hasOutline, isTrue);
      expect(netflix.backgroundOpacity, 0.0);

      final classic = SubtitleAppearance.fromPreset(SubtitlePreset.classic);
      expect(classic.preset, SubtitlePreset.classic);
      expect(classic.textColor.toARGB32(), 0xFFFFFF00); // Yellow
    });
  });

  group('AI Subtitle Job Status', () {
    test('job record correctly computes isFinished state', () {
      final runningJob = SubtitleJobRecord(
        id: 'job_1',
        videoId: 1,
        sourceLanguage: 'en',
        targetLanguage: 'hi',
        status: SubtitleJobStatus.transcribing,
        progress: 0.4,
        createdAt: 1000,
      );
      expect(runningJob.isFinished, isFalse);

      final completedJob = runningJob.copyWith(status: SubtitleJobStatus.completed, progress: 1.0);
      expect(completedJob.isFinished, isTrue);
    });
  });
}
