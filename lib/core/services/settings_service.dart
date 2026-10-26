import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user settings using SharedPreferences.
class SettingsService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p => _prefs!;

  // ─── Playback ───────────────────────────────────────────────
  static double get defaultPlaybackSpeed => _p.getDouble('playback_speed') ?? 1.0;
  static set defaultPlaybackSpeed(double v) => _p.setDouble('playback_speed', v);

  static bool get rememberPosition => _p.getBool('remember_position') ?? true;
  static set rememberPosition(bool v) => _p.setBool('remember_position', v);

  static bool get autoPlayNext => _p.getBool('auto_play_next') ?? false;
  static set autoPlayNext(bool v) => _p.setBool('auto_play_next', v);

  static bool get gestureControls => _p.getBool('gesture_controls') ?? true;
  static set gestureControls(bool v) => _p.setBool('gesture_controls', v);

  static bool get hardwareAcceleration => _p.getBool('hw_acceleration') ?? true;
  static set hardwareAcceleration(bool v) => _p.setBool('hw_acceleration', v);

  static String get repeatMode => _p.getString('repeat_mode') ?? 'none';
  static set repeatMode(String v) => _p.setString('repeat_mode', v);

  static bool get shuffleEnabled => _p.getBool('shuffle_enabled') ?? false;
  static set shuffleEnabled(bool v) => _p.setBool('shuffle_enabled', v);

  static String get scaleMode => _p.getString('scale_mode') ?? 'fit';
  static set scaleMode(String v) => _p.setString('scale_mode', v);

  static bool get showRemainingTime => _p.getBool('show_remaining_time') ?? false;
  static set showRemainingTime(bool v) => _p.setBool('show_remaining_time', v);

  // ─── Subtitles ──────────────────────────────────────────────
  static String get subtitleLanguage => _p.getString('subtitle_lang') ?? 'English';
  static set subtitleLanguage(String v) => _p.setString('subtitle_lang', v);

  static double get subtitleSize => _p.getDouble('subtitle_size') ?? 16.0;
  static set subtitleSize(double v) => _p.setDouble('subtitle_size', v);

  // ─── Appearance ─────────────────────────────────────────────
  static String get themeMode => _p.getString('theme_mode') ?? 'dark';
  static set themeMode(String v) => _p.setString('theme_mode', v);

  static int get accentColorValue => _p.getInt('accent_color') ?? 0xFF2563EB;
  static set accentColorValue(int v) => _p.setInt('accent_color', v);

  static bool get defaultGridView => _p.getBool('default_grid_view') ?? true;
  static set defaultGridView(bool v) => _p.setBool('default_grid_view', v);

  // ─── Library ────────────────────────────────────────────────
  static String get defaultSortOrder => _p.getString('sort_order') ?? 'dateAdded';
  static set defaultSortOrder(String v) => _p.setString('sort_order', v);

  static List<String> get excludedFolders => _p.getStringList('excluded_folders') ?? [];
  static set excludedFolders(List<String> v) => _p.setStringList('excluded_folders', v);

  static List<String> get customScanFolders => _p.getStringList('custom_scan_folders') ?? [];
  static set customScanFolders(List<String> v) => _p.setStringList('custom_scan_folders', v);

  static void addScanFolder(String path) {
    final list = List<String>.from(customScanFolders);
    if (!list.contains(path)) {
      list.add(path);
      customScanFolders = list;
    }
  }

  static void removeScanFolder(String path) {
    final list = List<String>.from(customScanFolders);
    list.remove(path);
    customScanFolders = list;
  }

  static int get lastScanTimestamp => _p.getInt('last_scan_timestamp') ?? 0;
  static set lastScanTimestamp(int v) => _p.setInt('last_scan_timestamp', v);

  // ─── Advanced ───────────────────────────────────────────────
  static int get thumbnailCacheMb => _p.getInt('thumb_cache_mb') ?? 200;
  static set thumbnailCacheMb(int v) => _p.setInt('thumb_cache_mb', v);
}
