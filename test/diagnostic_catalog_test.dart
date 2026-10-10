import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diagnostic_focus_test.dart' show FocusTestHandler;

class EmptyDiagnosticsStore extends PrototypeStore {
  EmptyDiagnosticsStore() : super(Directory.systemTemp);
  @override
  Future<List<SavedPassage>> passages() async => [];
}

class CatalogDiagnosticHandler extends FocusTestHandler {
  CatalogDiagnosticHandler(super.store, this.name);
  final String? name;
  @override
  Map<String, Object?> get diagnostics => {
    ...super.diagnostics,
    if (name != null) 'assetName': name,
  };
}

void main() {
  for (final name in <String?>['Al-Qadr', null]) {
    testWidgets('diagnostics render a full-catalog session safely: $name', (
      tester,
    ) async {
      final h = CatalogDiagnosticHandler(EmptyDiagnosticsStore(), name)
        ..spec = SessionSpec(assetId: 'zarami-hafs-097-v2', durationMs: 52924);
      await tester.pumpWidget(DiagnosticApp(handler: h));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('${name ?? 'zarami-hafs-097-v2'} • Full surah'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('${name ?? 'zarami-hafs-097-v2'} • Full surah'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      h.events.dispose();
      h.revision.dispose();
    });
  }
}
