import 'dart:async';

import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/core/audio/transport_seek_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SessionSpec item({String id = 'saved', int start = 2000}) => SessionSpec(
    assetId: 'recording-v1',
    durationMs: 20000,
    startMs: start,
    endMs: 12000,
    isPassage: true,
    passageId: id,
  );
  Future<void> mount(
    WidgetTester tester, {
    SessionSpec? spec,
    int position = 5000,
    bool enabled = true,
    required Future<void> Function(int) seek,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TransportSeekBar(
          spec: spec ?? item(),
          positionMs: position,
          enabled: enabled,
          onSeek: seek,
          positionLabels: (v) => Text('Preview $v'),
          semanticFormatter: (v) => '$v',
        ),
      ),
    ),
  );

  testWidgets(
    'forward/back taps and drags each commit once, with local time preview',
    (tester) async {
      final seeks = <int>[];
      await mount(tester, seek: (v) async => seeks.add(v));
      final slider = find.byType(Slider),
          rect = tester.getRect(find.byType(Slider));
      Offset at(double ratio) =>
          Offset(rect.left + 24 + (rect.width - 48) * ratio, rect.center.dy);
      for (final ratio in [.8, .2]) {
        final before = seeks.length;
        await tester.tapAt(at(ratio));
        await tester.pumpAndSettle();
        expect(seeks.length, before + 1);
        expect(seeks.last, closeTo(10000 * ratio, 2));
      }
      for (final ratio in [.9, .1]) {
        final before = seeks.length;
        final gesture = await tester.startGesture(at(.5));
        for (var i = 1; i <= 8; i++) {
          await gesture.moveTo(at(.5 + (ratio - .5) * i / 8));
          await tester.pump();
        }
        final preview = tester.widget<Slider>(slider).value;
        expect(seeks.length, before);
        expect(find.text('Preview ${preview.round()}'), findsOneWidget);
        await mount(tester, position: 4100, seek: (v) async => seeks.add(v));
        await tester.pump();
        expect(tester.widget<Slider>(slider).value, preview);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(seeks.length, before + 1);
        expect(seeks.last, preview.round());
      }
    },
  );

  testWidgets(
    'duplicate gesture end and older completion cannot clear a newer preview',
    (tester) async {
      final pending = <Completer<void>>[], seeks = <int>[];
      Future<void> seek(int v) {
        seeks.add(v);
        final c = Completer<void>();
        pending.add(c);
        return c.future;
      }

      await mount(tester, seek: seek);
      var slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChangeStart!(5000);
      slider.onChanged!(7000);
      slider.onChangeEnd!(7000);
      slider.onChangeEnd!(7000);
      await tester.pump();
      expect(seeks, [7000]);
      slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChangeStart!(7000);
      slider.onChanged!(3000);
      pending.first.complete();
      await tester.pump();
      expect(tester.widget<Slider>(find.byType(Slider)).value, 3000);
      slider.onChangeEnd!(3000);
      await tester.pump();
      expect(seeks, [7000, 3000]);
      pending.last.complete();
      await tester.pump();
    },
  );

  for (final change in ['item', 'bounds', 'disabled']) {
    testWidgets(
      '$change cancels the preview; stale gesture release cannot seek',
      (tester) async {
        final seeks = <int>[];
        await mount(tester, seek: (v) async => seeks.add(v));
        final old = tester.widget<Slider>(find.byType(Slider));
        old.onChangeStart!(5000);
        old.onChanged!(8000);
        await tester.pump();
        await mount(
          tester,
          spec: item(
            id: change == 'item' ? 'other' : 'saved',
            start: change == 'bounds' ? 3000 : 2000,
          ),
          enabled: change != 'disabled',
          position: 1000,
          seek: (v) async => seeks.add(v),
        );
        old.onChangeEnd!(8000);
        await tester.pump();
        expect(seeks, isEmpty);
        expect(tester.widget<Slider>(find.byType(Slider)).value, 1000);
      },
    );
  }

  testWidgets('keyboard transport remains one seek per adjustment', (
    tester,
  ) async {
    final seeks = <int>[];
    await mount(tester, seek: (v) async => seeks.add(v));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(seeks, hasLength(1));
    expect(seeks.single, greaterThan(5000));
  });
}
