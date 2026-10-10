import 'dart:async';
import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> until(bool Function() condition, {int seconds = 35}) async {
  final clock = Stopwatch()..start();
  while (!condition()) {
    if (clock.elapsed.inSeconds >= seconds) {
      throw TimeoutException('Count condition exceeded $seconds seconds');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native live total changes preserve current source/pass/intent and finite-stop',
    (tester) async {
      final base = await PrototypeStore.open();
      final original = await base.verifiedFile(samples.first);
      expect(
        original,
        isNotNull,
        reason: 'Verified retained fixture required; no download or audio copy',
      );
      final store = PrototypeStore(
        Directory(
          '${base.root.path}/stage4-live-count-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      await store.root.create(recursive: true);
      final h = await AudioService.init<PrototypeHandler>(
        builder: () =>
            PrototypeHandler(store, localResolver: (_) async => original),
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
            body: Center(child: Text('Bounded live count checks')),
          ),
        ),
      );
      await tester.pump();
      try {
        final duration = await h.inspect(samples.first);
        SessionSpec clip({int? count = 5, int gap = 0, int end = 5000}) =>
            SessionSpec(
              assetId: samples.first.id,
              durationMs: duration,
              startMs: 2000,
              endMs: end,
              isPassage: true,
              playCount: count,
              gapMs: gap,
              passageId: 'native-proof',
              passageTitle: 'Count proof',
            );
        int starts() =>
            h.events.value.where((e) => e.contains(' start ')).length;
        await h.start(clip());
        await until(() => h.pass == 3 && h.position.inMilliseconds >= 400);
        final position = h.position.inMilliseconds,
            loads = starts(),
            source = h.diagnostics['sourceUri'];
        await h.updateCount(33);
        expect(h.pass, 3);
        expect(h.spec!.playCount, 33);
        expect(h.playing, true);
        expect(
          h.position.inMilliseconds,
          inInclusiveRange(position - 100, position + 500),
        );
        expect(h.diagnostics['sourceUri'], source);
        expect(starts(), loads);
        await h.updateCount(4);
        await until(() => h.completed);
        expect(h.pass, 4);
        expect(h.playing, false);
        expect(h.lastError, isNull);
        debugPrint(
          'NATIVE_LIVE_COUNT growth_3of5_to33_then_finite4 PASS source starts unchanged',
        );

        await h.start(clip(gap: 2000));
        await until(() => h.pass == 2 && h.inGap);
        await h.pause();
        final gapLoads = starts();
        await h.updateCount(33);
        expect(h.pass, 2);
        expect(h.inGap, true);
        expect(h.playing, false);
        expect(starts(), gapLoads);
        await h.updateCount(3);
        await h.play();
        await until(() => h.completed);
        expect(h.pass, 3);
        expect(h.inGap, false);
        expect(h.lastError, isNull);
        debugPrint(
          'NATIVE_LIVE_COUNT paused_gap_growth_then_finite3 PASS no final gap',
        );

        await h.start(clip(count: null, end: 3000));
        await until(() => h.pass == 8 && h.position.inMilliseconds >= 150);
        final continuousLoads = starts();
        await h.updateCount(25);
        expect(h.pass, 8);
        expect(h.playing, true);
        expect(starts(), continuousLoads);
        await until(() => h.completed);
        expect(h.pass, 25);
        expect(h.playing, false);
        expect(h.lastError, isNull);
        debugPrint(
          'NATIVE_LIVE_COUNT continuous8_to_total25 PASS actual finite25 completion',
        );

        await h.start(clip());
        await until(() => h.pass == 2 && h.position.inMilliseconds >= 300);
        await h.pause();
        final titleLoads = starts(), titlePosition = h.position;
        await h.applySavedPassage(
          h.spec!.withPassage('native-proof', 'Renamed proof'),
        );
        expect(h.position, titlePosition);
        expect(h.pass, 2);
        expect(h.playing, false);
        expect(starts(), titleLoads);
        await h.applySavedPassage(
          SessionSpec(
            assetId: samples.first.id,
            durationMs: duration,
            startMs: 4000,
            endMs: 6000,
            isPassage: true,
            playCount: 3,
            passageId: 'native-proof',
            passageTitle: 'Revised proof',
          ),
        );
        expect(h.pass, 2);
        expect(h.position.inMilliseconds, lessThanOrEqualTo(100));
        expect(h.playing, false);
        await h.play();
        await until(() => h.position.inMilliseconds >= 300);
        final reachedLoads = starts();
        await h.updateCount(1);
        expect(h.playing, true);
        expect(starts(), reachedLoads);
        await until(() => h.completed);
        expect(h.pass, 2);
        expect(h.lastError, isNull);
        debugPrint(
          'NATIVE_LIVE_COUNT title_edit_boundary_apply_reached_total PASS paused preserved/current play finished',
        );
      } finally {
        await h.stop();
      }
    },
  );
}
