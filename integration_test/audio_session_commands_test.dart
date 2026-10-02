import 'dart:async';
import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Session command condition timed out');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

Future<void> prepareLocal(
  PrototypeStore base,
  PrototypeStore fixture,
  SampleAsset asset,
) async {
  // Read existing files only; this harness owns a separate fresh fixture store.
  for (final candidate in [
    base,
    PrototypeStore(Directory('${base.root.path}/native_test')),
  ]) {
    if (await candidate.isVerified(asset)) {
      await candidate.audioFile(asset).copy(fixture.audioFile(asset).path);
      break;
    }
  }
  if (!await fixture.isVerified(asset)) {
    await fixture.download(asset, (_, _) {});
  }
  expect(await fixture.isVerified(asset), true);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native session switch, seek, completion race and stop', (
    tester,
  ) async {
    final base = await PrototypeStore.open();
    final fixture = PrototypeStore(
      Directory(
        '${base.root.path}/session_commands_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    await fixture.root.create(recursive: true);
    final first = samples.first;
    final last = samples.last;
    await prepareLocal(base, fixture, first);
    await prepareLocal(base, fixture, last);
    final h = await createHandler(fixture);
    runApp(DiagnosticApp(handler: h));
    await tester.pump();
    try {
      final firstDuration = await h.inspect(first);
      final lastDuration = await h.inspect(last);
      expect(h.usingLocal, true);
      final firstSpec = SessionSpec(
        assetId: first.id,
        durationMs: firstDuration,
        startMs: 2000,
        endMs: 3500,
        playCount: 3,
        isPassage: true,
      );
      final lastSpec = SessionSpec(
        assetId: last.id,
        durationMs: lastDuration,
        startMs: 5000,
        endMs: 9000,
        isPassage: true,
      );

      // Concurrent requests must select the latest actual source/metadata.
      final olderLoad = h.inspect(first);
      final latestLoad = h.inspect(last);
      final durations = await Future.wait([olderLoad, latestLoad]);
      expect(durations.last, lastDuration);
      expect(h.spec!.assetId, last.id);
      expect(h.mediaItem.value!.id, last.id);
      expect(h.playing, false);
      final olderStart = h.start(firstSpec);
      final latestStart = h.start(lastSpec);
      await Future.wait([olderStart, latestStart]);
      await waitFor(() => h.playing && h.position.inMilliseconds > 250);
      expect(h.spec!.toJson(), lastSpec.toJson());
      expect(h.mediaItem.value!.id, last.id);
      expect(h.pass, 1);
      expect(h.lastError, null);
      await h.pause();
      debugPrint('SESSION_COMMAND_RESULT latest_recording_wins PASS');

      // A passage seek is relative to A and must not fabricate a new pass.
      await h.start(firstSpec, autoPlay: false);
      await h.seek(const Duration(milliseconds: 850));
      expect(h.position.inMilliseconds, closeTo(850, 100));
      expect(h.pass, 1);
      expect(h.playing, false);
      final pausedPosition = h.position;
      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(h.position, pausedPosition);
      expect(h.pass, 1);
      await h.play();
      await waitFor(() => h.pass == 2 && h.position.inMilliseconds > 100);
      await h.pause();
      await h.seek(const Duration(milliseconds: 600));
      expect(h.position.inMilliseconds, closeTo(600, 100));
      expect(h.pass, 2);
      expect(h.playing, false);
      debugPrint('SESSION_COMMAND_RESULT passage_seek_pause_pass PASS');

      // Completion near an old boundary must not pause a replacement session.
      await h.start(
        SessionSpec(
          assetId: first.id,
          durationMs: firstDuration,
          startMs: 2000,
          endMs: 3500,
          isPassage: true,
        ),
      );
      await waitFor(() => h.playing);
      final boundarySeek = h.seek(const Duration(milliseconds: 1450));
      final replacement = h.start(lastSpec);
      await Future.wait([boundarySeek, replacement]);
      await waitFor(() => h.playing && h.position.inMilliseconds > 200);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      expect(h.spec!.toJson(), lastSpec.toJson());
      expect(h.mediaItem.value!.id, last.id);
      expect(h.playing, true);
      expect(h.completed, false);
      expect(h.position.inMilliseconds, greaterThan(900));
      expect(h.lastError, null);
      debugPrint('SESSION_COMMAND_RESULT replace_near_old_end PASS');

      // Stop issued behind a start must leave native transport stopped.
      final queuedStart = h.start(firstSpec);
      final stop = h.stop();
      await Future.wait([queuedStart, stop]);
      await Future<void>.delayed(const Duration(seconds: 1));
      expect(h.playing, false);
      expect(h.diagnostics['playIntent'], false);
      expect(h.diagnostics['processingState'], 'idle');
      expect(h.lastError, null);
      debugPrint('SESSION_COMMAND_RESULT queued_start_stop PASS');
    } finally {
      await h.stop();
      await tester.pumpWidget(const SizedBox());
      await h.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
