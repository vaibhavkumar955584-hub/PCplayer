import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/velo_colors.dart';
import '../../../core/theme/velo_typography.dart';
import '../player_controller.dart';
import '../player_state.dart';
import '../../subtitles/domain/subtitle_appearance.dart';
import '../../ai_subtitles/presentation/ai_subtitle_sheet.dart';
import 'ai_summary_sheet.dart';
import 'keyboard_shortcuts_dialog.dart';

class PlayerSettingsSheet extends StatefulWidget {
  final PlayerState state;
  final PlayerController controller;

  const PlayerSettingsSheet({
    super.key,
    required this.state,
    required this.controller,
  });

  static void show(BuildContext context, PlayerState state, PlayerController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VeloColors.surfaceElevation2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PlayerSettingsSheet(state: state, controller: controller),
    );
  }

  @override
  State<PlayerSettingsSheet> createState() => _PlayerSettingsSheetState();
}

class _PlayerSettingsSheetState extends State<PlayerSettingsSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = widget.controller;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: VeloColors.hairlineBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.tune_rounded, color: VeloColors.accentCyan, size: 20),
                const SizedBox(width: 8),
                Text(
                  'PLAYER SETTINGS',
                  style: VeloTypography.labelSmall.copyWith(
                    color: VeloColors.accentCyan,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorColor: VeloColors.accentCyan,
              labelColor: VeloColors.accentCyan,
              unselectedLabelColor: VeloColors.textTertiary,
              labelStyle: VeloTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Playback'),
                Tab(text: 'Video'),
                Tab(text: 'Audio'),
                Tab(text: 'Subtitles'),
                Tab(text: 'Controls'),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPlaybackTab(state, controller),
                  _buildVideoTab(state, controller),
                  _buildAudioTab(state, controller),
                  _buildSubtitlesTab(state, controller),
                  _buildControlsTab(state, controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Playback Tab ────────────────────────────────────────────────
  Widget _buildPlaybackTab(PlayerState state, PlayerController controller) {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    return ListView(
      shrinkWrap: true,
      children: [
        _buildSectionTitle('PLAYBACK SPEED'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: speeds.map((s) {
            final isSelected = (state.playbackSpeed - s).abs() < 0.05;
            return ChoiceChip(
              label: Text('${s}x'),
              selected: isSelected,
              onSelected: (_) => controller.setPlaybackSpeed(s),
              selectedColor: VeloColors.primaryContainer,
              backgroundColor: VeloColors.surfaceElevation1,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : VeloColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('QUEUE REPEAT MODE'),
        Row(
          children: [
            _buildOptionButton(
              label: 'Off',
              isSelected: state.queue.repeatMode == PlaybackRepeatMode.none,
              icon: Icons.repeat_rounded,
              onTap: () {
                while (state.queue.repeatMode != PlaybackRepeatMode.none) {
                  controller.cycleRepeatMode();
                }
              },
            ),
            const SizedBox(width: 8),
            _buildOptionButton(
              label: 'Repeat All',
              isSelected: state.queue.repeatMode == PlaybackRepeatMode.all,
              icon: Icons.repeat_rounded,
              onTap: () {
                while (state.queue.repeatMode != PlaybackRepeatMode.all) {
                  controller.cycleRepeatMode();
                }
              },
            ),
            const SizedBox(width: 8),
            _buildOptionButton(
              label: 'Repeat One',
              isSelected: state.queue.repeatMode == PlaybackRepeatMode.one,
              icon: Icons.repeat_one_rounded,
              onTap: () {
                while (state.queue.repeatMode != PlaybackRepeatMode.one) {
                  controller.cycleRepeatMode();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('QUEUE PREFERENCES'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Shuffle Queue', style: VeloTypography.labelLarge),
          subtitle: Text('Play upcoming videos in randomized order', style: VeloTypography.bodyMedium.copyWith(fontSize: 12)),
          value: state.queue.isShuffled,
          activeTrackColor: VeloColors.primaryContainer,
          onChanged: (_) => controller.toggleShuffle(),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Auto-Play Next Video', style: VeloTypography.labelLarge),
          subtitle: Text('Automatically advance when current video finishes', style: VeloTypography.bodyMedium.copyWith(fontSize: 12)),
          value: SettingsService.autoPlayNext,
          activeTrackColor: VeloColors.primaryContainer,
          onChanged: (val) {
            setState(() => SettingsService.autoPlayNext = val);
          },
        ),
      ],
    );
  }

  // ─── Video Tab ───────────────────────────────────────────────────
  Widget _buildVideoTab(PlayerState state, PlayerController controller) {
    final modes = [
      (VideoScaleMode.fit, 'Fit', 'Preserve ratio, fit entire video in screen'),
      (VideoScaleMode.fill, 'Fill', 'Fill full screen, preserve ratio, crop edges'),
      (VideoScaleMode.stretch, 'Stretch', 'Stretch video to edges ignoring ratio'),
      (VideoScaleMode.original, '100% Original', 'Native 1:1 pixel resolution'),
      (VideoScaleMode.zoom, 'Zoom 1.25x', 'Slightly enlarged cinematic view'),
    ];

    return ListView(
      shrinkWrap: true,
      children: [
        _buildSectionTitle('ASPECT RATIO & SCALING'),
        ...modes.map((m) {
          final isSelected = state.scaleMode == m.$1;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? VeloColors.accentCyan : VeloColors.textTertiary,
            ),
            title: Text(m.$2, style: VeloTypography.labelLarge.copyWith(color: isSelected ? Colors.white : VeloColors.textSecondary)),
            subtitle: Text(m.$3, style: VeloTypography.bodyMedium.copyWith(fontSize: 12)),
            onTap: () => controller.setScaleMode(m.$1),
          );
        }),
      ],
    );
  }

  // ─── Audio Tab ───────────────────────────────────────────────────
  Widget _buildAudioTab(PlayerState state, PlayerController controller) {
    return ListView(
      shrinkWrap: true,
      children: [
        _buildSectionTitle('VOLUME'),
        Row(
          children: [
            IconButton(
              icon: Icon(
                state.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: state.isMuted ? VeloColors.error : VeloColors.accentCyan,
              ),
              onPressed: controller.toggleMute,
            ),
            Expanded(
              child: Slider(
                value: state.isMuted ? 0.0 : state.volume,
                min: 0.0,
                max: 1.0,
                activeColor: VeloColors.accentCyan,
                inactiveColor: Colors.white24,
                onChanged: (v) => controller.setVolume(v),
              ),
            ),
            Text(
              state.isMuted ? 'Muted' : '${(state.volume * 100).round()}%',
              style: VeloTypography.codeBadge,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('AUDIO STREAMS'),
        ...state.audioTracks.map((track) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.audiotrack_rounded, color: VeloColors.accentCyan),
            title: Text(track.label, style: VeloTypography.labelLarge),
            subtitle: Text('Language: ${track.language}', style: VeloTypography.bodyMedium.copyWith(fontSize: 12)),
            trailing: const Icon(Icons.check_rounded, color: VeloColors.accentCyan, size: 20),
          );
        }),
      ],
    );
  }

  // ─── Subtitles Tab ───────────────────────────────────────────────
  Widget _buildSubtitlesTab(PlayerState state, PlayerController controller) {
    return ListView(
      shrinkWrap: true,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Enable Subtitles', style: VeloTypography.labelLarge),
          subtitle: Text(state.hasSubtitles ? 'Display overlay text on video' : 'No subtitles currently loaded', style: VeloTypography.bodyMedium.copyWith(fontSize: 12)),
          value: state.subtitleEnabled,
          activeTrackColor: VeloColors.primaryContainer,
          onChanged: (_) => controller.toggleSubtitles(),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            AiSubtitleSheet.show(context, state, controller);
          },
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          label: const Text('AI Subtitles & Multi-Language Tracks'),
          style: FilledButton.styleFrom(
            backgroundColor: VeloColors.primaryContainer,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: () {
            Navigator.pop(context);
            AiSummarySheet.show(context, state, controller);
          },
          icon: const Icon(Icons.summarize_rounded, size: 18),
          label: const Text('AI Summary & Chapters'),
          style: FilledButton.styleFrom(
            backgroundColor: VeloColors.surfaceElevation1,
            foregroundColor: VeloColors.accentCyan,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: controller.loadSubtitlesFromPicker,
          icon: const Icon(Icons.file_open_rounded, size: 18),
          label: const Text('Load External Subtitle File (.srt, .vtt)'),
          style: FilledButton.styleFrom(
            backgroundColor: VeloColors.surfaceElevation1,
            foregroundColor: VeloColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('SUBTITLE STYLE PRESETS'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SubtitlePreset.values.map((preset) {
            final isSelected = state.subtitleAppearance.preset == preset;
            return ChoiceChip(
              label: Text(preset.label),
              selected: isSelected,
              selectedColor: VeloColors.primaryContainer,
              backgroundColor: VeloColors.surfaceElevation1,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : VeloColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (_) => controller.setSubtitlePreset(preset),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('SUBTITLE FONT SIZE'),
        Row(
          children: [
            const Text('A', style: TextStyle(fontSize: 12, color: VeloColors.textTertiary)),
            Expanded(
              child: Slider(
                value: state.subtitleSize,
                min: 12.0,
                max: 32.0,
                divisions: 10,
                label: '${state.subtitleSize.round()}pt',
                activeColor: VeloColors.accentCyan,
                inactiveColor: Colors.white24,
                onChanged: (v) => controller.setSubtitleSize(v),
              ),
            ),
            const Text('A', style: TextStyle(fontSize: 22, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionTitle('SUBTITLE DELAY & SYNC TIMING (-5.0s to +5.0s)'),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => controller.adjustSubtitleOffset(-0.5),
              child: const Text('-0.5s'),
            ),
            Expanded(
              child: Slider(
                value: state.subtitleOffset.clamp(-5.0, 5.0),
                min: -5.0,
                max: 5.0,
                divisions: 100,
                label: '${state.subtitleOffset >= 0 ? '+' : ''}${state.subtitleOffset.toStringAsFixed(1)}s',
                activeColor: VeloColors.accentCyan,
                inactiveColor: Colors.white24,
                onChanged: (v) {
                  controller.adjustSubtitleOffset(v - state.subtitleOffset);
                },
              ),
            ),
            OutlinedButton(
              onPressed: () => controller.adjustSubtitleOffset(0.5),
              child: const Text('+0.5s'),
            ),
          ],
        ),
        Center(
          child: TextButton.icon(
            onPressed: () => controller.adjustSubtitleOffset(-state.subtitleOffset),
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Reset Sync to 0.0s'),
            style: TextButton.styleFrom(foregroundColor: VeloColors.textTertiary),
          ),
        ),
      ],
    );
  }

  // ─── Controls Tab ────────────────────────────────────────────────
  Widget _buildControlsTab(PlayerState state, PlayerController controller) {
    return ListView(
      shrinkWrap: true,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Player Lock', style: VeloTypography.labelLarge),
          subtitle: Text('Lock all controls to prevent accidental touches', style: VeloTypography.bodyMedium.copyWith(fontSize: 12)),
          value: state.isLocked,
          activeTrackColor: VeloColors.accentCyan,
          onChanged: (_) {
            controller.toggleLock();
            Navigator.pop(context);
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Touch Gestures', style: VeloTypography.labelLarge),
          subtitle: Text('Swipe for volume, brightness & double-tap skip', style: VeloTypography.bodyMedium.copyWith(fontSize: 12)),
          value: SettingsService.gestureControls,
          activeTrackColor: VeloColors.primaryContainer,
          onChanged: (val) {
            setState(() => SettingsService.gestureControls = val);
          },
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.keyboard_rounded, color: VeloColors.accentCyan),
          title: Text('Keyboard Shortcuts Reference', style: VeloTypography.labelLarge),
          subtitle: Text('View desktop & keyboard VLC media shortcuts', style: VeloTypography.bodyMedium.copyWith(fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: VeloColors.textTertiary),
          onTap: () {
            Navigator.pop(context);
            KeyboardShortcutsDialog.show(context);
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: VeloTypography.labelSmall.copyWith(
          color: VeloColors.textTertiary,
          letterSpacing: 1.1,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? VeloColors.primaryContainer : VeloColors.surfaceElevation1,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? VeloColors.accentCyan : VeloColors.hairlineBorder,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : VeloColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : VeloColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
