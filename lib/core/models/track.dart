import '../utils/string_utils.dart';

class Track {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String audioUrl;
  final String? thumbUrl;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.audioUrl,
    this.thumbUrl,
  });

  /// Returns a version of the title sanitized for alphabetical sorting.
  String get sortableTitle => ApolloStringUtils.toSortable(title);

  factory Track.fromPlexJson(Map<String, dynamic> json, String serverUrl, String token) {
    final media = json['Media'][0];
    final part = media['Part'][0];
    final key = part['key'];
    return Track(
      id: json['ratingKey'].toString(),
      title: json['title'],
      artist: json['grandparentTitle'] ?? 'Unknown Artist',
      audioUrl: '$serverUrl$key?X-Plex-Token=$token',
    );
  }
}