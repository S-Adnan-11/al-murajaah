import 'dart:async';
import 'dart:io';

import 'package:al_murajaah/app/foundation_app.dart';
import 'package:al_murajaah/app/product_dependencies.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/core/database/app_database.dart' hide SavedPassage;
import 'package:al_murajaah/core/database/foundation_repository.dart';
import 'package:al_murajaah/core/theme/appearance_controller.dart';
import 'package:al_murajaah/core/theme/product_components.dart';
import 'package:al_murajaah/features/catalog/catalog.dart';
import 'package:al_murajaah/features/catalog/catalog_repository.dart';
import 'package:al_murajaah/features/downloads/audio_files.dart';
import 'package:al_murajaah/features/downloads/download_queue.dart';
import 'package:al_murajaah/features/product/product_shell.dart';
import 'package:al_murajaah/features/product/passage_library.dart';
import 'package:al_murajaah/features/product/product_controller.dart';
import 'package:al_murajaah/features/product/saved_sheet.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diagnostic_focus_test.dart' show FocusTestHandler;
import 'download_queue_test.dart' show FakeTransfers;

class MemoryPassages extends PrototypeStore {
  MemoryPassages(super.root);
  @override
  Future<List<SavedPassage>> passages() async => [];
}

class ProductTestHandler extends FocusTestHandler {
  ProductTestHandler(super.store, this.catalog);
  final Catalog catalog;
  bool intent = false, ended = false;
  SessionSpec? pendingDisplay;
  @override
  SessionSpec? get displaySession => pendingDisplay ?? spec;
  @override
  bool get loading => pendingDisplay != null;
  @override
  bool get playRequested => pendingDisplay != null || playing;
  int previewRestores = 0, previewCommits = 0;
  final appliedPassages = <SessionSpec>[];
  @override
  Future<void> applySavedPassage(SessionSpec revised) async {
    if (spec?.sameItem(revised) != true) return;
    appliedPassages.add(revised);
    final sourcePosition = spec!.relativeToSource(elapsed.inMilliseconds);
    elapsed = Duration(
      milliseconds:
          sourcePosition >= revised.startMs && sourcePosition < revised.endMs
          ? sourcePosition - revised.startMs
          : 0,
    );
    spec = revised;
    revision.value++;
  }

  @override
  PlaybackPreview beginPreview() => ProductTestPreview(this);
  @override
  bool get inGap => false;
  @override
  String get sleepLabel => 'Off';
  @override
  bool get sleepFinishesPass => true;
  @override
  Future<void> loadAndStart(SessionSpec request) async {
    await inspect(
      catalog.recordings
          .singleWhere((r) => r.assetId == request.assetId)
          .audioAsset,
    );
    await start(request);
  }

  int index = 0;
  Duration elapsed = Duration.zero;
  final positions = StreamController<Duration>.broadcast();
  final seeks = <int>[];
  @override
  bool get playing => intent && !ended;
  @override
  bool get completed => ended;
  @override
  int get pass => index + 1;
  @override
  Duration get position => elapsed;
  @override
  Stream<Duration> get positionStream => positions.stream;
  @override
  Map<String, Object?> get diagnostics => {
    'processingState': ended ? 'completed' : 'ready',
  };
  @override
  Future<int> inspect(SampleAsset asset) async {
    final recording = catalog.recordings.singleWhere(
      (r) => r.assetId == asset.id,
    );
    durations[asset.id] = recording.durationMs!;
    spec = null;
    return recording.durationMs!;
  }

  @override
  Future<void> start(
    SessionSpec request, {
    bool autoPlay = true,
    int initialIndex = 0,
    Duration initialPosition = Duration.zero,
  }) async {
    starts++;
    spec = request;
    intent = autoPlay;
    index = initialIndex;
    elapsed = initialPosition;
    ended = false;
    revision.value++;
  }

  @override
  Future<void> play() async {
    intent = true;
    ended = false;
    revision.value++;
  }

  @override
  Future<void> pause() async {
    pendingDisplay = null;
    intent = false;
    revision.value++;
  }

  @override
  Future<void> stop() async {
    stops++;
    intent = false;
    revision.value++;
  }

  @override
  Future<void> seek(Duration value) async {
    seeks.add(value.inMilliseconds);
    elapsed = Duration(
      milliseconds: value.inMilliseconds.clamp(0, spec!.lengthMs),
    );
    positions.add(elapsed);
    revision.value++;
  }
}

class ProductTestPreview implements PlaybackPreview {
  ProductTestPreview(this.testHandler)
    : before = testHandler.spec,
      beforePosition = testHandler.position,
      beforeIndex = testHandler.index,
      wasPlaying = testHandler.playing;
  final ProductTestHandler testHandler;
  final SessionSpec? before;
  final Duration beforePosition;
  final int beforeIndex;
  int? ownedRevision;
  @override
  bool closed = false;
  bool? returnPlaying;
  @override
  bool get ownsPlayback =>
      !closed && ownedRevision == testHandler.revision.value;
  @override
  final bool wasPlaying;
  @override
  Future<void> preview(SessionSpec request, {bool autoPlay = true}) async {
    testHandler.spec = request;
    testHandler.intent = autoPlay;
    testHandler.elapsed = Duration.zero;
    testHandler.revision.value++;
    ownedRevision = testHandler.revision.value;
  }

  @override
  Future<void> seek(Duration value) async {
    await testHandler.seek(value);
    ownedRevision = testHandler.revision.value;
  }

  @override
  Future<void> setPlaying(bool value) async {
    returnPlaying = value;
    if (value) {
      await testHandler.play();
    } else {
      await testHandler.pause();
    }
    ownedRevision = testHandler.revision.value;
  }

  @override
  Future<void> restore() async {
    testHandler.previewRestores++;
    if (!ownsPlayback) return;
    closed = true;
    testHandler.spec = before;
    testHandler.elapsed = beforePosition;
    testHandler.index = beforeIndex;
    testHandler.intent = returnPlaying ?? wasPlaying;
    testHandler.revision.value++;
  }

  @override
  void commit() {
    closed = true;
    testHandler.previewCommits++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalog catalog;
  setUpAll(() async {
    catalog = Catalog.parse(
      await rootBundle.loadString('assets/catalog/zarami.json'),
    );
  });
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.pumpAndSettle();
    // Lazy children can change scroll extent when first laid out at 200% text.
    // Recompute visibility from the settled layout before tapping.
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    expect(finder.hitTestable(), findsOneWidget);
  }

  Future<(FoundationDependencies, ProductTestHandler, Directory)>
  fixture() async {
    final root = await Directory.systemTemp.createTemp('product-ui');
    final db = AppDatabase(NativeDatabase.memory());
    await FoundationRepository(db).readTheme();
    await CatalogRepository(db).install(catalog);
    final assets = {
      for (final r in catalog.recordings) r.assetId: r.audioAsset,
    };
    final queue = DownloadQueue(
      db,
      AudioFiles(root),
      FakeTransfers(),
      assets,
      pollInterval: const Duration(days: 1),
    );
    final handler = ProductTestHandler(MemoryPassages(root), catalog);
    final product = ProductDependencies(catalog, assets, queue);
    return (
      FoundationDependencies(
        db,
        FoundationRepository(db),
        AppearanceController(
          persist: (mode) => FoundationRepository(db).saveTheme(mode.name),
        ),
        product: product,
      ),
      handler,
      root,
    );
  }

  Future<void> clean(
    WidgetTester tester,
    FoundationDependencies deps,
    ProductTestHandler h,
    Directory root,
  ) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpWidget(const SizedBox());
    // Let cancelled SQL watch queries drain in the widget test's fake clock
    // before closing the real connection outside that clock.
    await tester.pump(const Duration(milliseconds: 100));
    h.events.dispose();
    h.revision.dispose();
    await h.positions.close();
    await tester.runAsync(deps.close);
    await tester.runAsync(() => root.delete(recursive: true));
  }

  testWidgets(
    'automatic preparation keeps the next identity and a cancellable Pause control',
    (tester) async {
      final (deps, h, root) = (await tester.runAsync(fixture))!;
      final recordings = deps.product!.catalog.recordings;
      h.spec = SessionSpec(
        assetId: recordings.first.assetId,
        durationMs: recordings.first.durationMs!,
      );
      h.intent = true;
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue listening'));
        await tester.pumpAndSettle();
        h.pendingDisplay = SessionSpec(
          assetId: recordings[8].assetId,
          durationMs: recordings[8].durationMs!,
        );
        h.spec = null;
        h.revision.value++;
        await tester.pump();
        expect(find.text(recordings[8].name), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        final pause = find.byIcon(Icons.pause_rounded);
        expect(pause, findsOneWidget);
        await tester.tap(
          find.ancestor(of: pause, matching: find.byType(FilledButton)),
        );
        await tester.pumpAndSettle();
        expect(h.playRequested, false);
        expect(h.displaySession, isNull);
        expect(h.starts, 0);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );

  testWidgets(
    'Back dismisses keyboard and nested routes, then roots return Home and Home departs',
    (tester) async {
      final (deps, h, root) = (await tester.runAsync(fixture))!;
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        for (final label in ['Surahs', 'Saved', 'Activity']) {
          await tester.tap(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text(label),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Settings'));
          await tester.pumpAndSettle();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex,
            ['Home', 'Surahs', 'Saved', 'Activity'].indexOf(label),
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex,
            0,
          );
        }
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Surahs'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextField, 'Search surahs'));
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        await tester.pump();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          1,
        );
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          false,
        );
        tester.view.resetViewInsets();
        await tester.pump();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          0,
        );
        calls.clear();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          calls.where((c) => c.method == 'SystemNavigator.pop'),
          hasLength(1),
        );
        expect(h.stops, 0);
      } finally {
        tester.view.resetViewInsets();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
        await clean(tester, deps, h, root);
      }
    },
  );

  testWidgets(
    'automatic identity follows the active player but never an unrelated viewed item',
    (tester) async {
      final (deps, h, root) = (await tester.runAsync(fixture))!;
      try {
        h.spec = SessionSpec(
          assetId: catalog.recordings.first.assetId,
          durationMs: catalog.recordings.first.durationMs!,
        );
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        final c =
            (tester.state(find.byType(ProductShell)) as dynamic).controller
                as ProductController;
        h.revision.value++;
        final next = catalog.recordings[1];
        h.spec = SessionSpec(
          assetId: next.assetId,
          durationMs: next.durationMs!,
        );
        h.revision.value++;
        await tester.pumpAndSettle();
        expect(c.displayedSpec!.assetId, next.assetId);
        expect(c.selected!.assetId, next.assetId);
        await c.select(catalog.recordings[40]);
        final viewed = c.viewedSpec;
        h.spec = SessionSpec(
          assetId: catalog.recordings[2].assetId,
          durationMs: catalog.recordings[2].durationMs!,
        );
        h.revision.value++;
        await tester.pumpAndSettle();
        expect(c.viewedSpec, same(viewed));
        expect(h.starts, 0);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );

  testWidgets(
    'Activity updates stay scoped and opening it preserves active playback',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      final original = SessionSpec(
        assetId: catalog.chapter(1).assetId,
        durationMs: catalog.chapter(1).durationMs!,
      );
      h.spec = original;
      h.intent = true;
      h.elapsed = const Duration(milliseconds: 3333);
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Activity'));
        await tester.pumpAndSettle();
        expect(find.text('Today’s listening'), findsOneWidget);
        await tester.runAsync(() async {
          await deps.database.customStatement(
            'INSERT INTO listening_sessions (id,asset_id,started_utc_ms,speed) VALUES (?,?,?,1)',
            [
              'ui-activity',
              original.assetId,
              DateTime.now().toUtc().millisecondsSinceEpoch - 2000,
            ],
          );
          final now = DateTime.now();
          final date =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          await deps.repository.creditMeasuredInterval(
            eventId: 'ui-credit',
            sessionId: 'ui-activity',
            localDate: date,
            timezonePolicy: 'device-local-at-credit',
            wallMs: 1000,
            goalMs: 300000,
            utcMs: now.toUtc().millisecondsSinceEpoch,
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        for (
          var i = 0;
          i < 20 &&
              find
                  .descendant(
                    of: find.byKey(const ValueKey('today-listening-summary')),
                    matching: find.text('<1 min'),
                  )
                  .evaluate()
                  .isEmpty;
          i++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('today-listening-summary')),
            matching: find.text('<1 min'),
          ),
          findsOneWidget,
        );
        expect(h.spec, same(original));
        expect(h.starts, 0);
        expect(h.seeks, isEmpty);
        expect(h.playing, true);
        expect(h.position.inMilliseconds, 3333);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );

  testWidgets(
    'recent cards have 12px gaps and status updates leave lists intact',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      h.spec = SessionSpec(
        assetId: catalog.chapter(1).assetId,
        durationMs: catalog.chapter(1).durationMs!,
      );
      h.intent = true;
      await tester.runAsync(() async {
        for (var i = 0; i < 3; i++) {
          await PassageLibrary(deps.database).save(
            'Revision $i',
            SessionSpec(
              assetId: h.spec!.assetId,
              durationMs: h.spec!.durationMs,
              startMs: 1000,
              endMs: 5000,
              isPassage: true,
            ),
          );
        }
      });
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        final c =
            (tester.state(find.byType(ProductShell)) as dynamic).controller
                as ProductController;
        await tester.runAsync(c.refreshSaved);
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Recent passages'));
        final cards = find.byType(CollectionTile);
        expect(c.saved, hasLength(3));
        expect(cards.evaluate().length, greaterThanOrEqualTo(2));
        final first = tester.getRect(cards.at(0)),
            second = tester.getRect(cards.at(1));
        expect(second.top - first.bottom, 12);
        for (final tabName in ['Home', 'Saved']) {
          await tester.tap(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text(tabName),
            ),
          );
          await tester.pumpAndSettle();
          final list = find.byKey(
            PageStorageKey(tabName == 'Home' ? 'product-home' : 'saved-false'),
          );
          final before = tester.widget(list);
          for (final local in [true, false]) {
            h.usingLocal = local;
            for (var i = 1; i <= 60; i++) {
              h.elapsed = Duration(milliseconds: i * 100);
              h.positions.add(h.elapsed);
              h.revision.value++;
              await tester.pump(const Duration(milliseconds: 100));
              expect(identical(before, tester.widget(list)), isTrue);
            }
          }
          await tester.runAsync(() async {
            await deps.database.customStatement(
              "INSERT OR IGNORE INTO daily_activity (local_date,timezone_policy,played_wall_ms,goal_ms,qualified) VALUES ('2026-10-09','fixture',1000,300000,0)",
            );
            deps.database.markTablesUpdated([deps.database.dailyActivity]);
            await Future<void>.delayed(const Duration(milliseconds: 50));
          });
          await tester.pump();
          expect(identical(before, tester.widget(list)), isTrue);
        }
        expect(h.starts, 0);
        expect(h.playing, isTrue);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'Saved long mixed names at 320px/200% scroll above mini-player in $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 760);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final data = (await tester.runAsync(fixture))!;
        final deps = data.$1, h = data.$2, root = data.$3;
        final original = SessionSpec(
          assetId: catalog.chapter(9).assetId,
          durationMs: catalog.chapter(9).durationMs!,
        );
        h.spec = original;
        h.intent = true;
        const longName =
            'مراجعة سورة الفاتحة · A longer English passage name for quiet daily listening';
        String lastId = '';
        await tester.runAsync(() async {
          for (var i = 0; i < 8; i++) {
            lastId = await PassageLibrary(deps.database).save(
              i == 0 ? longName : 'Revision $i',
              SessionSpec(
                assetId: catalog.chapter(1).assetId,
                durationMs: catalog.chapter(1).durationMs!,
                startMs: 1000,
                endMs: 5000,
                isPassage: true,
              ),
            );
          }
        });
        try {
          await tester.pumpWidget(
            FoundationApp(handler: h, dependencies: deps),
          );
          await tester.pumpAndSettle();
          final c =
              (tester.state(find.byType(ProductShell)) as dynamic).controller
                  as ProductController;
          await tester.runAsync(c.refreshSaved);
          await tester.pumpAndSettle();
          await tester.tap(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text('Saved'),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Saved passages'), findsOneWidget);
          await reveal(tester, find.text(longName));
          final card = find.ancestor(
            of: find.text(longName),
            matching: find.byType(CollectionTile),
          );
          await Scrollable.ensureVisible(tester.element(card), alignment: 1);
          await tester.pumpAndSettle();
          final mini = tester.getRect(
            find.byKey(const ValueKey('mini-player-open')),
          );
          expect(tester.getRect(card).bottom, lessThanOrEqualTo(mini.top));
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text(longName));
          await tester.pumpAndSettle();
          await tester.tap(find.text(longName));
          await tester.pumpAndSettle();
          expect(h.spec, same(original));
          expect(h.starts, 0);
          await tester.tap(find.byTooltip('Close player'));
          await tester.pumpAndSettle();
          final scrollState = tester.state<ScrollableState>(
            find
                .byWidgetPredicate(
                  (widget) =>
                      widget is Scrollable &&
                      widget.axisDirection == AxisDirection.down,
                )
                .first,
          );
          scrollState.position.jumpTo(0);
          await tester.pumpAndSettle();
          await reveal(tester, find.byTooltip('Play Revision 7'));
          await tester.tap(find.byTooltip('Play Revision 7'));
          await tester.pumpAndSettle();
          expect(h.spec!.passageId, lastId);
          expect(h.starts, 1);
          expect(tester.takeException(), isNull);
        } finally {
          await clean(tester, deps, h, root);
        }
      },
    );
  }

  testWidgets(
    'live A/B marking saves an independent record without transport changes',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      final original = SessionSpec(
        assetId: catalog.chapter(1).assetId,
        durationMs: catalog.chapter(1).durationMs!,
        playCount: 5,
      );
      h.spec = original;
      h.intent = true;
      h.index = 2;
      h.elapsed = const Duration(milliseconds: 1234);
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('mini-player-open')));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Set passage'));
        await tester.tap(find.text('Set passage'));
        await tester.pumpAndSettle();
        expect(h.starts, 0);
        expect(h.seeks, isEmpty);
        expect(h.pass, 3);
        expect(h.playing, true);
        await tester.tap(find.text('Set start · A'));
        await tester.pump();
        h.elapsed = const Duration(milliseconds: 5678);
        h.positions.add(h.elapsed);
        await tester.pump();
        await tester.pump();
        await tester.tap(find.text('Set end · B'));
        await tester.pumpAndSettle();
        expect(find.text('A · 0:01.234'), findsOneWidget);
        expect(find.text('B · 0:05.678'), findsOneWidget);
        expect(
          await tester.runAsync(() => PassageLibrary(deps.database).read()),
          isEmpty,
        );
        expect(h.spec, same(original));
        await tester.tap(find.text('Name & save'));
        await tester.pumpAndSettle();
        final name = find.widgetWithText(TextField, 'Passage name');
        expect(tester.widget<TextField>(name).focusNode!.hasFocus, true);
        expect(name.hitTestable(), findsOneWidget);
        await tester.enterText(name, 'Live markings');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pumpAndSettle();
        final saved = (await tester.runAsync(
          () => PassageLibrary(deps.database).read(),
        ))!;
        expect(saved, hasLength(1));
        expect(saved.single.spec.startMs, 1234);
        expect(saved.single.spec.endMs, 5678);
        expect(saved.single.spec.assetId, original.assetId);
        expect(saved.single.title, 'Live markings');
        expect(h.spec, same(original));
        expect(h.position.inMilliseconds, 5678);
        expect(h.pass, 3);
        expect(h.playing, true);
        expect(h.starts, 0);
        expect(h.seeks, isEmpty);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );

  testWidgets(
    'Edit uses full coordinates; outside-range paused preview restores identity and progress on discard',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      final library = PassageLibrary(deps.database);
      final clip = SessionSpec(
        assetId: catalog.chapter(1).assetId,
        durationMs: catalog.chapter(1).durationMs!,
        startMs: 2000,
        endMs: 5000,
        isPassage: true,
        playCount: 5,
      );
      final id = (await tester.runAsync(
        () => library.save('Original selection', clip),
      ))!;
      h.spec = clip.withPassage(id, 'Original selection');
      h.elapsed = const Duration(milliseconds: 1000);
      h.index = 2;
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('mini-player-open')));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Edit passage'));
        await tester.tap(find.text('Edit passage'));
        await tester.pumpAndSettle();
        expect(find.text('Full surah timeline'), findsOneWidget);
        expect(tester.widget<Slider>(find.byType(Slider)).value, 3000);
        expect(find.text('A · 0:02.000'), findsOneWidget);
        expect(find.text('B · 0:05.000'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Save & play'), findsNothing);
        expect(h.starts, 0);
        expect(h.playing, false);
        var slider = tester.widget<Slider>(find.byType(Slider));
        slider.onChangeStart!(3000);
        slider.onChanged!(4000);
        await tester.pump();
        h.positions.add(const Duration(milliseconds: 500));
        await tester.pump();
        expect(tester.widget<Slider>(find.byType(Slider)).value, 4000);
        expect(h.seeks, isEmpty);
        slider.onChangeEnd!(4000);
        slider.onChangeEnd!(4000);
        await tester.pumpAndSettle();
        expect(h.seeks, [
          2000,
        ], reason: 'one source-to-passage mapping on release');
        expect(h.spec!.startMs, 2000);
        expect(h.pass, 3);
        slider = tester.widget<Slider>(find.byType(Slider));
        slider.onChangeStart!(4000);
        slider.onChanged!(10000);
        slider.onChangeEnd!(10000);
        await tester.pumpAndSettle();
        expect(h.spec!.passageTitle, 'Passage selection preview');
        expect(h.spec!.startMs, 10000);
        expect(
          h.playing,
          false,
          reason: 'seeking a paused selection must not start audio',
        );
        expect(tester.widget<Slider>(find.byType(Slider)).value, 10000);
        await tester.tap(find.text('Set end · B'));
        await tester.pumpAndSettle();
        expect((await tester.runAsync(library.read))!.single.spec.endMs, 5000);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Discard edits'));
        await tester.pumpAndSettle();
        expect(h.spec!.passageId, id);
        expect(h.spec!.startMs, 2000);
        expect(h.spec!.endMs, 5000);
        expect(h.pass, 3);
        expect(h.position.inMilliseconds, 2000);
        expect(h.playing, false);
        expect(h.previewRestores, 1);
        await tester.scrollUntilVisible(
          find.byType(Slider),
          -200,
          scrollable: find
              .byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<Slider>(find.byType(Slider)).value,
          2000,
          reason: 'normal player returns to passage-relative time',
        );
        expect((await tester.runAsync(library.read))!.single.spec.endMs, 5000);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );

  testWidgets(
    'Edit Save updates the exact active record and keeps progress; opening and marking remain drafts',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      final library = PassageLibrary(deps.database);
      final clip = SessionSpec(
        assetId: catalog.chapter(1).assetId,
        durationMs: catalog.chapter(1).durationMs!,
        startMs: 2000,
        endMs: 10000,
        isPassage: true,
        playCount: 5,
      );
      final id = (await tester.runAsync(
        () => library.save('Editable selection', clip),
      ))!;
      h.spec = clip.withPassage(id, 'Editable selection');
      h.elapsed = const Duration(milliseconds: 4000);
      h.intent = true;
      h.index = 2;
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('mini-player-open')));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Edit passage'));
        await tester.tap(find.text('Edit passage'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Set start · A'));
        await tester.pumpAndSettle();
        expect(
          (await tester.runAsync(library.read))!.single.spec.startMs,
          2000,
        );
        expect(h.spec!.startMs, 2000);
        expect(h.appliedPassages, isEmpty);
        await reveal(tester, find.widgetWithText(TextField, 'Passage name'));
        await tester.enterText(
          find.widgetWithText(TextField, 'Passage name'),
          'Updated selection',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pumpAndSettle();
        final saved = (await tester.runAsync(library.read))!;
        expect(saved, hasLength(1));
        expect(saved.single.id, id);
        expect(saved.single.spec.startMs, 6000);
        expect(saved.single.spec.endMs, 10000);
        expect(saved.single.title, 'Updated selection');
        expect(h.spec!.passageId, id);
        expect(h.spec!.startMs, 6000);
        expect(h.position.inMilliseconds, 0);
        expect(h.pass, 3);
        expect(h.playing, true);
        expect(h.appliedPassages, hasLength(1));
        expect(h.starts, 0);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );

  testWidgets('transport drag previews locally and commits once on release', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = (await tester.runAsync(fixture))!;
    final deps = data.$1, h = data.$2, root = data.$3;
    h.spec = SessionSpec(
      assetId: catalog.chapter(1).assetId,
      durationMs: catalog.chapter(1).durationMs!,
      startMs: 2000,
      endMs: 5000,
      isPassage: true,
      playCount: 5,
      passageId: 'drag-fixture',
    );
    h.elapsed = const Duration(milliseconds: 500);
    h.intent = true;
    h.index = 2;
    TestGesture? gesture;
    try {
      await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue listening'));
      await tester.pumpAndSettle();
      final slider = find.byType(Slider);
      final box = tester.getRect(slider);
      gesture = await tester.startGesture(
        Offset(box.left + 24 + (box.width - 48) / 6, box.center.dy),
      );
      for (var i = 1; i <= 8; i++) {
        await gesture.moveTo(
          Offset(
            box.left + 24 + (box.width - 48) * (.1667 + .075 * i),
            box.center.dy,
          ),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      debugPrint(
        'DRAG_REPRO beforeReleaseSeeks=${h.seeks.length} values=${h.seeks}',
      );
      expect(
        h.seeks,
        isEmpty,
        reason: 'visual drag preview must not seek or change passes',
      );
      final preview = tester.widget<Slider>(slider).value;
      h.elapsed = const Duration(milliseconds: 800);
      h.positions.add(h.elapsed);
      await tester.pump();
      expect(tester.widget<Slider>(slider).value, preview);
      expect(h.pass, 3);
      expect(h.playing, true);
      await gesture.up();
      gesture = null;
      await tester.pumpAndSettle();
      expect(h.seeks, hasLength(1));
      expect(h.seeks.single, preview.round());
      expect(h.spec!.relativeToSource(h.seeks.single), 2000 + preview.round());
      expect(h.pass, 3);
      expect(h.playing, true);
    } finally {
      await gesture?.cancel();
      await clean(tester, deps, h, root);
    }
  });

  testWidgets(
    'Save & play after preview persists then commits without briefly restoring previous audio',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      h.spec = SessionSpec(
        assetId: catalog.chapter(9).assetId,
        durationMs: catalog.chapter(9).durationMs!,
      );
      h.intent = true;
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue listening'));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Set passage'));
        await tester.tap(find.text('Set passage'));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Fine-tune'));
        await tester.tap(find.text('Fine-tune'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'A · time in full surah'),
          '2',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'B · time in full surah'),
          '5',
        );
        await reveal(tester, find.text('Preview start'));
        await tester.tap(find.text('Preview start'));
        await tester.pumpAndSettle();
        expect(h.spec!.passageTitle, 'Boundary preview');
        await tester.tap(find.text('Name & save'));
        await tester.pumpAndSettle();
        final name = find.widgetWithText(TextField, 'Passage name');
        await tester.ensureVisible(name);
        await tester.enterText(name, 'Preview to saved');
        await tester.tap(find.text('Save & play'));
        await tester.pumpAndSettle();
        for (var i = 0; i < 40 && h.spec?.passageId == null; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pumpAndSettle();
        }
        expect(h.spec!.passageId, isNotNull);
        expect(h.spec!.passageTitle, 'Preview to saved');
        expect(h.spec!.startMs, 2000);
        expect(h.spec!.endMs, 5000);
        expect(h.pass, 1);
        expect(h.playing, true);
        expect(h.previewCommits, 1);
        expect(h.previewRestores, 0);
        expect(h.starts, 1);
        expect(
          await tester.runAsync(() => PassageLibrary(deps.database).read()),
          hasLength(1),
        );
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );
  testWidgets(
    'Saved filters passages only; dedicated Home Starred combines types; Surahs Starred stays surah-only',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      final library = PassageLibrary(deps.database);
      final clip = SessionSpec(
        assetId: catalog.chapter(1).assetId,
        durationMs: catalog.chapter(1).durationMs!,
        startMs: 2000,
        endMs: 5000,
        isPassage: true,
      );
      await tester.runAsync(() async {
        final id = await library.save('Starred revision', clip);
        await library.save('Unstarred revision', clip);
        await deps.repository.setFavorite('passage', id, true);
        await deps.repository.setFavorite('surah', '9', true);
      });
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        final c =
            (tester.state(find.byType(ProductShell)) as dynamic).controller
                as ProductController;
        for (var i = 0; i < 40 && c.saved.length != 2; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pumpAndSettle();
        }
        expect(c.saved, hasLength(2));
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Saved'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilterChip>(
                find.widgetWithText(FilterChip, 'All passages'),
              )
              .selected,
          true,
        );
        expect(
          tester
              .widget<FilterChip>(find.widgetWithText(FilterChip, 'Starred'))
              .selected,
          false,
        );
        Finder inSheet(String text) => find.descendant(
          of: find.byType(SavedSheet),
          matching: find.text(text),
        );
        expect(inSheet('Starred revision'), findsOneWidget);
        expect(inSheet('Unstarred revision'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilterChip, 'Starred'));
        await tester.pumpAndSettle();
        expect(find.text('Surah · Full surah'), findsNothing);
        expect(find.text('At-Tawbah'), findsNothing);
        expect(inSheet('Starred revision'), findsOneWidget);
        expect(find.textContaining('Al-Fatihah\n0:02 – 0:05'), findsOneWidget);
        expect(inSheet('Unstarred revision'), findsNothing);
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Home'),
          ),
        );
        await tester.pumpAndSettle();
        await reveal(tester, find.widgetWithText(TextButton, 'Starred'));
        await tester.tap(find.widgetWithText(TextButton, 'Starred'));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(FilterChip, 'All passages'), findsNothing);
        expect(find.widgetWithText(FilterChip, 'Starred'), findsNothing);
        expect(find.text('Surah · Full surah'), findsOneWidget);
        expect(find.text('At-Tawbah'), findsOneWidget);
        expect(inSheet('Starred revision'), findsOneWidget);
        expect(inSheet('Unstarred revision'), findsNothing);
        await tester.tap(find.byTooltip('Back to Home'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Surahs'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilterChip, 'Starred'));
        await tester.pumpAndSettle();
        expect(find.text('At-Tawbah'), findsOneWidget);
        expect(find.text('Starred revision'), findsNothing);
        expect(find.text('Zarami · Hafs · 1 surahs'), findsOneWidget);
        final selectedStars = Set<String>.of(c.passageFavorites);
        await tester.runAsync(() => c.favorite(catalog.chapter(9)));
        await tester.pumpAndSettle();
        expect(c.favorites, isEmpty);
        expect(c.passageFavorites, selectedStars);
        expect(c.saved, hasLength(2));
        expect(h.starts, 0);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );
  testWidgets(
    'inactive full-surah screen cannot stop/pause or set sleep on a passage of the same recording',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      h.spec = SessionSpec(
        assetId: catalog.chapter(1).assetId,
        durationMs: catalog.chapter(1).durationMs!,
        startMs: 2000,
        endMs: 5000,
        isPassage: true,
        playCount: 33,
      );
      h.intent = true;
      final active = h.spec;
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Surahs'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(CustomScrollView),
            matching: find.text('Al-Fatihah'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Play recording'), findsOneWidget);
        await reveal(tester, find.text('Options · 1.0×'));
        expect(find.text('Stop'), findsNothing);
        expect(find.text('Pause'), findsNothing);
        expect(find.textContaining('Sleep:'), findsNothing);
        await tester.tap(find.text('Options · 1.0×'));
        await tester.pumpAndSettle();
        expect(find.text('15 minutes'), findsNothing);
        expect(find.text('Finish current pass at deadline'), findsNothing);
        await tester.tap(find.text('0.75×'));
        await tester.tap(find.text('Apply speed and gap'));
        await tester.pumpAndSettle();
        expect(h.spec, same(active));
        expect(h.playing, true);
        expect(h.starts, 0);
        expect(h.stops, 0);
        expect(find.text('Options · 0.75×'), findsOneWidget);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );
  testWidgets(
    'passage player stars only passage; full-surah player stars only surah',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      final clip = SessionSpec(
        assetId: catalog.chapter(1).assetId,
        durationMs: catalog.chapter(1).durationMs!,
        startMs: 2000,
        endMs: 5000,
        isPassage: true,
      );
      final id = (await tester.runAsync(
        () => PassageLibrary(deps.database).save('Scoped star', clip),
      ))!;
      h.spec = clip.withPassage(id, 'Scoped star');
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        final c =
            (tester.state(find.byType(ProductShell)) as dynamic).controller
                as ProductController;
        await tester.runAsync(c.refreshSaved);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue listening'));
        await tester.pumpAndSettle();
        expect(find.text('Star surah'), findsNothing);
        expect(find.text('Unstar surah'), findsNothing);
        await reveal(tester, find.text('Star passage'));
        await tester.tap(find.text('Star passage'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();
        expect(c.passageFavorites, contains(id));
        expect(c.favorites, isEmpty);
        await tester.tap(find.byTooltip('Close player'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Surahs'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(CustomScrollView),
            matching: find.text('Al-Fatihah'),
          ),
        );
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Star surah'));
        expect(find.text('Star passage'), findsNothing);
        expect(find.text('Unstar passage'), findsNothing);
        expect(c.passageFavorites, contains(id));
        expect(h.spec!.passageId, id);
        expect(h.starts, 0);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );
  testWidgets(
    'opening active full-surah from Surahs shows live position/count despite native duration padding',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      h.spec = SessionSpec(
        assetId: catalog.chapter(1).assetId,
        durationMs: catalog.chapter(1).durationMs! + 1,
        playCount: 33,
        speed: .9,
      );
      h.intent = true;
      h.index = 2;
      h.elapsed = const Duration(milliseconds: 8500);
      final active = h.spec;
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Surahs'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(CustomScrollView),
            matching: find.text('Al-Fatihah'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Pause playback'), findsOneWidget);
        expect(h.spec, same(active));
        expect(h.starts, 0);
        expect(h.pass, 3);
        expect(h.position.inMilliseconds, 8500);
        await reveal(tester, find.text('Pass 3 of 33'));
        expect(find.text('Pass 3 of 33'), findsOneWidget);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );
  testWidgets(
    'position updates do not rebuild Surahs during local or streamed playback',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      h.spec = SessionSpec(
        assetId: catalog.chapter(9).assetId,
        durationMs: catalog.chapter(9).durationMs!,
      );
      h.intent = true;
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Surahs'),
          ),
        );
        await tester.pumpAndSettle();
        final samples = <int>[];
        for (final local in [true, false]) {
          h.usingLocal = local;
          var rebuilds = 0;
          for (var i = 1; i <= 60; i++) {
            final previous = tester.widget(find.byType(CustomScrollView));
            h.elapsed = Duration(milliseconds: i * 200);
            h.positions.add(h.elapsed);
            await tester.pump(const Duration(milliseconds: 200));
            if (!identical(
              previous,
              tester.widget(find.byType(CustomScrollView)),
            )) {
              rebuilds++;
            }
          }
          debugPrint(
            'SURAHS_REBUILD_SAMPLE local=$local positionEvents=60 listRebuilds=$rebuilds',
          );
          samples.add(rebuilds);
        }
        expect(samples, [0, 0]);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );
  testWidgets(
    'Surahs taps and retaps reset to All; Home Starred opens the collection; browsing never interrupts a passage',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      h.spec = SessionSpec(
        assetId: catalog.chapter(9).assetId,
        durationMs: catalog.chapter(9).durationMs!,
        startMs: 2000,
        endMs: 5000,
        isPassage: true,
        playCount: 33,
      );
      h.intent = true;
      final session = h.spec;
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        await reveal(tester, find.widgetWithText(TextButton, 'Starred'));
        await tester.tap(find.widgetWithText(TextButton, 'Starred'));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(FilterChip, 'All passages'), findsNothing);
        expect(find.widgetWithText(FilterChip, 'Starred'), findsNothing);
        expect(find.byTooltip('Back to Home'), findsOneWidget);
        expect(find.byKey(const ValueKey('mini-player-open')), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Surahs'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilterChip>(find.widgetWithText(FilterChip, 'All'))
              .selected,
          true,
        );
        expect(find.text('Zarami · Hafs · 114 surahs'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilterChip, 'Downloaded'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Surahs'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilterChip>(find.widgetWithText(FilterChip, 'Downloaded'))
              .selected,
          false,
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Search surahs'),
          '41',
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Play Fussilat'), findsOneWidget);
        await tester.tap(find.text('Fussilat'));
        await tester.pumpAndSettle();
        expect(identical(h.spec, session), true);
        expect(h.playing, true);
        expect(h.starts, 0);
        expect(h.spec!.playCount, 33);
        expect(find.byTooltip('Ready to play'), findsOneWidget);
        h.ended = true;
        h.revision.value++;
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (w) => w is Icon && w.semanticLabel == 'Play recording',
          ),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Close player'));
        await tester.pumpAndSettle();
        expect(find.text('At-Tawbah passage'), findsOneWidget);
        expect(find.text('Fussilat'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Surahs'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(
                find.widgetWithText(TextField, 'Search surahs'),
              )
              .controller!
              .text,
          '',
        );
        expect(find.text('Zarami · Hafs · 114 surahs'), findsOneWidget);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );
  testWidgets(
    'real shell searches 114 records, opens without autoplay, explicitly plays and preserves one handler through appearance',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        expect(find.byType(ProductShell), findsOneWidget);
        expect(find.textContaining('DESIGN PREVIEW'), findsNothing);
        await tester.tap(find.text('Browse all surahs'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '41');
        await tester.pumpAndSettle();
        expect(find.text('Fussilat'), findsOneWidget);
        await tester.tap(find.text('Fussilat'));
        await tester.pumpAndSettle();
        expect(h.spec, isNull);
        expect(h.starts, 0);
        await tester.tap(find.bySemanticsLabel('Play recording'));
        await tester.pumpAndSettle();
        expect(h.spec!.assetId, 'zarami-hafs-041-v1');
        expect(h.spec!.isPassage, false);
        expect(h.spec!.playCount, 1);
        expect(find.byTooltip('Playing'), findsOneWidget);
        final session = h.spec, starts = h.starts;
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, 'Dark'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(identical(h.spec, session), true);
        expect(h.starts, starts);
        expect(await tester.runAsync(deps.repository.readTheme), 'dark');
        expect(tester.takeException(), isNull);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );
  testWidgets(
    'passage sheet uses source seconds and native pass state; editing B never resurrects keyboard',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      h.spec = SessionSpec(
        assetId: catalog.chapter(9).assetId,
        durationMs: catalog.chapter(9).durationMs!,
      );
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue listening'));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Set passage'));
        await tester.tap(find.text('Set passage'));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Fine-tune'));
        await tester.tap(find.text('Fine-tune'));
        await tester.pumpAndSettle();
        final a = find.widgetWithText(TextField, 'A · time in full surah'),
            b = find.widgetWithText(TextField, 'B · time in full surah');
        await tester.enterText(a, '2');
        await tester.enterText(b, '5');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Name & save'));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Repeat options'));
        await tester.tap(find.text('Repeat options'));
        await tester.pumpAndSettle();
        await tester.enterText(find.widgetWithText(TextField, 'Repeats'), '3');
        expect(tester.testTextInput.isVisible, true);
        final name = find.widgetWithText(TextField, 'Passage name');
        await tester.ensureVisible(name);
        await tester.enterText(name, 'Keyboard protection');
        await tester.tap(find.text('Save & play'));
        await tester.pumpAndSettle();
        for (var i = 0; i < 40 && h.spec?.isPassage != true; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pumpAndSettle();
        }
        expect(h.spec!.startMs, 2000);
        expect(h.spec!.endMs, 5000);
        expect(h.spec!.playCount, 3);
        expect(tester.testTextInput.isVisible, false);
        h.index = 1;
        h.elapsed = const Duration(milliseconds: 1000);
        h.revision.value++;
        await tester.pump();
        expect(find.text('Pass 2 of 3'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.textContaining('In full surah 0:03'),
          -200,
          scrollable: find
              .byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('In full surah 0:03'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Stop'),
          100,
          scrollable: find
              .byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              )
              .first,
        );
        await tester.tap(find.text('Stop'));
        await tester.pumpAndSettle();
        expect(h.stops, 1);
        expect(tester.testTextInput.isVisible, false);
        expect(tester.takeException(), isNull);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );
  testWidgets('player download action clears the Android navigation inset', (
    tester,
  ) async {
    final data = (await tester.runAsync(fixture))!;
    final deps = data.$1, h = data.$2, root = data.$3;
    h.spec = SessionSpec(
      assetId: catalog.chapter(108).assetId,
      durationMs: catalog.chapter(108).durationMs!,
    );
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    try {
      await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue listening'));
      await tester.pumpAndSettle();
      await reveal(tester, find.widgetWithText(FilledButton, 'Download'));
      final scroll = tester.state<ScrollableState>(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .first,
      );
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(find.widgetWithText(FilledButton, 'Download')).dy,
        lessThanOrEqualTo(752),
      );
      await tester.tap(find.byTooltip('Close player'));
      await tester.pumpAndSettle();
      expect(find.text('At your own pace').hitTestable(), findsOneWidget);
      expect(h.spec!.assetId, catalog.chapter(108).assetId);
      expect(tester.takeException(), isNull);
    } finally {
      await clean(tester, deps, h, root);
    }
  });
  testWidgets(
    'Home recent passage opens without replacing active playback and has separate Play',
    (tester) async {
      final data = (await tester.runAsync(fixture))!;
      final deps = data.$1, h = data.$2, root = data.$3;
      final original = SessionSpec(
        assetId: catalog.chapter(9).assetId,
        durationMs: catalog.chapter(9).durationMs!,
        isPassage: true,
        startMs: 2000,
        endMs: 5000,
        playCount: 33,
      );
      h.spec = original;
      h.intent = true;
      await tester.runAsync(
        () => PassageLibrary(deps.database).save(
          'Recent revision',
          SessionSpec(
            assetId: catalog.chapter(1).assetId,
            durationMs: catalog.chapter(1).durationMs!,
            startMs: 1000,
            endMs: 4000,
            isPassage: true,
            speed: .9,
          ),
        ),
      );
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.pumpAndSettle();
        // SQLite futures run outside the fake widget clock. Wait for the
        // library load, keeping a bounded readiness check rather than tapping
        // before Home has its saved rows.
        final controller =
            (tester.state(find.byType(ProductShell)) as dynamic).controller
                as ProductController;
        for (var i = 0; i < 40 && controller.saved.isEmpty; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pumpAndSettle();
        }
        expect(controller.saved.length, 1);
        await reveal(tester, find.text('Recent revision'));
        expect(find.byTooltip('Play Recent revision'), findsOneWidget);
        await tester.tap(find.text('Recent revision'));
        await tester.pumpAndSettle();
        expect(h.spec, same(original));
        expect(h.playing, true);
        expect(h.starts, 0);
        expect(find.text('Recent revision'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      'approved product screens fit 320px and 200% text in $brightness',
      (tester) async {
        final data = (await tester.runAsync(fixture))!;
        final deps = data.$1, h = data.$2, root = data.$3;
        deps.appearance.value = brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light;
        h.spec = SessionSpec(
          assetId: catalog.chapter(9).assetId,
          durationMs: catalog.chapter(9).durationMs!,
        );
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        try {
          await tester.pumpWidget(
            FoundationApp(handler: h, dependencies: deps),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text('Surahs'),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Home'));
          await tester.pumpAndSettle();
          await reveal(tester, find.text('Continue listening'));
          await tester.tap(find.text('Continue listening'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await reveal(tester, find.text('Set passage'));
          expect(find.text('Set passage').hitTestable(), findsOneWidget);
        } finally {
          await clean(tester, deps, h, root);
        }
      },
    );
  }

  testWidgets(
    'V20 inline download/cancel/delete never navigates and preserves unrelated session and stars',
    (tester) async {
      final (deps, h, root) = (await tester.runAsync(fixture))!;
      final recording = catalog.chapter(1), active = catalog.chapter(9);
      final queue = deps.product!.downloads;
      h.spec = SessionSpec(
        assetId: active.assetId,
        durationMs: active.durationMs!,
        isPassage: true,
        startMs: 2000,
        endMs: 5000,
        playCount: 5,
      );
      h.usingLocal = true;
      h.intent = true;
      final original = h.spec;
      try {
        await tester.runAsync(() async {
          await deps.repository.setFavorite('surah', '1', true);
        });
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Surahs'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.widgetWithText(CollectionTile, recording.name),
            matching: find.byIcon(Icons.star_rounded),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Download ${recording.name}'));
        for (var i = 0; i < 30 && !queue.entry(recording.assetId).active; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(
          queue.entry(recording.assetId).active,
          true,
          reason: queue.entry(recording.assetId).label,
        );
        expect(
          find.byTooltip('Cancel download ${recording.name}'),
          findsOneWidget,
        );
        expect(find.byTooltip('Close player'), findsNothing);
        expect(h.spec, same(original));
        expect(h.starts, 0);
        await tester.tap(find.byTooltip('Cancel download ${recording.name}'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        expect(queue.entry(recording.assetId).state, 'cancelled');
        await tester.runAsync(() async {
          await deps.product!.downloads.db.customStatement(
            "UPDATE downloads SET state='verified',received_bytes=?,relative_path=?,verified_sha256=? WHERE asset_id=?",
            [
              recording.byteSize,
              'audio/${recording.assetId}.mp3',
              recording.audioAsset.sha256,
              recording.assetId,
            ],
          );
          await queue.initialize();
        });
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Delete download ${recording.name}'));
        await tester.pumpAndSettle();
        expect(find.text('Stop & delete'), findsNothing);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(queue.entry(recording.assetId).state, 'verified');
        await tester.tap(find.byTooltip('Delete download ${recording.name}'));
        await tester.pumpAndSettle();
        // A new local session after the ordinary prompt requires new consent.
        h.spec = SessionSpec(
          assetId: recording.assetId,
          durationMs: recording.durationMs!,
        );
        await tester.tap(find.text('Delete download'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        expect(queue.entry(recording.assetId).state, 'verified');
        expect(h.stops, 0);
        h.spec = original;
        await tester.tap(find.byTooltip('Delete download ${recording.name}'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete download'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        expect(h.spec, same(original));
        expect(h.playing, true);
        expect(h.stops, 0);
        expect(h.starts, 0);
        expect(queue.entry(recording.assetId).state, 'cancelled');
        expect(
          await tester.runAsync(
            () => deps.product!.downloads.db
                .select(deps.product!.downloads.db.favorites)
                .get(),
          ),
          hasLength(1),
        );
        expect(find.byTooltip('Close player'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );

  testWidgets(
    'V20 active local deletion requires explicit consent and preserves independent saved star',
    (tester) async {
      final (deps, h, root) = (await tester.runAsync(fixture))!;
      final recording = catalog.chapter(1);
      final c = ProductController(h, deps.product!);
      try {
        await tester.runAsync(() async {
          await c.initialize();
          final spec = SessionSpec(
            assetId: recording.assetId,
            durationMs: recording.durationMs!,
            isPassage: true,
            startMs: 5000,
            endMs: 33000,
            playCount: 5,
          );
          await c.library.save('Independent star', spec);
          await c.refreshSaved();
          await c.favoritePassage(c.saved.single);
          h.spec = spec;
          h.usingLocal = true;
          h.intent = true;
          await expectLater(c.deleteAudio(recording), throwsStateError);
          expect(h.playing, true);
          expect(h.stops, 0);
          await c.deleteAudio(recording, stopLocal: true);
          expect(h.playing, false);
          expect(h.stops, 1);
          expect((await c.library.read()).single.row.startMs, 5000);
          expect(c.passageFavorites, contains(c.saved.single.id));
          expect(c.favorites, isEmpty);
          await c.favorite(recording);
          expect(c.passageFavorites, contains(c.saved.single.id));
          await c.favorite(recording);
          expect(c.favorites, isEmpty);
          expect(c.passageFavorites, contains(c.saved.single.id));
        });
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Independent star'));
        expect(
          find.descendant(
            of: find.widgetWithText(CollectionTile, 'Independent star'),
            matching: find.byIcon(Icons.star_rounded),
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Saved'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.widgetWithText(CollectionTile, 'Independent star'),
            matching: find.byIcon(Icons.star_rounded),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        c.dispose();
        await clean(tester, deps, h, root);
      }
    },
  );

  testWidgets(
    'V20 swipe keeps Home download filter; explicit Surahs retap resets it and Back returns Home',
    (tester) async {
      final (deps, h, root) = (await tester.runAsync(fixture))!;
      try {
        await tester.pumpWidget(FoundationApp(handler: h, dependencies: deps));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pumpAndSettle();
        await reveal(tester, find.widgetWithText(TextButton, 'Downloads'));
        await tester.tap(find.widgetWithText(TextButton, 'Downloads'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilterChip>(find.widgetWithText(FilterChip, 'Downloaded'))
              .selected,
          true,
        );
        await tester.dragFrom(const Offset(500, 250), const Offset(-300, 0));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          2,
        );
        await tester.dragFrom(const Offset(200, 250), const Offset(300, 0));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          1,
        );
        expect(
          tester
              .widget<FilterChip>(find.widgetWithText(FilterChip, 'Downloaded'))
              .selected,
          true,
        );
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Surahs'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilterChip>(find.widgetWithText(FilterChip, 'All'))
              .selected,
          true,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          0,
        );
        expect(h.starts, 0);
        expect(h.stops, 0);
        await tester.dragFrom(const Offset(500, 250), const Offset(-300, 0));
        await tester.pump(const Duration(milliseconds: 30));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          0,
        );
        expect(
          find.byKey(const PageStorageKey('product-home')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await clean(tester, deps, h, root);
      }
    },
  );
}
