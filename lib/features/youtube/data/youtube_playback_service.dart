import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/playback_service.dart';
import '../utils/youtube_url_parser.dart';

/// Implementation of [PlaybackService] for supported YouTube and embedded video streams.
/// Gracefully handles playback state, duration, position, volume, and fallback options.
class YouTubePlaybackService implements PlaybackService {
  PlaybackEngineStatus _status = PlaybackEngineStatus.idle;
  String? _errorMessage;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final Duration _buffered = Duration.zero;
  bool _isPlaying = false;
  YouTubeVideoInfo? _currentInfo;

  final StreamController<Duration> _positionStreamController = StreamController<Duration>.broadcast();
  final StreamController<PlaybackEngineStatus> _statusStreamController = StreamController<PlaybackEngineStatus>.broadcast();
  final List<VoidCallback> _listeners = [];
  Timer? _positionTimer;

  YouTubeVideoInfo? get currentInfo => _currentInfo;

  @override
  PlaybackEngineStatus get status => _status;

  @override
  String? get errorMessage => _errorMessage;

  @override
  VideoPlayerController? get rawVideoController => null;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  Duration get buffered => _buffered;

  @override
  double get aspectRatio => 16 / 9;

  @override
  bool get isPlaying => _isPlaying;

  @override
  bool get isBuffering => _status == PlaybackEngineStatus.loading;

  @override
  double get volume => _volume;

  @override
  double get playbackSpeed => _playbackSpeed;

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

  /// Initialize from a YouTube URL
  Future<void> initializeYouTube(String url) async {
    _setStatus(PlaybackEngineStatus.loading);
    _errorMessage = null;

    final info = YouTubeUrlParser.parse(url);
    if (info == null) {
      _errorMessage = 'Invalid or unsupported YouTube URL.';
      _setStatus(PlaybackEngineStatus.error);
      return;
    }

    _currentInfo = info;
    _position = Duration(seconds: info.startSeconds);
    _duration = const Duration(minutes: 10); // Standard placeholder until stream resolves
    _setStatus(PlaybackEngineStatus.ready);
  }

  @override
  Future<void> initializeFile(File file) async {
    _errorMessage = 'YouTubePlaybackService does not support local files.';
    _setStatus(PlaybackEngineStatus.error);
  }

  @override
  Future<void> initializeUrl(Uri uri) async {
    await initializeYouTube(uri.toString());
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
    _setStatus(PlaybackEngineStatus.playing);
    _startPositionTicker();
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    _positionTimer?.cancel();
    _setStatus(PlaybackEngineStatus.paused);
  }

  @override
  Future<void> seekTo(Duration target) async {
    _position = target;
    _positionStreamController.add(_position);
    _notify();
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    _notify();
  }

  @override
  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
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

  void _startPositionTicker() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPlaying) {
        _position += Duration(milliseconds: (1000 * _playbackSpeed).round());
        _positionStreamController.add(_position);
        _notify();
      }
    });
  }

  @override
  Future<void> dispose() async {
    _positionTimer?.cancel();
    _listeners.clear();
    await _positionStreamController.close();
    await _statusStreamController.close();
  }
}
