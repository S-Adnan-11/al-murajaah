import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

class DiagnosticFile {
  const DiagnosticFile(this.path, this.bytes, this.sha256);
  final String path;
  final int bytes;
  final String sha256;
}

/// Export complete stored JSONL bytes, not the clipboard's recent-event window.
/// Caller holds its logging write barrier until this snapshot is complete.
Future<DiagnosticFile> writeDiagnosticFile(
  String rootPath,
  Map<String, Object?> metadata,
) => Isolate.run(() async {
  final logs = Directory('$rootPath/logs');
  final records = <Map<String, Object?>>[];
  if (await logs.exists()) {
    final files = await logs
        .list()
        .where((f) => f is File)
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final bytes = await file.readAsBytes();
      Map<String, Object?> content;
      try {
        content = {'encoding': 'utf-8', 'rawJsonl': utf8.decode(bytes)};
      } on FormatException {
        content = {'encoding': 'base64', 'rawBytesBase64': base64Encode(bytes)};
      }
      // Raw JSONL is retained even if a previous process left a partial row.
      records.add({
        'name': file.uri.pathSegments.last,
        'bytes': bytes.length,
        'sha256': sha256.convert(bytes).toString(),
        ...content,
      });
    }
  }
  final payload = utf8.encode(
    jsonEncode({
      'format': 'al-murajaah-diagnostics-v1',
      'metadata': metadata,
      'storedLogs': records,
    }),
  );
  final exports = Directory('$rootPath/exports');
  await exports.create(recursive: true);
  final file = File(
    '${exports.path}/audio-diagnostics-${DateTime.now().toUtc().microsecondsSinceEpoch}.json',
  );
  await file.writeAsBytes(payload, flush: true);
  return DiagnosticFile(
    file.path,
    payload.length,
    sha256.convert(payload).toString(),
  );
});
