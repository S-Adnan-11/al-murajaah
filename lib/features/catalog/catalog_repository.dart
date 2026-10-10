import 'dart:convert';

import '../../core/audio/sample_catalog.dart';
import '../../core/database/app_database.dart';
import 'catalog.dart';

extension PlaybackRecording on CatalogRecording {
  SampleAsset get audioAsset =>
      SampleAsset(assetId, name, url.toString(), byteSize, sha256);
}

/// Installs a validated manifest atomically without replacing retained identities.
/// No preferences, passages, checkpoints, downloads or legacy JSON are deleted.
class CatalogRepository {
  CatalogRepository(this.db);
  final AppDatabase db;

  Future<void> install(Catalog catalog) => db.transaction(() async {
    final existing = {
      for (final asset in await db.select(db.audioAssets).get())
        asset.id: asset,
    };
    for (final recording in catalog.recordings) {
      final old = existing[recording.assetId];
      if (old != null &&
          (old.editionId != 'zarami-hafs-v1' ||
              old.surahNumber != recording.number ||
              old.version != recording.version ||
              old.url != recording.url.toString() ||
              old.mimeType != 'audio/mpeg' ||
              old.byteSize != recording.byteSize ||
              old.sha256 != recording.sha256 ||
              old.durationMs != recording.durationMs)) {
        throw StateError('Recording identity conflict: ${recording.assetId}');
      }
    }
    await db.batch((batch) {
      batch.customStatement(
        'INSERT OR IGNORE INTO reciters (id,display_name,attribution,source_info) VALUES (?,?,?,?)',
        [
          'zarami',
          'Muhammad Bukar Zarami',
          'Recordings used with permission',
          'Owner-supplied Cloudinary collection',
        ],
      );
      batch.customStatement(
        'INSERT OR IGNORE INTO recording_editions (id,reciter_id,riwayah,source_notes) VALUES (?,?,?,?)',
        [
          'zarami-hafs-v1',
          'zarami',
          'Hafs',
          'Verified distribution bytes; original introductions retained',
        ],
      );
      for (final recording in catalog.recordings) {
        batch.customStatement(
          "UPDATE audio_assets SET availability='retired' WHERE edition_id=? AND surah_number=? AND version<?",
          ['zarami-hafs-v1', recording.number, recording.version],
        );
        batch.customStatement(
          'INSERT INTO surahs (number,arabic_name,transliteration,search_aliases) VALUES (?,?,?,?) '
          'ON CONFLICT(number) DO UPDATE SET arabic_name=excluded.arabic_name,'
          'transliteration=excluded.transliteration,search_aliases=excluded.search_aliases',
          [
            recording.number,
            recording.arabicName,
            recording.name,
            jsonEncode(recording.searchAliases),
          ],
        );
        if (!existing.containsKey(recording.assetId)) {
          batch.customStatement(
            'INSERT INTO audio_assets (id,edition_id,surah_number,version,url,mime_type,duration_ms,byte_size,sha256,availability) '
            'VALUES (?,?,?,?,?,?,?,?,?,?)',
            [
              recording.assetId,
              'zarami-hafs-v1',
              recording.number,
              recording.version,
              recording.url.toString(),
              'audio/mpeg',
              recording.durationMs,
              recording.byteSize,
              recording.sha256,
              recording.available ? 'published' : 'unavailable',
            ],
          );
        }
      }
    });
  });

  /// Last good installed catalog, including retained bytes. Newer versions do
  /// not make old passage/download references resolve to another asset.
  Future<Catalog?> load() async {
    final rows = await db
        .customSelect(
          'SELECT a.*, s.arabic_name, s.transliteration, s.search_aliases '
          'FROM audio_assets a JOIN surahs s ON s.number=a.surah_number '
          "WHERE a.edition_id='zarami-hafs-v1' AND a.availability IN ('published','unavailable') "
          'ORDER BY a.surah_number, a.version DESC',
        )
        .get();
    final byNumber = <int, Map<String, dynamic>>{};
    for (final row in rows) {
      final r = row.data;
      final number = r['surah_number'] as int;
      byNumber.putIfAbsent(
        number,
        () => {
          'number': number,
          'arabicName': r['arabic_name'],
          'name': r['transliteration'],
          'searchAliases': jsonDecode(r['search_aliases'] as String),
          'assetId': r['id'],
          'version': r['version'],
          'url': r['url'],
          'mimeType': r['mime_type'],
          'durationMs': r['duration_ms'],
          'byteSize': r['byte_size'],
          'sha256': r['sha256'],
          'availability': r['availability'],
          'unavailableReason': r['availability'] == 'published'
              ? null
              : 'Recording under review',
        },
      );
    }
    if (byNumber.length != 114) return null;
    return Catalog.parse(
      jsonEncode({
        'schemaVersion': 1,
        'editionId': 'zarami-hafs-v1',
        'reciter': 'Zarami',
        'riwayah': 'Hafs',
        'recordings': byNumber.values.toList(),
      }),
    );
  }

  Future<Set<String>> retiredAssets() async => {
    for (final asset in await db.select(db.audioAssets).get())
      if (asset.availability == 'retired') asset.id,
  };
  Future<List<SampleAsset>> retainedPlaybackAssets() async {
    final names = {
      for (final s in await db.select(db.surahs).get())
        s.number: s.transliteration,
    };
    return [
      for (final asset in await db.select(db.audioAssets).get())
        if (asset.byteSize != null &&
            asset.sha256 != null &&
            asset.editionId == 'zarami-hafs-v1')
          SampleAsset(
            asset.id,
            '${names[asset.surahNumber] ?? 'Surah ${asset.surahNumber}'}${asset.availability == 'retired' ? ' (previous recording — review)' : ''}',
            asset.url,
            asset.byteSize!,
            asset.sha256!,
          ),
    ];
  }
}
