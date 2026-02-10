/// SQL Triggers for maintaining data integrity.
/// 
/// These keep denormalized name/thumb columns on the tracks table
/// in sync when the parent artist or album record is updated.
/// This addresses the "source of truth" conflict: tracks store
/// artist_name/album_name for performance, but the canonical name
/// lives in the artists/albums tables. Triggers ensure consistency.
class TriggerSchema {
  static const List<String> createTriggers = [
    // ============================================================
    // NAME SYNC TRIGGERS
    // When an artist or album is renamed (e.g., corrected metadata
    // from a Plex re-sync), propagate the change to all related
    // tracks and albums so the denormalized columns stay current.
    // ============================================================

    /// When an artist's title changes, update all related tracks and albums
    '''CREATE TRIGGER IF NOT EXISTS trg_artist_name_sync
       AFTER UPDATE OF title ON artists
       BEGIN
         UPDATE tracks SET artist_name = NEW.title WHERE artist_id = NEW.id;
         UPDATE albums SET artist_name = NEW.title WHERE artist_id = NEW.id;
       END''',

    /// When an album's title changes, update all related tracks
    '''CREATE TRIGGER IF NOT EXISTS trg_album_name_sync
       AFTER UPDATE OF title ON albums
       BEGIN
         UPDATE tracks SET album_name = NEW.title WHERE album_id = NEW.id;
       END''',

    // ============================================================
    // THUMB SYNC TRIGGERS
    // Keep thumbnail references on tracks current when the parent
    // artist or album artwork changes.
    // ============================================================

    /// When an artist's thumb changes, update all related tracks
    '''CREATE TRIGGER IF NOT EXISTS trg_artist_thumb_sync
       AFTER UPDATE OF thumb ON artists
       BEGIN
         UPDATE tracks SET grandparent_thumb = NEW.thumb WHERE artist_id = NEW.id;
       END''',

    /// When an album's thumb changes, update all related tracks
    '''CREATE TRIGGER IF NOT EXISTS trg_album_thumb_sync
       AFTER UPDATE OF thumb ON albums
       BEGIN
         UPDATE tracks SET parent_thumb = NEW.thumb WHERE album_id = NEW.id;
       END''',
  ];

  /// Execute all trigger creation statements
  static Future<void> createAll(dynamic db) async {
    for (final sql in createTriggers) {
      try {
        await db.execute(sql);
      } catch (e) {
        // Trigger may already exist or table structure may differ
      }
    }
  }

  /// Drop all triggers (for recreation)
  static Future<void> dropAll(dynamic db) async {
    final triggerNames = [
      'trg_artist_name_sync',
      'trg_album_name_sync',
      'trg_artist_thumb_sync',
      'trg_album_thumb_sync',
    ];
    for (final name in triggerNames) {
      await db.execute('DROP TRIGGER IF EXISTS $name');
    }
  }
}
