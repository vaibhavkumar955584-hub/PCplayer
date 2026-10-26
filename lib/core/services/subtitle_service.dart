import 'dart:io';
import 'package:file_picker/file_picker.dart';

/// A single subtitle cue with start/end timestamps and display text.
class SubtitleEntry {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleEntry({
    required this.start,
    required this.end,
    required this.text,
  });
}

/// Metadata describing a subtitle track
class SubtitleTrack {
  final String id;
  final String title;
  final String? language;
  final String? path;
  final bool isExternal;

  const SubtitleTrack({
    required this.id,
    required this.title,
    this.language,
    this.path,
    this.isExternal = false,
  });
}

/// Service for loading and parsing .srt and .vtt subtitle files.
class SubtitleService {
  /// Attempts to auto-detect sidecar subtitle files next to [videoPath].
  /// Returns parsed subtitles or null if none found.
  static Future<List<SubtitleEntry>?> autoDetect(String videoPath) async {
    final base = videoPath.replaceAll(RegExp(r'\.[^.]+$'), '');
    final candidates = [
      '$base.srt',
      '$base.vtt',
      '$base.en.srt',
      '$base.en.vtt',
      '$base.eng.srt',
      '$base.eng.vtt',
      '${base}_subtitle.srt',
      '${base}_subtitle.vtt',
    ];

    for (final candidate in candidates) {
      final file = File(candidate);
      if (await file.exists()) {
        try {
          final entries = await parseFile(file);
          if (entries.isNotEmpty) return entries;
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }

  /// Opens a file picker for the user to select a subtitle file (.srt, .vtt, .sub).
  /// Returns parsed subtitles or null if cancelled / failed.
  static Future<List<SubtitleEntry>?> pickAndLoad() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'vtt', 'sub', 'txt'],
      dialogTitle: 'Select Subtitle File (.srt, .vtt)',
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.first.path;
    if (path == null) return null;

    try {
      return await parseFile(File(path));
    } catch (_) {
      return null;
    }
  }

  /// Parse a subtitle file (.srt or .vtt) into a list of [SubtitleEntry].
  static Future<List<SubtitleEntry>> parseFile(File file) async {
    final content = await file.readAsString();
    if (file.path.toLowerCase().endsWith('.vtt') || content.trimLeft().startsWith('WEBVTT')) {
      return parseVtt(content);
    }
    return parseSrt(content);
  }

  /// Parse raw SRT string content into subtitle entries.
  static List<SubtitleEntry> parseSrt(String content) {
    final entries = <SubtitleEntry>[];

    // Normalize line endings and split on blank lines
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final blocks = normalized.split(RegExp(r'\n\s*\n'));

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 2) continue;

      // Find line with "-->"
      int timeLine = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('-->')) {
          timeLine = i;
          break;
        }
      }
      if (timeLine == -1 || timeLine >= lines.length) continue;

      final timeParts = lines[timeLine].split('-->');
      if (timeParts.length != 2) continue;

      final start = _parseTimestamp(timeParts[0].trim());
      final end = _parseTimestamp(timeParts[1].trim());
      if (start == null || end == null) continue;

      // Remaining lines are text
      final textLines = lines.sublist(timeLine + 1);
      final text = textLines
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .map((l) => l.replaceAll(RegExp(r'<[^>]+>'), ''))
          .join('\n');

      if (text.isNotEmpty) {
        entries.add(SubtitleEntry(start: start, end: end, text: text));
      }
    }

    entries.sort((a, b) => a.start.compareTo(b.start));
    return entries;
  }

  /// Parse raw WebVTT string content into subtitle entries.
  static List<SubtitleEntry> parseVtt(String content) {
    final entries = <SubtitleEntry>[];
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final blocks = normalized.split(RegExp(r'\n\s*\n'));

    for (final block in blocks) {
      final trimmed = block.trim();
      if (trimmed.isEmpty || trimmed.startsWith('WEBVTT') || trimmed.startsWith('NOTE') || trimmed.startsWith('STYLE')) {
        continue;
      }

      final lines = trimmed.split('\n');
      int timeLine = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('-->')) {
          timeLine = i;
          break;
        }
      }
      if (timeLine == -1) continue;

      final timeParts = lines[timeLine].split('-->');
      if (timeParts.length != 2) continue;

      // Strip VTT cue settings like "align:start position:10%"
      final rawStart = timeParts[0].trim();
      final rawEnd = timeParts[1].trim().split(RegExp(r'\s+')).first;

      final start = _parseTimestamp(rawStart);
      final end = _parseTimestamp(rawEnd);
      if (start == null || end == null) continue;

      final textLines = lines.sublist(timeLine + 1);
      final text = textLines
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          // Strip VTT tags like <v Speaker>, <c.yellow>, <b>, etc.
          .map((l) => l.replaceAll(RegExp(r'<[^>]+>'), ''))
          .join('\n');

      if (text.isNotEmpty) {
        entries.add(SubtitleEntry(start: start, end: end, text: text));
      }
    }

    entries.sort((a, b) => a.start.compareTo(b.start));
    return entries;
  }

  /// Parse timestamp like "00:01:23.456", "00:01:23,456", or "01:23.456" into [Duration].
  static Duration? _parseTimestamp(String s) {
    final cleaned = s.replaceAll(',', '.').trim();

    // Try standard format: hh:mm:ss.mmm
    final matchHms = RegExp(r'^(\d+):(\d{2}):(\d{2})(?:\.(\d{1,3}))?$').firstMatch(cleaned);
    if (matchHms != null) {
      final hours = int.parse(matchHms.group(1)!);
      final minutes = int.parse(matchHms.group(2)!);
      final seconds = int.parse(matchHms.group(3)!);
      final msStr = (matchHms.group(4) ?? '0').padRight(3, '0').substring(0, 3);
      final ms = int.parse(msStr);
      return Duration(hours: hours, minutes: minutes, seconds: seconds, milliseconds: ms);
    }

    // Try VTT short format: mm:ss.mmm
    final matchMs = RegExp(r'^(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?$').firstMatch(cleaned);
    if (matchMs != null) {
      final minutes = int.parse(matchMs.group(1)!);
      final seconds = int.parse(matchMs.group(2)!);
      final msStr = (matchMs.group(3) ?? '0').padRight(3, '0').substring(0, 3);
      final ms = int.parse(msStr);
      return Duration(minutes: minutes, seconds: seconds, milliseconds: ms);
    }

    return null;
  }

  /// Find the subtitle entry active at [position] using O(log N) binary search.
  static SubtitleEntry? findActive(List<SubtitleEntry> entries, Duration position) {
    if (entries.isEmpty) return null;
    if (position < entries.first.start) return null;

    int low = 0;
    int high = entries.length - 1;
    int best = -1;

    while (low <= high) {
      final mid = (low + high) >> 1;
      if (entries[mid].start <= position) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    if (best != -1 && position <= entries[best].end) {
      return entries[best];
    }
    // Check previous entry in case of overlapping cues
    if (best > 0 && position <= entries[best - 1].end) {
      return entries[best - 1];
    }
    return null;
  }

  /// Exports a list of [SubtitleEntry] into standard SubRip (.srt) text format.
  static String exportToSrt(List<SubtitleEntry> entries) {
    final buffer = StringBuffer();
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      buffer.writeln('${i + 1}');
      buffer.writeln('${_formatSrtTimestamp(e.start)} --> ${_formatSrtTimestamp(e.end)}');
      buffer.writeln(e.text);
      buffer.writeln();
    }
    return buffer.toString();
  }

  static String _formatSrtTimestamp(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds,$ms';
  }
}

