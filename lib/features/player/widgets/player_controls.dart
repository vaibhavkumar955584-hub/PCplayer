import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/velo_colors.dart';
import '../../../core/theme/velo_typography.dart';
import '../../../core/widgets/velo_components.dart';
import '../player_controller.dart';
import '../player_state.dart';
import 'ai_summary_sheet.dart';
import 'keyboard_shortcuts_dialog.dart';
import 'player_progress.dart';
import 'player_settings_sheet.dart';
import 'video_info_dialog.dart';

class PlayerControls extends StatefulWidget {
  final PlayerState state;
  final PlayerController controller;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipForward;
  final VoidCallback onSkipBackward;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onPlayNext;
  final VoidCallback? onPlayPrevious;
  final VoidCallback onToggleScaleMode;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onToggleLock;
  final VoidCallback onBack;
  final VoidCallback onUserInteraction;
  final VoidCallback onToggleSubtitles;
  final VoidCallback onLoadSubtitles;
  final VoidCallback? onOpenSubtitleMenu;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleMute;
  final ValueChanged<double> onBrightnessChanged;
  final VoidCallback onToggleRemainingTime;
  final VoidCallback onToggleShuffle;
  final VoidCallback onCycleRepeatMode;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onRemoveVideo;

  const PlayerControls({
    super.key,
    required this.state,
    required this.controller,
    required this.onPlayPause,
    required this.onSkipForward,
    required this.onSkipBackward,
    required this.onSeek,
    this.onPlayNext,
    this.onPlayPrevious,
    required this.onToggleScaleMode,
    required this.onToggleFullscreen,
    required this.onToggleLock,
    required this.onBack,
    required this.onUserInteraction,
    required this.onToggleSubtitles,
    required this.onLoadSubtitles,
    this.onOpenSubtitleMenu,
    required this.onVolumeChanged,
    required this.onToggleMute,
    required this.onBrightnessChanged,
    required this.onToggleRemainingTime,
    required this.onToggleShuffle,
    required this.onCycleRepeatMode,
    this.onToggleFavorite,
    this.onAddToPlaylist,
    this.onRemoveVideo,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  bool _showVolumeSlider = false;
  bool _showBrightnessSlider = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final video = state.video;

    return AnimatedOpacity(
      opacity: state.controlsVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !state.controlsVisible,
        child: state.isLocked
            ? SafeArea(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: GestureDetector(
                      onTap: widget.onToggleLock,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: VeloColors.accentCyan, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: VeloColors.accentCyan.withValues(alpha: 0.4),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.lock_rounded, color: VeloColors.accentCyan, size: 28),
                      ),
                    ),
                  ),
                ),
              )
            : GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  widget.onUserInteraction();
                  if (_showVolumeSlider || _showBrightnessSlider) {
                    setState(() {
                      _showVolumeSlider = false;
                      _showBrightnessSlider = false;
                    });
                  }
                },
                child: Stack(
                  children: [
                    // Top Shadow Gradient
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 120,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom Shadow Gradient
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 160,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Top App Bar ──────────────────────────────────
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              // Back button
                              GestureDetector(
                                onTap: widget.onBack,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white24, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          state.isFullscreen ? Icons.fullscreen_exit_rounded : Icons.arrow_back_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          state.isFullscreen ? 'Exit Fullscreen' : 'Back',
                                          style: VeloTypography.labelMedium.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Video title & spec
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      video?.title ?? 'Playing Video',
                                      style: VeloTypography.labelLarge.copyWith(color: Colors.white, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (video != null && video.resolutionLabel.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          SpecChip(label: video.resolutionLabel, highlight: true),
                                          const SizedBox(width: 4),
                                          SpecChip(label: video.formatLabel),
                                          if (state.queue.items.length > 1) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              '${state.queue.currentActiveIndex + 1}/${state.queue.items.length}',
                                              style: VeloTypography.codeBadge.copyWith(
                                                color: VeloColors.textTertiary,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Subtitle toggle & AI sheet
                              _TopBarButton(
                                icon: state.subtitleEnabled
                                    ? Icons.closed_caption_rounded
                                    : Icons.closed_caption_off_rounded,
                                color: state.subtitleEnabled ? VeloColors.accentCyan : Colors.white54,
                                tooltip: 'Subtitles & AI Transcripts',
                                onTap: () {
                                  if (widget.onOpenSubtitleMenu != null) {
                                    widget.onOpenSubtitleMenu!();
                                  } else if (state.hasSubtitles) {
                                    widget.onToggleSubtitles();
                                  } else {
                                    widget.onLoadSubtitles();
                                  }
                                },
                              ),
                              const SizedBox(width: 4),

                              // Speed badge
                              GestureDetector(
                                onTap: () => PlayerSettingsSheet.show(context, state, widget.controller),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white24, width: 0.5),
                                  ),
                                  child: Text(
                                    '${state.playbackSpeed}x',
                                    style: VeloTypography.codeBadge.copyWith(color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),

                              // Settings / More options
                              _TopBarButton(
                                icon: Icons.more_vert_rounded,
                                tooltip: 'More Options',
                                onTap: () => _showMoreOptions(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Center Controls ───────────────────────────────
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (state.hasPrevious) ...[
                            IconButton(
                              onPressed: widget.onPlayPrevious,
                              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 38),
                              tooltip: 'Previous Video (P)',
                            ),
                            const SizedBox(width: 12),
                          ],
                          IconButton(
                            onPressed: widget.onSkipBackward,
                            icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 40),
                            tooltip: 'Rewind 10s (Left Arrow)',
                          ),
                          const SizedBox(width: 20),
                          // Main Play/Pause Button
                          GestureDetector(
                            onTap: widget.onPlayPause,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: VeloColors.primaryContainer,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: VeloColors.primaryContainer.withValues(alpha: 0.55),
                                    blurRadius: 24,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: state.isLoading
                                  ? const Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      ),
                                    )
                                  : Icon(
                                      state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 42,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            onPressed: widget.onSkipForward,
                            icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 40),
                            tooltip: 'Forward 10s (Right Arrow)',
                          ),
                          if (state.hasNext) ...[
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: widget.onPlayNext,
                              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 38),
                              tooltip: 'Next Video (N)',
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Volume Slider Popup ────────────────────────────
                    if (_showVolumeSlider)
                      Positioned(
                        bottom: 96,
                        right: 16,
                        child: _VerticalSliderPopup(
                          value: state.isMuted ? 0.0 : state.volume,
                          color: Colors.amber,
                          icon: state.isMuted || state.volume == 0
                              ? Icons.volume_off_rounded
                              : (state.volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                          label: state.isMuted ? 'Muted' : '${(state.volume * 100).round()}%',
                          onChanged: widget.onVolumeChanged,
                        ),
                      ),

                    // ── Brightness Slider Popup ─────────────────────────
                    if (_showBrightnessSlider)
                      Positioned(
                        bottom: 96,
                        left: 16,
                        child: _VerticalSliderPopup(
                          value: state.brightness,
                          color: Colors.orangeAccent,
                          icon: Icons.brightness_6_rounded,
                          label: '${(state.brightness * 100).round()}%',
                          onChanged: widget.onBrightnessChanged,
                        ),
                      ),

                    // ── Bottom Controls Bar ──────────────────────────────
                    SafeArea(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PlayerProgress(
                              position: state.position,
                              duration: state.duration,
                              buffered: state.buffered,
                              showRemainingTime: state.showRemainingTime,
                              onToggleRemainingTime: widget.onToggleRemainingTime,
                              onSeek: widget.onSeek,
                              onScrubStart: () {
                                widget.controller.onScrubStart();
                                widget.onUserInteraction();
                              },
                              onScrubUpdate: (target) {
                                widget.controller.onScrubUpdate(target);
                              },
                              onScrubEnd: (target) {
                                widget.controller.onScrubEnd(target);
                                widget.onUserInteraction();
                              },
                            ),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Row(
                                children: [
                                  // Lock button
                                  IconButton(
                                    onPressed: widget.onToggleLock,
                                    icon: const Icon(Icons.lock_open_rounded, color: Colors.white70, size: 20),
                                    tooltip: 'Lock controls (L)',
                                  ),

                                  // Brightness toggle
                                  IconButton(
                                    onPressed: () => setState(() {
                                      _showBrightnessSlider = !_showBrightnessSlider;
                                      if (_showBrightnessSlider) _showVolumeSlider = false;
                                    }),
                                    icon: Icon(
                                      Icons.brightness_6_rounded,
                                      color: _showBrightnessSlider ? Colors.orangeAccent : Colors.white70,
                                      size: 20,
                                    ),
                                    tooltip: 'Brightness',
                                  ),

                                  // Volume button
                                  IconButton(
                                    onPressed: () => setState(() {
                                      _showVolumeSlider = !_showVolumeSlider;
                                      if (_showVolumeSlider) _showBrightnessSlider = false;
                                    }),
                                    icon: Icon(
                                      state.isMuted || state.volume == 0
                                          ? Icons.volume_off_rounded
                                          : (state.volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                                      color: _showVolumeSlider ? Colors.amber : Colors.white70,
                                      size: 20,
                                    ),
                                    tooltip: 'Volume (M to mute)',
                                  ),

                                  const Spacer(),

                                  // Shuffle Button
                                  IconButton(
                                    onPressed: widget.onToggleShuffle,
                                    icon: Icon(
                                      Icons.shuffle_rounded,
                                      color: state.queue.isShuffled ? VeloColors.accentCyan : Colors.white54,
                                      size: 20,
                                    ),
                                    tooltip: state.queue.isShuffled ? 'Shuffle: On' : 'Shuffle: Off',
                                  ),

                                  // Repeat Mode Button
                                  IconButton(
                                    onPressed: widget.onCycleRepeatMode,
                                    icon: Icon(
                                      state.queue.repeatMode == PlaybackRepeatMode.one
                                          ? Icons.repeat_one_rounded
                                          : Icons.repeat_rounded,
                                      color: state.queue.repeatMode != PlaybackRepeatMode.none
                                          ? VeloColors.accentCyan
                                          : Colors.white54,
                                      size: 20,
                                    ),
                                    tooltip: switch (state.queue.repeatMode) {
                                      PlaybackRepeatMode.none => 'Repeat: Off',
                                      PlaybackRepeatMode.all => 'Repeat: All',
                                      PlaybackRepeatMode.one => 'Repeat: One',
                                    },
                                  ),

                                  // Aspect ratio / Scale mode
                                  TextButton.icon(
                                    onPressed: widget.onToggleScaleMode,
                                    icon: const Icon(Icons.aspect_ratio_rounded, color: Colors.white70, size: 18),
                                    label: Text(
                                      switch (state.scaleMode) {
                                        VideoScaleMode.fit => 'FIT',
                                        VideoScaleMode.fill => 'FILL',
                                        VideoScaleMode.stretch => 'STRETCH',
                                        VideoScaleMode.original => 'ORIG',
                                        VideoScaleMode.zoom => 'ZOOM',
                                      },
                                      style: VeloTypography.codeBadge.copyWith(color: Colors.white70, fontSize: 10),
                                    ),
                                  ),

                                  // Fullscreen button
                                  IconButton(
                                    onPressed: widget.onToggleFullscreen,
                                    icon: Icon(
                                      state.isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                                      color: state.isFullscreen ? VeloColors.accentCyan : Colors.white70,
                                      size: 22,
                                    ),
                                    tooltip: state.isFullscreen ? 'Exit Fullscreen (Esc / F)' : 'Fullscreen (F)',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    final state = widget.state;
    final video = state.video;

    showModalBottomSheet(
      context: context,
      backgroundColor: VeloColors.surfaceElevation2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: VeloColors.hairlineBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('MORE OPTIONS', style: VeloTypography.labelSmall.copyWith(letterSpacing: 1.2, color: VeloColors.textTertiary)),
              const SizedBox(height: 12),

              // Player Settings
              ListTile(
                leading: const Icon(Icons.tune_rounded, color: VeloColors.accentCyan),
                title: Text('Playback & Video Settings', style: VeloTypography.labelLarge),
                onTap: () {
                  Navigator.pop(ctx);
                  PlayerSettingsSheet.show(context, state, widget.controller);
                },
              ),

              // AI Summary & Chapters
              ListTile(
                leading: const Icon(Icons.summarize_rounded, color: VeloColors.accentCyan),
                title: Text('AI Summary & Chapters', style: VeloTypography.labelLarge),
                subtitle: Text('Topical breakdown and key takeaways', style: VeloTypography.bodyMedium.copyWith(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  AiSummarySheet.show(context, state, widget.controller);
                },
              ),

              // Video Information
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: VeloColors.textSecondary),
                title: Text('Media Information', style: VeloTypography.labelLarge),
                subtitle: Text('Resolution, codec, file size, bitrates', style: VeloTypography.bodyMedium.copyWith(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  VideoInfoDialog.show(context, state);
                },
              ),

              // Keyboard Shortcuts
              ListTile(
                leading: const Icon(Icons.keyboard_rounded, color: VeloColors.textSecondary),
                title: Text('Keyboard Shortcuts Reference', style: VeloTypography.labelLarge),
                onTap: () {
                  Navigator.pop(ctx);
                  KeyboardShortcutsDialog.show(context);
                },
              ),

              // Add to Playlist
              if (video != null && widget.onAddToPlaylist != null)
                ListTile(
                  leading: const Icon(Icons.playlist_add_rounded, color: VeloColors.textSecondary),
                  title: Text('Add to Playlist', style: VeloTypography.labelLarge),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onAddToPlaylist?.call();
                  },
                ),

              // Favorite Toggle
              if (video != null && widget.onToggleFavorite != null)
                ListTile(
                  leading: Icon(
                    video.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: video.isFavorite ? Colors.redAccent : VeloColors.textSecondary,
                  ),
                  title: Text(video.isFavorite ? 'Remove from Favorites' : 'Add to Favorites', style: VeloTypography.labelLarge),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onToggleFavorite?.call();
                  },
                ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? tooltip;
  final VoidCallback onTap;

  const _TopBarButton({
    required this.icon,
    this.color = Colors.white70,
    this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _VerticalSliderPopup extends StatelessWidget {
  final double value;
  final Color color;
  final IconData icon;
  final String label;
  final ValueChanged<double> onChanged;

  const _VerticalSliderPopup({
    required this.value,
    required this.color,
    required this.icon,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
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
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: color,
                  inactiveTrackColor: color.withValues(alpha: 0.25),
                  thumbColor: color,
                  overlayColor: color.withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: value.clamp(0.0, 1.0),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
