import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/features/catalog/catalog.dart';
import 'package:al_murajaah/features/catalog/catalog_repository.dart';
import 'package:al_murajaah/features/product/passage_library.dart';

Future<void> until(bool Function() ready, {int seconds = 35}) async {
  final clock = Stopwatch()..start();
  while (!ready()) {
    if (clock.elapsed.inSeconds >= seconds) {
      throw TimeoutException('Native options condition exceeded $seconds s');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native rates, gap duration, timer Off, preview rollback and durable saved rate',
    (tester) async {
      final base = await PrototypeStore.open();
      final root = Directory(
        '${base.root.path}/stage4-options-proof-${DateTime.now().microsecondsSinceEpoch}',
      );
      await root.create(recursive: true);
      final store = PrototypeStore(root);
      final verified = <String, File>{};
      for (final asset in samples.take(2)) {
        final file = await base.verifiedFile(asset);
        expect(
          file,
          isNotNull,
          reason: 'Retained verified audio required; no download or copy.',
        );
        verified[asset.id] = file!;
      }
      final h = await AudioService.init<PrototypeHandler>(
        builder: () => PrototypeHandler(
          store,
          localResolver: (asset) async => verified[asset.id],
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
            body: Center(child: Text('Stage 4 bounded options checks')),
          ),
        ),
      );
      await tester.pump();
      AppDatabase? db;
      try {
        final duration = await h.inspect(samples.first);
        SessionSpec clip({double speed = 1, int gap = 0, int count = 1}) =>
            SessionSpec(
              assetId: samples.first.id,
              durationMs: duration,
              startMs: 2000,
              endMs: 3500,
              isPassage: true,
              playCount: count,
              speed: speed,
              gapMs: gap,
            );
        for (final speed in [.75, .9, 1.25]) {
          await h.loadAndStart(clip(speed: speed));
          await until(() => h.position.inMilliseconds >= 500);
          expect(h.diagnostics['speed'], speed);
          expect(h.diagnostics['pitch'], 1);
          await until(() => h.completed);
          expect(h.pass, 1);
          expect(h.playing, false);
          expect(h.lastError, isNull);
          debugPrint(
            'NATIVE_OPTIONS rate_$speed PASS state only, pitch parameter=1',
          );
        }
        for (final gap in [5000, 10000]) {
          await h.loadAndStart(clip(speed: 1.25, gap: gap, count: 2));
          await until(() => h.inGap);
          expect(h.pass, 1);
          final clock = Stopwatch()..start();
          await until(() => !h.inGap);
          final measured = clock.elapsedMilliseconds;
          expect(measured, inInclusiveRange(gap - 500, gap + 1500));
          expect(h.pass, 2);
          await until(() => h.completed);
          expect(h.inGap, false);
          expect(h.playing, false);
          expect(h.lastError, isNull);
          debugPrint(
            'NATIVE_OPTIONS gap_${gap}_at_1.25 PASS observedWallMs=$measured, 100ms sampling',
          );
        }
        await h.loadAndStart(clip(speed: .9, gap: 2000, count: 3));
        await until(() => h.inGap);
        await h.pause();
        final pass = h.pass;
        await h.setSpeed(1.25);
        expect(h.inGap, true);
        expect(h.pass, pass);
        expect(h.playing, false);
        await h.play();
        await until(() => h.completed);
        expect(h.pass, 3);
        expect(h.lastError, isNull);
        debugPrint(
          'NATIVE_OPTIONS live_rate_in_paused_gap PASS finite3 no final gap',
        );

        await h.loadAndStart(clip(speed: .75, count: 3));
        await h.setSleepTimer(null, afterPass: true);
        await h.setSleepTimer(null);
        expect(h.sleepLabel, 'Off');
        await until(() => h.completed);
        expect(h.pass, 3);
        expect(h.lastError, isNull);
        debugPrint(
          'NATIVE_OPTIONS Off_after_arming PASS restores remaining finite passes',
        );

        await h.loadAndStart(clip(count: 3));
        await h.setSleepTimer(
          const Duration(milliseconds: 500),
          finishCurrentPass: false,
        );
        await until(() => !h.playing);
        expect(h.completed, false);
        expect(h.pass, 1);
        expect(h.sleepLabel, 'Off');
        debugPrint(
          'NATIVE_OPTIONS accelerated_immediate_sleep PASS, not a 15/30/60-minute trial',
        );

        final catalog = Catalog.parse(
          await rootBundle.loadString('assets/catalog/zarami.json'),
        );
        final dbFile = File('${root.path}/saved-proof.sqlite');
        db = AppDatabase.file(dbFile);
        await CatalogRepository(db).install(catalog);
        var library = PassageLibrary(db);
        final tawbah = catalog.chapter(9);
        final savedSpec = SessionSpec(
          assetId: tawbah.assetId,
          durationMs: tawbah.durationMs!,
          startMs: 2000,
          endMs: 5000,
          isPassage: true,
          playCount: 3,
          speed: .9,
        );
        final id = await library.save(
          'Native rate proof',
          savedSpec,
          note: 'Isolated proof; owner saves untouched',
        );
        await library.save(
          'Native rate proof',
          savedSpec,
          id: id,
          note: 'Isolated proof; owner saves untouched',
        );
        await db.close();
        db = AppDatabase.file(dbFile);
        library = PassageLibrary(db);
        final rows = await library.read();
        expect(rows.length, 1);
        expect(rows.single.id, id);
        expect(rows.single.spec.speed, .9);
        await h.loadAndStart(rows.single.spec);
        await until(() => h.position.inMilliseconds >= 600);
        await h.pause();
        final originalPosition = h.position.inMilliseconds;
        final originalCheckpoint = await File('${root.path}/checkpoint.json')
            .readAsBytes();
        final preview = h.beginPreview();
        await preview.preview(clip(speed: 1.25));
        expect(
          await File('${root.path}/checkpoint.json').readAsBytes(),
          originalCheckpoint,
        );
        await preview.restore();
        expect(h.spec!.assetId, tawbah.assetId);
        expect(h.spec!.speed, .9);
        expect(h.spec!.passageId, id);
        expect(h.mediaItem.value!.album, 'Native rate proof');
        expect(h.pass, 1);
        expect(h.playing, false);
        expect(
          (h.position.inMilliseconds - originalPosition).abs(),
          lessThanOrEqualTo(100),
        );
        expect(h.lastError, isNull);
        await h.play();
        await until(() => h.completed);
        expect(h.pass, 3);
        debugPrint(
          'NATIVE_OPTIONS saved_rate_reopen_preview_rollback PASS, actual native finite3 stop',
        );

        await h.loadAndStart(
          SessionSpec(assetId: samples.first.id, durationMs: duration),
        );
        expect(h.spec!.isPassage, false);
        expect(h.spec!.speed, 1);
        expect(h.spec!.gapMs, 0);
        expect(h.spec!.playCount, 1);
        expect(h.spec!.passageId, isNull);
        expect(h.diagnostics['pitch'], 1);
        await h.pause();
        expect(
          await File('${base.root.path}/checkpoint.json').readAsString(),
          isNotEmpty,
        );
        debugPrint('NATIVE_OPTIONS explicit_full_defaults PASS');
      } finally {
        await db?.close();
        await h.stop();
        await h.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
