import '../../core/database/app_database.dart';
import 'support_content.dart';

/// Separate editions satisfy existing accounting foreign keys. The canonical
/// catalog still selects only zarami-hafs-v1; no new schema or download is used.
class StoryRepository {
  StoryRepository(this.db);
  final AppDatabase db;
  Future<void> install() => db.transaction(() async {
    for (final recording in storyRecordings) {
      if (!recording.valid) throw StateError('Invalid origin recording');
      final asset = recording.asset;
      final teacher = asset.id.startsWith('origin-');
      final reciter = teacher ? 'origin-abdulrahman' : 'origin-nasir';
      final edition = '$reciter-v1';
      final surah = switch (asset.id) {
        'brother-002' => 14,
        'brother-003' => 24,
        _ => 22,
      };
      final old = await (db.select(
        db.audioAssets,
      )..where((a) => a.id.equals(asset.id))).getSingleOrNull();
      if (old != null) {
        if (old.editionId != edition ||
            old.surahNumber != surah ||
            old.version != 1 ||
            old.url != asset.url ||
            old.sha256 != asset.sha256 ||
            old.byteSize != asset.bytes ||
            old.durationMs != recording.durationMs ||
            old.mimeType != 'audio/mpeg') {
          throw StateError('Origin recording identity conflict');
        }
        continue;
      }
      await db.customStatement(
        'INSERT OR IGNORE INTO reciters (id,display_name,attribution,source_info) VALUES (?,?,?,?)',
        [
          reciter,
          asset.reciter,
          'Owner-supplied recitation',
          'Origin recordings',
        ],
      );
      await db.customStatement(
        'INSERT OR IGNORE INTO recording_editions (id,reciter_id,riwayah,source_notes) VALUES (?,?,?,?)',
        [edition, reciter, null, 'Versioned owner-supplied excerpt'],
      );
      await db.customStatement(
        'INSERT INTO audio_assets (id,edition_id,surah_number,version,url,mime_type,duration_ms,byte_size,sha256,availability) VALUES (?,?,?,?,?,?,?,?,?,?)',
        [
          asset.id,
          edition,
          surah,
          1,
          asset.url,
          'audio/mpeg',
          recording.durationMs,
          asset.bytes,
          asset.sha256,
          'published',
        ],
      );
    }
  });
}
