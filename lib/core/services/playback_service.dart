import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Current playback state of the native engine
enum PlaybackEngineStatus {
  idle,
  loading,
  ready,
  playing,
  paused,
  completed,
  error,
}

/// Abstract contract for media playback engines.
/// Allows replacing video_player with other backends (e.g. media_kit, VLC FFI, ExoPlayer)
/// without changing PlayerController or UI.
abstract class PlaybackService {
  PlaybackEngineStatus get status;
  Duration get position;
  Duration get duration;
  Duration get buffered;
  double get aspectRatio;
  bool get isPlaying;
  bool get isBuffering;
  double get volume;
  double get playbackSpeed;
  String? get errorMessage;

  /// Underlying VideoPlayerController for video widget rendering (if available)
  VideoPlayerController? get rawVideoController;

  /// Stream of position updates
  Stream<Duration> get positionStream;

  /// Stream of state changes
  Stream<PlaybackEngineStatus> get statusStream;

  /// Initialize playback from a local file
  Future<void> initializeFile(File file);

  /// Initialize playback from a network URL
  Future<void> initializeUrl(Uri uri);

  /// Start or resume playback
  Future<void> play();

  /// Pause playback
  Future<void> pause();

  /// Seek to a specific timestamp
  Future<void> seekTo(Duration position);

  /// Adjust playback speed (e.g. 0.25 to 2.0)
  Future<void> setPlaybackSpeed(double speed);

  /// Set audio volume (0.0 to 1.0)
  Future<void> setVolume(double volume);

  /// Register a listener for player updates
  void addListener(VoidCallback listener);

  /// Remove a listener
  void removeListener(VoidCallback listener);

  /// Release resources and native controllers
  Future<void> dispose();
}

/// Concrete implementation of [PlaybackService] using the official `video_player` package.
class VideoPlayerServiceAdapter implements PlaybackService {
  VideoPlayerController? _controller;
  PlaybackEngineStatus _status = PlaybackEngineStatus.idle;
  String? _errorMessage;
  double _currentVolume = 1.0;
  double _currentSpeed = 1.0;

  final StreamController<Duration> _positionStreamController = StreamController<Duration>.broadcast();
  final StreamController<PlaybackEngineStatus> _statusStreamController = StreamController<PlaybackEngineStatus>.broadcast();
  final List<VoidCallback> _listeners = [];
  Duration _lastReportedPosition = Duration.zero;

  @override
  PlaybackEngineStatus get status => _status;

  @override
  String? get errorMessage => _errorMessage;

  @override
  VideoPlayerController? get rawVideoController => _controller;

  @override
  Duration get position => _controller?.value.position ?? Duration.zero;

  @override
  Duration get duration => _controller?.value.duration ?? Duration.zero;

  @override
  Duration get buffered {
    if (_controller == null || _controller!.value.buffered.isEmpty) {
      return Duration.zero;
    }
    return _controller!.value.buffered.last.end;
  }

  @override
  double get aspectRatio {
    if (_controller == null || !_controller!.value.isInitialized) return 16 / 9;
    final size = _controller!.value.size;
    if (size.width == 0 || size.height == 0) return 16 / 9;
    return size.width / size.height;
  }

  @override
  bool get isPlaying => _controller?.value.isPlaying ?? false;

  @override
  bool get isBuffering => _controller?.value.isBuffering ?? false;

  @override
  double get volume => _currentVolume;

  @override
  double get playbackSpeed => _currentSpeed;

  @override
  Stream<Duration> get positionStream => _positionStreamController.stream;

  @override
  Stream<PlaybackEngineStatus> get statusStream => _statusStreamController.stream;

  void _setStatus(PlaybackEngineStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusStreamController.add(_status);
      _notify();
    }
  }

  void _notify() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  void _onControllerUpdate() {
    if (_controller == null) return;
    final val = _controller!.value;

    if (val.hasError) {
      _errorMessage = val.errorDescription ?? 'Playback error encountered';
      _setStatus(PlaybackEngineStatus.error);
      return;
    }

    if (val.isInitialized) {
      if (val.position >= val.duration && val.duration > Duration.zero) {
        _setStatus(PlaybackEngineStatus.completed);
      } else if (val.isPlaying) {
        _setStatus(PlaybackEngineStatus.playing);
      } else {
        _setStatus(PlaybackEngineStatus.paused);
      }

      if (val.position != _lastReportedPosition) {
        _lastReportedPosition = val.position;
        _positionStreamController.add(val.position);
      }
    }

    _notify();
  }

  @override
  Future<void> initializeFile(File file) async {
    await _disposeExisting();
    _setStatus(PlaybackEngineStatus.loading);
    _errorMessage = null;

    try {
      final ctrl = VideoPlayerController.file(file);
      _controller = ctrl;
      ctrl.addListener(_onControllerUpdate);
      await ctrl.initialize();
      await ctrl.setVolume(_currentVolume);
      await ctrl.setPlaybackSpeed(_currentSpeed);
      _setStatus(PlaybackEngineStatus.ready);
    } catch (e) {
      _errorMessage = 'Failed to initialize local file: $e';
      _setStatus(PlaybackEngineStatus.error);
      rethrow;
    }
  }

  @override
  Future<void> initializeUrl(Uri uri) async {
    await _disposeExisting();
    _setStatus(PlaybackEngineStatus.loading);
    _errorMessage = null;

    try {
      final ctrl = VideoPlayerController.networkUrl(uri);
      _controller = ctrl;
      ctrl.addListener(_onControllerUpdate);
      await ctrl.initialize();
      await ctrl.setVolume(_currentVolume);
      await ctrl.setPlaybackSpeed(_currentSpeed);
      _setStatus(PlaybackEngineStatus.ready);
    } catch (e) {
      _errorMessage = 'Failed to initialize network stream: $e';
      _setStatus(PlaybackEngineStatus.error);
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    await _controller!.play();
    _setStatus(PlaybackEngineStatus.playing);
  }

  @override
  Future<void> pause() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    await _controller!.pause();
    _setStatus(PlaybackEngineStatus.paused);
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    await _controller!.seekTo(position);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    _currentSpeed = speed;
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.setPlaybackSpeed(speed);
    }
    _notify();
  }

  @override
  Future<void> setVolume(double volume) async {
    _currentVolume = volume.clamp(0.0, 1.0);
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.setVolume(_currentVolume);
    }
    _notify();
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  Future<void> _disposeExisting() async {
    if (_controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      await _controller!.dispose();
      _controller = null;
    }
  }

  @override
  Future<void> dispose() async {
    await _disposeExisting();
    _listeners.clear();
    await _positionStreamController.close();
    await _statusStreamController.close();
  }
}
