import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../core/audio/prototype_store.dart' as legacy;
import '../../core/audio/session_spec.dart';
import '../../core/database/app_database.dart';

class LibraryPassage {
  LibraryPassage(this.row, this.durationMs, this.recordingName, this.review);
  final SavedPassage row;
  final int durationMs;
  final String recordingName;
  final bool review;
  String get id => row.id;
  String get title => row.title;
  SessionSpec get spec => SessionSpec(
    assetId: row.assetId,
    durationMs: durationMs,
    startMs: row.startMs,
    endMs: row.endMs,
    isPassage: true,
    playCount: row.playCount,
    gapMs: row.gapMs,
    speed: row.speed,
    passageId: row.id,
    passageTitle: row.title,
  );
}

/// SQLite owns product saves. Import leaves the diagnostic JSON untouched and
/// uses stable IDs so repeated launches cannot duplicate the older saves.
class PassageLibrary {
  PassageLibrary(this.db);
  final AppDatabase db;
  static String uuid(List<int> bytes) {
    bytes = List.of(bytes);
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
  }

  static String newId() =>
      uuid(List.generate(16, (_) => Random.secure().nextInt(256)));

  Future<void> importLegacy(legacy.PrototypeStore store) async {
    final old = await store.passages();
    final receipt = File('${store.root.path}/product-passages-import.json');
    final imported = await receipt.exists()
        ? (jsonDecode(await receipt.readAsString()) as List)
              .cast<String>()
              .toSet()
        : <String>{};
    await db.transaction(() async {
      for (var i = 0; i < old.length; i++) {
        final p = old[i];
        final id = uuid(
          sha256
              .convert(
                utf8.encode(
                  jsonEncode({
                    'legacyIndex': i,
                    'title': p.title,
                    'spec': p.spec.toJson(),
                  }),
                ),
              )
              .bytes
              .take(16)
              .toList(),
        );
        if (imported.contains(id)) continue;
        final exists = await (db.select(
          db.savedPassages,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (exists == null) await save(p.title, p.spec, id: id);
        imported.add(id);
      }
    });
    if (old.isNotEmpty) {
      final temporary = File('${receipt.path}.part');
      await temporary.writeAsString(jsonEncode(imported.toList()), flush: true);
      await temporary.rename(receipt.path);
    }
  }

  Future<List<LibraryPassage>> read() async {
    final rows = await (db.select(db.savedPassages)).get();
    final assets = {
      for (final a in await db.select(db.audioAssets).get()) a.id: a,
    };
    final surahs = {
      for (final s in await db.select(db.surahs).get()) s.number: s,
    };
    return [
      for (final row in rows)
        LibraryPassage(
          row,
          assets[row.assetId]!.durationMs!,
          surahs[assets[row.assetId]!.surahNumber]!.transliteration,
          assets[row.assetId]!.availability != 'published',
        ),
    ];
  }

  Future<String> save(
    String title,
    SessionSpec spec, {
    String? id,
    String? note,
    double? speed,
  }) async {
    if (title.trim().isEmpty || !spec.isPassage) {
      throw ArgumentError('Name a passage');
    }
    final key = id ?? newId();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT INTO saved_passages (id,asset_id,title,start_ms,end_ms,repeat_mode,play_count,gap_ms,speed,note,created_utc_ms,updated_utc_ms) '
      'VALUES (?,?,?,?,?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET '
      'title=excluded.title,start_ms=excluded.start_ms,end_ms=excluded.end_ms,repeat_mode=excluded.repeat_mode,'
      'play_count=excluded.play_count,gap_ms=excluded.gap_ms,speed=excluded.speed,note=excluded.note,updated_utc_ms=excluded.updated_utc_ms',
      [
        key,
        spec.assetId,
        title.trim(),
        spec.startMs,
        spec.endMs,
        spec.playCount == null ? 'continuous' : 'finite',
        spec.playCount,
        spec.gapMs,
        speed ?? spec.speed,
        note,
        now,
        now,
      ],
    );
    return key;
  }

  Future<void> delete(String id) async {
    await (db.delete(db.savedPassages)..where((t) => t.id.equals(id))).go();
  }
}
