import 'dart:async';
import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Exercise real diagnostic widgets with commands held pending. Native playback
// is deliberately outside this keyboard/focus regression's scope.
class FocusTestHandler implements PrototypeHandler {
  FocusTestHandler(this.store);
  @override
  final PrototypeStore store;
  @override
  final revision = ValueNotifier<int>(0);
  @override
  final events = ValueNotifier<List<String>>([]);
  @override
  final durations = {samples.first.id: 79263};
  @override
  SessionSpec? spec;
  @override
  String? lastError;
  @override
  bool forceStreaming = false;
  @override
  bool usingLocal = false;
  @override
  bool get playing => false;
  @override
  bool get completed => false;
  @override
  int get pass => 1;
  @override
  Duration get position => Duration.zero;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Map<String, Object?> get diagnostics => {
    'processingState': 'ready',
    'speed': 1.0,
    'pitch': 1.0,
  };
  Completer<void>? pending;
  int starts = 0, stops = 0;
  @override
  Future<void> start(
    SessionSpec request, {
    bool autoPlay = true,
    int initialIndex = 0,
    Duration initialPosition = Duration.zero,
  }) {
    starts++;
    spec = request;
    return (pending = Completer<void>()).future;
  }

  @override
  Future<void> stop() {
    stops++;
    return (pending = Completer<void>()).future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory root;
  late FocusTestHandler handler;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('murajaah_focus');
    handler = FocusTestHandler(PrototypeStore(root));
  });
  tearDown(() async {
    handler.events.dispose();
    handler.revision.dispose();
    await root.delete(recursive: true);
  });
  for (final action in ['Start passage / restart at pass 1', 'Stop']) {
    testWidgets('$action clears B input focus through busy completion', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(DiagnosticApp(handler: handler));
      await tester.pump();
      final endInput = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'B: source seconds',
      );
      await tester.showKeyboard(endInput);
      expect(tester.testTextInput.isVisible, true);
      await tester.tap(find.text(action));
      await tester.pump();
      final field = tester.widget<EditableText>(
        find.descendant(of: endInput, matching: find.byType(EditableText)),
      );
      expect(field.focusNode.hasFocus, false);
      expect(tester.testTextInput.isVisible, false);
      handler.pending!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(field.focusNode.hasFocus, false);
      expect(tester.testTextInput.isVisible, false);
      expect(handler.starts, action == 'Stop' ? 0 : 1);
      expect(handler.stops, action == 'Stop' ? 1 : 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
