import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/velo_colors.dart';
import '../../core/theme/velo_typography.dart';
import '../../core/widgets/velo_components.dart';
import 'player_controller.dart';
import 'player_state.dart';
import 'widgets/player_controls.dart';
import 'widgets/player_gesture_layer.dart';
import 'widgets/player_settings_sheet.dart';
import 'widgets/subtitle_overlay.dart';
import 'widgets/video_info_dialog.dart';
import '../ai_subtitles/presentation/ai_subtitle_sheet.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final int videoId;
  final List<int>? queue;
  final String? networkUrl;
  final QueueSource source;
  final String? sourceTitle;

  const PlayerScreen({
    super.key,
    required this.videoId,
    this.queue,
    this.networkUrl,
    this.source = QueueSource.library,
    this.sourceTitle,
  });

  static Route<void> route({
    required int videoId,
    List<int>? queue,
    String? networkUrl,
    QueueSource source = QueueSource.library,
    String? sourceTitle,
  }) {
    return MaterialPageRoute(
      builder: (_) => PlayerScreen(
        videoId: videoId,
        queue: queue,
        networkUrl: networkUrl,
        source: source,
        sourceTitle: sourceTitle,
      ),
    );
  }

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> with WidgetsBindingObserver {
  late final FocusNode _focusNode;

  ({int videoId, List<int>? queue, String? networkUrl}) get _providerArgs => (
        videoId: widget.videoId,
        queue: widget.queue,
        networkUrl: widget.networkUrl,
      );

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    // Desktop (Windows/macOS/Linux) apps should NOT pause when losing focus or switching tasks!
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return;
    }
    // On mobile, pause only when application is detached
    if (lifecycle == AppLifecycleState.detached) {
      final notifier = ref.read(playerControllerProvider(_providerArgs).notifier);
      notifier.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        windowManager.setFullScreen(false);
      } catch (_) {}
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFullscreenToggle(bool goFullscreen) async {
    final controller = ref.read(playerControllerProvider(_providerArgs).notifier);
    controller.toggleFullscreen(goFullscreen);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        await windowManager.setFullScreen(goFullscreen);
      } catch (_) {}
    } else if (Platform.isAndroid || Platform.isIOS) {
      if (goFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    }
  }

  void _handlePop(BuildContext context, bool isFullscreen) {
    if (isFullscreen) {
      _handleFullscreenToggle(false);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleToggleFavorite(Video video) async {
    if (video.id == null) return;
    final newFav = !video.isFavorite;
    await AppDatabase.setFavorite(video.id!, newFav);
    refreshFavorites(ref);
    final controller = ref.read(playerControllerProvider(_providerArgs).notifier);
    controller.showGestureFeedback(
      GestureFeedbackType.seek,
      newFav ? 'Added to Favorites' : 'Removed from Favorites',
    );
  }

  Future<void> _handleAddToPlaylist(Video video) async {
    if (video.id == null) return;
    final playlists = await AppDatabase.getAllPlaylists();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: VeloColors.surfaceElevation2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: VeloColors.hairlineBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text('ADD TO PLAYLIST', style: VeloTypography.labelSmall.copyWith(letterSpacing: 1.2, color: VeloColors.textTertiary)),
              const SizedBox(height: 8),
              if (playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No playlists found. Create one in Playlists tab.', style: VeloTypography.bodyMedium),
                )
              else
                ...playlists.map((pl) => ListTile(
                  leading: const Icon(Icons.playlist_play_rounded, color: VeloColors.accentCyan),
                  title: Text(pl.name, style: VeloTypography.labelLarge),
                  onTap: () async {
                    await AppDatabase.addVideoToPlaylist(pl.id!, video.id!);
                    if (ctx.mounted) Navigator.pop(ctx);
                    ref.read(playerControllerProvider(_providerArgs).notifier).showGestureFeedback(
                      GestureFeedbackType.seek,
                      'Added to ${pl.name}',
                    );
                  },
                )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerControllerProvider(_providerArgs));
    final controller = ref.read(playerControllerProvider(_providerArgs).notifier);

    // Mouse cursor auto-hiding in fullscreen on desktop
    final hideCursor = state.isFullscreen && !state.controlsVisible && !state.isLoading;

    return PopScope(
      canPop: !state.isFullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handlePop(context, state.isFullscreen);
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          // Never intercept keyboard shortcuts if a text input currently has focus!
          final primaryFocus = FocusManager.instance.primaryFocus;
          if (primaryFocus != null && primaryFocus.context?.widget is EditableText) {
            return KeyEventResult.ignored;
          }

          if (event is KeyDownEvent) {
            final isShift = HardwareKeyboard.instance.isShiftPressed;
            final isControl = HardwareKeyboard.instance.isControlPressed;

            switch (event.logicalKey) {
              case LogicalKeyboardKey.space:
              case LogicalKeyboardKey.keyK:
                controller.togglePlayPause();
                return KeyEventResult.handled;

              case LogicalKeyboardKey.arrowLeft:
              case LogicalKeyboardKey.keyJ:
                if (isShift) {
                  controller.skipBackward(30);
                } else {
                  controller.skipBackward(10);
                }
                return KeyEventResult.handled;

              case LogicalKeyboardKey.arrowRight:
              case LogicalKeyboardKey.keyL:
                if (isShift) {
                  controller.skipForward(30);
                } else {
                  controller.skipForward(10);
                }
                return KeyEventResult.handled;

              case LogicalKeyboardKey.arrowUp:
                controller.adjustVolume(0.05);
                return KeyEventResult.handled;

              case LogicalKeyboardKey.arrowDown:
                controller.adjustVolume(-0.05);
                return KeyEventResult.handled;

              case LogicalKeyboardKey.keyM:
                controller.toggleMute();
                return KeyEventResult.handled;

              case LogicalKeyboardKey.keyF:
                if (isControl) {
                  VideoInfoDialog.show(context, state);
                } else {
                  _handleFullscreenToggle(!state.isFullscreen);
                }
                return KeyEventResult.handled;

              case LogicalKeyboardKey.keyI:
                VideoInfoDialog.show(context, state);
                return KeyEventResult.handled;

              case LogicalKeyboardKey.escape:
                _handlePop(context, state.isFullscreen);
                return KeyEventResult.handled;

              case LogicalKeyboardKey.bracketLeft:
                controller.decreaseSpeed();
                return KeyEventResult.handled;

              case LogicalKeyboardKey.bracketRight:
                controller.increaseSpeed();
                return KeyEventResult.handled;

              case LogicalKeyboardKey.keyS:
                controller.cycleScaleMode();
                return KeyEventResult.handled;

              case LogicalKeyboardKey.digit0:
              case LogicalKeyboardKey.numpad0:
                controller.seekTo(Duration.zero);
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit1:
              case LogicalKeyboardKey.numpad1:
                controller.seekTo(Duration(milliseconds: (state.duration.inMilliseconds * 0.1).round()));
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit2:
              case LogicalKeyboardKey.numpad2:
                controller.seekTo(Duration(milliseconds: (state.duration.inMilliseconds * 0.2).round()));
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit3:
              case LogicalKeyboardKey.numpad3:
                controller.seekTo(Duration(milliseconds: (state.duration.inMilliseconds * 0.3).round()));
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit4:
              case LogicalKeyboardKey.numpad4:
                controller.seekTo(Duration(milliseconds: (state.duration.inMilliseconds * 0.4).round()));
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit5:
              case LogicalKeyboardKey.numpad5:
                controller.seekTo(Duration(milliseconds: (state.duration.inMilliseconds * 0.5).round()));
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit6:
              case LogicalKeyboardKey.numpad6:
                controller.seekTo(Duration(milliseconds: (state.duration.inMilliseconds * 0.6).round()));
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit7:
              case LogicalKeyboardKey.numpad7:
                controller.seekTo(Duration(milliseconds: (state.duration.inMilliseconds * 0.7).round()));
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit8:
              case LogicalKeyboardKey.numpad8:
                controller.seekTo(Duration(milliseconds: (state.duration.inMilliseconds * 0.8).round()));
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit9:
              case LogicalKeyboardKey.numpad9:
                controller.seekTo(Duration(milliseconds: (state.duration.inMilliseconds * 0.9).round()));
                return KeyEventResult.handled;

              case LogicalKeyboardKey.keyN:
                controller.playNext();
                return KeyEventResult.handled;

              case LogicalKeyboardKey.keyP:
                controller.playPrevious();
                return KeyEventResult.handled;

              case LogicalKeyboardKey.keyC:
                controller.toggleSubtitles();
                return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: hideCursor ? SystemMouseCursors.none : SystemMouseCursors.basic,
          onHover: (_) => controller.onPointerActivity(),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: state.hasError
                ? _buildErrorView(state, controller)
                : (state.isFullscreen
                    ? _buildFullscreenView(state, controller)
                    : _buildWindowedView(state, controller)),
          ),
        ),
      ),
    );
  }

  // ─── Windowed Mode Layout ──────────────────────────────────────────
  Widget _buildWindowedView(PlayerState state, PlayerController controller) {
    final video = state.video;

    return Column(
      children: [
        // ── Video Viewport ───────────────────────────────────────────
        SafeArea(
          bottom: false,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildVideoSurface(state, controller),
                SubtitleOverlay(state: state),
                GestureFeedbackOverlay(state: state),
                _buildHudControls(state, controller),
              ],
            ),
          ),
        ),

        // ── Windowed Details & Queue Section ─────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              // Resume Prompt Banner (if active)
              if (state.resumePromptPosition != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: VeloColors.surfaceElevation2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: VeloColors.accentCyan.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, color: VeloColors.accentCyan, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Resumed from ${_formatDuration(state.resumePromptPosition!)}',
                          style: VeloTypography.bodyMedium.copyWith(fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: controller.startOver,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Start Over', style: TextStyle(color: VeloColors.accentCyan)),
                      ),
                    ],
                  ),
                ),

              // Title and Specs Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video?.title ?? 'Velo Video Player',
                          style: VeloTypography.headlineSmall.copyWith(fontSize: 17),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (video != null && video.resolutionLabel.isNotEmpty) ...[
                              SpecChip(label: video.resolutionLabel, highlight: true),
                              const SizedBox(width: 6),
                              SpecChip(label: video.formatLabel),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              video?.formattedSize ?? '',
                              style: VeloTypography.codeBadge.copyWith(color: VeloColors.textTertiary, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Enter Fullscreen Button
                  FilledButton.icon(
                    onPressed: () => _handleFullscreenToggle(true),
                    icon: const Icon(Icons.fullscreen_rounded, size: 18),
                    label: const Text('Fullscreen'),
                    style: FilledButton.styleFrom(
                      backgroundColor: VeloColors.primaryContainer,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Actions Toolbar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(
                    icon: video != null && video.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: video != null && video.isFavorite ? Colors.redAccent : Colors.white70,
                    label: 'Favorite',
                    onTap: video != null ? () => _handleToggleFavorite(video) : null,
                  ),
                  _buildQuickAction(
                    icon: Icons.playlist_add_rounded,
                    color: Colors.white70,
                    label: 'Playlist',
                    onTap: video != null ? () => _handleAddToPlaylist(video) : null,
                  ),
                  _buildQuickAction(
                    icon: Icons.auto_awesome_rounded,
                    color: VeloColors.primaryContainer,
                    label: 'AI Subtitles',
                    onTap: () => AiSubtitleSheet.show(context, state, controller),
                  ),
                  _buildQuickAction(
                    icon: Icons.info_outline_rounded,
                    color: Colors.white70,
                    label: 'Media Info',
                    onTap: () => VideoInfoDialog.show(context, state),
                  ),
                  _buildQuickAction(
                    icon: Icons.tune_rounded,
                    color: VeloColors.accentCyan,
                    label: 'Settings',
                    onTap: () => PlayerSettingsSheet.show(context, state, controller),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Playback Queue / Up Next Section
              if (state.queue.items.length > 1) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PLAYBACK QUEUE (${state.queue.items.length})',
                      style: VeloTypography.labelSmall.copyWith(
                        color: VeloColors.textTertiary,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      state.queue.isShuffled ? 'Shuffled' : 'Sequential',
                      style: VeloTypography.codeBadge.copyWith(color: VeloColors.accentCyan, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: VeloColors.surfaceElevation1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: VeloColors.hairlineBorder, width: 1),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.queue.activeOrder.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: VeloColors.hairlineBorder),
                    itemBuilder: (context, i) {
                      final itemIdx = state.queue.activeOrder[i];
                      if (itemIdx < 0 || itemIdx >= state.queue.items.length) return const SizedBox.shrink();
                      final item = state.queue.items[itemIdx];
                      final isCurrent = i == state.queue.currentActiveIndex;

                      return ListTile(
                        selected: isCurrent,
                        selectedTileColor: VeloColors.primaryContainer.withValues(alpha: 0.15),
                        leading: SizedBox(
                          width: 52,
                          height: 36,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              VideoThumbnail(thumbnailPath: item.thumbnailPath),
                              if (isCurrent)
                                Container(
                                  color: Colors.black45,
                                  child: const Center(
                                    child: Icon(Icons.play_arrow_rounded, color: VeloColors.accentCyan, size: 20),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: VeloTypography.labelLarge.copyWith(
                            color: isCurrent ? VeloColors.accentCyan : Colors.white,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          item.formattedDuration,
                          style: VeloTypography.codeTime.copyWith(color: VeloColors.textTertiary, fontSize: 10),
                        ),
                        trailing: isCurrent
                            ? const SpecChip(label: 'PLAYING', highlight: true)
                            : null,
                        onTap: () => controller.jumpToQueueIndex(i),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Immersive Fullscreen Mode Layout ──────────────────────────────
  Widget _buildFullscreenView(PlayerState state, PlayerController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildVideoSurface(state, controller),
        SubtitleOverlay(state: state),
        GestureFeedbackOverlay(state: state),
        _buildHudControls(state, controller),
      ],
    );
  }

  // ─── Common Video Surface & Gesture Integration ────────────────────
  Widget _buildVideoSurface(PlayerState state, PlayerController controller) {
    return PlayerGestureLayer(
      isLocked: state.isLocked,
      gesturesEnabled: SettingsService.gestureControls,
      volume: state.isMuted ? 0.0 : state.volume,
      brightness: state.brightness,
      position: state.position,
      duration: state.duration,
      onTap: () {
        _focusNode.requestFocus();
        controller.toggleControls();
      },
      onDoubleTapLeft: () => controller.skipBackward(10),
      onDoubleTapRight: () => controller.skipForward(10),
      onDoubleTapCenter: () => _handleFullscreenToggle(!state.isFullscreen),
      onVolumeChanged: (v) => controller.setVolume(v),
      onBrightnessChanged: (b) => controller.setBrightness(b),
      onHorizontalSeekEnd: (target) => controller.seekTo(target),
      onPointerMove: () {
        _focusNode.requestFocus();
        controller.onPointerActivity();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: _buildVideoView(controller, state),
          ),
          // Brightness Dim Tint
          if (state.brightness < 1.0)
            IgnorePointer(
              child: Container(
                color: Colors.black.withValues(alpha: 1.0 - state.brightness),
              ),
            ),
          // Loading spinner
          if (state.isLoading)
            const Center(
              child: VeloLoadingState(message: 'Loading media stream...'),
            ),
        ],
      ),
    );
  }

  Widget _buildHudControls(PlayerState state, PlayerController controller) {
    final video = state.video;

    return PlayerControls(
      state: state,
      controller: controller,
      onPlayPause: () => controller.togglePlayPause(),
      onSkipForward: () => controller.skipForward(10),
      onSkipBackward: () => controller.skipBackward(10),
      onSeek: (target) => controller.seekTo(target),
      onPlayNext: state.hasNext ? () => controller.playNext() : null,
      onPlayPrevious: state.hasPrevious ? () => controller.playPrevious() : null,
      onToggleScaleMode: () => controller.cycleScaleMode(),
      onToggleFullscreen: () => _handleFullscreenToggle(!state.isFullscreen),
      onToggleLock: () => controller.toggleLock(),
      onBack: () => _handlePop(context, state.isFullscreen),
      onUserInteraction: () => controller.resetControlsTimer(),
      onToggleSubtitles: () => controller.toggleSubtitles(),
      onLoadSubtitles: () => controller.loadSubtitlesFromPicker(),
      onOpenSubtitleMenu: () => AiSubtitleSheet.show(context, state, controller),
      onVolumeChanged: (v) => controller.setVolume(v),
      onToggleMute: () => controller.toggleMute(),
      onBrightnessChanged: (b) => controller.setBrightness(b),
      onToggleRemainingTime: () => controller.toggleTimeDisplay(),
      onToggleShuffle: () => controller.toggleShuffle(),
      onCycleRepeatMode: () => controller.cycleRepeatMode(),
      onToggleFavorite: video != null ? () => _handleToggleFavorite(video) : null,
      onAddToPlaylist: video != null ? () => _handleAddToPlaylist(video) : null,
    );
  }

  Widget _buildVideoView(PlayerController controller, PlayerState state) {
    final vpc = controller.videoPlayerController;
    if (vpc == null || !vpc.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final videoSize = vpc.value.size;

    if (state.scaleMode == VideoScaleMode.original) {
      return Center(
        child: SizedBox(
          width: videoSize.width,
          height: videoSize.height,
          child: VideoPlayer(vpc),
        ),
      );
    }

    if (state.scaleMode == VideoScaleMode.zoom) {
      return Transform.scale(
        scale: 1.25,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: videoSize.width,
            height: videoSize.height,
            child: VideoPlayer(vpc),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: state.fit,
        child: SizedBox(
          width: videoSize.width,
          height: videoSize.height,
          child: VideoPlayer(vpc),
        ),
      ),
    );
  }

  Widget _buildErrorView(PlayerState state, PlayerController controller) {
    if (state.isMissingFile) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.file_present_rounded, color: VeloColors.warning, size: 56),
                const SizedBox(height: 16),
                Text('Video Unavailable', style: VeloTypography.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'The media file could not be found on storage.\nIt may have been moved, renamed, or deleted.',
                  textAlign: TextAlign.center,
                  style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        ref.read(scanProvider.notifier).scanDevice();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('Rescan Library'),
                      style: FilledButton.styleFrom(backgroundColor: VeloColors.primaryContainer),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () async {
                        if (state.video?.id != null) {
                          await AppDatabase.deleteVideo(state.video!.id!);
                        }
                        if (mounted) Navigator.of(context).pop();
                      },
                      child: const Text('Remove from Library'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Center(
        child: VeloErrorState(
          message: state.errorMessage ?? 'Playback error occurred.',
          onRetry: () => controller.loadVideo(state.video?.id ?? widget.videoId),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: VeloColors.surfaceElevation1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VeloColors.hairlineBorder, width: 1),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: VeloTypography.labelSmall.copyWith(fontSize: 11, color: VeloColors.textSecondary)),
        ],
      ),
    );
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
}
