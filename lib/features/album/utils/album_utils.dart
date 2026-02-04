/// Utility functions for album pages
class AlbumUtils {
  static String formatDuration(int? milliseconds) {
    if (milliseconds == null || milliseconds == 0) return '0:00';
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static String formatDate(int? millisecondsSinceEpoch) {
    if (millisecondsSinceEpoch == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch * 1000);
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  static void sortTracks(List<Map<String, dynamic>> tracks, String column, bool ascending) {
    tracks.sort((a, b) {
      int comparison = 0;

      switch (column) {
        case 'title':
          comparison = (a['title'] as String).compareTo(b['title'] as String);
          break;
        case 'artist':
          comparison = (a['artist'] as String).compareTo(b['artist'] as String);
          break;
        case 'duration':
          comparison = ((a['duration'] as int?) ?? 0).compareTo((b['duration'] as int?) ?? 0);
          break;
        case 'addedAt':
          comparison = ((a['addedAt'] as int?) ?? 0).compareTo((b['addedAt'] as int?) ?? 0);
          break;
      }

      return ascending ? comparison : -comparison;
    });
  }
}
