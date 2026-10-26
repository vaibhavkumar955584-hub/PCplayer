import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/velo_colors.dart';
import '../../core/theme/velo_typography.dart';
import '../../core/widgets/velo_components.dart';
import '../player/player_screen.dart';

class FolderDetailScreen extends ConsumerWidget {
  final String folderName;

  const FolderDetailScreen({super.key, required this.folderName});

  static Route<void> route({required String folderName}) {
    return MaterialPageRoute(
      builder: (_) => FolderDetailScreen(folderName: folderName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVideos = ref.watch(folderVideosProvider(folderName));
    final isGrid = ref.watch(isGridViewProvider);

    return Scaffold(
      backgroundColor: VeloColors.canvasBase,
      body: SafeArea(
        child: Column(
          children: [
            VeloTopBar(
              title: folderName,
              subtitle: 'FOLDER COLLECTION',
              showBack: true,
              onBack: () => Navigator.of(context).pop(),
              actions: [
                asyncVideos.when(
                  data: (videos) => videos.isEmpty
                      ? const SizedBox.shrink()
                      : FilledButton.icon(
                          onPressed: () {
                            final queue = videos.map((v) => v.id!).toList();
                            Navigator.of(context).push(
                              PlayerScreen.route(videoId: queue.first, queue: queue),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Play All'),
                          style: FilledButton.styleFrom(
                            backgroundColor: VeloColors.primaryContainer,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            textStyle: VeloTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),
              ],
            ),
            Expanded(
              child: asyncVideos.when(
                loading: () => const VeloLoadingState(message: 'Loading folder videos...'),
                error: (e, _) => VeloErrorState(
                  message: 'Failed to load videos: $e',
                  onRetry: () => ref.invalidate(folderVideosProvider(folderName)),
                ),
                data: (videos) {
                  if (videos.isEmpty) {
                    return const VeloEmptyState(
                      icon: Icons.folder_off_rounded,
                      title: 'Folder Empty',
                      subtitle: 'No videos found in this folder',
                    );
                  }

                  final queue = videos.map((v) => v.id!).toList();

                  if (isGrid) {
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        return _FolderVideoGridCard(
                          video: video,
                          onTap: () {
                            Navigator.of(context).push(
                              PlayerScreen.route(videoId: video.id!, queue: queue),
                            );
                          },
                        );
                      },
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: videos.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return _FolderVideoListRow(
                        video: video,
                        onTap: () {
                          Navigator.of(context).push(
                            PlayerScreen.route(videoId: video.id!, queue: queue),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderVideoGridCard extends StatelessWidget {
  final Video video;
  final VoidCallback onTap;

  const _FolderVideoGridCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: VeloColors.surfaceElevation1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VeloColors.hairlineBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: VideoThumbnail(
                  thumbnailPath: video.thumbnailPath,
                  width: double.infinity,
                  borderRadius: BorderRadius.zero,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: VeloTypography.labelMedium.copyWith(color: VeloColors.textPrimary, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (video.resolutionLabel.isNotEmpty) SpecChip(label: video.resolutionLabel),
                        const SizedBox(width: 4),
                        SpecChip(label: video.formatLabel),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${video.formattedDuration} • ${video.formattedSize}',
                      style: VeloTypography.codeBadge.copyWith(fontSize: 9),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderVideoListRow extends StatelessWidget {
  final Video video;
  final VoidCallback onTap;

  const _FolderVideoListRow({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: VeloColors.surfaceElevation1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VeloColors.hairlineBorder, width: 1),
        ),
        child: Row(
          children: [
            VideoThumbnail(
              thumbnailPath: video.thumbnailPath,
              width: 72,
              height: 50,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title, style: VeloTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (video.resolutionLabel.isNotEmpty) ...[
                        SpecChip(label: video.resolutionLabel),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '${video.formattedDuration} • ${video.formattedSize}',
                        style: VeloTypography.codeBadge.copyWith(fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_outline_rounded, color: VeloColors.primaryContainer, size: 28),
          ],
        ),
      ),
    );
  }
}
