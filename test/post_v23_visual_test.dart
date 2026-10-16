import 'dart:io';
import 'dart:ui' as ui;

import 'package:al_murajaah/app/product_dependencies.dart';
import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/theme/app_theme.dart';
import 'package:al_murajaah/features/catalog/catalog.dart';
import 'package:al_murajaah/features/downloads/audio_files.dart';
import 'package:al_murajaah/features/downloads/download_queue.dart';
import 'package:al_murajaah/features/product/product_shell.dart';
import 'package:al_murajaah/features/support/credits_screen.dart';
import 'package:al_murajaah/features/support/developer_screen.dart';
import 'package:al_murajaah/features/support/diagnostics_gate.dart';
import 'package:al_murajaah/features/support/feedback_screen.dart';
import 'package:al_murajaah/features/support/feedback_client.dart';
import 'package:al_murajaah/features/support/support_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'post_v23_test.dart' show originDatabase;
import 'stage5_v21_support_test.dart' show MemorySupportStore, FakeFeedback;
import 'stage5_v19_playback_test.dart' show V19Player;
import 'download_queue_test.dart' show FakeTransfers;

void main() {
  final output = Platform.environment['AL_MURAJAAH_UI_CAPTURES'];
  late Directory reviewRoot;
  late PrototypeHandler reviewHandler;
  late ProductDependencies reviewProduct;
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (output == null) return;
    reviewRoot = await Directory.systemTemp.createTemp('v24-visual');
    final db = await originDatabase();
    final catalog = Catalog.parse(
      await rootBundle.loadString('assets/catalog/zarami.json'),
    );
    final assets = {
      for (final r in catalog.recordings) r.assetId: r.audioAsset,
      for (final r in storyRecordings) r.assetId: r.asset,
    };
    final queue = DownloadQueue(
      db,
      AudioFiles(reviewRoot),
      FakeTransfers(),
      assets,
      pollInterval: const Duration(days: 1),
    );
    reviewProduct = ProductDependencies(
      catalog,
      assets,
      queue,
      supportStore: MemorySupportStore()..data['originDiscovered'] = true,
    );
    reviewHandler = PrototypeHandler(
      PrototypeStore(reviewRoot),
      player: V19Player(),
      assetResolver: (id) => assets[id]!,
      localResolver: (_) async => null,
    );
    await reviewHandler.loadAndStart(storyRecordings[1].session);
    final fonts = Platform.environment['AL_MURAJAAH_FONT_DIR'];
    if (fonts == null) return;
    final loader = FontLoader('Roboto');
    for (final name in [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
    ]) {
      if (!File('$fonts/$name').existsSync()) continue;
      loader.addFont(
        File('$fonts/$name').readAsBytes().then(ByteData.sublistView),
      );
    }
    await loader.load();
    await (FontLoader('MaterialIcons')..addFont(
          File('$fonts/materialicons-regular.otf')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
    await (FontLoader('NotoSansArabic')..addFont(
          File('assets/fonts/noto-sans-arabic/NotoSansArabic-Variable.ttf')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
  });
  tearDownAll(() async {
    if (output == null) return;
    await reviewHandler.dispose();
    reviewProduct.downloads.dispose();
    await reviewProduct.downloads.db.close();
    await reviewRoot.delete(recursive: true);
  });
  Future<void> capture(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('review-capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(output!).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Widget app(Widget page, Brightness brightness, {double scale = 1}) =>
      MaterialApp(
        theme: AppTheme.forBrightness(brightness),
        builder: (context, child) => RepaintBoundary(
          key: const ValueKey('review-capture'),
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
        home: page,
      );
  Future<void> open(
    WidgetTester tester,
    Widget page,
    Brightness brightness, {
    double scale = 1,
  }) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(page, brightness, scale: scale));
    final context = tester.element(
      find.byKey(const ValueKey('review-capture')),
    );
    await tester.runAsync(() async {
      for (final path in [
        'assets/brand/main-blue.png',
        'assets/brand/wordmark-white.png',
        'assets/credits/zarami.png',
      ]) {
        await precacheImage(AssetImage(path), context);
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      250,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .last,
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'isolated visual review and actual discovery/feedback animation frames',
    (tester) async {
      tester.view.physicalSize = const Size(480, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.almurajaah/support'),
            (call) async => <String, String>{},
          );
      for (final brightness in Brightness.values) {
        final suffix = brightness.name;
        await open(
          tester,
          DeveloperScreen(
            store: MemorySupportStore()..data['originDiscovered'] = true,
          ),
          brightness,
        );
        await capture(tester, 'developer-$suffix');
        await open(tester, const OriginScreen(), brightness);
        await capture(tester, 'story-start-$suffix');
        await reveal(tester, find.text('فَسَمَّيْنَاهُ الْمُرَاجَعَة'));
        await capture(tester, 'story-arabic-$suffix');
        await reveal(tester, find.text('Recitations'));
        await tester.drag(find.byType(ListView), const Offset(0, -280));
        await tester.pumpAndSettle();
        await capture(tester, 'origin-rows-$suffix');
        await open(tester, const CreditsScreen(), brightness);
        await capture(tester, 'credits-$suffix');
        await open(
          tester,
          DiagnosticsGate(builder: (_) => const SizedBox()),
          brightness,
        );
        await capture(tester, 'pin-$suffix');
        await open(
          tester,
          FeedbackScreen(store: MemorySupportStore()),
          brightness,
        );
        await tester.enterText(
          find.byType(TextField),
          'A retained private review draft.',
        );
        await tester.pumpAndSettle();
        await capture(tester, 'feedback-draft-$suffix');
        tester.view.physicalSize = const Size(320, 720);
        await open(tester, const CreditsScreen(), brightness, scale: 2);
        await capture(tester, 'credits-large-$suffix');
        await open(
          tester,
          DeveloperScreen(store: MemorySupportStore()),
          brightness,
          scale: 2,
        );
        await capture(tester, 'developer-large-$suffix');
        await open(
          tester,
          FeedbackScreen(store: MemorySupportStore()),
          brightness,
          scale: 2,
        );
        await tester.enterText(find.byType(TextField), 'Large text draft');
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        await tester.pumpAndSettle();
        await capture(tester, 'feedback-large-keyboard-insets-$suffix');
        tester.view.resetViewInsets();
        tester.view.physicalSize = const Size(480, 800);
        expect(tester.takeException(), isNull);
      }
      await open(
        tester,
        DeveloperScreen(store: MemorySupportStore()),
        Brightness.dark,
      );
      for (var i = 0; i < 7; i++) {
        await tester.tap(find.byKey(const ValueKey('developer-mark')));
        await tester.pump();
      }
      for (var frame = 0; frame < 25; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
        await capture(
          tester,
          'discovery-frame-${frame.toString().padLeft(2, '0')}',
        );
      }
      await tester.pumpAndSettle();
      await open(
        tester,
        FeedbackScreen(
          store: MemorySupportStore(),
          client: FakeFeedback(
            Future.value(const FeedbackResult(FeedbackStatus.confirmed, 42)),
          ),
        ),
        Brightness.light,
      );
      await tester.enterText(
        find.byType(TextField),
        'Mocked confirmation; no public issue.',
      );
      await reveal(tester, find.text('Send'));
      await tester.tap(find.text('Send'));
      await tester.pump();
      for (var frame = 0; frame < 25; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
        await capture(
          tester,
          'feedback-frame-${frame.toString().padLeft(2, '0')}',
        );
      }
      await tester.pumpAndSettle();
      for (final brightness in Brightness.values) {
        await open(
          tester,
          ProductShell(handler: reviewHandler, dependencies: reviewProduct),
          brightness,
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        await capture(tester, 'home-wordmark-${brightness.name}');
        await tester.tap(find.byKey(const ValueKey('mini-player-open')));
        await tester.pumpAndSettle();
        await capture(tester, 'origin-player-${brightness.name}');
        await reveal(tester, find.text('Repeats'));
        await capture(tester, 'origin-controls-${brightness.name}');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    },
    skip: output == null,
  );
}
