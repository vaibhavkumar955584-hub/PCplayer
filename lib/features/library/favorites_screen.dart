import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/velo_colors.dart';
import '../../core/theme/velo_typography.dart';
import '../../core/widgets/velo_components.dart';
import '../player/player_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFavs = ref.watch(favoritesProvider);

    return Column(
      children: [
        VeloTopBar(
          title: 'Favorites',
          subtitle: 'SAVED VIDEOS',
          actions: [
            asyncFavs.when(
              data: (favs) => favs.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '${favs.length} videos',
                        style: VeloTypography.labelSmall.copyWith(color: VeloColors.textSecondary),
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        Expanded(
          child: asyncFavs.when(
            loading: () => const VeloLoadingState(message: 'Loading favorites...'),
            error: (e, _) => VeloErrorState(
              message: 'Failed to load favorites: $e',
              onRetry: () => ref.invalidate(favoritesProvider),
            ),
            data: (favorites) {
              if (favorites.isEmpty) {
                return const VeloEmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'No Favorites Yet',
                  subtitle: 'Long-press any video or tap ♥ to add it to your favorites.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: favorites.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final video = favorites[index];
                  return _FavoriteVideoCard(
                    video: video,
                    onTap: () {
                      final queue = favorites.map((v) => v.id!).toList();
                      Navigator.of(context).push(
                        PlayerScreen.route(videoId: video.id!, queue: queue),
                      );
                    },
                    onToggleFavorite: () async {
                      await AppDatabase.setFavorite(video.id!, false);
                      refreshFavorites(ref);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FavoriteVideoCard extends StatelessWidget {
  final Video video;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _FavoriteVideoCard({
    required this.video,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VeloColors.surfaceElevation1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VeloColors.hairlineBorder, width: 1),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: VideoThumbnail(
                thumbnailPath: video.thumbnailPath,
                width: 80,
                height: 56,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: VeloTypography.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (video.resolutionLabel.isNotEmpty) ...[
                        SpecChip(label: video.resolutionLabel, highlight: true),
                        const SizedBox(width: 4),
                      ],
                      SpecChip(label: video.formatLabel),
                      const SizedBox(width: 6),
                      Text(
                        '${video.formattedDuration} • ${video.formattedSize}',
                        style: VeloTypography.codeBadge.copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                GestureDetector(
                  onTap: onToggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: VeloColors.tertiary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: VeloColors.tertiary,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                VeloPlayButton(size: 32, onTap: onTap),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
