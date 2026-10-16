import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:al_murajaah/app/product_dependencies.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/database/foundation_repository.dart';
import 'package:al_murajaah/core/theme/app_theme.dart';
import 'package:al_murajaah/features/backup/metadata_backup.dart';
import 'package:al_murajaah/features/catalog/catalog.dart';
import 'package:al_murajaah/features/catalog/catalog_repository.dart';
import 'package:al_murajaah/features/downloads/audio_files.dart';
import 'package:al_murajaah/features/downloads/download_queue.dart';
import 'package:al_murajaah/features/product/product_controller.dart';
import 'package:al_murajaah/features/support/confirmation_overlay.dart';
import 'package:al_murajaah/features/support/diagnostics_gate.dart';
import 'package:al_murajaah/features/support/developer_screen.dart';
import 'package:al_murajaah/features/support/feedback_client.dart';
import 'package:al_murajaah/features/support/feedback_screen.dart';
import 'package:al_murajaah/features/support/support_content.dart';
import 'package:al_murajaah/features/support/story_repository.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'download_queue_test.dart' show FakeTransfers;
import 'stage5_v19_playback_test.dart' show V19Player;
import 'stage5_v21_support_test.dart' show MemorySupportStore, FakeFeedback;
import 'stage4_offline_recovery_test.dart' show until;
import 'app_theme_test.dart' show contrast;

Future<AppDatabase> originDatabase() async {
  final db = AppDatabase(NativeDatabase.memory());
  await FoundationRepository(db).readTheme();
  await CatalogRepository(db).install(
    Catalog.parse(await rootBundle.loadString('assets/catalog/zarami.json')),
  );
  await StoryRepository(db).install();
  return db;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  test('approved story is verbatim, with Arabic and final prayer intact', () {
    expect(
      sha256.convert(utf8.encode(originStory)).toString(),
      '761ead94402a149eae88988086f8f3e1fa933b7e3fdd4739dd41e34df03b58a0',
    );
  });
  for (final brightness in Brightness.values) {
    test('warm text/container contrast $brightness', () {
      final colors = AppTheme.forBrightness(brightness).colorScheme;
      expect(
        contrast(colors.onSecondaryContainer, colors.secondaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(colors.secondary, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
    });
  }
  test('origin stars/passages round trip once with independent canonical stars; v1 still imports', () async {
    final source = await originDatabase(), target = await originDatabase();
    try {
      final repo = FoundationRepository(source);
      await repo.setFavorite('surah', '22', true);
      await repo.setFavorite('recording', 'brother-001', true);
      await expectLater(
        repo.setFavorite('recording', 'zarami-hafs-022-v1', true),
        throwsA(isA<Exception>()),
      );
      final root = await Directory.systemTemp.createTemp('origin-controller');
      final catalog = Catalog.parse(
        await rootBundle.loadString('assets/catalog/zarami.json'),
      );
      final assets = {
        for (final r in catalog.recordings) r.assetId: r.audioAsset,
        for (final r in storyRecordings) r.assetId: r.asset,
      };
      final queue = DownloadQueue(
        source,
        AudioFiles(root),
        FakeTransfers(),
        assets,
      );
      final handler = PrototypeHandler(
        PrototypeStore(root),
        player: V19Player(),
        assetResolver: (id) => assets[id]!,
        localResolver: (_) async => null,
      );
      final controller = ProductController(
        handler,
        ProductDependencies(catalog, assets, queue),
      );
      try {
        final full = storyRecordings.first.session;
        final passage = SessionSpec(
          assetId: full.assetId,
          durationMs: full.durationMs,
          startMs: 2000,
          endMs: 6000,
          isPassage: true,
          playCount: 3,
          gapMs: 2000,
          speed: 1.5,
        );
        await controller.select(storyRecordings.first);
        await controller.saveDraft(passage, 'Origin revision', create: true);
        await repo.setFavorite('passage', controller.savedId!, true);
        await controller.refreshSaved();
        expect(controller.selected, storyRecordings.first);
        expect(controller.saved.single.recordingName, contains('Nasir'));
        expect(controller.saved.single.spec.assetId, 'brother-001');
        expect(controller.favorites, {'22'});
        expect(controller.recordingFavorites, {'brother-001'});
        final backup = MetadataBackup(target);
        final text = await MetadataBackup(source).export();
        expect(jsonDecode(text)['version'], 4);
        await backup.import(await backup.preview(text));
        await backup.import(await backup.preview(text));
        expect(await target.select(target.savedPassages).get(), hasLength(1));
        expect(await target.select(target.favorites).get(), hasLength(3));
        final old = jsonDecode(text) as Map<String, dynamic>;
        old['version'] = 1;
        old.remove('best_listening_streak');
        (old['settings'] as Map).remove('alternate_home_text');
        (old['settings'] as Map).remove('home_text_language');
        (old['stars'] as List).removeWhere((r) => r['type'] == 'recording');
        await backup.import(await backup.preview(jsonEncode(old)));
        expect(await target.select(target.favorites).get(), hasLength(3));
        await FoundationRepository(target).verifyIntegrity();
      } finally {
        controller.dispose();
        await handler.dispose();
        queue.dispose();
        await root.delete(recursive: true);
      }
    } finally {
      await source.close();
      await target.close();
    }
  });
  test('origin viewed/active identity preserves browsing, passage metadata and finite completion', () async {
    final db = await originDatabase();
    final root = await Directory.systemTemp.createTemp('origin-shared');
    final catalog = Catalog.parse(
      await rootBundle.loadString('assets/catalog/zarami.json'),
    );
    final assets = {
      for (final r in catalog.recordings) r.assetId: r.audioAsset,
      for (final r in storyRecordings) r.assetId: r.asset,
    };
    final queue = DownloadQueue(db, AudioFiles(root), FakeTransfers(), assets);
    final player = V19Player();
    final handler = PrototypeHandler(
      PrototypeStore(root),
      player: player,
      assetResolver: (id) => assets[id]!,
      localResolver: (_) async => null,
    );
    final c = ProductController(
      handler,
      ProductDependencies(catalog, assets, queue),
    );
    try {
      await handler.loadAndStart(storyRecordings[1].session.withCount(3));
      await c.select(storyRecordings[0]);
      expect(handler.spec!.assetId, 'brother-002');
      expect(handler.playing, true);
      expect(c.viewedIsActive, false);
      await c.select(storyRecordings[1]);
      expect(c.viewedIsActive, true);
      expect(c.displayedSpec!.playCount, 3);
      await c.changeCount(1);
      expect(handler.spec!.continuesToNext, false);
      player.finish(twice: true);
      await until(() => handler.completed);
      expect(handler.spec!.assetId, 'brother-002');
      expect(player.playing, false);
      c.showActive();
      expect(c.activeRecording, storyRecordings[1]);
      expect(handler.mediaItem.value!.artist, 'Nasir');
    } finally {
      c.dispose();
      await handler.dispose();
      queue.dispose();
      await db.close();
      await root.delete(recursive: true);
    }
  });
  testWidgets(
    'PIN rejects, unlocks only current visit and relocks on covered route/background',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [diagnosticsRouteObserver],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DiagnosticsGate(
                      builder: (context) => Scaffold(
                        body: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const Scaffold(body: Text('Covered')),
                            ),
                          ),
                          child: const Text('Unlocked diagnostics'),
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('Visit'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Visit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1111');
      await tester.tap(find.text('Open'));
      await tester.pump();
      expect(find.text('Incorrect PIN'), findsOneWidget);
      expect(find.text('Unlocked diagnostics'), findsNothing);
      await tester.enterText(find.byType(TextField), '4444');
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unlocked diagnostics'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), '4444');
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Visit'), findsOneWidget);
    },
  );
  testWidgets(
    'remembered discovery never celebrates again; static celebration dismisses immediately',
    (tester) async {
      final store = MemorySupportStore()..data['originDiscovered'] = true;
      await tester.pumpWidget(MaterialApp(home: DeveloperScreen(store: store)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Where it began'));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmationOverlay), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showConfirmation(
                    context,
                    message: 'Masha Allah, you found it!',
                    discovery: true,
                  ),
                  child: const Text('Celebrate'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Celebrate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap to dismiss'));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmationOverlay), findsNothing);
    },
  );
  testWidgets(
    'confirmation only follows a confirmed submission, cancels with route and never stacks',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.almurajaah/support'),
            (call) async => <String, String>{},
          );
      final client = FakeFeedback(
        Future.value(const FeedbackResult(FeedbackStatus.pending)),
      );
      final store = MemorySupportStore();
      await tester.pumpWidget(
        MaterialApp(
          home: FeedbackScreen(client: client, store: store),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Keep draft on unknown outcome',
      );
      await tester.ensureVisible(find.text('Send'));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmationOverlay), findsNothing);
      expect(
        (store.data['feedbackDraft'] as Map)['message'],
        'Keep draft on unknown outcome',
      );
      client.result = Future.value(
        const FeedbackResult(FeedbackStatus.confirmed, 8),
      );
      await tester.tap(find.text('Check submission'));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmationOverlay), findsOneWidget);
      expect(find.text('Thank you for your feedback.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect((store.data['feedbackDraft'] as Map)['message'], '');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.byType(ConfirmationOverlay), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    },
  );
}
