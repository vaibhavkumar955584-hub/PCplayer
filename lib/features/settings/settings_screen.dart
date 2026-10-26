import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/thumbnail_service.dart';
import '../../core/theme/velo_colors.dart';
import '../../core/theme/velo_typography.dart';
import '../../core/widgets/velo_components.dart';
import '../player/widgets/keyboard_shortcuts_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _cacheSizeBytes = 0;
  bool _isLoadingCache = false;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final size = await ThumbnailService.getCacheSize();
    if (mounted) {
      setState(() => _cacheSizeBytes = size);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);

    return Column(
      children: [
        const VeloTopBar(
          title: 'Settings',
          subtitle: 'PREFERENCES & STORAGE',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              // Playback section
              _buildSectionHeader('PLAYBACK'),
              _buildCard([
                SwitchListTile(
                  value: SettingsService.rememberPosition,
                  onChanged: (val) {
                    setState(() => SettingsService.rememberPosition = val);
                  },
                  activeTrackColor: VeloColors.primaryContainer,
                  activeThumbColor: Colors.white,
                  title: Text('Remember Playback Position', style: VeloTypography.labelLarge),
                  subtitle: Text('Resume videos from where you left off', style: VeloTypography.bodyMedium.copyWith(fontSize: 12)),
                ),
                _buildDivider(),
                SwitchListTile(
                  value: SettingsService.autoPlayNext,
                  onChanged: (val) {
                    setState(() => SettingsService.autoPlayNext = val);
                  },
                  activeTrackColor: VeloColors.primaryContainer,
                  activeThumbColor: Colors.white,
                  title: Text('Auto-Play Next Video', style: VeloTypography.labelLarge),
                  subtitle: Text('Automatically advance when a video finishes', style: VeloTypography.bodyMedium.copyWith(fontSize: 12)),
                ),
                _buildDivider(),
                SwitchListTile(
                  value: SettingsService.gestureControls,
                  onChanged: (val) {
                    setState(() => SettingsService.gestureControls = val);
                  },
                  activeTrackColor: VeloColors.primaryContainer,
                  activeThumbColor: Colors.white,
                  title: Text('Gesture Controls', style: VeloTypography.labelLarge),
                  subtitle: Text('Double-tap to skip, vertical swipe for volume/brightness', style: VeloTypography.bodyMedium.copyWith(fontSize: 12)),
                ),
                _buildDivider(),
                ListTile(
                  title: Text('Default Playback Speed', style: VeloTypography.labelLarge),
                  trailing: DropdownButton<double>(
                    value: SettingsService.defaultPlaybackSpeed,
                    dropdownColor: VeloColors.surfaceElevation2,
                    underline: const SizedBox.shrink(),
                    style: VeloTypography.codeBadge.copyWith(color: VeloColors.accentCyan),
                    items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                      return DropdownMenuItem<double>(
                        value: s,
                        child: Text('${s}x'),
                      );
                    }).toList(),
                    onChanged: (s) {
                      if (s != null) {
                        setState(() => SettingsService.defaultPlaybackSpeed = s);
                      }
                    },
                  ),
                ),
                _buildDivider(),
                ListTile(
                  leading: const Icon(Icons.keyboard_rounded, color: VeloColors.accentCyan),
                  title: Text('Keyboard Shortcuts Reference', style: VeloTypography.labelLarge),
                  subtitle: Text('VLC-inspired playback shortcuts for desktop & keyboard', style: VeloTypography.bodyMedium.copyWith(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: VeloColors.textTertiary),
                  onTap: () => KeyboardShortcutsDialog.show(context),
                ),
              ]),

              const SizedBox(height: 20),

              // Library & Media section
              _buildSectionHeader('LIBRARY & SCANNING'),
              _buildCard([
                ListTile(
                  leading: Icon(
                    scanState.status == ScanStatus.scanning ? Icons.sync_rounded : Icons.search_rounded,
                    color: VeloColors.accentCyan,
                  ),
                  title: Text('Rescan Device Media', style: VeloTypography.labelLarge),
                  subtitle: Text(
                    scanState.status == ScanStatus.scanning
                        ? 'Scanning storage (${scanState.totalCount} found)...'
                        : 'Discover newly added or moved video files',
                    style: VeloTypography.bodyMedium.copyWith(fontSize: 12),
                  ),
                  trailing: scanState.status == ScanStatus.scanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: VeloColors.accentCyan),
                        )
                      : FilledButton.tonal(
                          onPressed: () => ref.read(scanProvider.notifier).scanDevice(),
                          style: FilledButton.styleFrom(
                            backgroundColor: VeloColors.primaryContainer.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Scan Now'),
                        ),
                ),
              ]),

              const SizedBox(height: 20),

              // Storage & Cache
              _buildSectionHeader('STORAGE & CACHE'),
              _buildCard([
                ListTile(
                  leading: const Icon(Icons.cached_rounded, color: VeloColors.accentCyan),
                  title: Text('Thumbnail Cache', style: VeloTypography.labelLarge),
                  subtitle: Text(_formatBytes(_cacheSizeBytes), style: VeloTypography.codeBadge),
                  trailing: _isLoadingCache
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: () async {
                            setState(() => _isLoadingCache = true);
                            await ThumbnailService.clearCache();
                            await _loadCacheSize();
                            setState(() => _isLoadingCache = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Thumbnail cache cleared')),
                              );
                            }
                          },
                          child: const Text('Clear', style: TextStyle(color: VeloColors.error)),
                        ),
                ),
              ]),

              const SizedBox(height: 20),

              // About & Information
              _buildSectionHeader('ABOUT'),
              _buildCard([
                ListTile(
                  leading: const VeloLogoMark(size: 32),
                  title: Text('Velo Player', style: VeloTypography.headlineSmall.copyWith(fontSize: 16)),
                  subtitle: Text('v1.0.0 • Cyber / OLED Edition', style: VeloTypography.labelSmall),
                ),
                _buildDivider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'High-performance local video player featuring direct platform MediaStore indexing, hardware-accelerated rendering, persistent watch state, and custom collections.',
                    style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textSecondary, height: 1.4),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: VeloTypography.labelSmall.copyWith(
          color: VeloColors.textTertiary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: VeloColors.surfaceElevation1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VeloColors.hairlineBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: VeloColors.hairlineBorder);
  }
}
