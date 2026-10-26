import 'package:flutter/material.dart';
import '../../../core/theme/velo_colors.dart';
import '../../../core/theme/velo_typography.dart';
import '../player_state.dart';

class VideoInfoDialog extends StatelessWidget {
  final PlayerState state;

  const VideoInfoDialog({super.key, required this.state});

  static void show(BuildContext context, PlayerState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VeloColors.surfaceElevation2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => VideoInfoDialog(state: state),
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

  @override
  Widget build(BuildContext context) {
    final video = state.video;

    return SafeArea(
      child: Padding(
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
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: VeloColors.accentCyan, size: 22),
                const SizedBox(width: 8),
                Text(
                  'MEDIA INFORMATION',
                  style: VeloTypography.labelSmall.copyWith(
                    color: VeloColors.accentCyan,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              video?.title ?? 'Active Video',
              style: VeloTypography.headlineSmall.copyWith(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VeloColors.surfaceElevation1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VeloColors.hairlineBorder, width: 1),
              ),
              child: Column(
                children: [
                  _buildRow('Resolution', video != null && video.width > 0 ? '${video.width} × ${video.height} (${video.resolutionLabel})' : 'Auto / Native'),
                  _buildDivider(),
                  _buildRow('Format / Container', video?.formatLabel ?? 'MP4'),
                  _buildDivider(),
                  _buildRow('Duration', _formatDuration(state.duration)),
                  _buildDivider(),
                  _buildRow('Current Position', _formatDuration(state.position)),
                  _buildDivider(),
                  _buildRow('File Size', video?.formattedSize ?? 'Unknown'),
                  _buildDivider(),
                  _buildRow('Audio Stream', state.selectedAudioTrack?.label ?? 'Default Stereo'),
                  _buildDivider(),
                  _buildRow('Subtitles', state.subtitleEnabled ? (state.selectedSubtitleTrack?.title ?? 'Active') : 'Disabled'),
                  if (video != null && video.path.isNotEmpty) ...[
                    _buildDivider(),
                    _buildRow('File Path', video.path, isPath: true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isPath = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: isPath ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textTertiary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: VeloTypography.codeBadge.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
              maxLines: isPath ? 3 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: VeloColors.hairlineBorder);
  }
}
