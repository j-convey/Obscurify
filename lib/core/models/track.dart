import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/string_utils.dart';

/// Model class representing a music track.
class Track {
  final int? id;
  final String ratingKey;
  final String title;
  final String artistName;
  final String? artistRatingKey;
  final String albumName;
  final String? albumRatingKey;
  final int? artistId;
  final int? albumId;
  final String trackKey;
  final int? trackNumber;
  final int? discNumber;
  final int duration;
  final String? thumb;
  final String? albumThumb;
  final String? artistThumb;
  final int? year;
  final String? genre;
  final double? userRating;
  final String serverId;
  final String libraryKey;
  final int? addedAt;
  final List<dynamic> media;

  const Track({
    this.id,
    required this.ratingKey,
    required this.title,
    this.artistName = 'Unknown Artist',
    this.artistRatingKey,
    this.albumName = 'Unknown Album',
    this.albumRatingKey,
    this.artistId,
    this.albumId,
    required this.trackKey,
    this.trackNumber,
    this.discNumber = 1,
    this.duration = 0,
    this.thumb,
    this.albumThumb,
    this.artistThumb,
    this.year,
    this.genre,
    this.userRating,
    required this.serverId,
    required this.libraryKey,
    this.addedAt,
    this.media = const [],
  });

  /// Returns a version of the title sanitized for alphabetical sorting.
  String get sortableTitle => ObscurifyStringUtils.toSortable(title);

  /// Returns null if the string is null or empty (treats '' as null)
  static String? _nonEmpty(String? s) => (s != null && s.isNotEmpty) ? s : null;

  /// Check if track is liked (rating >= 5)
  bool get isLiked => (userRating ?? 0) >= 5.0;

  /// Creates a Track from database row (includes view columns)
  factory Track.fromDb(Map<String, dynamic> map) {
    // Parse media data
    List<dynamic> mediaData = [];
    try {
      final mediaStr = map['media_data'] as String?;
      if (mediaStr != null && mediaStr.isNotEmpty) {
        final decoded = jsonDecode(mediaStr);
        mediaData = decoded is List ? decoded : [];
      }
    } catch (e) {
      // Ignore parse errors
    }

    // Prefer normalized joined data, fall back to denormalized columns
    final albumName = (map['album_name'] as String?) ??
        (map['parent_title'] as String?) ??
        (map['album_name_stored'] as String?) ??
        'Unknown Album';
    final artistName = (map['artist_name'] as String?) ??
        (map['grandparent_title'] as String?) ??
        (map['artist_name_stored'] as String?) ??
        'Unknown Artist';
    final albumThumb =
        _nonEmpty(map['album_thumb'] as String?) ?? _nonEmpty(map['parent_thumb'] as String?);
    final artistThumb =
        _nonEmpty(map['artist_thumb'] as String?) ?? _nonEmpty(map['grandparent_thumb'] as String?);
    final albumRatingKey =
        (map['album_rating_key'] as String?) ?? (map['parent_rating_key'] as String?);
    final artistRatingKey = (map['artist_rating_key'] as String?) ??
        (map['grandparent_rating_key'] as String?);
    
    final userRating = map['user_rating'] as double?;
    final title = map['title'] as String? ?? 'Unknown';
    
    if (userRating != null) {
      debugPrint('SYNC_DEBUG [fromDb]: Track "$title" loaded with user_rating: $userRating');
    }

    return Track(
      id: map['id'] as int?,
      ratingKey: map['rating_key'] as String? ?? '',
      title: title,
      artistName: artistName,
      artistRatingKey: artistRatingKey,
      albumName: albumName,
      albumRatingKey: albumRatingKey,
      artistId: map['artist_id'] as int?,
      albumId: map['album_id'] as int?,
      trackKey: map['track_key'] as String? ?? '',
      trackNumber: map['track_number'] as int?,
      discNumber: (map['disc_number'] as int?) ?? 1,
      duration: (map['duration'] as int?) ?? 0,
      thumb: _nonEmpty(map['thumb'] as String?),
      albumThumb: albumThumb,
      artistThumb: artistThumb,
      year: map['year'] as int?,
      genre: map['genre'] as String?,
      userRating: userRating,
      serverId: map['server_id'] as String? ?? '',
      libraryKey: map['library_key'] as String? ?? '',
      addedAt: map['added_at'] as int?,
      media: mediaData,
    );
  }

  /// Creates a Track from Plex API JSON response
  factory Track.fromPlexJson(
    Map<String, dynamic> json, {
    required String serverId,
    required String libraryKey,
  }) {
    final userRating = json['userRating']?.toDouble();
    final title = json['title'] ?? 'Unknown';
    
    if (userRating != null) {
      debugPrint('SYNC_DEBUG [fromPlexJson]: Track "$title" has userRating: $userRating');
    }
    
    return Track(
      ratingKey: json['ratingKey']?.toString() ?? '',
      title: title,
      artistName: json['grandparentTitle'] ?? 'Unknown Artist',
      artistRatingKey: json['grandparentRatingKey']?.toString(),
      albumName: json['parentTitle'] ?? 'Unknown Album',
      albumRatingKey: json['parentRatingKey']?.toString(),
      trackKey: json['key'] ?? '',
      trackNumber: json['index'] ?? json['trackNumber'],
      discNumber: json['parentIndex'] ?? json['discNumber'] ?? 1,
      duration: json['duration'] ?? 0,
      thumb: json['thumb'],
      albumThumb: json['parentThumb'],
      artistThumb: json['grandparentThumb'],
      year: json['year'],
      genre: json['Genre'] != null && (json['Genre'] as List).isNotEmpty
          ? json['Genre'][0]['tag']
          : null,
      userRating: userRating,
      serverId: serverId,
      libraryKey: libraryKey,
      addedAt: json['addedAt'],
      media: json['Media'] ?? [],
    );
  }

  /// Convert to database map for insert/update
  Map<String, dynamic> toDb() {
    if (userRating != null) {
      debugPrint('SYNC_DEBUG [toDb]: Track "$title" saving with user_rating: $userRating');
    }
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'library_key': libraryKey,
      'track_key': trackKey,
      'rating_key': ratingKey,
      'title': title,
      'artist_id': artistId,
      'artist_name': artistName,
      'album_id': albumId,
      'album_name': albumName,
      'track_number': trackNumber,
      'disc_number': discNumber ?? 1,
      'duration': duration,
      'thumb': thumb ?? '',
      'year': year ?? 0,
      'genre': genre,
      'added_at': addedAt,
      'media_data': jsonEncode(media),
      'user_rating': userRating,
      'parent_rating_key': albumRatingKey,
      'parent_thumb': albumThumb ?? '',
      'grandparent_rating_key': artistRatingKey,
      'grandparent_thumb': artistThumb ?? '',
    };
  }

  /// Convert to Map for UI consumption (backward compatible)
  Map<String, dynamic> toJson() {
    if (userRating != null) {
      debugPrint('SYNC_DEBUG [toJson]: Track "$title" converting with userRating: $userRating');
    }
    return {
      'id': id,
      'ratingKey': ratingKey,
      'title': title,
      'artist': artistName,
      'album': albumName,
      'duration': duration,
      'key': trackKey,
      'thumb': thumb,
      'year': year,
      'addedAt': addedAt,
      'serverId': serverId,
      'libraryKey': libraryKey,
      'Media': media,
      'userRating': userRating,
      'trackNumber': trackNumber,
      'discNumber': discNumber,
      'grandparentRatingKey': artistRatingKey,
      'grandparentTitle': artistName,
      'grandparentThumb': artistThumb,
      'parentRatingKey': albumRatingKey,
      'parentTitle': albumName,
      'parentThumb': albumThumb,
    };
  }

  Track copyWith({
    int? id,
    String? ratingKey,
    String? title,
    String? artistName,
    String? artistRatingKey,
    String? albumName,
    String? albumRatingKey,
    int? artistId,
    int? albumId,
    String? trackKey,
    int? trackNumber,
    int? discNumber,
    int? duration,
    String? thumb,
    String? albumThumb,
    String? artistThumb,
    int? year,
    String? genre,
    double? userRating,
    String? serverId,
    String? libraryKey,
    int? addedAt,
    List<dynamic>? media,
  }) {
    return Track(
      id: id ?? this.id,
      ratingKey: ratingKey ?? this.ratingKey,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      artistRatingKey: artistRatingKey ?? this.artistRatingKey,
      albumName: albumName ?? this.albumName,
      albumRatingKey: albumRatingKey ?? this.albumRatingKey,
      artistId: artistId ?? this.artistId,
      albumId: albumId ?? this.albumId,
      trackKey: trackKey ?? this.trackKey,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      duration: duration ?? this.duration,
      thumb: thumb ?? this.thumb,
      albumThumb: albumThumb ?? this.albumThumb,
      artistThumb: artistThumb ?? this.artistThumb,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      userRating: userRating ?? this.userRating,
      serverId: serverId ?? this.serverId,
      libraryKey: libraryKey ?? this.libraryKey,
      addedAt: addedAt ?? this.addedAt,
      media: media ?? this.media,
    );
  }

  @override
  String toString() =>
      'Track(id: $id, title: $title, artist: $artistName, album: $albumName)';
}