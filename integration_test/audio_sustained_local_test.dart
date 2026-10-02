import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'audio_sustained_test.dart' as sustained;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('verified downloaded At-Tawbah 12 minute local transport trial', (
    tester,
  ) async {
    final base = await PrototypeStore.open();
    // Prepared by copying the previously completed, hash-checked Android
    // download. Never remove or replace the original download/user store.
    final store = PrototypeStore(
      Directory('${base.root.path}/verified_fixture'),
    );
    expect(
      await store.isVerified(samples[1]),
      true,
      reason: 'Prepare the complete downloaded fixture before this test.',
    );
    final h = await createHandler(store);
    runApp(DiagnosticApp(handler: h));
    await tester.pump();
    try {
      final duration = await h
          .inspect(samples[1])
          .timeout(const Duration(seconds: 90));
      expect(h.usingLocal, true);
      expect(duration, 4299684);
      await sustained.runSustainedTrial(h, duration, 'verified-local');
    } finally {
      await h.stop();
      await tester.pumpWidget(const SizedBox());
      await h.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 16)));
}
