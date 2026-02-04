/// Model class representing a music artist.
class Artist {
  final String id;
  final String name;
  final String? thumb;
  final String? art;
  final String? summary;
  final int? albumCount;
  final int? trackCount;

  Artist({
    required this.id,
    required this.name,
    this.thumb,
    this.art,
    this.summary,
    this.albumCount,
    this.trackCount,
  });

  /// Creates an Artist from Plex API JSON response.
  factory Artist.fromPlexJson(Map<String, dynamic> json) {
    return Artist(
      id: json['ratingKey']?.toString() ?? '',
      name: json['title'] ?? 'Unknown Artist',
      thumb: json['thumb'],
      art: json['art'],
      summary: json['summary'],
      albumCount: json['childCount'],
      trackCount: json['leafCount'],
    );
  }

  /// Creates a minimal Artist from track's grandparent info.
  factory Artist.fromTrack(Map<String, dynamic> track) {
    return Artist(
      id: track['grandparentRatingKey']?.toString() ?? '',
      name: track['grandparentTitle'] ?? 'Unknown Artist',
      thumb: track['grandparentThumb'],
      art: track['grandparentArt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'thumb': thumb,
      'art': art,
      'summary': summary,
      'albumCount': albumCount,
      'trackCount': trackCount,
    };
  }
}
