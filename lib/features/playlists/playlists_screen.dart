import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/playlist_providers.dart';
import '../../core/theme/velo_colors.dart';
import '../../core/theme/velo_typography.dart';
import '../../core/widgets/velo_components.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VeloColors.surfaceElevation2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VeloColors.hairlineBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Create New Playlist', style: VeloTypography.headlineSmall),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Playlist Name',
                  hintStyle: VeloTypography.bodyMedium.copyWith(color: VeloColors.textTertiary),
                  filled: true,
                  fillColor: VeloColors.surfaceElevation1,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: VeloColors.hairlineBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: VeloColors.primaryContainer),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: TextStyle(color: VeloColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final name = textController.text.trim();
                      if (name.isNotEmpty) {
                        await PlaylistActions.createPlaylist(name);
                        refreshPlaylists(ref);
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: VeloColors.primaryContainer,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlaylistOptions(BuildContext context, Playlist playlist) {
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
              Text(playlist.name, style: VeloTypography.headlineSmall),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: VeloColors.textPrimary),
                title: const Text('Rename Playlist'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog(context, playlist);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: VeloColors.error),
                title: const Text('Delete Playlist', style: TextStyle(color: VeloColors.error)),
                onTap: () async {
                  await PlaylistActions.deletePlaylist(playlist.id!);
                  refreshPlaylists(ref);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, Playlist playlist) {
    final textController = TextEditingController(text: playlist.name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VeloColors.surfaceElevation2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VeloColors.hairlineBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Rename Playlist', style: VeloTypography.headlineSmall),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: VeloColors.surfaceElevation1,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: VeloColors.hairlineBorder),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: TextStyle(color: VeloColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final newName = textController.text.trim();
                      if (newName.isNotEmpty && newName != playlist.name) {
                        await PlaylistActions.renamePlaylist(playlist.id!, newName);
                        refreshPlaylists(ref);
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: VeloColors.primaryContainer,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncPlaylists = ref.watch(allPlaylistsProvider);

    return Column(
      children: [
        VeloTopBar(
          title: 'Playlists',
          subtitle: 'CUSTOM COLLECTIONS',
          actions: [
            IconButton(
              onPressed: () => _showCreatePlaylistDialog(context),
              icon: const Icon(Icons.add_rounded, color: VeloColors.accentCyan, size: 26),
              tooltip: 'New Playlist',
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              VeloSearchBar(
                controller: _searchController,
                onChanged: (q) => setState(() => _searchQuery = q.toLowerCase()),
                hint: 'Search playlists...',
              ),
              const SizedBox(height: 16),
              asyncPlaylists.when(
                loading: () => const VeloLoadingState(message: 'Loading playlists...'),
                error: (e, _) => VeloErrorState(
                  message: 'Failed to load playlists: $e',
                  onRetry: () => refreshPlaylists(ref),
                ),
                data: (playlists) {
                  final filtered = _searchQuery.isEmpty
                      ? playlists
                      : playlists.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();

                  if (filtered.isEmpty) {
                    return VeloEmptyState(
                      icon: Icons.playlist_add_rounded,
                      title: 'No Playlists',
                      subtitle: _searchQuery.isEmpty
                          ? 'Create your first playlist to group videos'
                          : 'No playlists match "$_searchQuery"',
                      actionLabel: _searchQuery.isEmpty ? 'Create Playlist' : null,
                      onAction: _searchQuery.isEmpty ? () => _showCreatePlaylistDialog(context) : null,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final playlist = filtered[index];
                      return _PlaylistCard(
                        playlist: playlist,
                        onTap: () {
                          Navigator.of(context).push(
                            PlaylistDetailScreen.route(playlist: playlist),
                          );
                        },
                        onOptions: () => _showPlaylistOptions(context, playlist),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaylistCard extends ConsumerWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onOptions;

  const _PlaylistCard({
    required this.playlist,
    required this.onTap,
    required this.onOptions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(playlistVideoCountProvider(playlist.id!));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: VeloColors.surfaceElevation1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VeloColors.hairlineBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: VeloColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: VeloColors.primaryContainer.withValues(alpha: 0.3), width: 1),
              ),
              child: const Icon(Icons.playlist_play_rounded, color: VeloColors.accentCyan, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: VeloTypography.labelLarge.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  countAsync.when(
                    data: (count) => Text('$count videos', style: VeloTypography.labelSmall),
                    loading: () => Text('...', style: VeloTypography.labelSmall),
                    error: (e, s) => Text('0 videos', style: VeloTypography.labelSmall),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onOptions,
              icon: const Icon(Icons.more_vert_rounded, color: VeloColors.textTertiary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
