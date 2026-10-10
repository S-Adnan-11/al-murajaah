import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/features/product/passage_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final active in [false, true]) {
    testWidgets(
      'Edit has only Save, active=$active; Create actions stay distinct',
      (tester) async {
        PassageDraft? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showDialog<PassageDraft>(
                      context: context,
                      builder: (_) => PassageEditor(
                        spec: SessionSpec(
                          assetId: 'test',
                          durationMs: 10000,
                          startMs: 2000,
                          endMs: 5000,
                          isPassage: true,
                          playCount: 5,
                        ),
                        title: 'Original',
                        editing: true,
                        active: active,
                      ),
                    );
                  },
                  child: const Text('Edit'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
        expect(find.text('Edit passage'), findsOneWidget);
        expect(find.text('Save & apply'), findsNothing);
        expect(find.text('Save & play'), findsNothing);
        final semantics = tester.ensureSemantics();
        await tester.ensureVisible(find.text('Repeat options'));
        await tester.tap(find.text('Repeat options'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.widgetWithText(TextField, 'Repeats'));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.loop_rounded), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            RegExp('Total plays, including the first play'),
          ),
          findsOneWidget,
        );
        semantics.dispose();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(result!.play, false);
        expect(result!.spec.startMs, 2000);
        expect(result!.spec.playCount, 5);
        expect(result!.title, 'Original');
      },
    );
  }
  test(
    'full editor uses catalog EOF while existing passage intervals stay intact',
    () {
      final full = SessionSpec(assetId: 'test', durationMs: 30466);
      final editor = editorSourceSpec(full, 30459);
      expect(editor.durationMs, 30459);
      expect(editor.endMs, 30459);
      expect(editor.isPassage, false);
      final passage = SessionSpec(
        assetId: 'test',
        durationMs: 30466,
        startMs: 2000,
        endMs: 5000,
        isPassage: true,
        playCount: 33,
      );
      expect(editorSourceSpec(passage, 30459), same(passage));
      expect(editorSourceSpec(full, null), same(full));
    },
  );
  test('typed source coordinates support seconds, minutes/hours and reject invalid components', () {
    expect(parseSourceTime('12:25'), 745000);
    expect(parseSourceTime('1:02:03.1'), 3723100);
    expect(parseSourceTime('2.1'), 2100);
    for (final s in ['NaN', '-1', '2:60', '1.5:02', 'a']) {
      expect(() => parseSourceTime(s), throwsA(isA<Exception>()));
    }
  });
  testWidgets(
    'visual and typed editor saves a named draft with fine boundaries and zero gap without starting audio',
    (tester) async {
      PassageDraft? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<PassageDraft>(
                    context: ctx,
                    builder: (_) => PassageEditor(
                      spec: SessionSpec(assetId: 'test', durationMs: 180000),
                      sourcePositionMs: 10000,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(RangeSlider), findsNothing);
      expect(find.text('Set start · A'), findsOneWidget);
      expect(find.text('Set end · B'), findsOneWidget);
      await tester.ensureVisible(find.text('Fine-tune'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fine-tune'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'A · time in full surah'),
        '0:02',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'B · time in full surah'),
        '0:05',
      );
      await tester.ensureVisible(find.text('A +0.1s'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A +0.1s'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name & save'));
      await tester.pumpAndSettle();
      final name = find.widgetWithText(TextField, 'Passage name');
      await tester.ensureVisible(name);
      await tester.enterText(name, 'Today’s revision');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result!.play, false);
      expect(result!.title, 'Today’s revision');
      expect(result!.spec.startMs, 2100);
      expect(result!.spec.endMs, 5000);
      expect(result!.spec.gapMs, 0);
      expect(tester.testTextInput.isVisible, false);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('editor remains scrollable at 320px and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PassageEditor(
            spec: SessionSpec(assetId: 'test', durationMs: 180000),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsWidgets);
  });
  for (final brightness in Brightness.values) {
    testWidgets('mark and name at 320px / 200% text in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final position = ValueNotifier<int>(1234);
      addTearDown(position.dispose);
      PassageDraft? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<PassageDraft>(
                    MaterialPageRoute(
                      builder: (_) => ValueListenableBuilder<int>(
                        valueListenable: position,
                        builder: (_, value, _) => PassageEditor(
                          spec: SessionSpec(
                            assetId: 'test',
                            durationMs: 180000,
                          ),
                          sourcePositionMs: value,
                          onSeek: (v) async {
                            position.value = v;
                          },
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      Future<void> reveal(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        expect(finder.hitTestable(), findsOneWidget);
      }

      await reveal(find.text('Set start · A'));
      await tester.tap(find.text('Set start · A'));
      position.value = 5678;
      await tester.pump();
      await reveal(find.text('Set end · B'));
      await tester.tap(find.text('Set end · B'));
      await tester.pumpAndSettle();
      expect(find.text('A · 0:01.234'), findsOneWidget);
      expect(find.text('B · 0:05.678'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(RangeSlider), findsNothing);
      await tester.tap(find.text('Name & save'));
      await tester.pumpAndSettle();
      final name = find.widgetWithText(TextField, 'Passage name');
      expect(tester.widget<TextField>(name).focusNode!.hasFocus, true);
      await reveal(name);
      await tester.enterText(name, 'Small-screen passage');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result!.spec.startMs, 1234);
      expect(result!.spec.endMs, 5678);
      expect(result!.play, false);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('keyboard leaves creation Save actions visible above its inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 340);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final position = ValueNotifier<int>(1234);
    addTearDown(position.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<int>(
          valueListenable: position,
          builder: (_, value, _) => PassageEditor(
            spec: SessionSpec(assetId: 'test', durationMs: 30000),
            sourcePositionMs: value,
            onSeek: (_) async {},
          ),
        ),
      ),
    );
    Future<void> mark(String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await mark('Set start · A');
    position.value = 5678;
    await tester.pump();
    await mark('Set end · B');
    await tester.tap(find.text('Name & save'));
    await tester.pumpAndSettle();
    for (final label in ['Cancel', 'Save', 'Save & play']) {
      expect(find.text(label).hitTestable(), findsOneWidget);
      expect(tester.getRect(find.text(label)).bottom, lessThanOrEqualTo(460));
    }
    expect(tester.takeException(), isNull);
  });
}
