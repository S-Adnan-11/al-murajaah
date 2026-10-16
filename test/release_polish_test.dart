import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/theme/appearance_controller.dart';
import 'package:al_murajaah/core/theme/home_reading.dart';
import 'package:al_murajaah/core/theme/home_text_controller.dart';
import 'package:al_murajaah/core/theme/themed_app.dart';
import 'package:al_murajaah/features/backup/metadata_backup.dart';
import 'package:al_murajaah/features/product/product_appearance.dart';
import 'package:al_murajaah/features/settings/product_settings.dart';
import 'package:al_murajaah/features/support/about_screen.dart';
import 'package:al_murajaah/main.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'database/generated/foundation/generated/schema.dart';
import 'diagnostic_focus_test.dart' show FocusTestHandler;
import 'stage5_v19_playback_test.dart' show V19Player;
import 'fixtures/foundation_fixture.dart';

import 'package:al_murajaah/core/audio/prototype_store.dart';

class StartupHandler extends FocusTestHandler {
  StartupHandler(super.store);
  @override
  void recordDiagnostic(String reason) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('periodic diagnostics settle while paused and resume only for active transport', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.audio_session'),
          (_) async => null,
        );
    final folder = await Directory.systemTemp.createTemp('idle-diagnostics');
    final handler = PrototypeHandler(
      PrototypeStore(folder),
      player: V19Player(),
    );
    int sampleCount() =>
        RegExp('"reason":"sample"').allMatches(handler.diagnosticExport).length;
    try {
      await handler.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 5200));
      expect(sampleCount(), 0);
      await handler.inspect(samples.first);
      await handler.start(
        SessionSpec(assetId: 'zarami-hafs-001-v1', durationMs: 10000),
      );
      await Future<void>.delayed(const Duration(milliseconds: 5200));
      expect(sampleCount(), greaterThan(0));
      await handler.pause();
      final paused = sampleCount();
      await Future<void>.delayed(const Duration(milliseconds: 5200));
      expect(sampleCount(), paused);
    } finally {
      await handler.dispose();
      await folder.delete(recursive: true);
    }
  });
  for (final version in [1, 2, 3, 4, 5, 6]) {
    for (final policy in ['wifi', 'any']) {
      test('v$version to v7 retains $policy and all original data', () async {
        final helper = GeneratedHelper(),
            verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(version);
        final old = helper.databaseForVersion(schema.newConnection(), version);
        await old.customStatement(
          "INSERT INTO app_settings(id,theme,network_policy) VALUES(1,'dark',?)",
          [policy],
        );
        await seedFoundationFixture(old);
        const tables = [
          'app_settings',
          'reciters',
          'surahs',
          'recording_editions',
          'audio_assets',
          'saved_passages',
          'favorites',
          'downloads',
          'playback_checkpoints',
          'listening_sessions',
          'daily_activity',
          'activity_events',
        ];
        final before = <String, List<Map<String, Object?>>>{};
        for (final table in tables) {
          before[table] = (await old.customSelect('SELECT * FROM $table').get())
              .map((r) => Map<String, Object?>.of(r.data))
              .toList();
        }
        final db = AppDatabase(schema.newConnection());
        try {
          await verifier.migrateAndValidate(db, 7);
          for (final table in tables) {
            final after = (await db.customSelect('SELECT * FROM $table').get())
                .map((r) => Map<String, Object?>.of(r.data))
                .toList();
            if (table == 'app_settings') {
              expect(after.single.remove('alternate_home_text'), 1);
              expect(after.single.remove('home_text_language'), 'english');
              if (version < 2) expect(after.single.remove('updated_utc_ms'), 0);
              if (version < 3) expect(after.single.remove('aurora_enabled'), 0);
            }
            expect(after, before[table], reason: table);
          }
          await db.customStatement('DELETE FROM app_settings');
          await db.customStatement('INSERT INTO app_settings(id) VALUES(1)');
          expect(
            (await db.select(db.appSettings).getSingle()).networkPolicy,
            'any',
          );
          expect(
            await db.customSelect('PRAGMA foreign_key_check').get(),
            isEmpty,
          );
        } finally {
          await db.close();
          await old.close();
        }
      });
    }
  }

  test('exact approved Home copy and Cairo font are bundled', () {
    expect(HomeReading.english, const [
      "Let not! A day fades away...",
      "except that with it is Murāja’ah.",
      "if you\u0027re unable to revise, then recite.",
      "if you\u0027re unable to recite, then at least listen.",
    ]);
    expect(HomeReading.arabic, const [
      "لَا تَدَعْ يَوْمًا يَمْضِي...",
      "إِلَّا وَلَكَ مَعَ القُرْآنِ صِلَةٌ؛.",
      "فَإِنْ لَمْ تَسْتَطِعْ أَنْ تُرَاجِعَ وَتَتَدَبَّرَ فَاقْرَأْ،",
      "وَإِنْ لَمْ تَسْتَطِعْ أَنْ تَقْرَأَ فَاسْتَمِعْ.",
    ]);
    expect(
      File('assets/fonts/cairo/Cairo-Variable.ttf').lengthSync(),
      greaterThan(100000),
    );
  });

  for (final arabic in [false, true]) {
    test(
      'frozen ${arabic ? 'Arabic' : 'English'} survives recreation and backup/import',
      () async {
        final folder = await Directory.systemTemp.createTemp(
          'home-text-polish',
        );
        final file = File('${folder.path}/app.sqlite');
        var db = AppDatabase(NativeDatabase(file));
        final preferences = HomeTextController(database: db);
        final target = AppDatabase(NativeDatabase.memory());
        try {
          await preferences.restore();
          await seedFoundationFixture(db);
          await seedFoundationFixture(target);
          final before =
              (await db.select(db.appSettings).getSingle()).updatedUtcMs;
          await preferences.commitLanguage(arabic);
          expect(
            (await db.select(db.appSettings).getSingle()).updatedUtcMs,
            before,
            reason: 'automatic changes do not write',
          );
          await preferences.setAlternating(false);
          await db.close();
          db = AppDatabase(NativeDatabase(file));
          final restored = HomeTextController(database: db);
          await restored.restore();
          expect(restored.alternating, false);
          expect(restored.arabic, arabic);
          final text = await MetadataBackup(db).export();
          final backup = MetadataBackup(target);
          await backup.import(await backup.preview(text), applySettings: true);
          final imported = HomeTextController(database: target);
          await imported.restore();
          expect(imported.alternating, false);
          expect(imported.arabic, arabic);
          for (final version in [1, 2, 3]) {
            final legacy = jsonDecode(text) as Map<String, dynamic>;
            legacy['version'] = version;
            if (version < 3) legacy.remove('best_listening_streak');
            (legacy['settings'] as Map).remove('alternate_home_text');
            (legacy['settings'] as Map).remove('home_text_language');
            (legacy['settings'] as Map).remove('network_policy');
            await backup.import(
              await backup.preview(jsonEncode(legacy)),
              applySettings: true,
            );
            await imported.restore();
            expect(imported.alternating, true);
            expect(
              (await target.select(target.appSettings).getSingle())
                  .networkPolicy,
              'any',
            );
          }
          imported.dispose();
          restored.dispose();
        } finally {
          preferences.dispose();
          await db.close();
          await target.close();
          await folder.delete(recursive: true);
        }
      },
    );
  }

  testWidgets(
    'Home gives each language 6500 ms fully readable and obeys visibility, route, lifecycle and toggle',
    (tester) async {
      final preferences = HomeTextController(), scroll = ScrollController();
      var active = true;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [appRouteObserver],
          home: StatefulBuilder(
            builder: (context, set) {
              update = set;
              return Scaffold(
                body: ListView(
                  controller: scroll,
                  children: [
                    HomeReading(
                      active: active,
                      scroll: scroll,
                      preferences: preferences,
                    ),
                    const SizedBox(height: 1800),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 6499));
      expect(preferences.arabic, false);
      expect(
        tester
            .widget<FadeTransition>(find.byType(FadeTransition).last)
            .opacity
            .value,
        1,
      );
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      expect(preferences.arabic, true);
      expect(find.text(HomeReading.english.first), findsNothing);
      await tester.pump(const Duration(milliseconds: 140));
      await preferences.setAlternating(false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      expect(preferences.arabic, true);
      await preferences.setAlternating(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 6499));
      expect(preferences.arabic, true);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pump(const Duration(milliseconds: 140));
      expect(preferences.arabic, false);
      update(() => active = false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      expect(preferences.arabic, false);
      update(() => active = true);
      await tester.pump();
      scroll.jumpTo(900);
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      expect(preferences.arabic, false);
      scroll.jumpTo(0);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 30));
      expect(preferences.arabic, false);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Covered')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 30));
      expect(preferences.arabic, false);
      navigator.pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 6499));
      expect(preferences.arabic, false);
      await tester.pumpWidget(const SizedBox());
      preferences.dispose();
      scroll.dispose();
    },
  );

  testWidgets('mid-fade navigation freezes the committed language', (
    tester,
  ) async {
    final preferences = HomeTextController(), scroll = ScrollController();
    var active = true;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (_, set) {
            update = set;
            return Scaffold(
              body: ListView(
                controller: scroll,
                children: [
                  HomeReading(
                    active: active,
                    scroll: scroll,
                    preferences: preferences,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(HomeReading.dwell);
    await tester.pump(const Duration(milliseconds: 70));
    update(() => active = false);
    await tester.pump();
    await preferences.setAlternating(false);
    await tester.pump(const Duration(seconds: 20));
    expect(preferences.arabic, false);
    update(() => active = true);
    await tester.pump();
    expect(find.text(HomeReading.english.first), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    preferences.dispose();
    scroll.dispose();
  });

  testWidgets(
    'theme tiles select immediately, persist and System follows live OS brightness',
    (tester) async {
      ThemeMode? saved;
      final appearance = AppearanceController(
        persist: (mode) async {
          saved = mode;
        },
      );
      await tester.pumpWidget(
        ThemedApp(appearance: appearance, home: const ProductAppearance()),
      );
      expect(find.byType(ThemePreviewTile), findsNWidgets(3));
      expect(find.text('Font and software licenses'), findsNothing);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(saved, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(ProductAppearance))).brightness,
        Brightness.dark,
      );
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(ProductAppearance))).brightness,
        Brightness.light,
      );
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(ProductAppearance))).brightness,
        Brightness.dark,
      );
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
    },
  );

  testWidgets('Settings order and About retain exact remaining destinations', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.select(db.appSettings).getSingle();
    await tester.pumpWidget(
      MaterialApp(
        home: ProductSettings(db: db, downloaded: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Audio diagnostics'), 400);
    final group = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((w) => (w.title as Text?)?.data)
        .whereType<String>()
        .toList();
    expect(group.sublist(group.indexOf('Send feedback')), [
      'Send feedback',
      'Developer',
      'Credits',
      'Privacy & help',
      'Font and software licenses',
      'About App',
      'Audio diagnostics',
    ]);
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Download on Wi-Fi only'),
          )
          .value,
      false,
    );
    final visited = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.almurajaah/support'),
      (_) async => '1.0.1',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AboutScreen(
          developer: () => visited.add('developer'),
          feedback: () => visited.add('feedback'),
          credits: () => visited.add('credits'),
          licenses: () => visited.add('licenses'),
          privacy: () => visited.add('privacy'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Developer'), findsNothing);
    expect(find.text('Send feedback'), findsNothing);
    for (final label in [
      'Credits',
      'Font and software licenses',
      'Privacy & help',
    ]) {
      final tile = find.widgetWithText(ListTile, label);
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
    }
    expect(visited, ['credits', 'licenses', 'privacy']);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  for (final elapsed in [0, 1000]) {
    testWidgets(
      'entrance includes native ${elapsed}ms while local preparation runs in parallel',
      (tester) async {
        final folder = Directory.systemTemp.createTempSync('entrance-polish');
        final handler = StartupHandler(PrototypeStore(folder));
        var started = false;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('dev.almurajaah/support'),
          (_) async => elapsed,
        );
        await tester.pumpWidget(
          DiagnosticBootstrap(
            loader: (_) async {
              started = true;
              return handler;
            },
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(started, true);
        expect(find.text('Al-Murāja’ah'), findsOneWidget);
        await tester.pump(
          Duration(milliseconds: elapsed == 0 ? 2400 : 2499 - elapsed),
        );
        expect(find.byType(DiagnosticApp), findsNothing);
        await tester.pump(Duration(milliseconds: elapsed == 0 ? 200 : 1));
        await tester.pump();
        expect(find.byType(DiagnosticApp), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        handler.events.dispose();
        handler.revision.dispose();
        folder.deleteSync(recursive: true);
      },
    );
  }
  testWidgets(
    'unresponsive native timestamp cannot extend the entrance or block local preparation',
    (tester) async {
      final native = Completer<int>();
      final local = Completer<PrototypeHandler>();
      var localStarted = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.almurajaah/support'),
        (_) => native.future,
      );
      await tester.pumpWidget(
        DiagnosticBootstrap(
          loader: (_) {
            localStarted = true;
            return local.future;
          },
        ),
      );
      await tester.pump();
      expect(localStarted, true);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 2250));
      expect(find.text('Al-Murāja’ah'), findsNothing);
      expect(find.text('Opening your listening library…'), findsOneWidget);
      native.complete(0);
      await tester.pump();
      expect(find.text('Opening your listening library…'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'local preparation overlaps presentation after the first branded frame is painted',
    (tester) async {
      final painted = Completer<void>();
      final local = Completer<PrototypeHandler>();
      var started = false;
      await tester.pumpWidget(
        DiagnosticBootstrap(
          firstFrameReady: () => painted.future,
          loader: (_) {
            started = true;
            return local.future;
          },
        ),
      );
      await tester.pump();
      expect(find.text('Al-Murāja’ah'), findsOneWidget);
      expect(started, false);
      painted.complete();
      await tester.pump();
      expect(started, true);
      await tester.pump(const Duration(milliseconds: 2500));
      expect(find.text('Opening your listening library…'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
