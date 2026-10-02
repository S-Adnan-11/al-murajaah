import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:al_murajaah/main.dart';
import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';

Future<void> eventually(bool Function() condition, {int seconds = 90}) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Native condition timed out');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native streamed/local clips, counts, pause, continuous and long seek',
    (tester) async {
      final base = await PrototypeStore.open();
      final root = Directory('${base.root.path}/native_test');
      await root.create(recursive: true);
      final store = PrototypeStore(root);
      // The test directory belongs exclusively to this harness.
      final checkpoint = File('${root.path}/checkpoint.json');
      if (await checkpoint.exists()) await checkpoint.delete();
      final handler = await createHandler(store);
      runApp(DiagnosticApp(handler: handler));
      await tester.pump();
      try {
        final short = samples.first;
        final existing = store.audioFile(short);
        if (await existing.exists()) {
          await existing.delete(); // Force a real streaming trial.
        }
        final shortDuration = await handler.inspect(short);
        expect(handler.usingLocal, false);
        await _finite(handler, short, shortDuration, 1);
        debugPrint(
          'NATIVE_RESULT streamed_count_1 PASS durationMs=$shortDuration',
        );
        for (final asset in samples) {
          await store.download(asset, (_, _) {});
          expect(await store.isVerified(asset), true);
          final duration = await handler.inspect(asset);
          expect(handler.usingLocal, true);
          debugPrint(
            'NATIVE_RESULT verified_download ${asset.id} durationMs=$duration bytes=${asset.bytes}',
          );
        }
        await handler.inspect(short);
        for (final count in [1, 3, 10]) {
          await _finite(handler, short, shortDuration, count);
          debugPrint('NATIVE_RESULT local_count_$count PASS');
        }
        final continuous = SessionSpec(
          assetId: short.id,
          durationMs: shortDuration,
          startMs: 2000,
          endMs: 3500,
          playCount: null,
          isPassage: true,
        );
        await handler.start(continuous);
        await eventually(() => handler.playing);
        await Future<void>.delayed(const Duration(seconds: 6));
        expect(handler.completed, false);
        expect(handler.playing, true);
        await handler.pause();
        final pausedPass = handler.pass;
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(handler.playing, false);
        expect(handler.pass, pausedPass);
        await handler.play();
        await eventually(() => handler.playing);
        await handler.pause();
        debugPrint('NATIVE_RESULT continuous_pause_resume PASS');
        await store.savePassage('Native test range', continuous);
        expect(
          (await PrototypeStore(root).passages()).last.spec.toJson(),
          continuous.toJson(),
        );
        expect((await store.readCheckpoint())!['spec']['assetId'], short.id);
        final long = samples[1];
        final longDuration = await handler.inspect(long);
        expect(longDuration, greaterThan(938000));
        await handler.start(
          SessionSpec(
            assetId: long.id,
            durationMs: longDuration,
            startMs: 745000,
            endMs: 747000,
            isPassage: true,
          ),
        );
        await eventually(() => handler.completed, seconds: 120);
        expect(handler.playing, false);
        expect(handler.position.inMilliseconds, closeTo(2000, 150));
        debugPrint(
          'NATIVE_RESULT long_local_clip_after_12min PASS durationMs=$longDuration',
        );
        await handler.start(
          SessionSpec(assetId: long.id, durationMs: longDuration),
          autoPlay: false,
        );
        expect(handler.spec!.isPassage, false);
        expect(handler.spec!.playCount, 1);
        await handler.seek(Duration(milliseconds: longDuration - 2000));
        await handler.play();
        await eventually(() => handler.completed, seconds: 120);
        debugPrint('NATIVE_RESULT full_scope_reset_and_EOF PASS');
      } finally {
        await handler.stop();
        await tester.pumpWidget(const SizedBox());
        await handler.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

Future<void> _finite(
  PrototypeHandler handler,
  SampleAsset asset,
  int duration,
  int count,
) async {
  final indices = <int>{};
  void record() {
    if (handler.playing) indices.add(handler.pass);
  }

  handler.revision.addListener(record);
  try {
    await handler.start(
      SessionSpec(
        assetId: asset.id,
        durationMs: duration,
        startMs: 2000,
        endMs: 3500,
        isPassage: true,
        playCount: count,
      ),
    );
    await eventually(() => handler.completed, seconds: 120);
    expect(handler.pass, count);
    expect(handler.playing, false);
    expect(handler.position.inMilliseconds, closeTo(1500, 150));
    expect(indices, containsAll(List.generate(count, (i) => i + 1)));
  } finally {
    handler.revision.removeListener(record);
  }
}
