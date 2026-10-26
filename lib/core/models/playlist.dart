/// Playlist entity.
class Playlist {
  final int? id;
  final String name;
  final int createdAt;  // epoch millis
  final int updatedAt;  // epoch millis

  const Playlist({
    this.id,
    required this.name,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  Playlist copyWith({int? id, String? name, int? createdAt, int? updatedAt}) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      createdAt: map['created_at'] as int? ?? 0,
      updatedAt: map['updated_at'] as int? ?? 0,
    );
  }
}

/// Join table entry linking a playlist to a video with ordering.
class PlaylistVideo {
  final int? id;
  final int playlistId;
  final int videoId;
  final int sortOrder;

  const PlaylistVideo({
    this.id,
    required this.playlistId,
    required this.videoId,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'playlist_id': playlistId,
      'video_id': videoId,
      'sort_order': sortOrder,
    };
  }

  factory PlaylistVideo.fromMap(Map<String, dynamic> map) {
    return PlaylistVideo(
      id: map['id'] as int?,
      playlistId: map['playlist_id'] as int? ?? 0,
      videoId: map['video_id'] as int? ?? 0,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}
