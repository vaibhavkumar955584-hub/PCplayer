import 'dart:math';
import 'video.dart';

enum PlaybackRepeatMode {
  none,
  all,
  one,
}

enum QueueSource {
  library,
  folder,
  playlist,
  search,
  favorites,
  continueWatching,
  directUrl,
}

/// Represents the active playback queue, supporting repeat modes, shuffle,
/// and queue-aware navigation across various media sources.
class PlaybackQueue {
  final List<Video> items;
  final int currentActiveIndex;
  final PlaybackRepeatMode repeatMode;
  final bool isShuffled;
  final List<int> originalOrder; // Indices into items
  final List<int> activeOrder;   // Order currently played
  final QueueSource source;
  final String? sourceTitle;

  PlaybackQueue({
    required this.items,
    this.currentActiveIndex = 0,
    this.repeatMode = PlaybackRepeatMode.none,
    this.isShuffled = false,
    List<int>? originalOrder,
    List<int>? activeOrder,
    this.source = QueueSource.library,
    this.sourceTitle,
  })  : originalOrder = originalOrder ?? List.generate(items.length, (i) => i),
        activeOrder = activeOrder ?? List.generate(items.length, (i) => i);

  factory PlaybackQueue.single(Video video, {QueueSource source = QueueSource.library}) {
    return PlaybackQueue(
      items: [video],
      currentActiveIndex: 0,
      source: source,
      sourceTitle: video.title,
    );
  }

  factory PlaybackQueue.fromVideos({
    required List<Video> videos,
    required int initialIndex,
    QueueSource source = QueueSource.library,
    String? sourceTitle,
    PlaybackRepeatMode repeatMode = PlaybackRepeatMode.none,
  }) {
    final maxLen = max<int>(0, videos.length - 1);
    final safeIndex = videos.isEmpty ? 0 : initialIndex.clamp(0, maxLen);
    return PlaybackQueue(
      items: videos,
      currentActiveIndex: safeIndex,
      source: source,
      sourceTitle: sourceTitle,
      repeatMode: repeatMode,
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;

  /// The currently active Video being played
  Video? get currentVideo {
    if (isEmpty || currentActiveIndex < 0 || currentActiveIndex >= activeOrder.length) {
      return null;
    }
    final realIndex = activeOrder[currentActiveIndex];
    if (realIndex < 0 || realIndex >= items.length) return null;
    return items[realIndex];
  }

  /// Whether there is a subsequent video to play
  bool get hasNext {
    if (isEmpty) return false;
    if (repeatMode == PlaybackRepeatMode.one || repeatMode == PlaybackRepeatMode.all) return true;
    return currentActiveIndex < activeOrder.length - 1;
  }

  /// Whether there is a preceding video
  bool get hasPrevious {
    if (isEmpty) return false;
    if (repeatMode == PlaybackRepeatMode.one || repeatMode == PlaybackRepeatMode.all) return true;
    return currentActiveIndex > 0;
  }

  /// Next active index in queue
  int? get nextActiveIndex {
    if (isEmpty) return null;
    if (repeatMode == PlaybackRepeatMode.one) return currentActiveIndex;
    if (currentActiveIndex < activeOrder.length - 1) {
      return currentActiveIndex + 1;
    }
    if (repeatMode == PlaybackRepeatMode.all) {
      return 0;
    }
    return null;
  }

  /// Previous active index in queue
  int? get previousActiveIndex {
    if (isEmpty) return null;
    if (repeatMode == PlaybackRepeatMode.one) return currentActiveIndex;
    if (currentActiveIndex > 0) {
      return currentActiveIndex - 1;
    }
    if (repeatMode == PlaybackRepeatMode.all) {
      return activeOrder.length - 1;
    }
    return null;
  }

  /// Upcoming videos after the current one
  List<Video> get upcomingVideos {
    if (isEmpty || currentActiveIndex >= activeOrder.length - 1) return [];
    return activeOrder
        .sublist(currentActiveIndex + 1)
        .map((idx) => items[idx])
        .toList();
  }

  /// Toggle shuffle mode
  PlaybackQueue toggleShuffle() {
    if (items.length <= 1) {
      return copyWith(isShuffled: !isShuffled);
    }

    if (isShuffled) {
      // Unshuffle: find current item's index in original order
      final currentRealIndex = activeOrder[currentActiveIndex];
      final newActiveIndex = originalOrder.indexOf(currentRealIndex);
      return copyWith(
        isShuffled: false,
        activeOrder: List<int>.from(originalOrder),
        currentActiveIndex: newActiveIndex >= 0 ? newActiveIndex : 0,
      );
    } else {
      // Shuffle: keep current video at index 0 and shuffle the rest
      final currentRealIndex = activeOrder[currentActiveIndex];
      final otherIndices = originalOrder.where((idx) => idx != currentRealIndex).toList();
      otherIndices.shuffle(Random());
      final newOrder = [currentRealIndex, ...otherIndices];

      return copyWith(
        isShuffled: true,
        activeOrder: newOrder,
        currentActiveIndex: 0,
      );
    }
  }

  /// Cycle repeat mode: none -> all -> one -> none
  PlaybackQueue cycleRepeatMode() {
    final nextMode = switch (repeatMode) {
      PlaybackRepeatMode.none => PlaybackRepeatMode.all,
      PlaybackRepeatMode.all => PlaybackRepeatMode.one,
      PlaybackRepeatMode.one => PlaybackRepeatMode.none,
    };
    return copyWith(repeatMode: nextMode);
  }

  /// Move to a specific active index
  PlaybackQueue moveTo(int activeIndex) {
    if (activeIndex < 0 || activeIndex >= activeOrder.length) return this;
    return copyWith(currentActiveIndex: activeIndex);
  }

  PlaybackQueue copyWith({
    List<Video>? items,
    int? currentActiveIndex,
    PlaybackRepeatMode? repeatMode,
    bool? isShuffled,
    List<int>? originalOrder,
    List<int>? activeOrder,
    QueueSource? source,
    String? sourceTitle,
  }) {
    return PlaybackQueue(
      items: items ?? this.items,
      currentActiveIndex: currentActiveIndex ?? this.currentActiveIndex,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffled: isShuffled ?? this.isShuffled,
      originalOrder: originalOrder ?? this.originalOrder,
      activeOrder: activeOrder ?? this.activeOrder,
      source: source ?? this.source,
      sourceTitle: sourceTitle ?? this.sourceTitle,
    );
  }
}
