import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/velo_colors.dart';
import '../../core/theme/velo_typography.dart';
import '../../core/models/models.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/media_scanner_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/widgets/velo_components.dart';
import '../subtitles/domain/subtitle_models.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final void Function(int videoId)? onPlayVideo;
  final void Function(String folderName)? onOpenFolder;
  final VoidCallback? onRescan;

  const LibraryScreen({super.key, this.onPlayVideo, this.onOpenFolder, this.onRescan});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoCountAsync = ref.watch(videoCountProvider);
    final sortOption = ref.watch(sortOptionProvider);
    final filterCategory = ref.watch(filterCategoryProvider);
    final isGrid = ref.watch(isGridViewProvider);

    return Column(
      children: [
        VeloTopBar(
          title: 'Library',
          subtitle: 'YOUR COLLECTION',
          actions: [
            IconButton(
              icon: const Icon(Icons.file_open_rounded, color: VeloColors.accentCyan),
              tooltip: 'Open Video File',
              onPressed: _handleOpenFile,
            ),
            IconButton(
              icon: const Icon(Icons.create_new_folder_rounded, color: VeloColors.textPrimary),
              tooltip: 'Add Folder to Scan',
              onPressed: _handleAddFolder,
            ),
            videoCountAsync.when(
              data: (count) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: VeloColors.accentCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'INDEXED $count',
                  style: VeloTypography.codeBadge.copyWith(color: VeloColors.accentCyan, fontSize: 9),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              // Search
              VeloSearchBar(
                controller: _searchController,
                onChanged: (q) => ref.read(searchQueryProvider.notifier).state = q,
                hint: 'Search library...',
              ),
              const SizedBox(height: 14),

              // Sort & View Toggle Row
              Row(
                children: [
                  // Sort dropdown
                  GestureDetector(
                    onTap: () => _showSortMenu(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: VeloColors.surfaceElevation1,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: VeloColors.hairlineBorder, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort_rounded, color: VeloColors.textSecondary, size: 14),
                          const SizedBox(width: 4),
                          Text(sortOption.label, style: VeloTypography.labelSmall.copyWith(color: VeloColors.textPrimary)),
                          const SizedBox(width: 2),
                          Icon(Icons.keyboard_arrow_down_rounded, color: VeloColors.textSecondary, size: 14),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Grid/List toggle
                  Container(
                    decoration: BoxDecoration(
                      color: VeloColors.surfaceElevation1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: VeloColors.hairlineBorder, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => ref.read(isGridViewProvider.notifier).state = true,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isGrid ? VeloColors.primaryContainer.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                            ),
                            child: Icon(Icons.grid_view_rounded, size: 16, color: isGrid ? Colors.white : VeloColors.textTertiary),
                          ),
                        ),
                        Container(width: 1, height: 20, color: VeloColors.hairlineBorder),
                        GestureDetector(
                          onTap: () => ref.read(isGridViewProvider.notifier).state = false,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: !isGrid ? VeloColors.primaryContainer.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                            ),
                            child: Icon(Icons.view_list_rounded, size: 16, color: !isGrid ? Colors.white : VeloColors.textTertiary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Category pills
              _CategoryPills(filterCategory: filterCategory, ref: ref),
              const SizedBox(height: 16),

              // Content
              _LibraryContent(
                isGrid: isGrid,
                filterCategory: filterCategory,
                onPlayVideo: widget.onPlayVideo,
                onOpenFolder: widget.onOpenFolder,
                onOpenFile: _handleOpenFile,
                onAddFolder: _handleAddFolder,
              ),

              const SizedBox(height: 16),

              // Device sync card
              _DeviceSyncCard(
                onRescan: widget.onRescan,
                onAddFolder: _handleAddFolder,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleOpenFile() async {
    final video = await MediaScannerService.pickAndImportSingleFile();
    if (video != null && video.id != null) {
      ref.invalidate(allVideosProvider);
      ref.invalidate(videoFoldersProvider);
      ref.invalidate(videoCountProvider);
      ref.invalidate(recentlyAddedProvider);
      widget.onPlayVideo?.call(video.id!);
    }
  }

  Future<void> _handleAddFolder() async {
    final count = await MediaScannerService.pickAndScanFolder();
    if (count != null && mounted) {
      ref.invalidate(allVideosProvider);
      ref.invalidate(videoFoldersProvider);
      ref.invalidate(videoCountProvider);
      ref.invalidate(recentlyAddedProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count == 0 ? 'Folder added. No new videos found.' : 'Found $count new video${count == 1 ? '' : 's'}!'),
          backgroundColor: VeloColors.surfaceElevation2,
        ),
      );
    }
  }

  void _showSortMenu(BuildContext context) {
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
              Container(width: 32, height: 4, decoration: BoxDecoration(color: VeloColors.hairlineBorder, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Sort By', style: VeloTypography.headlineSmall),
              const SizedBox(height: 8),
              ...VideoSortOption.values.map((option) => ListTile(
                title: Text(option.label, style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textPrimary)),
                trailing: ref.read(sortOptionProvider) == option
                    ? const Icon(Icons.check_rounded, color: VeloColors.primaryContainer, size: 20)
                    : null,
                onTap: () {
                  ref.read(sortOptionProvider.notifier).state = option;
                  Navigator.pop(ctx);
                },
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryPills extends StatelessWidget {
  final VideoFilterCategory filterCategory;
  final WidgetRef ref;

  const _CategoryPills({required this.filterCategory, required this.ref});

  @override
  Widget build(BuildContext context) {
    final videoCountAsync = ref.watch(videoCountProvider);
    final folderCountAsync = ref.watch(videoFoldersProvider);
    final favCountAsync = ref.watch(favoritesProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: VideoFilterCategory.values.map((cat) {
          final isActive = cat == filterCategory;
          String countLabel = '';
          if (cat == VideoFilterCategory.all) {
            countLabel = videoCountAsync.when(data: (c) => ' $c', loading: () => '', error: (e, s) => '');
          } else if (cat == VideoFilterCategory.videos) {
            countLabel = videoCountAsync.when(data: (c) => ' $c', loading: () => '', error: (e, s) => '');
          } else if (cat == VideoFilterCategory.folders) {
            countLabel = folderCountAsync.when(data: (f) => ' ${f.length}', loading: () => '', error: (e, s) => '');
          } else if (cat == VideoFilterCategory.favorites) {
            countLabel = favCountAsync.when(data: (f) => ' ${f.length}', loading: () => '', error: (e, s) => '');
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref.read(filterCategoryProvider.notifier).state = cat,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? VeloColors.primaryContainer.withValues(alpha: 0.15) : VeloColors.surfaceElevation1,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? VeloColors.primaryContainer.withValues(alpha: 0.4) : VeloColors.hairlineBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(color: VeloColors.primaryContainer, shape: BoxShape.circle),
                      ),
                    Text(
                      '${cat.label}$countLabel',
                      style: VeloTypography.labelMedium.copyWith(
                        color: isActive ? VeloColors.textPrimary : VeloColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LibraryContent extends ConsumerWidget {
  final bool isGrid;
  final VideoFilterCategory filterCategory;
  final void Function(int videoId)? onPlayVideo;
  final void Function(String folderName)? onOpenFolder;
  final VoidCallback? onOpenFile;
  final VoidCallback? onAddFolder;

  const _LibraryContent({
    required this.isGrid,
    required this.filterCategory,
    this.onPlayVideo,
    this.onOpenFolder,
    this.onOpenFile,
    this.onAddFolder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show folders view
    if (filterCategory == VideoFilterCategory.folders) {
      return _FoldersView(onOpenFolder: onOpenFolder);
    }

    // Show favorites
    if (filterCategory == VideoFilterCategory.favorites) {
      final asyncFavs = ref.watch(favoritesProvider);
      return asyncFavs.when(
        loading: () => const VeloLoadingState(),
        error: (e, _) => VeloErrorState(message: 'Failed to load favorites: $e'),
        data: (videos) {
          if (videos.isEmpty) {
            return const VeloEmptyState(icon: Icons.favorite_border_rounded, title: 'No Favorites', subtitle: 'Tap the heart icon on any video to add it here');
          }
          return _buildVideoContent(videos, isGrid, ref);
        },
      );
    }

    // All / Videos
    final searchQuery = ref.watch(searchQueryProvider);
    if (searchQuery.isNotEmpty) {
      final asyncSearch = ref.watch(searchResultsProvider);
      final asyncSubSearch = ref.watch(subtitleSearchResultsProvider);

      return asyncSearch.when(
        loading: () => const VeloLoadingState(),
        error: (e, _) => VeloErrorState(message: 'Search failed: $e'),
        data: (videos) {
          return asyncSubSearch.when(
            loading: () => const VeloLoadingState(),
            error: (_, _) => _buildVideoContent(videos, isGrid, ref),
            data: (subResults) {
              if (videos.isEmpty && subResults.isEmpty) {
                return VeloEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No Results',
                  subtitle: 'No videos or spoken dialogue match "$searchQuery"',
                );
              }

              return ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  if (videos.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Text(
                        'VIDEOS (${videos.length})',
                        style: VeloTypography.labelSmall.copyWith(
                          color: VeloColors.accentCyan,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildVideoContent(videos, isGrid, ref),
                    const SizedBox(height: 16),
                  ],
                  if (subResults.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: VeloColors.primaryContainer, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'SPOKEN CONTENT & SUBTITLES (${subResults.length})',
                            style: VeloTypography.labelSmall.copyWith(
                              color: VeloColors.primaryContainer,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...subResults.map((SubtitleSearchResult res) {
                      final timeStr = _formatMs(res.startMs);
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
                              color: VeloColors.primaryContainer.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow_rounded, color: VeloColors.accentCyan, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  timeStr,
                                  style: VeloTypography.codeBadge.copyWith(
                                    color: VeloColors.accentCyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          title: Text(
                            res.videoTitle,
                            style: VeloTypography.labelLarge.copyWith(fontSize: 13, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '"${res.text}"',
                              style: VeloTypography.bodyMedium.copyWith(
                                fontSize: 12,
                                color: VeloColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: VeloColors.surfaceElevation2,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              res.languageName,
                              style: const TextStyle(fontSize: 10, color: VeloColors.textTertiary),
                            ),
                          ),
                          onTap: () async {
                            await AppDatabase.upsertWatchHistory(WatchHistory(
                              videoId: res.videoId,
                              positionMs: res.startMs,
                              durationMs: 0,
                              completionPercentage: 0.05,
                              lastWatchedTimestamp: DateTime.now().millisecondsSinceEpoch,
                            ));
                            onPlayVideo?.call(res.videoId);
                          },
                        ),
                      );
                    }),
                  ],
                ],
              );
            },
          );
        },
      );
    }

    final asyncVideos = ref.watch(sortedVideosProvider);
    return asyncVideos.when(
      loading: () => const VeloLoadingState(),
      error: (e, _) => VeloErrorState(message: 'Failed to load library: $e'),
      data: (videos) {
        if (videos.isEmpty) {
          return _EmptyLibraryView(
            onOpenFile: onOpenFile,
            onAddFolder: onAddFolder,
            onRescan: () {
              ref.read(scanProvider.notifier).scanDevice().then((_) {
                ref.invalidate(allVideosProvider);
                ref.invalidate(videoFoldersProvider);
                ref.invalidate(videoCountProvider);
              });
            },
          );
        }
        return _buildVideoContent(videos, isGrid, ref);
      },
    );
  }

  Widget _buildVideoContent(List<Video> videos, bool isGrid, WidgetRef ref) {
    if (isGrid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: videos.length,
        itemBuilder: (context, index) => _VideoGridCard(video: videos[index], onTap: () => onPlayVideo?.call(videos[index].id!)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: videos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _VideoListRow(video: videos[index], onTap: () => onPlayVideo?.call(videos[index].id!)),
    );
  }

  String _formatMs(int ms) {
    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final hours = d.inHours.toString();
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _FoldersView extends ConsumerWidget {
  final void Function(String folderName)? onOpenFolder;
  const _FoldersView({this.onOpenFolder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFolders = ref.watch(videoFoldersProvider);

    return asyncFolders.when(
      loading: () => const VeloLoadingState(),
      error: (e, _) => VeloErrorState(message: 'Failed to load folders: $e'),
      data: (folders) {
        if (folders.isEmpty) {
          return const VeloEmptyState(icon: Icons.folder_off_rounded, title: 'No Folders', subtitle: 'Videos will be grouped by folder');
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: folders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final folder = folders[index];
            return GestureDetector(
              onTap: () => onOpenFolder?.call(folder.name),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: VeloColors.surfaceElevation1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VeloColors.hairlineBorder, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_rounded, color: VeloColors.accentCyan, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(folder.name, style: VeloTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${folder.videoCount} videos', style: VeloTypography.labelSmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: VeloColors.textTertiary, size: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _VideoGridCard extends StatelessWidget {
  final Video video;
  final VoidCallback? onTap;
  const _VideoGridCard({required this.video, this.onTap});

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

class _VideoListRow extends StatelessWidget {
  final Video video;
  final VoidCallback? onTap;
  const _VideoListRow({required this.video, this.onTap});

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
                        '${video.formattedDuration} • ${video.formattedSize} • ${video.folderName}',
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

class _DeviceSyncCard extends ConsumerWidget {
  final VoidCallback? onRescan;
  final VoidCallback? onAddFolder;

  const _DeviceSyncCard({this.onRescan, this.onAddFolder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);
    final customFolders = SettingsService.customScanFolders;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VeloColors.surfaceElevation1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VeloColors.hairlineBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                scanState.status == ScanStatus.scanning
                    ? Icons.sync_rounded
                    : Icons.storage_rounded,
                color: VeloColors.accentCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                scanState.status == ScanStatus.scanning
                    ? 'Scanning...'
                    : scanState.status == ScanStatus.completed
                        ? 'Scan Complete'
                        : 'Storage & Media Folders',
                style: VeloTypography.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            scanState.status == ScanStatus.scanning
                ? 'Discovering videos across all drives and folders...'
                : scanState.status == ScanStatus.completed
                    ? '${scanState.newCount} new video${scanState.newCount == 1 ? '' : 's'} found'
                    : 'Scans default media directories on all connected drives (C:, D:, etc.) plus any custom folders.',
            style: VeloTypography.bodyMedium,
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: scanState.status == ScanStatus.scanning
                      ? null
                      : () {
                          ref.read(scanProvider.notifier).scanDevice().then((_) {
                            ref.invalidate(allVideosProvider);
                            ref.invalidate(videoFoldersProvider);
                            ref.invalidate(videoCountProvider);
                          });
                        },
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: Text(scanState.status == ScanStatus.scanning ? 'Scanning...' : 'Rescan Storage'),
                  style: FilledButton.styleFrom(
                    backgroundColor: VeloColors.surfaceElevation2,
                    foregroundColor: VeloColors.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddFolder,
                  icon: const Icon(Icons.create_new_folder_rounded, size: 16),
                  label: const Text('Add Folder...'),
                  style: FilledButton.styleFrom(
                    backgroundColor: VeloColors.primaryContainer.withValues(alpha: 0.15),
                    foregroundColor: VeloColors.accentCyan,
                    side: const BorderSide(color: VeloColors.accentCyan, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),

          if (customFolders.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'CUSTOM SCANNED FOLDERS',
              style: VeloTypography.codeBadge.copyWith(fontSize: 10, color: VeloColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: customFolders.map((fPath) {
                return Chip(
                  backgroundColor: VeloColors.surfaceElevation2,
                  label: Text(
                    fPath,
                    style: VeloTypography.labelSmall.copyWith(color: VeloColors.textPrimary, fontSize: 11),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded, size: 14, color: VeloColors.textTertiary),
                  onDeleted: () {
                    SettingsService.removeScanFolder(fPath);
                    ref.invalidate(videoFoldersProvider);
                    ref.invalidate(allVideosProvider);
                    ref.invalidate(videoCountProvider);
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyLibraryView extends StatelessWidget {
  final VoidCallback? onOpenFile;
  final VoidCallback? onAddFolder;
  final VoidCallback? onRescan;

  const _EmptyLibraryView({
    this.onOpenFile,
    this.onAddFolder,
    this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: VeloColors.surfaceElevation1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VeloColors.hairlineBorder, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: VeloColors.accentCyan.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.video_library_rounded, color: VeloColors.accentCyan, size: 30),
          ),
          const SizedBox(height: 16),
          Text('No Videos Indexed Yet', style: VeloTypography.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Your library does not contain any videos yet.\nOpen a video directly from any drive, or select a folder to index.',
            textAlign: TextAlign.center,
            style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (onOpenFile != null)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onOpenFile,
                    icon: const Icon(Icons.file_open_rounded, size: 16),
                    label: const Text('Open File'),
                    style: FilledButton.styleFrom(
                      backgroundColor: VeloColors.primaryContainer,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (onOpenFile != null && onAddFolder != null)
                const SizedBox(width: 12),
              if (onAddFolder != null)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAddFolder,
                    icon: const Icon(Icons.create_new_folder_rounded, size: 16),
                    label: const Text('Add Folder'),
                    style: FilledButton.styleFrom(
                      backgroundColor: VeloColors.surfaceElevation2,
                      foregroundColor: VeloColors.accentCyan,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (onRescan != null)
            TextButton.icon(
              onPressed: onRescan,
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: const Text('Rescan All Connected Drives'),
              style: TextButton.styleFrom(foregroundColor: VeloColors.textSecondary),
            ),
        ],
      ),
    );
  }
}
