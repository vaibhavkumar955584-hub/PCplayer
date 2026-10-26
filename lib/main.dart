import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:video_player_win/video_player_win_plugin.dart';
import 'package:window_manager/window_manager.dart';
import 'core/database/app_database.dart';
import 'core/providers/app_providers.dart';
import 'core/services/media_scanner_service.dart';
import 'core/services/settings_service.dart';
import 'core/theme/velo_colors.dart';
import 'core/theme/velo_theme.dart';
import 'core/widgets/velo_components.dart';
import 'features/home/home_screen.dart';
import 'features/library/favorites_screen.dart';
import 'features/library/folder_detail_screen.dart';
import 'features/library/library_screen.dart';
import 'features/player/player_screen.dart';
import 'features/playlists/playlists_screen.dart';
import 'features/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize desktop SQLite FFI, Windows Video Player, and Window Manager
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow(
      const WindowOptions(
        minimumSize: Size(600, 450),
        center: true,
        title: 'Velo Player',
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }
  if (Platform.isWindows) {
    WindowsVideoPlayer.registerWith();
  }

  // Initialize database and persisted settings
  await AppDatabase.database;
  await SettingsService.init();

  // Edge-to-edge transparent system bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: VeloPlayerApp(),
    ),
  );
}

class VeloPlayerApp extends StatelessWidget {
  const VeloPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velo Player',
      debugShowCheckedModeBanner: false,
      theme: VeloTheme.darkTheme,
      darkTheme: VeloTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const RootNavigationShell(),
    );
  }
}

class RootNavigationShell extends ConsumerStatefulWidget {
  const RootNavigationShell({super.key});

  @override
  ConsumerState<RootNavigationShell> createState() => _RootNavigationShellState();
}

class _RootNavigationShellState extends ConsumerState<RootNavigationShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndScan();
  }

  Future<void> _checkPermissionsAndScan() async {
    // Check permission on startup and trigger initial scan if permitted
    final hasPerm = await MediaScannerService.hasPermission();
    if (!hasPerm) {
      final granted = await MediaScannerService.requestPermission();
      if (granted && mounted) {
        ref.read(scanProvider.notifier).scanDevice();
      }
    } else {
      ref.read(scanProvider.notifier).scanDevice();
    }
  }

  void _onPlayVideo(int videoId, {List<int>? queue}) async {
    // If no explicit queue is passed, find all videos from current state
    List<int>? playbackQueue = queue;
    if (playbackQueue == null) {
      final allVideos = ref.read(allVideosProvider).asData?.value;
      if (allVideos != null && allVideos.isNotEmpty) {
        playbackQueue = allVideos.map((v) => v.id!).toList();
      }
    }

    await Navigator.of(context).push(
      PlayerScreen.route(videoId: videoId, queue: playbackQueue),
    );

    // Refresh history and favorites upon return
    if (mounted) {
      refreshHistory(ref);
      refreshFavorites(ref);
      ref.invalidate(continueWatchingProvider);
      ref.invalidate(recentlyAddedProvider);
    }
  }

  Future<void> _onPlayUrl(String url) async {
    await Navigator.of(context).push(
      PlayerScreen.route(videoId: 0, networkUrl: url),
    );
  }

  void _onOpenFolder(String folderName) {
    Navigator.of(context).push(
      FolderDetailScreen.route(folderName: folderName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeloColors.canvasBase,
      body: Stack(
        children: [
          // Indexed page content
          IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(
                onPlayVideo: (id) => _onPlayVideo(id),
                onOpenFolder: _onOpenFolder,
                onPlayUrl: _onPlayUrl,
              ),
              LibraryScreen(
                onPlayVideo: (id) => _onPlayVideo(id),
                onOpenFolder: _onOpenFolder,
                onRescan: () => ref.read(scanProvider.notifier).scanDevice(),
              ),
              const FavoritesScreen(),
              const PlaylistsScreen(),
              const SettingsScreen(),
            ],
          ),

          // Floating Glass Bottom Navigation
          Align(
            alignment: Alignment.bottomCenter,
            child: VeloBottomNav(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
        ],
      ),
    );
  }
}
