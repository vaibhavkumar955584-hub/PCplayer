import 'package:flutter/material.dart';
import '../../../core/theme/velo_colors.dart';
import '../../../core/theme/velo_typography.dart';
import '../../../core/database/app_database.dart';
import '../player_controller.dart';
import '../player_state.dart';
import '../../ai_subtitles/data/ai_summary_service.dart';
import '../../ai_subtitles/domain/ai_chapter_model.dart';
import '../../ai_subtitles/presentation/ai_subtitle_sheet.dart';

class AiSummarySheet extends StatefulWidget {
  final PlayerState state;
  final PlayerController controller;

  const AiSummarySheet({
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
      builder: (_) => AiSummarySheet(state: state, controller: controller),
    );
  }

  @override
  State<AiSummarySheet> createState() => _AiSummarySheetState();
}

class _AiSummarySheetState extends State<AiSummarySheet> {
  AiSummaryResult? _summaryResult;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final videoId = widget.state.video?.id;
    final videoTitle = widget.state.video?.title ?? 'Video';

    if (videoId == null) {
      setState(() {
        _isLoading = false;
        _summaryResult = null;
      });
      return;
    }

    // Try loading segments from active track or primary subtitle track
    final tracks = await AppDatabase.getSubtitleTracksForVideo(videoId);
    if (tracks.isNotEmpty) {
      final segments = await AppDatabase.getSubtitleSegmentsForTrack(tracks.first.id!);
      if (segments.isNotEmpty) {
        final result = AiSummaryService.generateFromSegments(segments, videoTitle: videoTitle);
        if (mounted) {
          setState(() {
            _summaryResult = result;
            _isLoading = false;
          });
          return;
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _summaryResult = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: VeloColors.accentCyan, size: 22),
                const SizedBox(width: 8),
                Text('AI Summary & Chapters', style: VeloTypography.headlineSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: VeloColors.accentCyan),
                    )
                  : _summaryResult == null || _summaryResult!.chapters.isEmpty
                      ? _buildEmptyState()
                      : _buildSummaryContent(_summaryResult!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VeloColors.surfaceElevation1,
                shape: BoxShape.circle,
                border: Border.all(color: VeloColors.hairlineBorder),
              ),
              child: const Icon(Icons.format_list_bulleted_rounded, color: VeloColors.textTertiary, size: 36),
            ),
            const SizedBox(height: 16),
            Text('No Dialogue Available', style: VeloTypography.labelLarge.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Generate AI subtitles first to unlock automatic chapter detection, summaries, and key takeaways.',
              textAlign: TextAlign.center,
              style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                AiSubtitleSheet.show(context, widget.state, widget.controller);
              },
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Generate Subtitles with AI'),
              style: FilledButton.styleFrom(backgroundColor: VeloColors.primaryContainer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryContent(AiSummaryResult summary) {
    return ListView(
      children: [
        // Overview Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: VeloColors.surfaceElevation1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VeloColors.hairlineBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OVERVIEW',
                style: VeloTypography.labelSmall.copyWith(
                  color: VeloColors.accentCyan,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                summary.overview,
                style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textPrimary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Key Points
        if (summary.keyPoints.isNotEmpty) ...[
          Text(
            'KEY TAKEAWAYS',
            style: VeloTypography.labelSmall.copyWith(
              color: VeloColors.textTertiary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...summary.keyPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 8),
                    child: Icon(Icons.circle, size: 6, color: VeloColors.accentCyan),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textSecondary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Chapters
        Text(
          'CHAPTERS',
          style: VeloTypography.labelSmall.copyWith(
            color: VeloColors.textTertiary,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...summary.chapters.map((chapter) => _buildChapterTile(chapter)),
      ],
    );
  }

  Widget _buildChapterTile(AiChapter chapter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: VeloColors.surfaceElevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VeloColors.hairlineBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: VeloColors.accentCyan.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            chapter.formattedStartTime,
            style: VeloTypography.codeBadge.copyWith(color: VeloColors.accentCyan),
          ),
        ),
        title: Text(chapter.title, style: VeloTypography.labelLarge),
        subtitle: chapter.summary.isNotEmpty
            ? Text(
                chapter.summary,
                style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textTertiary, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.play_circle_fill_rounded, color: VeloColors.accentCyan, size: 24),
        onTap: () {
          widget.controller.seekTo(chapter.start);
          Navigator.pop(context);
        },
      ),
    );
  }
}
