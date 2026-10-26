import 'models.dart';
import '../../features/player/player_state.dart';

/// Represents the active playback session, completely decoupled from the UI.
/// Manages the queue, current video, repeat/shuffle policies, and playback parameters.
class PlaybackSession {
  final Video? currentVideo;
  final PlaybackQueue queue;
  final PlaybackRepeatMode repeatMode;
  final bool isShuffled;
  final bool autoPlayNext;
  final VideoScaleMode scaleMode;
  final double? aspectRatio;
  final Duration lastPosition;
  final DateTime sessionStartTime;

  PlaybackSession({
    this.currentVideo,
    required this.queue,
    this.repeatMode = PlaybackRepeatMode.none,
    this.isShuffled = false,
    this.autoPlayNext = true,
    this.scaleMode = VideoScaleMode.fit,
    this.aspectRatio,
    this.lastPosition = Duration.zero,
    DateTime? sessionStartTime,
  }) : sessionStartTime = sessionStartTime ?? DateTime.now();

  int get currentIndex => queue.currentActiveIndex;
  List<Video> get playlist => queue.items;
  bool get hasNext => queue.hasNext;
  bool get hasPrevious => queue.hasPrevious;

  PlaybackSession copyWith({
    Video? currentVideo,
    PlaybackQueue? queue,
    PlaybackRepeatMode? repeatMode,
    bool? isShuffled,
    bool? autoPlayNext,
    VideoScaleMode? scaleMode,
    double? aspectRatio,
    Duration? lastPosition,
  }) {
    return PlaybackSession(
      currentVideo: currentVideo ?? this.currentVideo,
      queue: queue ?? this.queue,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffled: isShuffled ?? this.isShuffled,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
      scaleMode: scaleMode ?? this.scaleMode,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      lastPosition: lastPosition ?? this.lastPosition,
      sessionStartTime: sessionStartTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'video_id': currentVideo?.id,
      'position_ms': lastPosition.inMilliseconds,
      'repeat_mode': repeatMode.name,
      'is_shuffled': isShuffled ? 1 : 0,
      'auto_play_next': autoPlayNext ? 1 : 0,
      'scale_mode': scaleMode.name,
      'session_start': sessionStartTime.millisecondsSinceEpoch,
    };
  }
}
