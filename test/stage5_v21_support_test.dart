import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/features/catalog/catalog.dart';
import 'package:al_murajaah/core/theme/app_theme.dart';
import 'package:al_murajaah/core/theme/brand.dart';
import 'package:al_murajaah/features/activity/activity_screen.dart';
import 'package:al_murajaah/features/product/duration_display.dart';
import 'package:al_murajaah/features/support/developer_screen.dart';
import 'package:al_murajaah/features/support/feedback_client.dart';
import 'package:al_murajaah/features/support/feedback_screen.dart';
import 'package:al_murajaah/features/support/support_content.dart';
import 'package:al_murajaah/features/support/support_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class MemorySupportStore extends SupportStore {
  MemorySupportStore() : super(File('unused'));
  Map<String, dynamic> data = {};
  @override
  Future<Map<String, dynamic>> read() async => Map.of(data);
  @override
  Future<void> update(String key, Object? value) async {
    data[key] = value;
  }
}

class FakeFeedback extends FeedbackClient {
  FakeFeedback(this.result);
  Future<FeedbackResult> result;
  final attempts = <Map<String, dynamic>>[];
  @override
  bool get configured => true;
  @override
  Future<FeedbackResult> send(Map<String, dynamic> payload) {
    attempts.add(payload);
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = Platform.environment['AL_MURAJAAH_FONT_DIR'];
    if (fonts == null) return;
    final loader = FontLoader('Roboto');
    for (final name in [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
    ]) {
      final file = File('$fonts/$name');
      if (await file.exists()) {
        loader.addFont(file.readAsBytes().then(ByteData.sublistView));
      }
    }
    await loader.load();
    await (FontLoader('MaterialIcons')..addFont(
          File('$fonts/materialicons-regular.otf')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
  });
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.almurajaah/support'),
          (call) async => call.method == 'feedbackDetails'
              ? {
                  'appVersion': '1.0.0+21',
                  'androidVersion': 'test',
                  'model': 'Fixture',
                  'manufacturer': 'Fixture',
                }
              : null,
        );
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.almurajaah/support'),
          null,
        ),
  );

  test('listening labels split completed minutes consistently; source times untouched', () {
    for (final entry in {
      0: '0 min',
      59999: '<1 min',
      60000: '1 min',
      3599999: '59 min',
      3600000: '1 hr',
      4979999: '1 hr 22 min',
      4980000: '1 hr 23 min',
      7199999: '1 hr 59 min',
      7200000: '2 hr',
    }.entries) {
      expect(listeningDuration(entry.key), entry.value);
    }
    expect(listeningEquivalence(4980999), '1 hr 23 min\n83 min');
    expect(listeningEquivalence(7199999), '1 hr 59 min\n119 min');
    expect(playbackTime(4980000), '1:23:00');
    expect(passageLengthLabel(90000), '2 min');
  });
  test(
    'support state persists independently without rewriting other values',
    () async {
      final root = await Directory.systemTemp.createTemp('support');
      try {
        final file = File('${root.path}/support.json');
        final store = SupportStore(file);
        await Future.wait([
          store.update('originDiscovered', true),
          store.update('feedbackDraft', {'message': 'Retain me'}),
        ]);
        final restored = await SupportStore(file).read();
        expect(restored['originDiscovered'], true);
        expect(restored['feedbackDraft'], {'message': 'Retain me'});
      } finally {
        await root.delete(recursive: true);
      }
    },
  );
  test(
    'brother namespace has independent metadata and no catalog auto-next',
    () {
      final recording = StoryRecording(
        SampleAsset(
          'brother-001',
          'Fixture title',
          'https://example.invalid/v1/fixture.mp3',
          123,
          'a' * 64,
          reciter: 'Approved fixture credit',
          riwayah: null,
        ),
        5000,
      );
      expect(recording.valid, true);
      expect(recording.session.continuesToNext, false);
      expect(recording.asset.reciter, 'Approved fixture credit');
      expect(
        SessionSpec(
          assetId: 'zarami-hafs-001-v1',
          durationMs: 5000,
        ).continuesToNext,
        true,
      );
      expect(storyRecordings, hasLength(4));
      expect(
        storyRecordings.every((r) => r.valid && !r.session.continuesToNext),
        true,
      );
      expect(
        storyRecordings.take(3).every((r) => r.asset.reciter == 'Nasir'),
        true,
      );
      expect(storyRecordings.last.asset.reciter, 'Shaykh Abdulrahman');
    },
  );
  test('feedback confirmation requires explicit valid response; endpoint has no credentials', () {
    expect(
      FeedbackClient.decode(200, {'status': 'confirmed'}).status,
      FeedbackStatus.pending,
    );
    expect(
      FeedbackClient.decode(200, {
        'status': 'confirmed',
        'reference': 12,
      }).reference,
      12,
    );
    expect(
      FeedbackClient.decode(202, {'status': 'pending'}).status,
      FeedbackStatus.pending,
    );
    expect(
      FeedbackClient.decode(429, {'status': 'rate_limited'}).status,
      FeedbackStatus.rateLimited,
    );
    expect(
      FeedbackClient(endpoint: 'https://token@host/feedback').configured,
      false,
    );
    expect(
      FeedbackClient(endpoint: 'https://host/feedback?token=bad').configured,
      false,
    );
    expect(FeedbackClient(endpoint: 'https://host/feedback').configured, true);
    expect(
      submissionId(),
      matches(
        RegExp(r'^[a-f0-9-]{14}4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$'),
      ),
    );
  });

  testWidgets(
    'seven deliberate taps discover story; idle reset and remembered shortcut',
    (tester) async {
      final store = MemorySupportStore();
      await tester.pumpWidget(MaterialApp(home: DeveloperScreen(store: store)));
      await tester.pumpAndSettle();
      final logo = find.byKey(const ValueKey('developer-mark'));
      for (var i = 0; i < 3; i++) {
        await tester.tap(logo);
        await tester.pump();
      }
      await tester.pump(const Duration(seconds: 5));
      for (var i = 0; i < 6; i++) {
        await tester.tap(logo);
        await tester.pump();
      }
      expect(find.text(originStory.split('\n\n').first), findsNothing);
      await tester.tap(logo);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(originStory.split('\n\n').first), findsOneWidget);
      expect(find.text('Masha Allah, you found it!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(store.data['originDiscovered'], true);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Where it began'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MaterialApp(home: DeveloperScreen(store: store)));
      await tester.pumpAndSettle();
      expect(find.text('Where it began'), findsOneWidget);
    },
  );
  testWidgets('logo offers accessible discovery action', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(home: DeveloperScreen(store: MemorySupportStore())),
    );
    await tester.pumpAndSettle();
    final node = tester.getSemantics(
      find.bySemanticsLabel("Al-Murāja'ah mark"),
    );
    expect(node.getSemanticsData().customSemanticsActionIds, isNotEmpty);
    semantics.dispose();
  });
  testWidgets('listening total opens compact equivalent minutes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ListeningTotal(4980000))),
      );
      final node = tester.getSemantics(
        find.bySemanticsLabel(
          '1 hr 23 min, 83 total minutes. Show time details',
        ),
      );
      expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), true);
      tester
          .renderObject<RenderObject>(
            find.bySemanticsLabel(
              '1 hr 23 min, 83 total minutes. Show time details',
            ),
          )
          .owner!
          .semanticsOwner!
          .performAction(node.id, ui.SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(find.text('1 hr 23 min\n83 min'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('1 hr 23 min'));
      await tester.pumpAndSettle();
      expect(find.text('1 hr 23 min\n83 min'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
  testWidgets(
    'native feedback preserves draft, blocks rapid taps and retries identical pending payload',
    (tester) async {
      final store = MemorySupportStore();
      final pending = Completer<FeedbackResult>();
      final client = FakeFeedback(pending.future);
      await tester.pumpWidget(
        MaterialApp(
          home: FeedbackScreen(store: store, client: client),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Reviewable feedback message',
      );
      await tester.ensureVisible(find.text('Send'));
      await tester.tap(find.text('Send'));
      await tester.pump();
      expect(client.attempts, hasLength(1));
      expect(client.attempts.single['details'], isEmpty);
      expect(find.text(feedbackNotice), findsOneWidget);
      pending.complete(const FeedbackResult(FeedbackStatus.pending));
      await tester.pumpAndSettle();
      client.result = Future.value(
        const FeedbackResult(FeedbackStatus.rateLimited),
      );
      await tester.tap(find.text('Check submission'));
      await tester.pumpAndSettle();
      expect(find.text('Check submission'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, true);
      client.result = Future.value(
        const FeedbackResult(FeedbackStatus.confirmed, 12),
      );
      await tester.tap(find.text('Check submission'));
      await tester.pumpAndSettle();
      expect(client.attempts, hasLength(3));
      expect(client.attempts[0], client.attempts[1]);
      expect(client.attempts[1], client.attempts[2]);
      expect(find.text('Feedback sent. Reference #12.'), findsOneWidget);
      expect((store.data['feedbackDraft'] as Map)['message'], '');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'leaving while sending still saves confirmation without a disposed controller',
    (tester) async {
      final store = MemorySupportStore();
      final pending = Completer<FeedbackResult>();
      await tester.pumpWidget(
        MaterialApp(
          home: FeedbackScreen(
            store: store,
            client: FakeFeedback(pending.future),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Keep sending during navigation',
      );
      await tester.ensureVisible(find.text('Send'));
      await tester.tap(find.text('Send'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      pending.complete(const FeedbackResult(FeedbackStatus.confirmed, 4));
      await tester.pump();
      expect((store.data['feedbackDraft'] as Map)['message'], '');
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('support and startup at 320px / 200% $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final page in <Widget>[
        DeveloperScreen(store: MemorySupportStore()),
        const OriginScreen(),
        FeedbackScreen(store: MemorySupportStore()),
        const BrandedStartup(),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.forBrightness(brightness),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: page,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
    testWidgets('support asset placement captures $brightness', (tester) async {
      final directory = Platform.environment['AL_MURAJAAH_UI_CAPTURES'];
      tester.view.physicalSize = const Size(480, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final entry in <String, Widget>{
        'developer': DeveloperScreen(store: MemorySupportStore()),
        'origin': const OriginScreen(),
        'feedback': FeedbackScreen(store: MemorySupportStore()),
        'startup': const BrandedStartup(),
      }.entries) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.forBrightness(brightness),
            home: RepaintBoundary(
              key: const ValueKey('capture'),
              child: entry.value,
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (directory != null) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('capture')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(directory).create(recursive: true);
            await File('$directory/${entry.key}-${brightness.name}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        expect(tester.takeException(), isNull);
      }
    });
  }
}
