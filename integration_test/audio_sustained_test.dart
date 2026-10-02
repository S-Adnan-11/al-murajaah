import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('At-Tawbah 12 minute stream and verified local transport trials', (
    tester,
  ) async {
    final base = await PrototypeStore.open();
    // Fresh isolated directory: never delete the user's downloads/checkpoint.
    final root = Directory(
      '${base.root.path}/sustained-${DateTime.now().toUtc().microsecondsSinceEpoch}',
    );
    await root.create(recursive: true);
    final store = PrototypeStore(root);
    final h = await createHandler(store);
    runApp(DiagnosticApp(handler: h));
    await tester.pump();
    try {
      final asset = samples[1];
      final duration = await h
          .inspect(asset)
          .timeout(const Duration(seconds: 90));
      expect(h.usingLocal, false);
      expect(duration, 4299684);
      await runSustainedTrial(h, duration, 'stream');
      await store
          .download(asset, (_, _) {})
          .timeout(const Duration(minutes: 3));
      expect(await store.isVerified(asset), true);
      expect(await store.audioFile(asset).length(), asset.bytes);
      final localDuration = await h
          .inspect(asset)
          .timeout(const Duration(seconds: 90));
      expect(localDuration, duration);
      expect(h.usingLocal, true);
      await runSustainedTrial(h, duration, 'verified-local');
    } finally {
      await h.stop();
      await tester.pumpWidget(const SizedBox());
      await h.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}

Future<void> runSustainedTrial(
  PrototypeHandler h,
  int duration,
  String mode,
) async {
  await h.start(SessionSpec(assetId: samples[1].id, durationMs: duration));
  final readyDeadline = DateTime.now().add(const Duration(seconds: 90));
  while (h.diagnostics['processingState'] != 'ready' ||
      h.position.inMilliseconds == 0) {
    if (DateTime.now().isAfter(readyDeadline)) {
      throw TimeoutException('Playback readiness: $mode');
    }
    expect(h.lastError, isNull);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  final initialPosition = h.position.inMilliseconds;
  final watch = Stopwatch()..start();
  final samplesFile = File('${h.store.root.path}/$mode-samples.jsonl');
  var nextMinute = 0;
  while (watch.elapsed < const Duration(minutes: 12)) {
    final row = {
      ...h.diagnostics,
      'mode': mode,
      'elapsedMs': watch.elapsedMilliseconds,
    };
    await samplesFile.writeAsString(
      '${jsonEncode(row)}\n',
      mode: FileMode.append,
      flush: true,
    );
    expect(h.lastError, isNull, reason: jsonEncode(row));
    expect(h.completed, false, reason: jsonEncode(row));
    expect(h.pass, 1, reason: jsonEncode(row));
    expect(row['speed'], 1.0);
    expect(row['pitch'], 1.0);
    expect(row['volume'], 1.0);
    if (watch.elapsed.inSeconds >= nextMinute) {
      debugPrint('SUSTAINED_SAMPLE ${jsonEncode(row)}');
      h.recordDiagnostic('sustained-$mode-minute');
      nextMinute += 60;
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  final end = {
    ...h.diagnostics,
    'mode': mode,
    'elapsedMs': watch.elapsedMilliseconds,
  };
  await samplesFile.writeAsString(
    '${jsonEncode(end)}\n',
    mode: FileMode.append,
    flush: true,
  );
  // Strict full-rate transport progression. This does not assert audible output.
  expect(
    h.position.inMilliseconds - initialPosition,
    closeTo(watch.elapsedMilliseconds, 5000),
    reason: jsonEncode(end),
  );
  expect(end['processingState'], 'ready');
  await h.pause();
  final paused = h.position;
  final pausedPass = h.pass;
  await Future<void>.delayed(const Duration(seconds: 2));
  expect(h.position, paused);
  expect(h.pass, pausedPass);
  debugPrint('SUSTAINED_RESULT $mode 12min TRANSPORT_PASS ${jsonEncode(end)}');
}
