import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/models.dart';
import '../domain/ai_subtitle_models.dart';
import '../../subtitles/domain/subtitle_models.dart';
import 'ai_subtitle_provider.dart';

/// Central coordinator for AI speech-to-text, translation, and subtitle persistence.
/// Ensures transcription and translation run asynchronously without blocking playback or UI.
class AiSubtitleJobManager {
  static final AiSubtitleJobManager instance = AiSubtitleJobManager._internal();
  AiSubtitleJobManager._internal();

  final AiSubtitleProvider _defaultProvider = LocalAiSubtitleProvider();
  final StreamController<SubtitleJobRecord> _jobUpdatesController = StreamController<SubtitleJobRecord>.broadcast();

  Stream<SubtitleJobRecord> get jobUpdatesStream => _jobUpdatesController.stream;

  /// Starts or resumes an AI subtitle generation job for [video] into [targetLanguage].
  Future<DbSubtitleTrack> generateSubtitles({
    required Video video,
    required String targetLanguage,
    String? sourceLanguage,
    AiSubtitleProvider? provider,
    void Function(double progress, String status)? onProgress,
  }) async {
    final aiProvider = provider ?? _defaultProvider;
    final videoId = video.id ?? 0;
    final jobId = 'job_${videoId}_${targetLanguage}_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Check if target subtitle track already exists in SQLite cache
    final existingTracks = await AppDatabase.getSubtitleTracksForVideo(videoId);
    final cachedTarget = existingTracks.where((t) => t.languageCode == targetLanguage).firstOrNull;
    if (cachedTarget != null) {
      onProgress?.call(1.0, 'Loaded from local cache');
      return cachedTarget;
    }

    // 2. Initialize job record in SQLite
    var job = SubtitleJobRecord(
      id: jobId,
      videoId: videoId,
      sourceLanguage: sourceLanguage ?? 'auto',
      targetLanguage: targetLanguage,
      status: SubtitleJobStatus.queued,
      progress: 0.05,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await AppDatabase.insertSubtitleJob(job);
    _broadcastJobUpdate(job);

    try {
      // 3. Check for existing canonical transcript track to avoid re-transcribing
      DbSubtitleTrack? canonicalTrack = existingTracks.where((t) => t.isAiGenerated && !t.isTranslated).firstOrNull;
      List<DbSubtitleSegment> canonicalSegments = [];

      if (canonicalTrack != null && canonicalTrack.id != null) {
        canonicalSegments = await AppDatabase.getSubtitleSegmentsForTrack(canonicalTrack.id!);
      }

      // If no canonical transcript found, perform audio transcription
      if (canonicalSegments.isEmpty) {
        job = job.copyWith(status: SubtitleJobStatus.transcribing, progress: 0.2);
        await AppDatabase.updateSubtitleJob(job);
        _broadcastJobUpdate(job);

        final transcript = await aiProvider.transcribe(
          video.path,
          onProgress: (p, msg) {
            final overall = 0.2 + (p * 0.4);
            onProgress?.call(overall, msg);
            _broadcastJobUpdate(job.copyWith(progress: overall));
          },
        );

        // Save canonical track to SQLite
        final canonicalTrackId = await AppDatabase.insertSubtitleTrack(DbSubtitleTrack(
          videoId: videoId,
          languageCode: transcript.language,
          languageName: _languageDisplayName(transcript.language),
          sourceType: 'ai_generated',
          isAiGenerated: true,
          isTranslated: false,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ));

        canonicalSegments = transcript.segments.asMap().entries.map((e) {
          return DbSubtitleSegment(
            subtitleTrackId: canonicalTrackId,
            startMs: e.value.startMs,
            endMs: e.value.endMs,
            text: e.value.text,
            sequence: e.key + 1,
          );
        }).toList();

        await AppDatabase.insertSubtitleSegments(canonicalTrackId, canonicalSegments);

        canonicalTrack = DbSubtitleTrack(
          id: canonicalTrackId,
          videoId: videoId,
          languageCode: transcript.language,
          languageName: _languageDisplayName(transcript.language),
          sourceType: 'ai_generated',
          isAiGenerated: true,
          isTranslated: false,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }

      // If requested target language is the same as the canonical language, we are done!
      if (canonicalTrack != null && canonicalTrack.languageCode.toLowerCase() == targetLanguage.toLowerCase()) {
        job = job.copyWith(
          status: SubtitleJobStatus.completed,
          progress: 1.0,
          completedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await AppDatabase.updateSubtitleJob(job);
        _broadcastJobUpdate(job);
        onProgress?.call(1.0, 'Ready');
        return canonicalTrack;
      }

      // 4. Translate canonical segments into target language
      job = job.copyWith(status: SubtitleJobStatus.translating, progress: 0.65);
      await AppDatabase.updateSubtitleJob(job);
      _broadcastJobUpdate(job);

      final translatedTrackId = await AppDatabase.insertSubtitleTrack(DbSubtitleTrack(
        videoId: videoId,
        languageCode: targetLanguage,
        languageName: _languageDisplayName(targetLanguage),
        sourceType: 'ai_generated',
        isAiGenerated: true,
        isTranslated: true,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));

      final translatedSegments = await aiProvider.translate(
        canonicalSegments,
        targetLanguage,
        onProgress: (p, msg) {
          final overall = 0.65 + (p * 0.3);
          onProgress?.call(overall, msg);
          _broadcastJobUpdate(job.copyWith(progress: overall));
        },
      );

      final dbTranslatedSegments = translatedSegments.asMap().entries.map((e) {
        return DbSubtitleSegment(
          subtitleTrackId: translatedTrackId,
          startMs: e.value.startMs,
          endMs: e.value.endMs,
          text: e.value.text,
          sequence: e.key + 1,
        );
      }).toList();

      await AppDatabase.insertSubtitleSegments(translatedTrackId, dbTranslatedSegments);

      final finalTrack = DbSubtitleTrack(
        id: translatedTrackId,
        videoId: videoId,
        languageCode: targetLanguage,
        languageName: _languageDisplayName(targetLanguage),
        sourceType: 'ai_generated',
        isAiGenerated: true,
        isTranslated: true,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Mark job completed
      job = job.copyWith(
        status: SubtitleJobStatus.completed,
        progress: 1.0,
        completedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await AppDatabase.updateSubtitleJob(job);
      _broadcastJobUpdate(job);
      onProgress?.call(1.0, 'Completed');

      return finalTrack;
    } catch (e) {
      job = job.copyWith(
        status: SubtitleJobStatus.failed,
        error: e.toString(),
        completedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await AppDatabase.updateSubtitleJob(job);
      _broadcastJobUpdate(job);
      rethrow;
    }
  }

  void _broadcastJobUpdate(SubtitleJobRecord job) {
    if (!_jobUpdatesController.isClosed) {
      _jobUpdatesController.add(job);
    }
  }

  String _languageDisplayName(String code) {
    switch (code.toLowerCase()) {
      case 'hi':
        return 'Hindi (हिन्दी)';
      case 'es':
        return 'Spanish (Español)';
      case 'fr':
        return 'French (Français)';
      case 'de':
        return 'German (Deutsch)';
      case 'ja':
        return 'Japanese (日本語)';
      case 'ar':
        return 'Arabic (العربية)';
      case 'pt':
        return 'Portuguese (Português)';
      case 'ru':
        return 'Russian (Русский)';
      case 'zh':
        return 'Chinese (中文)';
      default:
        return 'English';
    }
  }
}

/// Riverpod providers for AI Subtitle Job Management
final aiSubtitleJobManagerProvider = Provider<AiSubtitleJobManager>((ref) {
  return AiSubtitleJobManager.instance;
});

final aiSubtitleJobStreamProvider = StreamProvider<SubtitleJobRecord>((ref) {
  return AiSubtitleJobManager.instance.jobUpdatesStream;
});
