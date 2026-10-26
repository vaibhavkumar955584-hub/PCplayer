import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'velo_colors.dart';
import 'velo_typography.dart';

/// Cinematic Precision ThemeData
class VeloTheme {
  VeloTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VeloColors.canvasBase,
      colorScheme: const ColorScheme.dark(
        surface: VeloColors.surface,
        onSurface: VeloColors.textPrimary,
        primary: VeloColors.primaryContainer,
        onPrimary: VeloColors.onPrimaryContainer,
        primaryContainer: VeloColors.primaryContainer,
        onPrimaryContainer: VeloColors.onPrimaryContainer,
        secondary: VeloColors.secondary,
        tertiary: VeloColors.tertiary,
        error: VeloColors.error,
        errorContainer: VeloColors.errorContainer,
        outline: Color(0xFF8D90A0),
        outlineVariant: Color(0xFF434655),
      ),
      textTheme: TextTheme(
        displayLarge: VeloTypography.displayLarge,
        headlineLarge: VeloTypography.headlineLarge,
        headlineMedium: VeloTypography.headlineMedium,
        headlineSmall: VeloTypography.headlineSmall,
        bodyLarge: VeloTypography.bodyLarge,
        bodyMedium: VeloTypography.bodyMedium,
        bodySmall: VeloTypography.bodySmall,
        labelLarge: VeloTypography.labelLarge,
        labelMedium: VeloTypography.labelMedium,
        labelSmall: VeloTypography.labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: VeloColors.canvasBase,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: VeloTypography.headlineSmall,
        iconTheme: const IconThemeData(color: VeloColors.textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: VeloColors.surfaceElevation1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: VeloColors.hairlineBorder, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: VeloColors.accentCyan,
        unselectedItemColor: VeloColors.textTertiary,
      ),
      dividerTheme: const DividerThemeData(
        color: VeloColors.hairlineBorder,
        thickness: 1,
        space: 0,
      ),
      iconTheme: const IconThemeData(
        color: VeloColors.textSecondary,
        size: 22,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: VeloColors.primaryContainer,
        inactiveTrackColor: VeloColors.surfaceContainerHigh,
        thumbColor: VeloColors.textPrimary,
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return VeloColors.primaryContainer;
          }
          return VeloColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return VeloColors.primaryContainer.withValues(alpha: 0.4);
          }
          return VeloColors.surfaceContainerHigh;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: VeloColors.surfaceElevation2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: VeloColors.surfaceElevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
