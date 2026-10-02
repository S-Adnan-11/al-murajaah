import 'package:flutter/services.dart';

import 'diagnostic_export.dart';

class AndroidDiagnostics {
  static const _channel = MethodChannel('dev.almurajaah/diagnostics');

  static Future<Map<String, Object?>> platformEvidence() async {
    try {
      return Map<String, Object?>.from(
        await _channel.invokeMapMethod<String, Object?>('platformEvidence') ??
            {},
      );
    } on PlatformException catch (error) {
      return {'platformEvidenceError': error.toString()};
    } on MissingPluginException {
      return {'platformEvidence': 'unavailable on this target'};
    }
  }

  static Future<Map<String, Object?>?> saveFile(DiagnosticFile file) async {
    return _channel.invokeMapMethod<String, Object?>('saveDiagnosticFile', {
      'path': file.path,
      'bytes': file.bytes,
      'sha256': file.sha256,
    });
  }
}
