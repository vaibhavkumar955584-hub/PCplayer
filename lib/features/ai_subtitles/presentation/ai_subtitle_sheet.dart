import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/subtitle_service.dart';
import '../../../core/theme/velo_colors.dart';
import '../../../core/theme/velo_typography.dart';
import '../../player/player_controller.dart';
import '../../player/player_state.dart';
import '../../subtitles/domain/subtitle_models.dart';
import '../data/ai_subtitle_job_manager.dart';

class AiSubtitleSheet extends ConsumerStatefulWidget {
  final PlayerState state;
  final PlayerController controller;

  const AiSubtitleSheet({
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
      builder: (_) => AiSubtitleSheet(state: state, controller: controller),
    );
  }

  @override
  ConsumerState<AiSubtitleSheet> createState() => _AiSubtitleSheetState();
}

class _AiSubtitleSheetState extends ConsumerState<AiSubtitleSheet> {
  List<DbSubtitleTrack> _dbTracks = [];
  bool _isLoadingTracks = true;
  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String _generationStatus = '';
  String _selectedTargetLanguage = 'hi';

  static const List<({String code, String name, String flag})> _supportedLanguages = [
    (code: 'en', name: 'English', flag: '🇺🇸'),
    (code: 'hi', name: 'Hindi (हिन्दी)', flag: '🇮🇳'),
    (code: 'es', name: 'Spanish (Español)', flag: '🇪🇸'),
    (code: 'fr', name: 'French (Français)', flag: '🇫🇷'),
    (code: 'de', name: 'German (Deutsch)', flag: '🇩🇪'),
    (code: 'ja', name: 'Japanese (日本語)', flag: '🇯🇵'),
    (code: 'ar', name: 'Arabic (العربية)', flag: '🇸🇦'),
    (code: 'pt', name: 'Portuguese (Português)', flag: '🇧🇷'),
    (code: 'ru', name: 'Russian (Русский)', flag: '🇷🇺'),
    (code: 'zh', name: 'Chinese (中文)', flag: '🇨🇳'),
  ];

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final videoId = widget.state.video?.id;
    if (videoId == null) {
      if (mounted) setState(() => _isLoadingTracks = false);
      return;
    }
    final tracks = await AppDatabase.getSubtitleTracksForVideo(videoId);
    if (mounted) {
      setState(() {
        _dbTracks = tracks;
        _isLoadingTracks = false;
      });
    }
  }

  Future<void> _startAiGeneration(String targetLang) async {
    final video = widget.state.video;
    if (video == null) return;

    setState(() {
      _isGenerating = true;
      _generationProgress = 0.05;
      _generationStatus = 'Initializing pipeline...';
    });

    try {
      final track = await AiSubtitleJobManager.instance.generateSubtitles(
        video: video,
        targetLanguage: targetLang,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _generationProgress = progress;
              _generationStatus = status;
            });
          }
        },
      );

      // Fetch segments from SQLite and activate in player
      if (track.id != null) {
        final segments = await AppDatabase.getSubtitleSegmentsForTrack(track.id!);
        final entries = segments.map((s) => SubtitleEntry(
          start: s.start,
          end: s.end,
          text: s.text,
        )).toList();

        final subtitleTrack = SubtitleTrack(
          id: 'db_${track.id}',
          title: '${track.languageName} (AI)',
          language: track.languageCode,
          isExternal: false,
        );

        widget.controller.loadSubtitleEntries(subtitleTrack, entries);
      }

      await _loadTracks();
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generationProgress = 1.0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generationStatus = 'Error: $e';
        });
      }
    }
  }

  Future<void> _selectDbTrack(DbSubtitleTrack track) async {
    if (track.id == null) return;
    final segments = await AppDatabase.getSubtitleSegmentsForTrack(track.id!);
    final entries = segments.map((s) => SubtitleEntry(
      start: s.start,
      end: s.end,
      text: s.text,
    )).toList();

    final subtitleTrack = SubtitleTrack(
      id: 'db_${track.id}',
      title: '${track.languageName} ${track.isAiGenerated ? '(AI)' : ''}',
      language: track.languageCode,
      isExternal: false,
    );

    widget.controller.loadSubtitleEntries(subtitleTrack, entries);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                const Icon(Icons.subtitles_rounded, color: VeloColors.accentCyan, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SUBTITLES & AI ENGINE',
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
            const Divider(color: VeloColors.hairlineBorder),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Generation progress card if actively transcribing/translating
                  if (_isGenerating) _buildProgressCard(),

                  // Subtitles Off toggle option
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.subtitles_off_rounded,
                      color: !state.subtitleEnabled ? VeloColors.error : VeloColors.textTertiary,
                    ),
                    title: Text(
                      'Subtitles Off',
                      style: VeloTypography.labelLarge.copyWith(
                        color: !state.subtitleEnabled ? Colors.white : VeloColors.textSecondary,
                      ),
                    ),
                    trailing: !state.subtitleEnabled
                        ? const Icon(Icons.check_rounded, color: VeloColors.accentCyan, size: 20)
                        : null,
                    onTap: () {
                      if (state.subtitleEnabled) widget.controller.toggleSubtitles();
                      Navigator.pop(context);
                    },
                  ),

                  // Loaded sidecar / external tracks
                  if (state.subtitleTracks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildSectionHeader('LOADED TRACKS'),
                    ...state.subtitleTracks.map((t) {
                      final isSelected = state.subtitleEnabled && state.selectedSubtitleTrack?.id == t.id;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.description_outlined, color: VeloColors.accentCyan),
                        title: Text(t.title, style: VeloTypography.labelLarge),
                        subtitle: Text(
                          t.isExternal ? 'External file' : 'Sidecar track',
                          style: VeloTypography.bodyMedium.copyWith(fontSize: 12),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded, color: VeloColors.accentCyan, size: 20)
                            : null,
                        onTap: () {
                          widget.controller.selectSubtitleTrack(t);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],

                  if (_isLoadingTracks)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: VeloColors.accentCyan),
                        ),
                      ),
                    )
                  else if (_dbTracks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildSectionHeader('SAVED SUBTITLE TRACKS'),
                    ..._dbTracks.map((t) {
                      final isSelected = state.subtitleEnabled && state.selectedSubtitleTrack?.id == 'db_${t.id}';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          t.isAiGenerated ? Icons.auto_awesome_rounded : Icons.subtitles_rounded,
                          color: t.isAiGenerated ? VeloColors.primaryContainer : VeloColors.accentCyan,
                        ),
                        title: Text(
                          t.languageName,
                          style: VeloTypography.labelLarge.copyWith(
                            color: isSelected ? Colors.white : VeloColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          t.isAiGenerated ? (t.isTranslated ? 'AI Translated' : 'AI Canonical Speech') : 'Local Database',
                          style: VeloTypography.bodyMedium.copyWith(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Icon(Icons.check_rounded, color: VeloColors.accentCyan, size: 20),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: VeloColors.textTertiary),
                              onPressed: () async {
                                if (t.id != null) {
                                  await AppDatabase.deleteSubtitleTrack(t.id!);
                                  _loadTracks();
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () => _selectDbTrack(t),
                      );
                    }),
                  ],

                  const SizedBox(height: 16),
                  _buildSectionHeader('AI SUBTITLE PIPELINE'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VeloColors.surfaceElevation1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: VeloColors.hairlineBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: VeloColors.accentCyan, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Generate Multi-Language Subtitles',
                              style: VeloTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Detects spoken audio, generates a canonical transcript, and translates into any chosen language completely local-first.',
                          style: VeloTypography.bodyMedium.copyWith(fontSize: 12, color: VeloColors.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedTargetLanguage,
                                dropdownColor: VeloColors.surfaceElevation2,
                                decoration: InputDecoration(
                                  labelText: 'Target Language',
                                  labelStyle: const TextStyle(color: VeloColors.textSecondary, fontSize: 13),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: VeloColors.hairlineBorder),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: _supportedLanguages.map((l) {
                                  return DropdownMenuItem<String>(
                                    value: l.code,
                                    child: Row(
                                      children: [
                                        Text(l.flag, style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Text(l.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedTargetLanguage = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: _isGenerating ? null : () => _startAiGeneration(_selectedTargetLanguage),
                              icon: const Icon(Icons.play_arrow_rounded, size: 18),
                              label: const Text('Generate'),
                              style: FilledButton.styleFrom(
                                backgroundColor: VeloColors.primaryContainer,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  _buildSectionHeader('EXTERNAL FILE'),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.controller.loadSubtitlesFromPicker();
                    },
                    icon: const Icon(Icons.file_open_rounded, size: 18),
                    label: const Text('Open External Subtitle (.srt, .vtt)'),
                    style: FilledButton.styleFrom(
                      backgroundColor: VeloColors.surfaceElevation1,
                      foregroundColor: VeloColors.accentCyan,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        title,
        style: VeloTypography.labelSmall.copyWith(
          color: VeloColors.accentCyan,
          letterSpacing: 1.1,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VeloColors.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VeloColors.primaryContainer.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: VeloColors.accentCyan),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _generationStatus,
                  style: VeloTypography.labelLarge.copyWith(color: Colors.white),
                ),
              ),
              Text(
                '${(_generationProgress * 100).round()}%',
                style: VeloTypography.codeBadge.copyWith(color: VeloColors.accentCyan),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _generationProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(VeloColors.accentCyan),
            ),
          ),
        ],
      ),
    );
  }
}
