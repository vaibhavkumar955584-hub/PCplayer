import 'package:flutter/material.dart';

/// Supported subtitle aesthetic presets
enum SubtitlePreset {
  cinema,
  netflix,
  classic,
  youTube,
  minimal,
  highContrast;

  String get label {
    switch (this) {
      case SubtitlePreset.cinema:
        return 'Cinema';
      case SubtitlePreset.netflix:
        return 'Netflix';
      case SubtitlePreset.classic:
        return 'Classic';
      case SubtitlePreset.youTube:
        return 'YouTube';
      case SubtitlePreset.minimal:
        return 'Minimal';
      case SubtitlePreset.highContrast:
        return 'High Contrast';
    }
  }
}

enum SubtitleVerticalPosition { bottom, top }

/// Comprehensive visual styling configuration for video subtitle rendering.
class SubtitleAppearance {
  final SubtitlePreset preset;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
  final Color backgroundColor;
  final double backgroundOpacity;
  final bool hasOutline;
  final Color outlineColor;
  final double outlineWidth;
  final bool hasShadow;
  final Color shadowColor;
  final SubtitleVerticalPosition position;
  final TextAlign alignment;
  final double bottomOffset;

  const SubtitleAppearance({
    this.preset = SubtitlePreset.cinema,
    this.fontSize = 18.0,
    this.fontWeight = FontWeight.w600,
    this.textColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.backgroundOpacity = 0.75,
    this.hasOutline = false,
    this.outlineColor = Colors.black,
    this.outlineWidth = 1.5,
    this.hasShadow = true,
    this.shadowColor = Colors.black,
    this.position = SubtitleVerticalPosition.bottom,
    this.alignment = TextAlign.center,
    this.bottomOffset = 36.0,
  });

  factory SubtitleAppearance.cinema() {
    return const SubtitleAppearance(
      preset: SubtitlePreset.cinema,
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      textColor: Colors.white,
      backgroundColor: Colors.black,
      backgroundOpacity: 0.75,
      hasOutline: false,
      hasShadow: true,
      shadowColor: Colors.black,
      position: SubtitleVerticalPosition.bottom,
    );
  }

  factory SubtitleAppearance.netflix() {
    return const SubtitleAppearance(
      preset: SubtitlePreset.netflix,
      fontSize: 19.0,
      fontWeight: FontWeight.w700,
      textColor: Colors.white,
      backgroundColor: Colors.transparent,
      backgroundOpacity: 0.0,
      hasOutline: true,
      outlineColor: Colors.black,
      outlineWidth: 2.0,
      hasShadow: true,
      shadowColor: Colors.black87,
      position: SubtitleVerticalPosition.bottom,
    );
  }

  factory SubtitleAppearance.classic() {
    return const SubtitleAppearance(
      preset: SubtitlePreset.classic,
      fontSize: 17.0,
      fontWeight: FontWeight.w500,
      textColor: Color(0xFFFFFF00), // Vibrant yellow
      backgroundColor: Colors.black,
      backgroundOpacity: 0.85,
      hasOutline: false,
      hasShadow: true,
      position: SubtitleVerticalPosition.bottom,
    );
  }

  factory SubtitleAppearance.youTube() {
    return const SubtitleAppearance(
      preset: SubtitlePreset.youTube,
      fontSize: 17.0,
      fontWeight: FontWeight.w600,
      textColor: Colors.white,
      backgroundColor: Colors.black,
      backgroundOpacity: 0.8,
      hasOutline: false,
      hasShadow: false,
      position: SubtitleVerticalPosition.bottom,
    );
  }

  factory SubtitleAppearance.minimal() {
    return const SubtitleAppearance(
      preset: SubtitlePreset.minimal,
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      textColor: Colors.white,
      backgroundColor: Colors.transparent,
      backgroundOpacity: 0.0,
      hasOutline: false,
      hasShadow: true,
      shadowColor: Colors.black,
      position: SubtitleVerticalPosition.bottom,
    );
  }

  factory SubtitleAppearance.highContrast() {
    return const SubtitleAppearance(
      preset: SubtitlePreset.highContrast,
      fontSize: 20.0,
      fontWeight: FontWeight.w800,
      textColor: Color(0xFF00FFCC), // High contrast cyan
      backgroundColor: Colors.black,
      backgroundOpacity: 1.0,
      hasOutline: true,
      outlineColor: Colors.black,
      outlineWidth: 2.5,
      hasShadow: true,
      position: SubtitleVerticalPosition.bottom,
    );
  }

  factory SubtitleAppearance.fromPreset(SubtitlePreset preset) {
    switch (preset) {
      case SubtitlePreset.cinema:
        return SubtitleAppearance.cinema();
      case SubtitlePreset.netflix:
        return SubtitleAppearance.netflix();
      case SubtitlePreset.classic:
        return SubtitleAppearance.classic();
      case SubtitlePreset.youTube:
        return SubtitleAppearance.youTube();
      case SubtitlePreset.minimal:
        return SubtitleAppearance.minimal();
      case SubtitlePreset.highContrast:
        return SubtitleAppearance.highContrast();
    }
  }

  SubtitleAppearance copyWith({
    SubtitlePreset? preset,
    double? fontSize,
    FontWeight? fontWeight,
    Color? textColor,
    Color? backgroundColor,
    double? backgroundOpacity,
    bool? hasOutline,
    Color? outlineColor,
    double? outlineWidth,
    bool? hasShadow,
    Color? shadowColor,
    SubtitleVerticalPosition? position,
    TextAlign? alignment,
    double? bottomOffset,
  }) {
    return SubtitleAppearance(
      preset: preset ?? this.preset,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      hasOutline: hasOutline ?? this.hasOutline,
      outlineColor: outlineColor ?? this.outlineColor,
      outlineWidth: outlineWidth ?? this.outlineWidth,
      hasShadow: hasShadow ?? this.hasShadow,
      shadowColor: shadowColor ?? this.shadowColor,
      position: position ?? this.position,
      alignment: alignment ?? this.alignment,
      bottomOffset: bottomOffset ?? this.bottomOffset,
    );
  }
}
