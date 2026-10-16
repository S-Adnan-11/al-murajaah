import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Local support preferences/draft only; separate from listening and backups.
class SupportStore {
  SupportStore(this.file);
  final File file;
  Future<void> _writes = Future.value();
  Map<String, dynamic>? _data;
  static Future<SupportStore>? _shared;
  static Future<SupportStore> open() => _shared ??= _open();
  static Future<SupportStore> _open() async => SupportStore(
    File('${(await getApplicationSupportDirectory()).path}/support_v1.json'),
  );
  Future<Map<String, dynamic>> read() async {
    await _writes;
    _data ??= await file.exists()
        ? Map<String, dynamic>.from(jsonDecode(await file.readAsString()))
        : {};
    return Map.of(_data!);
  }

  Future<void> update(String key, Object? value) {
    final result = _writes.then((_) async {
      _data ??= await file.exists()
          ? Map<String, dynamic>.from(jsonDecode(await file.readAsString()))
          : {};
      final next = {..._data!, key: value};
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.part');
      await temporary.writeAsString(jsonEncode(next), flush: true);
      await temporary.rename(file.path);
      _data = next;
    });
    _writes = result.catchError((Object _) {});
    return result;
  }
}
