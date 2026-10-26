import 'package:flutter/material.dart';
import '../../../core/theme/velo_colors.dart';
import '../../../core/theme/velo_typography.dart';

class PlayerProgress extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onScrubStart;
  final ValueChanged<Duration>? onScrubUpdate;
  final ValueChanged<Duration>? onScrubEnd;
  final bool showRemainingTime;
  final VoidCallback? onToggleRemainingTime;

  const PlayerProgress({
    super.key,
    required this.position,
    required this.duration,
    required this.buffered,
    required this.onSeek,
    this.onScrubStart,
    this.onScrubUpdate,
    this.onScrubEnd,
    this.showRemainingTime = false,
    this.onToggleRemainingTime,
  });

  @override
  State<PlayerProgress> createState() => _PlayerProgressState();
}

class _PlayerProgressState extends State<PlayerProgress> {
  bool _isDragging = false;
  double _dragValue = 0.0; // 0.0 to 1.0

  String _formatDuration(Duration d, {bool isNegative = false}) {
    final prefix = isNegative ? '-' : '';
    final totalSec = d.inSeconds.abs();
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    if (h > 0) {
      return '$prefix${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$prefix${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = widget.duration.inMilliseconds;
    final currentMs = _isDragging
        ? (_dragValue * totalMs).toInt()
        : widget.position.inMilliseconds;
    final bufferedMs = widget.buffered.inMilliseconds;

    final progress = totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;
    final bufferedProgress = totalMs > 0 ? (bufferedMs / totalMs).clamp(0.0, 1.0) : 0.0;

    final remainingDuration = widget.duration - Duration(milliseconds: currentMs);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider Bar with floating time bubble
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final thumbX = (progress * trackWidth).clamp(24.0, trackWidth - 24.0);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Floating target time preview bubble during scrubbing
                  if (_isDragging)
                    Positioned(
                      left: thumbX - 32,
                      top: -34,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: VeloColors.accentCyan.withValues(alpha: 0.6), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: VeloColors.accentCyan.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _formatDuration(Duration(milliseconds: currentMs)),
                          style: VeloTypography.codeTime.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (details) {
                      setState(() {
                        _isDragging = true;
                      });
                      widget.onScrubStart?.call();
                      _updateDragPosition(details.localPosition.dx, trackWidth);
                    },
                    onHorizontalDragUpdate: (details) {
                      _updateDragPosition(details.localPosition.dx, trackWidth);
                    },
                    onHorizontalDragEnd: (_) {
                      setState(() {
                        _isDragging = false;
                      });
                      final seekTarget = Duration(milliseconds: (_dragValue * totalMs).toInt());
                      widget.onScrubEnd?.call(seekTarget);
                      widget.onSeek(seekTarget);
                    },
                    onTapDown: (details) {
                      final fraction = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                      final seekTarget = Duration(milliseconds: (fraction * totalMs).toInt());
                      widget.onSeek(seekTarget);
                    },
                    child: SizedBox(
                      height: 28,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Background track
                          Container(
                            height: _isDragging ? 5 : 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                          // Buffered track
                          FractionallySizedBox(
                            widthFactor: bufferedProgress,
                            child: Container(
                              height: _isDragging ? 5 : 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),
                          // Played track
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: _isDragging ? 5 : 4,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [VeloColors.accentCyan, VeloColors.primaryContainer],
                                ),
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),
                          // Scrubber thumb
                          Align(
                            alignment: Alignment(progress * 2 - 1, 0),
                            child: Container(
                              width: _isDragging ? 16 : 12,
                              height: _isDragging ? 16 : 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: VeloColors.primaryContainer.withValues(alpha: 0.7),
                                    blurRadius: _isDragging ? 10 : 4,
                                    spreadRadius: _isDragging ? 2 : 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Time Labels (Current Position & Duration / Remaining)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(Duration(milliseconds: currentMs)),
                style: VeloTypography.codeTime.copyWith(color: Colors.white, fontSize: 11),
              ),
              GestureDetector(
                onTap: widget.onToggleRemainingTime,
                child: Tooltip(
                  message: widget.showRemainingTime ? 'Show Total Duration' : 'Show Remaining Time',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      widget.showRemainingTime
                          ? _formatDuration(remainingDuration, isNegative: true)
                          : _formatDuration(widget.duration),
                      style: VeloTypography.codeTime.copyWith(
                        color: widget.showRemainingTime ? VeloColors.accentCyan : VeloColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateDragPosition(double localX, double trackWidth) {
    if (trackWidth <= 0) return;
    final fraction = (localX / trackWidth).clamp(0.0, 1.0);
    setState(() {
      _dragValue = fraction;
    });
    final target = Duration(milliseconds: (fraction * widget.duration.inMilliseconds).toInt());
    widget.onScrubUpdate?.call(target);
  }
}
