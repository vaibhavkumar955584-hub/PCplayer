/// Represents a folder containing videos.
class VideoFolder {
  final String name;
  final String path;
  final int videoCount;

  const VideoFolder({
    required this.name,
    required this.path,
    this.videoCount = 0,
  });
}

/// Sort options for video library.
enum VideoSortOption {
  name('Name'),
  dateAdded('Date Added'),
  recentlyWatched('Recently Watched'),
  duration('Duration'),
  fileSize('File Size');

  final String label;
  const VideoSortOption(this.label);
}

/// Filter category for library.
enum VideoFilterCategory {
  all('All'),
  videos('Videos'),
  folders('Folders'),
  favorites('Favorites');

  final String label;
  const VideoFilterCategory(this.label);
}
