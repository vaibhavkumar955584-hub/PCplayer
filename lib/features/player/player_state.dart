import 'package:flutter/widgets.dart';
import '../../core/models/models.dart';
import '../../core/services/subtitle_service.dart';
import '../subtitles/domain/subtitle_appearance.dart';

enum PlayerStatus {
  initial,
  loading,
  ready,
  playing,
  paused,
  completed,
  error,
}

enum VideoScaleMode {
  fit,      // Preserve aspect ratio, show full video (letterbox/pillarbox)
  fill,     // Fill screen, preserve aspect ratio, crop edges
  stretch,  // Fill screen ignoring aspect ratio
  original, // 1:1 pixel native video size
  zoom,     // 1.25x crop zoom
}

enum FullscreenMode {
  windowed,
  fullscreen,
}

/// Representation of an audio track stream
class AudioTrack {
  final String id;
  final String label;
  final String language;
  final bool isDefault;

  const AudioTrack({
    required this.id,
    required this.label,
    this.language = 'und',
    this.isDefault = false,
  });
}

/// Temporary overlay feedback shown when user gestures or changes settings
enum GestureFeedbackType { seek, volume, brightness, speed, scale }

class GestureFeedback {
  final GestureFeedbackType type;
  final String message;
  final double? level; // 0.0 to 1.0 for volume/brightness bars
  const GestureFeedback({required this.type, required this.message, this.level});
}

class PlayerState {
  final Video? video;
  final PlayerStatus status;
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final double playbackSpeed;
  final double volume;
  final bool isMuted;
  final bool controlsVisible;
  final PlaybackQueue queue;
  final VideoScaleMode scaleMode;
  final FullscreenMode fullscreenMode;
  final bool isLocked;
  final String? errorMessage;
  final bool isMissingFile;

  // Subtitle
  final bool subtitleEnabled;
  final List<SubtitleEntry> subtitles;
  final SubtitleEntry? currentSubtitle;
  final double subtitleOffset; // seconds offset for fine-tuning
  final double subtitleSize;
  final SubtitleAppearance subtitleAppearance;
  final List<SubtitleTrack> subtitleTracks;
  final SubtitleTrack? selectedSubtitleTrack;

  // Audio tracks
  final List<AudioTrack> audioTracks;
  final AudioTrack? selectedAudioTrack;

  // Display & HUD options
  final double brightness;
  final bool showRemainingTime;
  final double zoomScale;
  final GestureFeedback? gestureFeedback;

  // Resume prompt
  final Duration? resumePromptPosition;

  const PlayerState({
    this.video,
    this.status = PlayerStatus.initial,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = Duration.zero,
    this.playbackSpeed = 1.0,
    this.volume = 1.0,
    this.isMuted = false,
    this.controlsVisible = true,
    required this.queue,
    this.scaleMode = VideoScaleMode.fit,
    this.fullscreenMode = FullscreenMode.windowed,
    this.isLocked = false,
    this.errorMessage,
    this.isMissingFile = false,
    this.subtitleEnabled = false,
    this.subtitles = const [],
    this.currentSubtitle,
    this.subtitleOffset = 0.0,
    this.subtitleSize = 16.0,
    this.subtitleAppearance = const SubtitleAppearance(),
    this.subtitleTracks = const [],
    this.selectedSubtitleTrack,
    this.audioTracks = const [
      AudioTrack(id: 'default', label: 'Default Stereo Audio', isDefault: true),
    ],
    this.selectedAudioTrack,
    this.brightness = 1.0,
    this.showRemainingTime = false,
    this.zoomScale = 1.0,
    this.gestureFeedback,
    this.resumePromptPosition,
  });

  bool get isPlaying => status == PlayerStatus.playing;
  bool get isLoading => status == PlayerStatus.loading || status == PlayerStatus.initial;
  bool get hasError => status == PlayerStatus.error;
  bool get isFullscreen => fullscreenMode == FullscreenMode.fullscreen;
  bool get hasNext => queue.hasNext;
  bool get hasPrevious => queue.hasPrevious;
  bool get hasSubtitles => subtitles.isNotEmpty;

  // Backwards compatibility for widgets expecting queueIds and currentQueueIndex
  List<int> get queueIds => queue.items.map((v) => v.id ?? 0).toList();
  int get currentQueueIndex => queue.currentActiveIndex;

  // Maps VideoScaleMode to BoxFit
  BoxFit get fit {
    switch (scaleMode) {
      case VideoScaleMode.fit:
        return BoxFit.contain;
      case VideoScaleMode.fill:
        return BoxFit.cover;
      case VideoScaleMode.stretch:
        return BoxFit.fill;
      case VideoScaleMode.original:
        return BoxFit.scaleDown;
      case VideoScaleMode.zoom:
        return BoxFit.cover;
    }
  }

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  PlayerState copyWith({
    Video? video,
    PlayerStatus? status,
    Duration? position,
    Duration? duration,
    Duration? buffered,
    double? playbackSpeed,
    double? volume,
    bool? isMuted,
    bool? controlsVisible,
    PlaybackQueue? queue,
    VideoScaleMode? scaleMode,
    FullscreenMode? fullscreenMode,
    bool? isLocked,
    String? errorMessage,
    bool? isMissingFile,
    bool? subtitleEnabled,
    List<SubtitleEntry>? subtitles,
    SubtitleEntry? currentSubtitle,
    bool clearSubtitle = false,
    double? subtitleOffset,
    double? subtitleSize,
    SubtitleAppearance? subtitleAppearance,
    List<SubtitleTrack>? subtitleTracks,
    SubtitleTrack? selectedSubtitleTrack,
    List<AudioTrack>? audioTracks,
    AudioTrack? selectedAudioTrack,
    double? brightness,
    bool? showRemainingTime,
    double? zoomScale,
    GestureFeedback? gestureFeedback,
    bool clearGestureFeedback = false,
    Duration? resumePromptPosition,
    bool clearResumePrompt = false,
  }) {
    return PlayerState(
      video: video ?? this.video,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffered: buffered ?? this.buffered,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      controlsVisible: controlsVisible ?? this.controlsVisible,
      queue: queue ?? this.queue,
      scaleMode: scaleMode ?? this.scaleMode,
      fullscreenMode: fullscreenMode ?? this.fullscreenMode,
      isLocked: isLocked ?? this.isLocked,
      errorMessage: errorMessage ?? this.errorMessage,
      isMissingFile: isMissingFile ?? this.isMissingFile,
      subtitleEnabled: subtitleEnabled ?? this.subtitleEnabled,
      subtitles: subtitles ?? this.subtitles,
      currentSubtitle: clearSubtitle ? null : (currentSubtitle ?? this.currentSubtitle),
      subtitleOffset: subtitleOffset ?? this.subtitleOffset,
      subtitleSize: subtitleSize ?? this.subtitleSize,
      subtitleAppearance: subtitleAppearance ?? this.subtitleAppearance,
      subtitleTracks: subtitleTracks ?? this.subtitleTracks,
      selectedSubtitleTrack: selectedSubtitleTrack ?? this.selectedSubtitleTrack,
      audioTracks: audioTracks ?? this.audioTracks,
      selectedAudioTrack: selectedAudioTrack ?? this.selectedAudioTrack,
      brightness: brightness ?? this.brightness,
      showRemainingTime: showRemainingTime ?? this.showRemainingTime,
      zoomScale: zoomScale ?? this.zoomScale,
      gestureFeedback: clearGestureFeedback ? null : (gestureFeedback ?? this.gestureFeedback),
      resumePromptPosition: clearResumePrompt ? null : (resumePromptPosition ?? this.resumePromptPosition),
    );
  }
}

