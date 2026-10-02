import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:al_murajaah/core/audio/diagnostic_export.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/main.dart';
import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pending startup draws a scrollable window; failure is visible', (
    tester,
  ) async {
    final pending = Completer<PrototypeHandler>();
    await tester.pumpWidget(
      DiagnosticBootstrap(
        loader: (status) {
          status('Verifying retained recording…');
          return pending.future;
        },
      ),
    );
    await tester.pump();
    expect(find.text('Verifying retained recording…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pump();
    pending.completeError(StateError('fixture initialization failure'));
    await tester.pump();
    expect(
      find.textContaining('fixture initialization failure'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('complete export exceeds 20KB and preserves final rows and invalid raw bytes', () async {
    final root = await Directory.systemTemp.createTemp('murajaah_export');
    try {
      final logs = Directory('${root.path}/logs');
      await logs.create();
      final entries = List.generate(
        200,
        (i) => jsonEncode({
          'index': i,
          'marker': 'complete-row-$i',
          'pad': 'x' * 150,
        }),
      );
      final text = '${entries.join('\n')}\n';
      await File('${logs.path}/valid.jsonl').writeAsString(text);
      await File('${logs.path}/partial.jsonl').writeAsBytes([123, 0xf0, 0x9f]);
      final exported = await writeDiagnosticFile(root.path, {
        'scope': 'fixture',
      });
      final bytes = await File(exported.path).readAsBytes();
      expect(bytes.length, greaterThan(20000));
      expect(bytes.length, exported.bytes);
      expect(sha256.convert(bytes).toString(), exported.sha256);
      final parsed = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final records = parsed['storedLogs'] as List<dynamic>;
      final valid = records.singleWhere((r) => r['name'] == 'valid.jsonl');
      expect(valid['rawJsonl'], text);
      expect(valid['rawJsonl'], contains('complete-row-199'));
      final partial = records.singleWhere((r) => r['name'] == 'partial.jsonl');
      expect(base64Decode(partial['rawBytesBase64']), [123, 0xf0, 0x9f]);
    } finally {
      await root.delete(recursive: true);
    }
  });

  test('worker download verifies bytes, throttles progress and rejects concurrency', () async {
    final root = await Directory.systemTemp.createTemp('murajaah_worker');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final payload = List<int>.generate(65536, (i) => i % 251);
    final completed = Completer<void>();
    server.listen((request) async {
      request.response.headers.contentType = ContentType('audio', 'mpeg');
      request.response.contentLength = payload.length;
      for (var offset = 0; offset < payload.length; offset += 1024) {
        request.response.add(payload.sublist(offset, offset + 1024));
        await request.response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await request.response.close();
      completed.complete();
    });
    try {
      final store = PrototypeStore(root);
      final asset = SampleAsset(
        'worker',
        'fixture',
        'http://127.0.0.1:${server.port}/recording',
        payload.length,
        sha256.convert(payload).toString(),
      );
      var updates = 0;
      var heartbeats = 0;
      final heartbeat = Timer.periodic(
        const Duration(milliseconds: 10),
        (_) => heartbeats++,
      );
      try {
        final download = store.download(asset, (_, _) => updates++);
        await expectLater(store.download(asset, (_, _) {}), throwsStateError);
        final file = await download;
        await completed.future;
        expect(await file.readAsBytes(), payload);
        expect(await store.isVerified(asset), true);
        expect(heartbeats, greaterThan(5));
        expect(updates, lessThan(20));
        expect(await File('${file.path}.part').exists(), false);
      } finally {
        heartbeat.cancel();
      }
    } finally {
      await server.close(force: true);
      await root.delete(recursive: true);
    }
  });

  test(
    'failed worker verification preserves existing audio and removes partial',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'murajaah_bad_transfer',
      );
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.headers.contentType = ContentType('audio', 'mpeg');
        request.response.contentLength = 3;
        request.response.add([1, 2, 4]);
        await request.response.close();
      });
      try {
        final store = PrototypeStore(root);
        final asset = SampleAsset(
          'corrupt',
          'fixture',
          'http://127.0.0.1:${server.port}/recording',
          3,
          sha256.convert([1, 2, 3]).toString(),
        );
        final file = store.audioFile(asset);
        await file.writeAsBytes([1, 2, 3]);
        await expectLater(
          store.download(asset, (_, _) {}),
          throwsFormatException,
        );
        expect(await file.readAsBytes(), [1, 2, 3]);
        expect(await store.isVerified(asset), true);
        expect(await File('${file.path}.part').exists(), false);
      } finally {
        await server.close(force: true);
        await root.delete(recursive: true);
      }
    },
  );
}
