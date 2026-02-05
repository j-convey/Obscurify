import 'package:flutter/foundation.dart';
import 'plex_api_client.dart';

/// Service for managing Plex media ratings.
class PlexRatingService {
  final PlexApiClient _client = PlexApiClient();

  /// Rate an item on the Plex server.
  /// 
  /// [serverUrl] - The Plex server URL
  /// [token] - The Plex authentication token
  /// [ratingKey] - The rating key of the item to rate
  /// [rating] - The rating value (0-10). Use 0 to remove the rating.
  /// 
  /// Returns true if the rating was successfully set.
  Future<bool> rateItem({
    required String serverUrl,
    required String token,
    required String ratingKey,
    required double rating,
  }) async {
    try {
      // Clamp rating to valid range
      final clampedRating = rating.clamp(0.0, 10.0);
      
      final url = '$serverUrl/:/rate'
          '?identifier=com.plexapp.plugins.library'
          '&key=$ratingKey'
          '&rating=$clampedRating';

      debugPrint('RATING: Setting rating $clampedRating for item $ratingKey');
      
      final response = await _client.put(url, token: token);

      if (response.statusCode == 200) {
        debugPrint('RATING: Successfully set rating for $ratingKey');
        return true;
      } else {
        debugPrint('RATING: Failed to set rating - ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('RATING: Error setting rating: $e');
      return false;
    }
  }

  /// Toggle the like status of an item.
  /// 
  /// If the current rating is >= 5, this will set it to 0 (unlike).
  /// If the current rating is < 5 or null, this will set it to 10 (like).
  /// 
  /// Returns the new rating value, or null if the operation failed.
  Future<double?> toggleLike({
    required String serverUrl,
    required String token,
    required String ratingKey,
    double? currentRating,
  }) async {
    final isCurrentlyLiked = (currentRating ?? 0) >= 5;
    final newRating = isCurrentlyLiked ? 0.0 : 10.0;

    final success = await rateItem(
      serverUrl: serverUrl,
      token: token,
      ratingKey: ratingKey,
      rating: newRating,
    );

    return success ? newRating : null;
  }
}
