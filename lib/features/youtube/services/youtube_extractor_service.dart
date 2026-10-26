import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../utils/youtube_url_parser.dart';

/// Available stream resolution/quality option for YouTube playback.
class YouTubeQualityOption {
  final String label;
  final String url;
  final int bitrate;
  final int? height;
  final String format;

  const YouTubeQualityOption({
    required this.label,
    required this.url,
    required this.bitrate,
    this.height,
    required this.format,
  });
}

/// Rich metadata and direct media stream details extracted from YouTube.
class YouTubeExtractionResult {
  final String videoId;
  final String title;
  final String author;
  final Duration duration;
  final String thumbnailUrl;
  final String directStreamUrl;
  final int startSeconds;
  final String cleanUrl;
  final List<YouTubeQualityOption> availableQualities;

  const YouTubeExtractionResult({
    required this.videoId,
    required this.title,
    required this.author,
    required this.duration,
    required this.thumbnailUrl,
    required this.directStreamUrl,
    this.startSeconds = 0,
    required this.cleanUrl,
    this.availableQualities = const [],
  });
}

/// Core service for resolving YouTube URLs and video IDs into direct playable media streams.
class YouTubeExtractorService {
  static YoutubeExplode? _ytInstance;

  static YoutubeExplode get _yt => _ytInstance ??= YoutubeExplode();

  /// Extracts direct playable stream URL and metadata from any valid YouTube URL or Video ID.
  static Future<YouTubeExtractionResult> extract(String input) async {
    final info = YouTubeUrlParser.parse(input);
    final videoId = info?.videoId ?? input.trim();

    if (videoId.length != 11) {
      throw Exception('Invalid YouTube URL or Video ID: $input');
    }

    try {
      // 1. Fetch metadata (Title, Author, Duration, High-Res Thumbnails)
      final video = await _yt.videos.get(videoId).timeout(const Duration(seconds: 15));

      // 2. Fetch stream manifest
      final manifest = await _yt.videos.streamsClient.getManifest(videoId).timeout(const Duration(seconds: 15));

      // 3. Extract muxed streams (synced audio + video in a single MP4/WebM container)
      final muxedStreams = manifest.muxed.sortByVideoQuality();

      if (muxedStreams.isEmpty) {
        // Fallback: Check for video-only streams if muxed is unavailable
        final videoStreams = manifest.video.sortByVideoQuality();
        if (videoStreams.isEmpty) {
          throw Exception('No playable video stream found for video: $videoId');
        }

        final bestVideo = videoStreams.last;
        return YouTubeExtractionResult(
          videoId: videoId,
          title: video.title,
          author: video.author,
          duration: video.duration ?? Duration.zero,
          thumbnailUrl: video.thumbnails.highResUrl.isNotEmpty
              ? video.thumbnails.highResUrl
              : (info?.thumbnailUrl ?? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'),
          directStreamUrl: bestVideo.url.toString(),
          startSeconds: info?.startSeconds ?? 0,
          cleanUrl: video.url,
          availableQualities: [
            YouTubeQualityOption(
              label: '${bestVideo.videoQuality.name} (${bestVideo.container.name.toUpperCase()})',
              url: bestVideo.url.toString(),
              bitrate: bestVideo.bitrate.bitsPerSecond,
              height: bestVideo.videoResolution.height,
              format: bestVideo.container.name,
            ),
          ],
        );
      }

      // Populate available qualities from muxed streams
      final List<YouTubeQualityOption> qualities = muxedStreams.map((s) {
        return YouTubeQualityOption(
          label: '${s.videoQuality.name} (${s.container.name.toUpperCase()})',
          url: s.url.toString(),
          bitrate: s.bitrate.bitsPerSecond,
          height: s.videoResolution.height,
          format: s.container.name,
        );
      }).toList();

      // Highest quality muxed stream (e.g. 720p or 360p mp4)
      final bestMuxed = muxedStreams.last;

      return YouTubeExtractionResult(
        videoId: videoId,
        title: video.title,
        author: video.author,
        duration: video.duration ?? Duration.zero,
        thumbnailUrl: video.thumbnails.highResUrl.isNotEmpty
            ? video.thumbnails.highResUrl
            : (info?.thumbnailUrl ?? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'),
        directStreamUrl: bestMuxed.url.toString(),
        startSeconds: info?.startSeconds ?? 0,
        cleanUrl: video.url,
        availableQualities: qualities,
      );
    } on TimeoutException {
      throw Exception('Connection timed out while extracting YouTube stream. Please check your internet connection.');
    } on VideoUnplayableException catch (e) {
      throw Exception('This YouTube video is unplayable or age-restricted: ${e.message}');
    } on VideoRequiresPurchaseException {
      throw Exception('This YouTube video requires purchase or rental.');
    } on VideoUnavailableException {
      throw Exception('This YouTube video is private or unavailable.');
    } catch (e) {
      // If error mentions connection or socket, give a friendly message
      final errStr = e.toString();
      if (errStr.contains('SocketException') || errStr.contains('HandshakeException')) {
        throw Exception('Network connection failed. Please check your internet connection.');
      }
      throw Exception('Unable to load YouTube stream: $e');
    }
  }

  /// Close and cleanup resources
  static void dispose() {
    _ytInstance?.close();
    _ytInstance = null;
  }
}
