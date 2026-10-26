import 'package:flutter/material.dart';
import '../../../core/theme/velo_colors.dart';
import '../player_state.dart';
import '../../subtitles/domain/subtitle_appearance.dart';

/// Displays the current subtitle text overlaid on the video using [SubtitleAppearance].
class SubtitleOverlay extends StatelessWidget {
  final PlayerState state;

  const SubtitleOverlay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.subtitleEnabled || state.currentSubtitle == null) {
      return const SizedBox.shrink();
    }

    final text = state.currentSubtitle!.text;
    final style = state.subtitleAppearance;
    final isTop = style.position == SubtitleVerticalPosition.top;

    final bottomOffset = isTop
        ? null
        : (state.controlsVisible ? 92.0 : style.bottomOffset);
    final topOffset = isTop ? (state.controlsVisible ? 84.0 : 36.0) : null;

    final shadows = <Shadow>[];
    if (style.hasShadow) {
      shadows.add(Shadow(
        color: style.shadowColor,
        offset: const Offset(1.5, 1.5),
        blurRadius: 4,
      ));
    }
    if (style.hasOutline) {
      // Create multi-directional outline shadow effect
      shadows.addAll([
        Shadow(color: style.outlineColor, offset: Offset(-style.outlineWidth, -style.outlineWidth)),
        Shadow(color: style.outlineColor, offset: Offset(style.outlineWidth, -style.outlineWidth)),
        Shadow(color: style.outlineColor, offset: Offset(-style.outlineWidth, style.outlineWidth)),
        Shadow(color: style.outlineColor, offset: Offset(style.outlineWidth, style.outlineWidth)),
      ]);
    }

    final hasBg = style.backgroundOpacity > 0.0;

    return Positioned(
      left: 20,
      right: 20,
      bottom: bottomOffset,
      top: topOffset,
      child: Center(
        child: Container(
          padding: hasBg ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6) : EdgeInsets.zero,
          decoration: hasBg
              ? BoxDecoration(
                  color: style.backgroundColor.withValues(alpha: style.backgroundOpacity),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12, width: 0.5),
                )
              : null,
          child: Text(
            text,
            textAlign: style.alignment,
            style: TextStyle(
              color: style.textColor,
              fontSize: style.fontSize,
              fontWeight: style.fontWeight,
              height: 1.35,
              shadows: shadows.isNotEmpty ? shadows : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a temporary gesture or setting feedback indicator
class GestureFeedbackOverlay extends StatelessWidget {
  final PlayerState state;

  const GestureFeedbackOverlay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final feedback = state.gestureFeedback;
    if (feedback == null) return const SizedBox.shrink();

    IconData icon;
    Color color;

    switch (feedback.type) {
      case GestureFeedbackType.seek:
        icon = Icons.fast_forward_rounded;
        color = VeloColors.accentCyan;
        break;
      case GestureFeedbackType.volume:
        icon = Icons.volume_up_rounded;
        color = Colors.amber;
        break;
      case GestureFeedbackType.brightness:
        icon = Icons.brightness_6_rounded;
        color = Colors.orangeAccent;
        break;
      case GestureFeedbackType.speed:
        icon = Icons.speed_rounded;
        color = const Color(0xFF10B981);
        break;
      case GestureFeedbackType.scale:
        icon = Icons.aspect_ratio_rounded;
        color = VeloColors.primaryContainer;
        break;
    }

    return Center(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    feedback.message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),
              if (feedback.level != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 120,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: feedback.level!.clamp(0.0, 1.0),
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
