import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/playlist_providers.dart';
import '../../core/theme/velo_colors.dart';
import '../../core/theme/velo_typography.dart';
import '../../core/widgets/velo_components.dart';
import '../player/player_screen.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  static Route<void> route({required Playlist playlist}) {
    return MaterialPageRoute(
      builder: (_) => PlaylistDetailScreen(playlist: playlist),
    );
  }

  void _showAddVideosSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VeloColors.surfaceElevation2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _AddVideosModal(playlistId: playlist.id!);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVideos = ref.watch(playlistVideosProvider(playlist.id!));

    return Scaffold(
      backgroundColor: VeloColors.canvasBase,
      body: SafeArea(
        child: Column(
          children: [
            VeloTopBar(
              title: playlist.name,
              subtitle: 'PLAYLIST',
              showBack: true,
              onBack: () => Navigator.of(context).pop(),
              actions: [
                IconButton(
                  onPressed: () => _showAddVideosSheet(context, ref),
                  icon: const Icon(Icons.add_to_photos_rounded, color: VeloColors.accentCyan, size: 22),
                  tooltip: 'Add Videos',
                ),
              ],
            ),
            Expanded(
              child: asyncVideos.when(
                loading: () => const VeloLoadingState(message: 'Loading playlist videos...'),
                error: (e, _) => VeloErrorState(
                  message: 'Failed to load videos: $e',
                  onRetry: () => refreshPlaylists(ref),
                ),
                data: (videos) {
                  if (videos.isEmpty) {
                    return VeloEmptyState(
                      icon: Icons.playlist_remove_rounded,
                      title: 'Playlist Empty',
                      subtitle: 'Add videos to this playlist from your library',
                      actionLabel: 'Add Videos',
                      onAction: () => _showAddVideosSheet(context, ref),
                    );
                  }

                  final queue = videos.map((v) => v.id!).toList();

                  return Column(
                    children: [
                      // Action buttons: Play All & Shuffle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    PlayerScreen.route(videoId: queue.first, queue: queue),
                                  );
                                },
                                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                                label: Text('Play All (${videos.length})'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: VeloColors.primaryContainer,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              onPressed: () {
                                final shuffled = List<int>.from(queue)..shuffle(Random());
                                Navigator.of(context).push(
                                  PlayerScreen.route(videoId: shuffled.first, queue: shuffled),
                                );
                              },
                              icon: const Icon(Icons.shuffle_rounded, color: VeloColors.accentCyan),
                              style: IconButton.styleFrom(
                                backgroundColor: VeloColors.surfaceElevation1,
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              tooltip: 'Shuffle Play',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Reorderable list of videos
                      Expanded(
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: videos.length,
                          onReorder: (oldIndex, newIndex) async {
                            var targetIndex = newIndex;
                            if (targetIndex > oldIndex) targetIndex -= 1;
                            final reordered = List<Video>.from(videos);
                            final item = reordered.removeAt(oldIndex);
                            reordered.insert(targetIndex, item);

                            final newIds = reordered.map((v) => v.id!).toList();
                            await PlaylistActions.reorderVideos(playlist.id!, newIds);
                            refreshPlaylists(ref);
                          },
                          itemBuilder: (context, index) {
                            final video = videos[index];
                            return _PlaylistVideoRow(
                              key: ValueKey(video.id),
                              video: video,
                              index: index + 1,
                              onTap: () {
                                Navigator.of(context).push(
                                  PlayerScreen.route(videoId: video.id!, queue: queue),
                                );
                              },
                              onRemove: () async {
                                await PlaylistActions.removeVideoFromPlaylist(playlist.id!, video.id!);
                                refreshPlaylists(ref);
                              },
                            );
                          },
                        ),
                      ),
                    ],
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

class _PlaylistVideoRow extends StatelessWidget {
  final Video video;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PlaylistVideoRow({
    super.key,
    required this.video,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: VeloColors.surfaceElevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VeloColors.hairlineBorder, width: 1),
      ),
      child: Row(
        children: [
          // Index label
          SizedBox(
            width: 24,
            child: Text(
              '$index',
              style: VeloTypography.codeBadge.copyWith(color: VeloColors.textTertiary, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Thumbnail
          GestureDetector(
            onTap: onTap,
            child: VideoThumbnail(
              thumbnailPath: video.thumbnailPath,
              width: 60,
              height: 42,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          // Title and duration
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: VeloTypography.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${video.formattedDuration} • ${video.formatLabel}',
                    style: VeloTypography.labelSmall,
                  ),
                ],
              ),
            ),
          ),
          // Remove button
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline_rounded, color: VeloColors.textTertiary, size: 20),
            tooltip: 'Remove from playlist',
          ),
          // Drag handle
          const Icon(Icons.drag_indicator_rounded, color: VeloColors.textTertiary, size: 20),
        ],
      ),
    );
  }
}

class _AddVideosModal extends ConsumerStatefulWidget {
  final int playlistId;
  const _AddVideosModal({required this.playlistId});

  @override
  ConsumerState<_AddVideosModal> createState() => _AddVideosModalState();
}

class _AddVideosModalState extends ConsumerState<_AddVideosModal> {
  final Set<int> _selectedIds = {};
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final allVideosAsync = ref.watch(allVideosProvider);
    final currentVideosAsync = ref.watch(playlistVideosProvider(widget.playlistId));

    final currentIds = currentVideosAsync.asData?.value.map((v) => v.id!).toSet() ?? {};

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 32, height: 4, decoration: BoxDecoration(color: VeloColors.hairlineBorder, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Videos', style: VeloTypography.headlineSmall),
                  if (_selectedIds.isNotEmpty)
                    FilledButton(
                      onPressed: () async {
                        for (final vid in _selectedIds) {
                          await PlaylistActions.addVideoToPlaylist(widget.playlistId, vid);
                        }
                        refreshPlaylists(ref);
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: VeloColors.primaryContainer,
                      ),
                      child: Text('Add (${_selectedIds.length})'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              VeloSearchBar(
                onChanged: (q) => setState(() => _search = q.toLowerCase()),
                hint: 'Filter videos...',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: allVideosAsync.when(
                  loading: () => const VeloLoadingState(),
                  error: (e, _) => VeloErrorState(message: '$e'),
                  data: (videos) {
                    final candidates = videos
                        .where((v) => !currentIds.contains(v.id))
                        .where((v) => _search.isEmpty || v.title.toLowerCase().contains(_search))
                        .toList();

                    if (candidates.isEmpty) {
                      return const VeloEmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'No Videos Available',
                        subtitle: 'All matching videos are already in this playlist',
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: candidates.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final video = candidates[index];
                        final isSelected = _selectedIds.contains(video.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedIds.add(video.id!);
                              } else {
                                _selectedIds.remove(video.id);
                              }
                            });
                          },
                          activeColor: VeloColors.primaryContainer,
                          secondary: VideoThumbnail(
                            thumbnailPath: video.thumbnailPath,
                            width: 50,
                            height: 36,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          title: Text(
                            video.title,
                            style: VeloTypography.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(video.formattedDuration, style: VeloTypography.labelSmall),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
