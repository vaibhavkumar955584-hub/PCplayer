/// Information extracted from a parsed YouTube URL.
class YouTubeVideoInfo {
  final String videoId;
  final int startSeconds;
  final String originalUrl;
  final String cleanUrl;
  final String embedUrl;
  final String thumbnailUrl;

  const YouTubeVideoInfo({
    required this.videoId,
    this.startSeconds = 0,
    required this.originalUrl,
    required this.cleanUrl,
    required this.embedUrl,
    required this.thumbnailUrl,
  });

  @override
  String toString() => 'YouTubeVideoInfo(videoId: $videoId, startSeconds: $startSeconds)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YouTubeVideoInfo &&
          runtimeType == other.runtimeType &&
          videoId == other.videoId &&
          startSeconds == other.startSeconds;

  @override
  int get hashCode => Object.hash(videoId, startSeconds);
}

/// Utility for parsing, extracting, and validating YouTube URLs and start timestamps.
class YouTubeUrlParser {
  static final RegExp _videoIdRegex = RegExp(
    r'(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?|shorts|live)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    caseSensitive: false,
  );
  static final RegExp _directIdRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');

  /// Checks if a given text string contains or is a supported YouTube URL or Video ID.
  static bool isYouTubeUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    return _videoIdRegex.hasMatch(trimmed) || _directIdRegex.hasMatch(trimmed);
  }

  /// Extracts YouTubeVideoInfo from a URL string or Video ID, or returns null if not a valid YouTube source.
  static YouTubeVideoInfo? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    String? videoId;
    final match = _videoIdRegex.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      videoId = match.group(1);
    } else if (_directIdRegex.hasMatch(trimmed)) {
      videoId = trimmed;
    }

    if (videoId == null || videoId.length != 11) return null;

    final startSeconds = _extractStartSeconds(trimmed);
    final cleanUrl = 'https://www.youtube.com/watch?v=$videoId';
    final embedUrl = startSeconds > 0
        ? 'https://www.youtube-nocookie.com/embed/$videoId?autoplay=1&start=$startSeconds'
        : 'https://www.youtube-nocookie.com/embed/$videoId?autoplay=1';
    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

    return YouTubeVideoInfo(
      videoId: videoId,
      startSeconds: startSeconds,
      originalUrl: trimmed,
      cleanUrl: cleanUrl,
      embedUrl: embedUrl,
      thumbnailUrl: thumbnailUrl,
    );
  }

  /// Extracts start seconds from query parameters (e.g. ?t=120, ?t=2m30s, ?t=1h2m3s, ?start=120).
  static int _extractStartSeconds(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final tParam = uri.queryParameters['t'] ?? uri.queryParameters['start'];
        if (tParam != null && tParam.isNotEmpty) {
          return parseTimeString(tParam);
        }
      }
    } catch (_) {}

    // Fallback regex in case Uri parsing fails with fragments
    final match = RegExp(r'[?&#](?:t|start)=([0-9hms]+)', caseSensitive: false).firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final param = match.group(1);
      if (param != null) {
        return parseTimeString(param);
      }
    }

    return 0;
  }

  /// Parses strings like "120", "120s", "2m30s", "1h2m3s", "1h30s".
  static int parseTimeString(String timeStr) {
    final raw = timeStr.trim().toLowerCase();
    if (raw.isEmpty) return 0;

    // Direct integer seconds e.g. "120" or "120s"
    if (RegExp(r'^\d+s?$').hasMatch(raw)) {
      return int.tryParse(raw.replaceAll('s', '')) ?? 0;
    }

    int totalSeconds = 0;

    final hourMatch = RegExp(r'(\d+)h').firstMatch(raw);
    if (hourMatch != null) {
      totalSeconds += (int.tryParse(hourMatch.group(1) ?? '0') ?? 0) * 3600;
    }

    final minMatch = RegExp(r'(\d+)m').firstMatch(raw);
    if (minMatch != null) {
      totalSeconds += (int.tryParse(minMatch.group(1) ?? '0') ?? 0) * 60;
    }

    final secMatch = RegExp(r'(\d+)s').firstMatch(raw);
    if (secMatch != null) {
      totalSeconds += int.tryParse(secMatch.group(1) ?? '0') ?? 0;
    }

    return totalSeconds;
  }
}
