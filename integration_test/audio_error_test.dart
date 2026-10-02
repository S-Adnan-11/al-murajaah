import 'dart:async';
import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';

// One real native player. Inject a command-layer exception without changing its
// speed or interrupting the recording bytes. This is an error-handling test,
// not a reproduction of the user's silence or audible quality finding.
class CommandFailurePlayer extends AudioPlayer {
  CommandFailurePlayer() : super(handleInterruptions: false);
  bool failNextSpeed = false;
  @override
  Future<void> setSpeed(double speed) async {
    if (failNextSpeed) {
      failNextSpeed = false;
      throw StateError(
        'Injected command failure while native audio is playing',
      );
    }
    await super.setSpeed(speed);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'known command error freezes progress and pauses native transport',
    (tester) async {
      final base = await PrototypeStore.open();
      final root = Directory(
        '${base.root.path}/error-test-${DateTime.now().microsecondsSinceEpoch}',
      );
      await root.create(recursive: true);
      final player = CommandFailurePlayer();
      final h = PrototypeHandler(PrototypeStore(root), player: player);
      await h.initialize();
      runApp(DiagnosticApp(handler: h));
      await tester.pump();
      try {
        final duration = await h
            .inspect(samples.first)
            .timeout(const Duration(seconds: 90));
        await h.start(
          SessionSpec(assetId: samples.first.id, durationMs: duration),
        );
        final deadline = DateTime.now().add(const Duration(seconds: 60));
        while (h.position.inMilliseconds < 1500 ||
            player.processingState != ProcessingState.ready) {
          if (DateTime.now().isAfter(deadline)) {
            throw TimeoutException('Native readiness');
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        expect(player.playing, true);
        expect(player.speed, 1.0);
        final pass = h.pass;
        player.failNextSpeed = true;
        await expectLater(h.setSpeed(1), throwsStateError);
        final pauseDeadline = DateTime.now().add(const Duration(seconds: 10));
        while (player.playing || h.lastError == null) {
          if (DateTime.now().isAfter(pauseDeadline)) {
            throw TimeoutException('Error did not pause native transport');
          }
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        expect(h.playing, false);
        final position = h.position;
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(h.position, position);
        expect(h.pass, pass);
        expect(player.speed, 1.0);
        // A notification/UI Play must not restart native audio underneath a
        // frozen error presentation. Reload is the explicit recovery boundary.
        await expectLater(h.play(), throwsStateError);
        expect(player.playing, false);
        expect(h.position, position);
        debugPrint('ERROR_GUARD_RESULT PASS ${h.diagnosticExport}');
      } finally {
        await h.stop();
        await tester.pumpWidget(const SizedBox());
        await h.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
