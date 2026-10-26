import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/velo_colors.dart';
import '../theme/velo_typography.dart';

/// Velo brand logo mark — blue gradient play triangle inside squircle.
class VeloLogoMark extends StatelessWidget {
  final double size;
  const VeloLogoMark({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [VeloColors.primaryContainer, Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}

/// Compact technical spec chip (e.g., "4K", "HDR", "HEVC", "ATMOS").
class SpecChip extends StatelessWidget {
  final String label;
  final bool highlight;
  const SpecChip({super.key, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: highlight
            ? VeloColors.accentCyan.withValues(alpha: 0.15)
            : VeloColors.surfaceContainerHigh.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: highlight
              ? VeloColors.accentCyan.withValues(alpha: 0.3)
              : VeloColors.hairlineBorder.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: VeloTypography.codeBadge.copyWith(
          color: highlight ? VeloColors.accentCyan : VeloColors.textSecondary,
          fontSize: 9,
        ),
      ),
    );
  }
}

/// Velo top bar with logo, title, section subtitle, optional back button, profile avatar.
class VeloTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const VeloTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (showBack)
              GestureDetector(
                onTap: onBack ?? () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.arrow_back_rounded, color: VeloColors.textPrimary, size: 22),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: VeloLogoMark(size: 32),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: VeloTypography.headlineSmall.copyWith(fontSize: 18)),
                  if (subtitle != null)
                    Text(subtitle!, style: VeloTypography.labelSmall.copyWith(color: VeloColors.textTertiary)),
                ],
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}

/// Cinematic search bar with search icon, mic, filter.
class VeloSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hint;

  const VeloSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.hint = 'Search videos, folders...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: VeloColors.surfaceElevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VeloColors.hairlineBorder, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, color: VeloColors.textTertiary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: VeloTypography.bodyMedium.copyWith(color: VeloColors.textTertiary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.mic_none_rounded, color: VeloColors.textTertiary, size: 20),
          const SizedBox(width: 8),
          Icon(Icons.tune_rounded, color: VeloColors.textTertiary, size: 20),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Floating glass bottom navigation bar.
class VeloBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const VeloBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.folder_rounded, label: 'Library'),
      _NavItem(icon: Icons.favorite_rounded, label: 'Favorites'),
      _NavItem(icon: Icons.playlist_play_rounded, label: 'Playlists'),
      _NavItem(icon: Icons.tune_rounded, label: 'Settings'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: VeloColors.surfaceElevation2.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: VeloColors.hairlineBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = i == currentIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i].icon,
                        size: 22,
                        color: isActive ? VeloColors.textPrimary : VeloColors.textTertiary,
                      ),
                      const SizedBox(height: 4),
                      if (isActive)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: VeloColors.accentCyan,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: VeloColors.accentCyan.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          items[i].label,
                          style: VeloTypography.labelSmall.copyWith(
                            fontSize: 9,
                            color: VeloColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

/// Circular play button with blue fill and drop glow.
class VeloPlayButton extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final bool isPlaying;

  const VeloPlayButton({super.key, this.size = 56, this.onTap, this.isPlaying = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: VeloColors.primaryContainer,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: VeloColors.primaryContainer.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// Video thumbnail widget with loading placeholder and error handling.
class VideoThumbnail extends StatelessWidget {
  final String? thumbnailPath;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const VideoThumbnail({
    super.key,
    this.thumbnailPath,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (thumbnailPath != null && thumbnailPath!.isNotEmpty) {
      final isNetwork = thumbnailPath!.startsWith('http://') || thumbnailPath!.startsWith('https://');
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: isNetwork
            ? Image.network(
                thumbnailPath!,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              )
            : Image.file(
                File(thumbnailPath!),
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: VeloColors.surfaceElevation1,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: Border.all(color: VeloColors.hairlineBorder, width: 0.5),
      ),
      child: const Center(
        child: Icon(Icons.movie_rounded, color: VeloColors.textTertiary, size: 32),
      ),
    );
  }
}

/// Progress bar widget for video cards.
class VideoProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color? color;

  const VideoProgressBar({super.key, required this.progress, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: VeloColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(1.5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? VeloColors.primaryContainer,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
    );
  }
}

/// Empty state widget with icon, title, and optional action.
class VeloEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const VeloEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: VeloColors.textTertiary, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              style: VeloTypography.headlineSmall.copyWith(color: VeloColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: VeloTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: VeloColors.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state widget.
class VeloErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const VeloErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: VeloColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: VeloTypography.bodyMedium.copyWith(color: VeloColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: TextButton.styleFrom(foregroundColor: VeloColors.primaryContainer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading state widget.
class VeloLoadingState extends StatelessWidget {
  final String? message;
  const VeloLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: VeloColors.primaryContainer,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: VeloTypography.bodyMedium),
          ],
        ],
      ),
    );
  }
}
