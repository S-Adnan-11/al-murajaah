import 'package:flutter/foundation.dart';

import '../database/app_database.dart';

/// The committed language survives Home's widget and route lifetimes. Automatic
/// transitions stay in memory; only an explicit preference change writes SQLite.
class HomeTextController extends ChangeNotifier {
  HomeTextController({this.database});
  final AppDatabase? database;
  bool _alternating = true, _arabic = false;
  bool get alternating => _alternating;
  bool get arabic => _arabic;

  Future<void> restore() async {
    final db = database;
    if (db == null) return;
    final row = await db.select(db.appSettings).getSingle();
    _alternating = row.alternateHomeText == 1;
    _arabic = row.homeTextLanguage == 'arabic';
    notifyListeners();
  }

  Future<void> setAlternating(bool value) async {
    if (_alternating == value) return;
    await _persist(value, _arabic);
    _alternating = value;
    notifyListeners();
  }

  Future<void> commitLanguage(bool value) async {
    if (_arabic == value) return;
    // A manual accessibility switch while frozen is also a meaningful choice.
    if (!_alternating) await _persist(false, value);
    _arabic = value;
    notifyListeners();
  }

  Future<void> _persist(bool alternating, bool arabic) async {
    final db = database;
    if (db == null) return;
    await db.customStatement(
      'UPDATE app_settings SET alternate_home_text=?,home_text_language=?,updated_utc_ms=? WHERE id=1',
      [
        alternating ? 1 : 0,
        arabic ? 'arabic' : 'english',
        DateTime.now().toUtc().millisecondsSinceEpoch,
      ],
    );
    db.markTablesUpdated([db.appSettings]);
  }
}
