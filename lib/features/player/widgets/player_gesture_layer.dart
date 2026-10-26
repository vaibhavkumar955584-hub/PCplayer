import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/velo_colors.dart';
import '../../../core/theme/velo_typography.dart';

class PlayerGestureLayer extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onDoubleTapLeft;
  final VoidCallback onDoubleTapRight;
  final VoidCallback onDoubleTapCenter;
  final bool isLocked;
  final bool gesturesEnabled;
  final double volume;
  final double brightness;
  final Duration position;
  final Duration duration;
  final ValueChanged<double>? onVolumeChanged;
  final ValueChanged<double>? onBrightnessChanged;
  final ValueChanged<Duration>? onHorizontalSeekEnd;
  final VoidCallback? onPointerMove;

  const PlayerGestureLayer({
    super.key,
    required this.child,
    required this.onTap,
    required this.onDoubleTapLeft,
    required this.onDoubleTapRight,
    required this.onDoubleTapCenter,
    this.isLocked = false,
    this.gesturesEnabled = true,
    this.volume = 1.0,
    this.brightness = 1.0,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.onVolumeChanged,
    this.onBrightnessChanged,
    this.onHorizontalSeekEnd,
    this.onPointerMove,
  });

  @override
  State<PlayerGestureLayer> createState() => _PlayerGestureLayerState();
}

enum _DragGestureType { none, verticalBrightness, verticalVolume, horizontalSeek }

class _PlayerGestureLayerState extends State<PlayerGestureLayer> {
  bool _showRewindIndicator = false;
  bool _showForwardIndicator = false;
  Timer? _indicatorTimer;

  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  Timer? _sliderTimer;

  // Horizontal seek swipe
  bool _showSeekSwipeIndicator = false;
  int _seekDeltaSeconds = 0;
  Duration _targetSeekPosition = Duration.zero;

  // Local display values
  double _localVolume = 1.0;
  double _localBrightness = 1.0;

  _DragGestureType _activeDragType = _DragGestureType.none;
  Offset _dragStartPos = Offset.zero;

  @override
  void didUpdateWidget(PlayerGestureLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_showVolumeIndicator) _localVolume = widget.volume;
    if (!_showBrightnessIndicator) _localBrightness = widget.brightness;
  }

  void _triggerRewindFeedback() {
    setState(() {
      _showRewindIndicator = true;
      _showForwardIndicator = false;
    });
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showRewindIndicator = false);
    });
  }

  void _triggerForwardFeedback() {
    setState(() {
      _showForwardIndicator = true;
      _showRewindIndicator = false;
    });
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showForwardIndicator = false);
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _indicatorTimer?.cancel();
    _sliderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => widget.onPointerMove?.call(),
      child: Stack(
        children: [
          widget.child,

          // Main gesture capture layer
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: widget.onTap,
                  onDoubleTapDown: (details) {
                    if (widget.isLocked) return;
                    final dx = details.localPosition.dx;
                    final fraction = dx / width;

                    if (fraction < 0.35) {
                      _triggerRewindFeedback();
                      widget.onDoubleTapLeft();
                    } else if (fraction > 0.65) {
                      _triggerForwardFeedback();
                      widget.onDoubleTapRight();
                    } else {
                      widget.onDoubleTapCenter();
                    }
                  },
                  onPanStart: !widget.gesturesEnabled || widget.isLocked
                      ? null
                      : (details) {
                          _dragStartPos = details.localPosition;
                          _activeDragType = _DragGestureType.none;
                          _seekDeltaSeconds = 0;
                        },
                  onPanUpdate: !widget.gesturesEnabled || widget.isLocked
                      ? null
                      : (details) {
                          final deltaX = details.localPosition.dx - _dragStartPos.dx;
                          final deltaY = details.localPosition.dy - _dragStartPos.dy;

                          // Decide gesture direction if not locked in yet
                          if (_activeDragType == _DragGestureType.none) {
                            if (deltaX.abs() > 18 && deltaX.abs() > deltaY.abs()) {
                              _activeDragType = _DragGestureType.horizontalSeek;
                            } else if (deltaY.abs() > 18) {
                              final startFraction = _dragStartPos.dx / width;
                              if (startFraction < 0.5) {
                                _activeDragType = _DragGestureType.verticalBrightness;
                              } else {
                                _activeDragType = _DragGestureType.verticalVolume;
                              }
                            }
                          }

                          // Execute active gesture
                          if (_activeDragType == _DragGestureType.verticalBrightness) {
                            final delta = -details.delta.dy / height;
                            final newBrightness = (_localBrightness + delta).clamp(0.1, 1.0);
                            setState(() {
                              _localBrightness = newBrightness;
                              _showBrightnessIndicator = true;
                              _showVolumeIndicator = false;
                            });
                            widget.onBrightnessChanged?.call(newBrightness);
                            _resetSliderTimer();
                          } else if (_activeDragType == _DragGestureType.verticalVolume) {
                            final delta = -details.delta.dy / height;
                            final newVolume = (_localVolume + delta).clamp(0.0, 1.0);
                            setState(() {
                              _localVolume = newVolume;
                              _showVolumeIndicator = true;
                              _showBrightnessIndicator = false;
                            });
                            widget.onVolumeChanged?.call(newVolume);
                            _resetSliderTimer();
                          } else if (_activeDragType == _DragGestureType.horizontalSeek) {
                            // Scale seek delta based on screen width (drag entire screen = 90s seek)
                            final totalDeltaRatio = (details.localPosition.dx - _dragStartPos.dx) / width;
                            final deltaSec = (totalDeltaRatio * 120).round();
                            final newTargetMs = (widget.position.inMilliseconds + (deltaSec * 1000))
                                .clamp(0, widget.duration.inMilliseconds);

                            setState(() {
                              _showSeekSwipeIndicator = true;
                              _seekDeltaSeconds = deltaSec;
                              _targetSeekPosition = Duration(milliseconds: newTargetMs);
                            });
                          }
                        },
                  onPanEnd: !widget.gesturesEnabled || widget.isLocked
                      ? null
                      : (details) {
                          if (_activeDragType == _DragGestureType.horizontalSeek) {
                            if (_seekDeltaSeconds != 0) {
                              widget.onHorizontalSeekEnd?.call(_targetSeekPosition);
                            }
                            setState(() {
                              _showSeekSwipeIndicator = false;
                            });
                          }
                          _activeDragType = _DragGestureType.none;
                        },
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),

          // Double-tap rewind indicator (-10s)
          if (_showRewindIndicator)
            Align(
              alignment: const Alignment(-0.6, 0.0),
              child: _FeedbackBubble(
                icon: Icons.replay_10_rounded,
                label: '-10s',
                color: VeloColors.accentCyan,
              ),
            ),

          // Double-tap forward indicator (+10s)
          if (_showForwardIndicator)
            Align(
              alignment: const Alignment(0.6, 0.0),
              child: _FeedbackBubble(
                icon: Icons.forward_10_rounded,
                label: '+10s',
                color: VeloColors.accentCyan,
              ),
            ),

          // Horizontal swipe seek overlay
          if (_showSeekSwipeIndicator)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VeloColors.accentCyan.withValues(alpha: 0.6), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: VeloColors.accentCyan.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _seekDeltaSeconds >= 0 ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
                      color: VeloColors.accentCyan,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_seekDeltaSeconds >= 0 ? '+' : ''}$_seekDeltaSeconds seconds',
                      style: VeloTypography.headlineSmall.copyWith(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDuration(_targetSeekPosition)} / ${_formatDuration(widget.duration)}',
                      style: VeloTypography.codeTime.copyWith(color: VeloColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // Volume HUD Indicator
          if (_showVolumeIndicator)
            Align(
              alignment: const Alignment(0.7, 0.0),
              child: _LevelIndicator(
                icon: _localVolume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                level: _localVolume,
                label: 'Volume',
                color: Colors.amber,
              ),
            ),

          // Brightness HUD Indicator
          if (_showBrightnessIndicator)
            Align(
              alignment: const Alignment(-0.7, 0.0),
              child: _LevelIndicator(
                icon: Icons.brightness_6_rounded,
                level: _localBrightness,
                label: 'Brightness',
                color: Colors.orangeAccent,
              ),
            ),
        ],
      ),
    );
  }

  void _resetSliderTimer() {
    _sliderTimer?.cancel();
    _sliderTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _showVolumeIndicator = false;
          _showBrightnessIndicator = false;
        });
      }
    });
  }
}

class _FeedbackBubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeedbackBubble({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Text(
            label,
            style: VeloTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _LevelIndicator extends StatelessWidget {
  final IconData icon;
  final double level;
  final String label;
  final Color color;

  const _LevelIndicator({
    required this.icon,
    required this.level,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          SizedBox(
            width: 8,
            height: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: RotatedBox(
                quarterTurns: 3,
                child: LinearProgressIndicator(
                  value: level.clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(level * 100).round()}%',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
