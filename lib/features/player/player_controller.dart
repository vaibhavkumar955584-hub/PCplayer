import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/subtitle_service.dart';
import '../subtitles/domain/subtitle_appearance.dart';
import '../subtitles/domain/subtitle_models.dart';
import '../youtube/services/youtube_extractor_service.dart';
import '../youtube/utils/youtube_url_parser.dart';
import 'player_state.dart';

class PlayerController extends StateNotifier<PlayerState> {
  final Ref ref;
  VideoPlayerController? _videoController;
  Timer? _controlsTimer;
  Timer? _saveHistoryTimer;
  Timer? _gestureFeedbackTimer;
  bool _isDisposed = false;
  int _lastSavedPositionMs = 0;
  bool _isScrubbing = false;

  PlayerController(
    this.ref, {
    required int initialVideoId,
    List<int>? queue,
    String? networkUrl,
    QueueSource source = QueueSource.library,
    String? sourceTitle,
  }) : super(PlayerState(
          queue: PlaybackQueue(
            items: const [],
            currentActiveIndex: 0,
            repeatMode: _parseRepeatMode(SettingsService.repeatMode),
            isShuffled: SettingsService.shuffleEnabled,
            source: source,
            sourceTitle: sourceTitle,
          ),
          playbackSpeed: SettingsService.defaultPlaybackSpeed,
          scaleMode: _parseScaleMode(SettingsService.scaleMode),
          showRemainingTime: SettingsService.showRemainingTime,
          subtitleSize: SettingsService.subtitleSize,
        )) {
    _initQueueAndStart(initialVideoId, queue: queue, networkUrl: networkUrl);
  }

  static PlaybackRepeatMode _parseRepeatMode(String mode) {
    switch (mode) {
      case 'all':
        return PlaybackRepeatMode.all;
      case 'one':
        return PlaybackRepeatMode.one;
      default:
        return PlaybackRepeatMode.none;
    }
  }

  static VideoScaleMode _parseScaleMode(String mode) {
    switch (mode) {
      case 'fill':
        return VideoScaleMode.fill;
      case 'stretch':
        return VideoScaleMode.stretch;
      case 'original':
        return VideoScaleMode.original;
      case 'zoom':
        return VideoScaleMode.zoom;
      default:
        return VideoScaleMode.fit;
    }
  }

  VideoPlayerController? get videoPlayerController => _videoController;

  // ─── Queue & Video Initialization ───────────────────────────────

  Future<void> _initQueueAndStart(int initialVideoId, {List<int>? queue, String? networkUrl}) async {
    if (_isDisposed) return;

    if (networkUrl != null) {
      await loadVideoFromUrl(networkUrl);
      return;
    }

    final idList = queue ?? [initialVideoId];
    final List<Video> loadedVideos = [];

    for (final id in idList) {
      final v = await AppDatabase.getVideoById(id);
      if (v != null) loadedVideos.add(v);
    }

    if (loadedVideos.isEmpty) {
      // Try loading single initial video directly
      final single = await AppDatabase.getVideoById(initialVideoId);
      if (single != null) loadedVideos.add(single);
    }

    final initialIdx = loadedVideos.indexWhere((v) => v.id == initialVideoId);
    final safeIdx = initialIdx >= 0 ? initialIdx : 0;

    var initialQueue = PlaybackQueue.fromVideos(
      videos: loadedVideos,
      initialIndex: safeIdx,
      source: state.queue.source,
      sourceTitle: state.queue.sourceTitle,
      repeatMode: state.queue.repeatMode,
    );

    if (SettingsService.shuffleEnabled) {
      initialQueue = initialQueue.toggleShuffle();
    }

    state = state.copyWith(queue: initialQueue);

    if (loadedVideos.isNotEmpty) {
      final current = initialQueue.currentVideo;
      if (current != null && current.id != null) {
        await loadVideo(current.id!);
      }
    } else {
      await loadVideo(initialVideoId);
    }
  }

  // ─── Video Loading ──────────────────────────────────────────────

  Future<void> loadVideo(int videoId) async {
    if (_isDisposed) return;

    await _saveCurrentProgress();
    await _disposeCurrentController();

    state = state.copyWith(
      status: PlayerStatus.loading,
      errorMessage: null,
      isMissingFile: false,
      position: Duration.zero,
      duration: Duration.zero,
      buffered: Duration.zero,
      subtitles: const [],
      clearSubtitle: true,
      subtitleEnabled: false,
      clearResumePrompt: true,
    );

    try {
      final video = await AppDatabase.getVideoById(videoId);
      if (video == null) {
        if (!_isDisposed) {
          state = state.copyWith(
            status: PlayerStatus.error,
            errorMessage: 'Video not found in database.',
          );
        }
        return;
      }

      VideoPlayerController controller;
      final isYouTube = video.sourceType == MediaSourceType.youtube ||
          YouTubeUrlParser.isYouTubeUrl(video.path) ||
          (video.externalUrl != null && YouTubeUrlParser.isYouTubeUrl(video.externalUrl!));

      if (isYouTube) {
        final ytUrl = (video.externalUrl != null && video.externalUrl!.isNotEmpty)
            ? video.externalUrl!
            : video.path;
        final extraction = await YouTubeExtractorService.extract(ytUrl);
        controller = VideoPlayerController.networkUrl(Uri.parse(extraction.directStreamUrl));
      } else if (video.path.startsWith('http://') || video.path.startsWith('https://')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(video.path));
      } else {
        final file = File(video.path);
        if (!await file.exists()) {
          if (!_isDisposed) {
            state = state.copyWith(
              status: PlayerStatus.error,
              isMissingFile: true,
              errorMessage: 'File not found on device storage:\n${video.path}',
            );
          }
          return;
        }
        controller = VideoPlayerController.file(file);
      }

      await controller.initialize();

      if (_isDisposed) {
        await controller.dispose();
        return;
      }

      _videoController = controller;

      // Update queue active index if this video is in queue
      var updatedQueue = state.queue;
      final qIndex = state.queue.activeOrder.indexWhere((idx) {
        if (idx < 0 || idx >= state.queue.items.length) return false;
        return state.queue.items[idx].id == videoId;
      });
      if (qIndex >= 0) {
        updatedQueue = updatedQueue.moveTo(qIndex);
      }

      state = state.copyWith(
        video: video,
        queue: updatedQueue,
        status: PlayerStatus.ready,
        duration: controller.value.duration,
      );

      await controller.setPlaybackSpeed(state.playbackSpeed);
      await controller.setVolume(state.isMuted ? 0.0 : state.volume);

      // Check Watch History for Resume
      if (SettingsService.rememberPosition) {
        final history = await AppDatabase.getWatchHistory(videoId);
        if (history != null && history.positionMs > 1500 && !history.isCompleted) {
          final resumePosition = Duration(milliseconds: history.positionMs);
          await controller.seekTo(resumePosition);
          state = state.copyWith(
            position: resumePosition,
            resumePromptPosition: resumePosition,
          );
          // Dismiss resume badge after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isDisposed) state = state.copyWith(clearResumePrompt: true);
          });
        }
      }

      controller.addListener(_onVideoControllerUpdate);

      await controller.play();
      if (!_isDisposed) {
        state = state.copyWith(status: PlayerStatus.playing);
      }

      _startAutoSaveTimer();
      _startControlsTimer();

      // Auto-detect sidecar subtitles
      if (!video.path.startsWith('http') && !isYouTube) {
        _autoLoadSubtitles(video.path);
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          status: PlayerStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> loadVideoFromUrl(String url) async {
    if (_isDisposed) return;

    await _saveCurrentProgress();
    await _disposeCurrentController();

    state = state.copyWith(
      status: PlayerStatus.loading,
      errorMessage: null,
      isMissingFile: false,
      position: Duration.zero,
      duration: Duration.zero,
      buffered: Duration.zero,
      subtitles: const [],
      clearSubtitle: true,
      subtitleEnabled: false,
      clearResumePrompt: true,
    );

    try {
      final isYouTube = YouTubeUrlParser.isYouTubeUrl(url);
      final ytInfo = isYouTube ? YouTubeUrlParser.parse(url) : null;

      Video urlVideo;
      Uri streamUri;
      int startSeconds = 0;

      if (isYouTube && ytInfo != null) {
        final extraction = await YouTubeExtractorService.extract(url);
        streamUri = Uri.parse(extraction.directStreamUrl);
        startSeconds = extraction.startSeconds;

        urlVideo = Video(
          path: ytInfo.originalUrl,
          title: extraction.title.isNotEmpty ? extraction.title : 'YouTube Video (${ytInfo.videoId})',
          folderName: 'YouTube',
          sourceType: MediaSourceType.youtube,
          durationMs: extraction.duration.inMilliseconds,
          externalUrl: extraction.cleanUrl,
          externalId: extraction.videoId,
          thumbnailPath: extraction.thumbnailUrl,
          dateAdded: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );
      } else {
        final fileName = url.split('/').last.split('?').first;
        streamUri = Uri.parse(url);
        urlVideo = Video(
          path: url,
          title: fileName.isNotEmpty ? Uri.decodeComponent(fileName) : 'Network Stream',
          folderName: 'Online',
          dateAdded: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );
      }

      // Persist in database so it gets an ID for history and continue watching
      final dbId = await AppDatabase.insertOrUpdateExternalVideo(urlVideo);
      urlVideo = urlVideo.copyWith(id: dbId);

      final controller = VideoPlayerController.networkUrl(streamUri);
      await controller.initialize();

      if (_isDisposed) {
        await controller.dispose();
        return;
      }

      _videoController = controller;

      final queue = PlaybackQueue.single(urlVideo, source: QueueSource.directUrl);

      state = state.copyWith(
        video: urlVideo,
        queue: queue,
        status: PlayerStatus.ready,
        duration: controller.value.duration,
      );

      await controller.setPlaybackSpeed(state.playbackSpeed);
      await controller.setVolume(state.isMuted ? 0.0 : state.volume);
      controller.addListener(_onVideoControllerUpdate);

      // Handle start timestamp if specified in URL (e.g. ?t=120)
      if (startSeconds > 0) {
        final startPos = Duration(seconds: startSeconds);
        await controller.seekTo(startPos);
        state = state.copyWith(position: startPos);
      }

      await controller.play();
      if (!_isDisposed) {
        state = state.copyWith(status: PlayerStatus.playing);
      }

      _startAutoSaveTimer();
      _startControlsTimer();
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          status: PlayerStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  // ─── Subtitle Methods ───────────────────────────────────────────

  Future<void> _autoLoadSubtitles(String videoPath) async {
    final entries = await SubtitleService.autoDetect(videoPath);
    if (entries != null && entries.isNotEmpty && !_isDisposed) {
      final sidecarTrack = SubtitleTrack(
        id: 'sidecar',
        title: 'Sidecar Subtitles',
        isExternal: false,
      );
      state = state.copyWith(
        subtitles: entries,
        subtitleEnabled: true,
        subtitleTracks: [sidecarTrack],
        selectedSubtitleTrack: sidecarTrack,
      );
    }
  }

  Future<void> loadSubtitlesFromPicker() async {
    final entries = await SubtitleService.pickAndLoad();
    if (entries != null && !_isDisposed) {
      final customTrack = SubtitleTrack(
        id: 'external_${DateTime.now().millisecondsSinceEpoch}',
        title: 'External Subtitle File',
        isExternal: true,
      );
      final updatedTracks = [...state.subtitleTracks, customTrack];
      state = state.copyWith(
        subtitles: entries,
        subtitleEnabled: true,
        subtitleTracks: updatedTracks,
        selectedSubtitleTrack: customTrack,
      );
      showGestureFeedback(GestureFeedbackType.seek, 'Subtitles loaded (${entries.length} cues)');
    }
  }

  void toggleSubtitles() {
    if (!state.hasSubtitles && state.subtitleTracks.isEmpty) {
      loadSubtitlesFromPicker();
      return;
    }
    final next = !state.subtitleEnabled;
    state = state.copyWith(subtitleEnabled: next);
    showGestureFeedback(GestureFeedbackType.seek, next ? 'Subtitles: On' : 'Subtitles: Off');
  }

  void adjustSubtitleOffset(double deltaSeconds) {
    final newOffset = state.subtitleOffset + deltaSeconds;
    state = state.copyWith(subtitleOffset: newOffset);
    final sign = newOffset >= 0 ? '+' : '';
    showGestureFeedback(GestureFeedbackType.seek, 'Sub sync: $sign${newOffset.toStringAsFixed(1)}s');
  }

  void setSubtitleSize(double size) {
    final clamped = size.clamp(12.0, 32.0);
    SettingsService.subtitleSize = clamped;
    final updatedAppearance = state.subtitleAppearance.copyWith(fontSize: clamped);
    state = state.copyWith(subtitleSize: clamped, subtitleAppearance: updatedAppearance);
  }

  void loadSubtitleEntries(SubtitleTrack track, List<SubtitleEntry> entries) {
    final updatedTracks = List<SubtitleTrack>.from(state.subtitleTracks);
    final existingIdx = updatedTracks.indexWhere((t) => t.id == track.id);
    if (existingIdx >= 0) {
      updatedTracks[existingIdx] = track;
    } else {
      updatedTracks.add(track);
    }

    state = state.copyWith(
      subtitles: entries,
      subtitleEnabled: true,
      subtitleTracks: updatedTracks,
      selectedSubtitleTrack: track,
    );
    showGestureFeedback(GestureFeedbackType.seek, 'Subtitles: ${track.title}');
  }

  void selectSubtitleTrack(SubtitleTrack track) async {
    // If it's a database track, load segments from SQLite
    if (track.id.startsWith('db_')) {
      final dbId = int.tryParse(track.id.replaceFirst('db_', ''));
      if (dbId != null) {
        final List<DbSubtitleSegment> segments = await AppDatabase.getSubtitleSegmentsForTrack(dbId);
        final entries = segments.map((s) => SubtitleEntry(
          start: s.start,
          end: s.end,
          text: s.text,
        )).toList();
        loadSubtitleEntries(track, entries);
        return;
      }
    }

    state = state.copyWith(
      selectedSubtitleTrack: track,
      subtitleEnabled: true,
    );
    showGestureFeedback(GestureFeedbackType.seek, 'Subtitles: ${track.title}');
  }

  void setSubtitlePreset(SubtitlePreset preset) {
    final style = SubtitleAppearance.fromPreset(preset);
    state = state.copyWith(
      subtitleAppearance: style,
      subtitleSize: style.fontSize,
    );
    showGestureFeedback(GestureFeedbackType.seek, 'Sub style: ${preset.label}');
  }

  void setSubtitleAppearance(SubtitleAppearance appearance) {
    state = state.copyWith(
      subtitleAppearance: appearance,
      subtitleSize: appearance.fontSize,
    );
  }

  // ─── Brightness & Volume ─────────────────────────────────────────

  void setBrightness(double brightness) {
    final clamped = brightness.clamp(0.1, 1.0);
    state = state.copyWith(brightness: clamped);
    showGestureFeedback(
      GestureFeedbackType.brightness,
      'Brightness ${(clamped * 100).round()}%',
      level: clamped,
    );
  }

  void adjustBrightness(double delta) {
    setBrightness(state.brightness + delta);
  }

  Future<void> setVolume(double volume) async {
    if (_videoController == null) return;
    final clamped = volume.clamp(0.0, 1.0);
    await _videoController!.setVolume(clamped);
    state = state.copyWith(volume: clamped, isMuted: clamped == 0);
    showGestureFeedback(
      GestureFeedbackType.volume,
      clamped == 0 ? 'Muted' : 'Volume ${(clamped * 100).round()}%',
      level: clamped,
    );
  }

  Future<void> adjustVolume(double delta) async {
    final newVolume = (state.volume + delta).clamp(0.0, 1.0);
    await setVolume(newVolume);
  }

  Future<void> toggleMute() async {
    if (_videoController == null) return;
    if (state.isMuted) {
      final restoreVol = state.volume > 0 ? state.volume : 0.5;
      await _videoController!.setVolume(restoreVol);
      state = state.copyWith(isMuted: false, volume: restoreVol);
      showGestureFeedback(
        GestureFeedbackType.volume,
        'Volume ${(restoreVol * 100).round()}%',
        level: restoreVol,
      );
    } else {
      await _videoController!.setVolume(0.0);
      state = state.copyWith(isMuted: true);
      showGestureFeedback(GestureFeedbackType.volume, 'Muted', level: 0.0);
    }
  }

  // ─── Video Scaling & Aspect Ratio ────────────────────────────────

  void setScaleMode(VideoScaleMode mode) {
    SettingsService.scaleMode = mode.name;
    state = state.copyWith(scaleMode: mode);
    final label = switch (mode) {
      VideoScaleMode.fit => 'Fit Screen',
      VideoScaleMode.fill => 'Fill Screen (Crop)',
      VideoScaleMode.stretch => 'Stretch to Fill',
      VideoScaleMode.original => '100% Original',
      VideoScaleMode.zoom => 'Zoom 1.25x',
    };
    showGestureFeedback(GestureFeedbackType.scale, label);
    _startControlsTimer();
  }

  void cycleScaleMode() {
    final next = switch (state.scaleMode) {
      VideoScaleMode.fit => VideoScaleMode.fill,
      VideoScaleMode.fill => VideoScaleMode.stretch,
      VideoScaleMode.stretch => VideoScaleMode.original,
      VideoScaleMode.original => VideoScaleMode.zoom,
      VideoScaleMode.zoom => VideoScaleMode.fit,
    };
    setScaleMode(next);
  }

  // Backwards compatible method
  void toggleFit() => cycleScaleMode();

  // ─── Fullscreen State Machine ───────────────────────────────────

  void setFullscreenMode(FullscreenMode mode) {
    state = state.copyWith(fullscreenMode: mode);
  }

  void toggleFullscreen([bool? goFullscreen]) {
    final target = goFullscreen ?? !state.isFullscreen;
    setFullscreenMode(target ? FullscreenMode.fullscreen : FullscreenMode.windowed);
  }

  // ─── Playback & Scrubbing ───────────────────────────────────────

  void _onVideoControllerUpdate() {
    if (_isDisposed || _videoController == null) return;
    final value = _videoController!.value;

    if (value.hasError) {
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: value.errorDescription ?? 'Playback error occurred',
      );
      return;
    }

    final currentPos = value.position;
    final totalDur = value.duration;
    final isPlaying = value.isPlaying;

    Duration buffered = Duration.zero;
    if (value.buffered.isNotEmpty) {
      buffered = value.buffered.last.end;
    }

    // Completion detection: either position matches duration or is at >= 95% near the end
    final isNearEnd = totalDur.inMilliseconds > 0 &&
        currentPos >= totalDur - const Duration(milliseconds: 300) &&
        totalDur > Duration.zero;

    if (isNearEnd) {
      if (state.status != PlayerStatus.completed) {
        state = state.copyWith(
          status: PlayerStatus.completed,
          position: totalDur,
        );
        _handleCompletion();
      }
      return;
    }

    // Subtitle evaluation
    SubtitleEntry? activeSub;
    if (state.subtitleEnabled && state.subtitles.isNotEmpty) {
      final offsetDuration = Duration(
        milliseconds: (state.subtitleOffset * 1000).round(),
      );
      final adjustedPos = currentPos - offsetDuration;
      activeSub = SubtitleService.findActive(state.subtitles, adjustedPos);
    }

    // Do not overwrite position while the user is actively dragging the scrubber
    final displayPos = _isScrubbing ? state.position : currentPos;

    state = state.copyWith(
      position: displayPos,
      duration: totalDur,
      buffered: buffered,
      status: isPlaying
          ? PlayerStatus.playing
          : (state.status == PlayerStatus.completed ? PlayerStatus.completed : PlayerStatus.paused),
      currentSubtitle: activeSub,
      clearSubtitle: activeSub == null,
    );
  }

  void _handleCompletion() async {
    await _saveCurrentProgress(forceComplete: true);

    if (state.queue.repeatMode == PlaybackRepeatMode.one) {
      await seekTo(Duration.zero);
      await play();
      return;
    }

    if (SettingsService.autoPlayNext && state.hasNext) {
      playNext();
    } else if (state.queue.repeatMode == PlaybackRepeatMode.all && state.hasNext) {
      playNext();
    } else {
      _showControls();
    }
  }

  Future<void> togglePlayPause() async {
    if (_videoController == null || !_videoController!.value.isInitialized) return;

    if (_videoController!.value.isPlaying) {
      await _videoController!.pause();
      state = state.copyWith(status: PlayerStatus.paused);
      await _saveCurrentProgress();
      _showControls();
    } else {
      if (state.status == PlayerStatus.completed) {
        await _videoController!.seekTo(Duration.zero);
      }
      await _videoController!.play();
      state = state.copyWith(status: PlayerStatus.playing);
      _startControlsTimer();
    }
  }

  Future<void> play() async {
    if (_videoController == null) return;
    await _videoController!.play();
    state = state.copyWith(status: PlayerStatus.playing);
    _startControlsTimer();
  }

  Future<void> pause() async {
    if (_videoController == null) return;
    await _videoController!.pause();
    state = state.copyWith(status: PlayerStatus.paused);
    await _saveCurrentProgress();
    _showControls();
  }

  void onScrubStart() {
    _isScrubbing = true;
    _controlsTimer?.cancel();
  }

  void onScrubUpdate(Duration target) {
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(0, state.duration.inMilliseconds),
    );
    state = state.copyWith(position: clamped);
  }

  Future<void> onScrubEnd(Duration target) async {
    _isScrubbing = false;
    await seekTo(target);
  }

  Future<void> seekTo(Duration target) async {
    if (_videoController == null) return;
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(0, state.duration.inMilliseconds),
    );
    await _videoController!.seekTo(clamped);
    state = state.copyWith(position: clamped);
    _startControlsTimer();
  }

  Future<void> skipForward([int seconds = 10]) async {
    final target = state.position + Duration(seconds: seconds);
    await seekTo(target);
    showGestureFeedback(GestureFeedbackType.seek, '+$seconds seconds');
  }

  Future<void> skipBackward([int seconds = 10]) async {
    final target = state.position - Duration(seconds: seconds);
    await seekTo(target);
    showGestureFeedback(GestureFeedbackType.seek, '-$seconds seconds');
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (_videoController == null) return;
    await _videoController!.setPlaybackSpeed(speed);
    state = state.copyWith(playbackSpeed: speed);
    showGestureFeedback(GestureFeedbackType.speed, '${speed}x Speed');
    _startControlsTimer();
  }

  Future<void> increaseSpeed() async {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final current = state.playbackSpeed;
    final next = speeds.firstWhere((s) => s > current + 0.01, orElse: () => 2.0);
    await setPlaybackSpeed(next);
  }

  Future<void> decreaseSpeed() async {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].reversed;
    final current = state.playbackSpeed;
    final prev = speeds.firstWhere((s) => s < current - 0.01, orElse: () => 0.25);
    await setPlaybackSpeed(prev);
  }

  void toggleTimeDisplay() {
    final next = !state.showRemainingTime;
    SettingsService.showRemainingTime = next;
    state = state.copyWith(showRemainingTime: next);
  }

  void startOver() {
    seekTo(Duration.zero);
    state = state.copyWith(clearResumePrompt: true);
    play();
  }

  // ─── Queue Navigation ───────────────────────────────────────────

  Future<void> playNext() async {
    final nextIdx = state.queue.nextActiveIndex;
    if (nextIdx != null) {
      final updatedQueue = state.queue.moveTo(nextIdx);
      state = state.copyWith(queue: updatedQueue);
      final nextVideo = updatedQueue.currentVideo;
      if (nextVideo != null && nextVideo.id != null) {
        await loadVideo(nextVideo.id!);
      }
    }
  }

  Future<void> playPrevious() async {
    // VLC convention: if more than 3s in, restart current track; else go to previous
    if (state.position.inSeconds > 3) {
      await seekTo(Duration.zero);
      return;
    }

    final prevIdx = state.queue.previousActiveIndex;
    if (prevIdx != null) {
      final updatedQueue = state.queue.moveTo(prevIdx);
      state = state.copyWith(queue: updatedQueue);
      final prevVideo = updatedQueue.currentVideo;
      if (prevVideo != null && prevVideo.id != null) {
        await loadVideo(prevVideo.id!);
      }
    }
  }

  Future<void> jumpToQueueIndex(int activeIndex) async {
    if (activeIndex < 0 || activeIndex >= state.queue.activeOrder.length) return;
    final updatedQueue = state.queue.moveTo(activeIndex);
    state = state.copyWith(queue: updatedQueue);
    final video = updatedQueue.currentVideo;
    if (video != null && video.id != null) {
      await loadVideo(video.id!);
    }
  }

  void toggleShuffle() {
    final updated = state.queue.toggleShuffle();
    SettingsService.shuffleEnabled = updated.isShuffled;
    state = state.copyWith(queue: updated);
    showGestureFeedback(
      GestureFeedbackType.seek,
      updated.isShuffled ? 'Shuffle: On' : 'Shuffle: Off',
    );
  }

  void cycleRepeatMode() {
    final updated = state.queue.cycleRepeatMode();
    SettingsService.repeatMode = updated.repeatMode.name;
    state = state.copyWith(queue: updated);
    final label = switch (updated.repeatMode) {
      PlaybackRepeatMode.none => 'Repeat: Off',
      PlaybackRepeatMode.all => 'Repeat: All',
      PlaybackRepeatMode.one => 'Repeat: One',
    };
    showGestureFeedback(GestureFeedbackType.seek, label);
  }

  // ─── Locking & Feedback ─────────────────────────────────────────

  void toggleLock() {
    final newLocked = !state.isLocked;
    state = state.copyWith(
      isLocked: newLocked,
      controlsVisible: !newLocked,
    );
    showGestureFeedback(
      GestureFeedbackType.seek,
      newLocked ? 'Controls Locked' : 'Controls Unlocked',
    );
    if (!newLocked) _startControlsTimer();
  }

  void toggleControls([bool? visible]) {
    if (state.isLocked) {
      state = state.copyWith(controlsVisible: visible ?? !state.controlsVisible);
      if (state.controlsVisible) _startControlsTimer(duration: const Duration(seconds: 2));
      return;
    }

    final newVisibility = visible ?? !state.controlsVisible;
    state = state.copyWith(controlsVisible: newVisibility);

    if (newVisibility) {
      _startControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _showControls() {
    state = state.copyWith(controlsVisible: true);
    _controlsTimer?.cancel();
  }

  void _startControlsTimer({Duration duration = const Duration(milliseconds: 3500)}) {
    _controlsTimer?.cancel();
    if (!state.isPlaying) return;
    _controlsTimer = Timer(duration, () {
      if (!_isDisposed && state.isPlaying && !state.isLocked) {
        state = state.copyWith(controlsVisible: false);
      }
    });
  }

  void resetControlsTimer() {
    if (state.controlsVisible && state.isPlaying) {
      _startControlsTimer();
    }
  }

  void onPointerActivity() {
    if (state.isLocked) return;
    if (!state.controlsVisible) {
      state = state.copyWith(controlsVisible: true);
    }
    if (state.isPlaying) {
      _startControlsTimer();
    }
  }

  void showGestureFeedback(GestureFeedbackType type, String message, {double? level}) {
    _gestureFeedbackTimer?.cancel();
    state = state.copyWith(
      gestureFeedback: GestureFeedback(type: type, message: message, level: level),
    );
    _gestureFeedbackTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!_isDisposed) {
        state = state.copyWith(clearGestureFeedback: true);
      }
    });
  }

  // ─── Persistence & Database ─────────────────────────────────────

  void _startAutoSaveTimer() {
    _saveHistoryTimer?.cancel();
    _saveHistoryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveCurrentProgress();
    });
  }

  Future<void> _saveCurrentProgress({bool forceComplete = false}) async {
    if (state.video == null || state.video!.id == null) return;
    final videoId = state.video!.id!;
    final posMs = state.position.inMilliseconds;
    final durMs = state.duration.inMilliseconds > 0
        ? state.duration.inMilliseconds
        : state.video!.durationMs;

    if (durMs <= 0) return;

    if ((posMs - _lastSavedPositionMs).abs() < 1000 && !forceComplete) {
      return;
    }
    _lastSavedPositionMs = posMs;

    final isCompleted = forceComplete || (posMs >= durMs * 0.95);
    final completionPct = isCompleted ? 1.0 : (posMs / durMs).clamp(0.0, 1.0);

    final history = WatchHistory(
      videoId: videoId,
      positionMs: isCompleted ? durMs : posMs,
      durationMs: durMs,
      completionPercentage: completionPct,
      lastWatchedTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await AppDatabase.upsertWatchHistory(history);
  }

  Future<void> _disposeCurrentController() async {
    _saveHistoryTimer?.cancel();
    _controlsTimer?.cancel();
    _gestureFeedbackTimer?.cancel();
    if (_videoController != null) {
      _videoController!.removeListener(_onVideoControllerUpdate);
      await _videoController!.dispose();
      _videoController = null;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _saveCurrentProgress();
    _disposeCurrentController();
    super.dispose();
  }
}

final playerControllerProvider = StateNotifierProvider.autoDispose
    .family<PlayerController, PlayerState, ({int videoId, List<int>? queue, String? networkUrl})>(
  (ref, args) => PlayerController(
    ref,
    initialVideoId: args.videoId,
    queue: args.queue,
    networkUrl: args.networkUrl,
  ),
);
