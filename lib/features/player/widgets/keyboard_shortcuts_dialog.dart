import 'package:flutter/material.dart';
import '../../../core/theme/velo_colors.dart';
import '../../../core/theme/velo_typography.dart';

class KeyboardShortcutsDialog extends StatelessWidget {
  const KeyboardShortcutsDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VeloColors.surfaceElevation2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const KeyboardShortcutsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      ('Space / K', 'Play / Pause playback'),
      ('← / →', 'Seek backward / forward 10 seconds'),
      ('Shift + ← / →', 'Seek backward / forward 30 seconds'),
      ('↑ / ↓', 'Adjust volume up / down (+/- 5%)'),
      ('M', 'Mute / unmute audio'),
      ('F', 'Toggle true immersive fullscreen'),
      ('Esc', 'Exit fullscreen mode / back'),
      ('[ / ]', 'Decrease / increase playback speed'),
      ('N / P', 'Play next / previous video in queue'),
      ('C', 'Toggle subtitles on / off'),
      ('L', 'Lock / unlock player controls'),
      ('Ctrl + F', 'Show media technical information'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: VeloColors.hairlineBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.keyboard_rounded, color: VeloColors.accentCyan, size: 22),
                const SizedBox(width: 8),
                Text(
                  'KEYBOARD SHORTCUTS',
                  style: VeloTypography.labelSmall.copyWith(
                    color: VeloColors.accentCyan,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: VeloColors.surfaceElevation1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VeloColors.hairlineBorder, width: 1),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shortcuts.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: VeloColors.hairlineBorder),
                itemBuilder: (context, i) {
                  final (key, desc) = shortcuts[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white24, width: 0.5),
                          ),
                          child: Text(
                            key,
                            style: VeloTypography.codeBadge.copyWith(
                              color: VeloColors.accentCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            desc,
                            style: VeloTypography.bodyMedium.copyWith(fontSize: 13),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
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
