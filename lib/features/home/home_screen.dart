import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/velo_colors.dart';
import '../../core/theme/velo_typography.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/media_scanner_service.dart';
import '../../core/widgets/velo_components.dart';
import '../youtube/utils/youtube_url_parser.dart';

class HomeScreen extends ConsumerWidget {
  final void Function(int videoId)? onPlayVideo;
  final void Function(String folderName)? onOpenFolder;
  final Future<void> Function(String url)? onPlayUrl;

  const HomeScreen({super.key, this.onPlayVideo, this.onOpenFolder, this.onPlayUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        VeloTopBar(
          title: 'Velo',
          subtitle: 'LOCAL PLAYER',
          actions: [
            IconButton(
              icon: const Icon(Icons.content_paste_rounded, color: VeloColors.accentCyan),
              tooltip: 'Paste & Play',
              onPressed: () => _handlePasteAndPlay(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.file_open_rounded, color: VeloColors.textPrimary),
              tooltip: 'Open Video File',
              onPressed: () => _handleOpenFile(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.create_new_folder_rounded, color: VeloColors.textSecondary),
              tooltip: 'Add Folder to Scan',
              onPressed: () => _handleAddFolder(context, ref),
            ),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            color: VeloColors.primaryContainer,
            backgroundColor: VeloColors.surfaceElevation1,
            onRefresh: () async {
              ref.invalidate(continueWatchingProvider);
              ref.invalidate(recentlyAddedProvider);
              ref.invalidate(videoFoldersProvider);
              ref.invalidate(favoritesProvider);
              ref.invalidate(allVideosProvider);
              ref.invalidate(videoCountProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              children: [
                VeloSearchBar(
                  onChanged: (q) => ref.read(searchQueryProvider.notifier).state = q,
                ),
                const SizedBox(height: 16),

                // Quick Action Bar
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.file_open_rounded,
                        label: 'Open Video',
                        color: VeloColors.primaryContainer,
                        onTap: () => _handleOpenFile(context, ref),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.content_paste_rounded,
                        label: 'Paste & Play',
                        color: VeloColors.surfaceElevation2,
                        textColor: VeloColors.accentCyan,
                        onTap: () => _handlePasteAndPlay(context, ref),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.link_rounded,
                        label: 'Open URL',
                        color: VeloColors.surfaceElevation2,
                        textColor: VeloColors.textSecondary,
                        onTap: () => _handleOpenUrl(context, ref),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // If no videos exist at all, show empty discovery card
                ref.watch(videoCountProvider).when(
                  data: (count) {
                    if (count == 0) {
                      return _EmptyLibraryHomeCard(
                        onOpenFile: () => _handleOpenFile(context, ref),
                        onAddFolder: () => _handleAddFolder(context, ref),
                        onRescan: () {
                          ref.read(scanProvider.notifier).scanDevice().then((_) {
                            ref.invalidate(allVideosProvider);
                            ref.invalidate(videoFoldersProvider);
                            ref.invalidate(videoCountProvider);
                            ref.invalidate(recentlyAddedProvider);
                          });
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),

                _ContinueWatchingSection(onPlayVideo: onPlayVideo),
                const SizedBox(height: 24),
                _RecentlyAddedSection(onPlayVideo: onPlayVideo),
                const SizedBox(height: 24),
                _LocalFoldersSection(onOpenFolder: onOpenFolder),
                const SizedBox(height: 24),
                _PinnedFavoritesSection(onPlayVideo: onPlayVideo),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleOpenFile(BuildContext context, WidgetRef ref) async {
    final video = await MediaScannerService.pickAndImportSingleFile();
    if (video != null && video.id != null) {
      ref.invalidate(allVideosProvider);
      ref.invalidate(videoFoldersProvider);
      ref.invalidate(videoCountProvider);
      ref.invalidate(recentlyAddedProvider);
      onPlayVideo?.call(video.id!);
    }
  }

  Future<void> _handlePasteAndPlay(BuildContext context, WidgetRef ref) async {
    final clipData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipData?.text?.trim();

    if (text == null || text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty. Copy a video or YouTube link first.'),
            backgroundColor: VeloColors.surfaceElevation2,
          ),
        );
      }
      return;
    }

    final isYouTube = YouTubeUrlParser.isYouTubeUrl(text);
    final ytInfo = isYouTube ? YouTubeUrlParser.parse(text) : null;

    if (isYouTube && ytInfo != null && context.mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: VeloColors.surfaceElevation2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.play_circle_filled_rounded, color: VeloColors.accentCyan, size: 22),
              const SizedBox(width: 8),
              Text('YouTube Video Detected', style: VeloTypography.headlineSmall),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Video ID: ${ytInfo.videoId}', style: VeloTypography.codeBadge),
              if (ytInfo.startSeconds > 0) ...[
                const SizedBox(height: 6),
                Text('Starts at: ${Duration(seconds: ytInfo.startSeconds).inMinutes}:${(ytInfo.startSeconds % 60).toString().padLeft(2, '0')}',
                    style: VeloTypography.bodyMedium.copyWith(color: VeloColors.accentCyan)),
              ],
              const SizedBox(height: 8),
              Text(
                'Play this YouTube video in VDO Player?',
                style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: VeloTypography.labelMedium.copyWith(color: VeloColors.textSecondary)),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Play'),
              style: FilledButton.styleFrom(backgroundColor: VeloColors.primaryContainer),
            ),
          ],
        ),
      );

      if (confirm == true && context.mounted) {
        onPlayUrl?.call(text);
      }
    } else if (text.startsWith('http://') || text.startsWith('https://')) {
      if (context.mounted) {
        onPlayUrl?.call(text);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clipboard content is not a valid video URL: $text'),
            backgroundColor: VeloColors.surfaceElevation2,
          ),
        );
      }
    }
  }

  Future<void> _handleOpenUrl(BuildContext context, WidgetRef ref) async {
    if (onPlayUrl == null) return;
    final controller = TextEditingController();
    
    // Check if clipboard already has a URL to pre-fill hint
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted) return;
    if (clip?.text != null && (clip!.text!.startsWith('http://') || clip.text!.startsWith('https://'))) {
      controller.text = clip.text!.trim();
    }

    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VeloColors.surfaceElevation2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.link_rounded, color: VeloColors.accentCyan, size: 20),
            const SizedBox(width: 8),
            Text('Open Video URL', style: VeloTypography.headlineSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste a YouTube URL or direct video stream (.mp4, .mkv, .m3u8):',
              style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'https://youtube.com/watch?v=... or .mp4',
                hintStyle: VeloTypography.bodyMedium.copyWith(color: VeloColors.textTertiary),
                filled: true,
                fillColor: VeloColors.canvasBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: VeloColors.hairlineBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: VeloColors.accentCyan, width: 1.5),
                ),
                prefixIcon: const Icon(Icons.link_rounded, color: VeloColors.accentCyan, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste_rounded, size: 18, color: VeloColors.accentCyan),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      controller.text = data!.text!.trim();
                    }
                  },
                ),
              ),
              onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: VeloTypography.labelMedium.copyWith(color: VeloColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: VeloColors.primaryContainer),
            child: const Text('Play'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url != null && url.isNotEmpty && context.mounted) {
      onPlayUrl?.call(url);
    }
  }

  Future<void> _handleAddFolder(BuildContext context, WidgetRef ref) async {
    final count = await MediaScannerService.pickAndScanFolder();
    if (count != null && context.mounted) {
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
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: VeloColors.hairlineBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: textColor ?? Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: VeloTypography.labelMedium.copyWith(
                color: textColor ?? Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLibraryHomeCard extends StatelessWidget {
  final VoidCallback onOpenFile;
  final VoidCallback onAddFolder;
  final VoidCallback onRescan;

  const _EmptyLibraryHomeCard({
    required this.onOpenFile,
    required this.onAddFolder,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VeloColors.surfaceElevation1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VeloColors.hairlineBorder, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: VeloColors.accentCyan.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.video_library_rounded, color: VeloColors.accentCyan, size: 28),
          ),
          const SizedBox(height: 14),
          Text('No Videos in Library', style: VeloTypography.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Your collection is empty. Open a video directly from your computer or pick a folder to scan.',
            textAlign: TextAlign.center,
            style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenFile,
                  icon: const Icon(Icons.file_open_rounded, size: 16),
                  label: const Text('Open File'),
                  style: FilledButton.styleFrom(
                    backgroundColor: VeloColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddFolder,
                  icon: const Icon(Icons.create_new_folder_rounded, size: 16),
                  label: const Text('Scan Folder'),
                  style: FilledButton.styleFrom(
                    backgroundColor: VeloColors.surfaceElevation2,
                    foregroundColor: VeloColors.accentCyan,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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

class _ContinueWatchingSection extends ConsumerWidget {
  final void Function(int videoId)? onPlayVideo;
  const _ContinueWatchingSection({this.onPlayVideo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCw = ref.watch(continueWatchingProvider);

    return asyncCw.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final first = items.first;
        final video = first.key;
        final history = first.value;
        final progress = history.durationMs > 0 ? history.positionMs / history.durationMs : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Continue Watching', style: VeloTypography.headlineSmall),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => onPlayVideo?.call(video.id!),
              child: Container(
                decoration: BoxDecoration(
                  color: VeloColors.surfaceElevation1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VeloColors.hairlineBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Stack(
                        children: [
                          VideoThumbnail(
                            thumbnailPath: video.thumbnailPath,
                            width: double.infinity,
                            height: 180,
                            borderRadius: BorderRadius.zero,
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: VeloPlayButton(size: 48, onTap: () => onPlayVideo?.call(video.id!)),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Row(
                              children: [
                                if (video.resolutionLabel.isNotEmpty) SpecChip(label: video.resolutionLabel, highlight: true),
                                const SizedBox(width: 4),
                                SpecChip(label: video.formatLabel),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            style: VeloTypography.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                history.formattedPosition,
                                style: VeloTypography.codeTime.copyWith(color: VeloColors.textSecondary, fontSize: 12),
                              ),
                              Text(
                                ' / ${video.formattedDuration}',
                                style: VeloTypography.codeTime.copyWith(color: VeloColors.textTertiary, fontSize: 12),
                              ),
                              const Spacer(),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: VeloTypography.codeBadge.copyWith(color: VeloColors.accentCyan),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          VideoProgressBar(progress: progress),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentlyAddedSection extends ConsumerWidget {
  final void Function(int videoId)? onPlayVideo;
  const _RecentlyAddedSection({this.onPlayVideo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecent = ref.watch(recentlyAddedProvider);

    return asyncRecent.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (videos) {
        if (videos.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recently Added', style: VeloTypography.headlineSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: videos.length.clamp(0, 10),
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return GestureDetector(
                    onTap: () => onPlayVideo?.call(video.id!),
                    child: SizedBox(
                      width: 130,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VideoThumbnail(
                            thumbnailPath: video.thumbnailPath,
                            width: 130,
                            height: 90,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            video.title,
                            style: VeloTypography.labelMedium.copyWith(color: VeloColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (video.resolutionLabel.isNotEmpty)
                                SpecChip(label: video.resolutionLabel),
                              const SizedBox(width: 4),
                              Text(
                                video.formattedSize,
                                style: VeloTypography.codeBadge.copyWith(fontSize: 9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LocalFoldersSection extends ConsumerWidget {
  final void Function(String folderName)? onOpenFolder;
  const _LocalFoldersSection({this.onOpenFolder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFolders = ref.watch(videoFoldersProvider);

    return asyncFolders.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (folders) {
        if (folders.isEmpty) return const SizedBox.shrink();
        final displayFolders = folders.take(4).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Local Folders', style: VeloTypography.headlineSmall),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: displayFolders.length,
              itemBuilder: (context, index) {
                final folder = displayFolders[index];
                return GestureDetector(
                  onTap: () => onOpenFolder?.call(folder.name),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: VeloColors.surfaceElevation1,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: VeloColors.hairlineBorder, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_rounded, color: VeloColors.accentCyan, size: 24),
                        const SizedBox(height: 6),
                        Text(
                          folder.name,
                          style: VeloTypography.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${folder.videoCount} videos',
                          style: VeloTypography.labelSmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _PinnedFavoritesSection extends ConsumerWidget {
  final void Function(int videoId)? onPlayVideo;
  const _PinnedFavoritesSection({this.onPlayVideo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFavs = ref.watch(favoritesProvider);

    return asyncFavs.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (favorites) {
        if (favorites.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pinned Favorites', style: VeloTypography.headlineSmall),
            const SizedBox(height: 12),
            ...favorites.take(5).map((video) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => onPlayVideo?.call(video.id!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: VeloColors.surfaceElevation1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: VeloColors.hairlineBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      VideoThumbnail(
                        thumbnailPath: video.thumbnailPath,
                        width: 56,
                        height: 40,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              style: VeloTypography.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${video.formattedDuration} • ${video.formatLabel}',
                              style: VeloTypography.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await AppDatabase.setFavorite(video.id!, !video.isFavorite);
                          refreshFavorites(ref);
                        },
                        child: Icon(
                          video.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: video.isFavorite ? VeloColors.tertiary : VeloColors.textTertiary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      VeloPlayButton(size: 32, onTap: () => onPlayVideo?.call(video.id!)),
                    ],
                  ),
                ),
              ),
            )),
          ],
        );
      },
    );
  }
}
