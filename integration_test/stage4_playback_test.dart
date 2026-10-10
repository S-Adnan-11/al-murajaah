import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:audio_service/audio_service.dart';
import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';

Future<void> until(bool Function() condition, {int seconds = 40}) async {
  final clock = Stopwatch()..start();
  while (!condition()) {
    if (clock.elapsed.inSeconds >= seconds) {
      throw TimeoutException('Stage4 condition exceeded $seconds seconds');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native cancellation, zero-gap, gaps and sleep stop', (
    tester,
  ) async {
    final base = await PrototypeStore.open();
    final root = Directory(
      '${base.root.path}/stage4-proof-${DateTime.now().microsecondsSinceEpoch}',
    );
    await root.create(recursive: true);
    final store = PrototypeStore(root);
    final original = await base.verifiedFile(samples.first);
    expect(
      original,
      isNotNull,
      reason:
          'Reuse the retained verified Fatihah; no implicit network download.',
    );
    await original!.copy(store.audioFile(samples.first).path);
    Completer<void>? held;
    final h = await AudioService.init<PrototypeHandler>(
      builder: () => PrototypeHandler(
        store,
        localResolver: (asset) async {
          await held?.future;
          return store.verifiedFile(asset);
        },
      ),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'dev.almurajaah.diagnostic.audio',
        androidNotificationChannelName: 'Passage playback',
        androidStopForegroundOnPause: false,
      ),
    );
    await h.initialize();
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Stage 4 bounded native checks')),
        ),
      ),
    );
    await tester.pump();
    try {
      final duration = await h.inspect(samples.first);
      final full = SessionSpec(assetId: samples.first.id, durationMs: duration);
      for (final pause in [true, false]) {
        held = Completer<void>();
        final request = h.loadAndStart(full);
        await Future<void>.delayed(const Duration(milliseconds: 150));
        final cancellation = pause ? h.pause() : h.stop();
        held.complete();
        await request.timeout(const Duration(seconds: 30));
        await cancellation.timeout(const Duration(seconds: 30));
        held = null;
        expect(h.playing, false);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        expect(h.playing, false);
        debugPrint(
          'NATIVE_STAGE4 ${pause ? 'pause' : 'stop'}_pending_load PASS',
        );
      }
      for (final gap in [0, 2000]) {
        await h.loadAndStart(
          SessionSpec(
            assetId: samples.first.id,
            durationMs: duration,
            startMs: 2000,
            endMs: 5000,
            isPassage: true,
            playCount: 3,
            gapMs: gap,
          ),
        );
        if (gap > 0) {
          debugPrint('NATIVE_STAGE4 BACKGROUND_READY gap=$gap');
          await until(() => h.inGap);
          expect(h.pass, 1);
          expect(h.position.inMilliseconds, 3000);
          await h.pause();
          final pass = h.pass;
          await Future<void>.delayed(const Duration(seconds: 3));
          expect(h.pass, pass);
          expect(h.playing, false);
          await h.play();
        }
        await until(() => h.completed);
        expect(h.pass, 3);
        expect(h.lastError, isNull);
        expect(h.inGap, false);
        await Future<void>.delayed(const Duration(milliseconds: 600));
        expect(h.playing, false);
        expect(h.pass, 3);
        debugPrint('NATIVE_STAGE4 finite_3_gap_$gap PASS');
      }
      await h.loadAndStart(
        SessionSpec(
          assetId: samples.first.id,
          durationMs: duration,
          startMs: 2000,
          endMs: 5000,
          isPassage: true,
          playCount: null,
          gapMs: 2000,
        ),
      );
      await until(() => h.pass >= 2);
      await h.setSleepTimer(null, afterPass: true);
      final last = h.pass;
      await until(() => h.completed);
      expect(h.pass, last);
      expect(h.playing, false);
      expect(h.lastError, isNull);
      debugPrint(
        'NATIVE_STAGE4 continuous_gap_sleep_after_pass PASS pass=$last',
      );
      await h.loadAndStart(
        SessionSpec(
          assetId: samples.first.id,
          durationMs: duration,
          startMs: 2000,
          endMs: 5000,
          isPassage: true,
          playCount: 10,
        ),
      );
      await h.setSleepTimer(const Duration(seconds: 1));
      await until(() => h.completed);
      expect(h.pass, 1);
      expect(h.playing, false);
      expect(h.lastError, isNull);
      debugPrint('NATIVE_STAGE4 accelerated_deadline_sleep PASS');
      final checkpoint = await store.readCheckpoint();
      expect(checkpoint!['spec']['gapMs'], 0);
    } finally {
      await h.stop();
      await h.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
