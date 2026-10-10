import 'dart:convert';

import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/features/catalog/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String source;
  setUpAll(() async {
    source = await rootBundle.loadString('assets/catalog/zarami.json');
  });
  test('114 delivery records; verified replacement corrects unshipped draft', () {
    final catalog = Catalog.parse(source);
    expect(
      catalog.recordings.map((r) => r.number),
      List.generate(114, (i) => i + 1),
    );
    expect(catalog.recordings.where((r) => r.available), hasLength(114));
    expect(catalog.chapter(41).available, isTrue);
    expect(catalog.chapter(41).version, 1);
    expect(catalog.chapter(41).assetId, 'zarami-hafs-041-v1');
    expect(catalog.chapter(41).durationMs, 1047301);
    expect(catalog.chapter(41).byteSize, 25234653);
    expect(
      catalog.chapter(41).url.toString(),
      'https://res.cloudinary.com/yw5eprsc/video/upload/zarami-041.mp3',
    );
    expect(
      catalog.chapter(41).sha256,
      'd4668a46907e97b2d980a60d3e07435190dcf17f0faac4739ca1ee248ce74fb7',
    );
    expect(catalog.recordings.fold(0, (n, r) => n + r.byteSize), 2017703450);
    expect(
      catalog.chapter(2).sha256,
      '5148333a067ea6cc69ef30b1cf5173f05930ae8471f5ca47cea302df60a3e8e2',
    );
    expect(catalog.chapter(2).byteSize, 91805804);
    expect(catalog.chapter(2).durationMs, 10659344);
    // Preserve the three known identities and URLs, not a replacement edition.
    for (final sample in samples) {
      final current = catalog.recordings.singleWhere(
        (r) => r.assetId == sample.id,
      );
      expect(current.url.toString(), sample.url);
      expect(current.byteSize, sample.bytes);
      expect(current.sha256, sample.sha256);
    }
  });
  test(
    'unavailable fixture retains no accepted duration and cannot publish',
    () {
      final json = jsonDecode(source) as Map<String, dynamic>;
      final blocked = json['recordings'][40] as Map<String, dynamic>;
      blocked['availability'] = 'unavailable';
      blocked['durationMs'] = null;
      blocked['unavailableReason'] = 'Recording under review';
      final catalog = Catalog.parse(jsonEncode(json));
      expect(catalog.recordings.where((r) => r.available), hasLength(113));
      expect(catalog.chapter(41).available, isFalse);
      expect(catalog.chapter(41).durationMs, isNull);
      blocked['availability'] = 'published';
      expect(() => Catalog.parse(jsonEncode(json)), throwsFormatException);
    },
  );
  test('offline number, common transliteration and Arabic searches', () {
    final catalog = Catalog.parse(source);
    expect(catalog.search('Fatihah').single.number, 1);
    expect(catalog.search('Fātiha').single.number, 1);
    expect(catalog.search('البَقَرَة').single.number, 2);
    expect(catalog.search('Ali Imran').single.number, 3);
    expect(catalog.search('Tawbah').single.number, 9);
    expect(catalog.search('114').single.number, 114);
    expect(catalog.search('not a surah'), isEmpty);
  });
  test(
    'reject incomplete/duplicate coverage and malformed publication metadata',
    () {
      void rejects(void Function(Map<String, dynamic>) change) {
        final json = jsonDecode(source) as Map<String, dynamic>;
        change(json);
        expect(() => Catalog.parse(jsonEncode(json)), throwsFormatException);
      }

      rejects((json) => (json['recordings'] as List).removeLast());
      rejects((json) {
        final rows = json['recordings'] as List;
        rows[113] = rows[0];
      });
      rejects((json) => json['recordings'][0]['sha256'] = '0' * 63);
      rejects((json) => json['recordings'][0]['durationMs'] = 1.5);
      rejects((json) => json['recordings'][0]['byteSize'] = 0);
      rejects((json) => json['recordings'][40]['durationMs'] = null);
      for (final invalidVersion in [0, -1, 1.5, '2']) {
        rejects((json) => json['recordings'][40]['version'] = invalidVersion);
      }
      rejects(
        (json) => json['recordings'][40]['assetId'] = 'zarami-hafs-041-v2',
      );
      rejects(
        (json) => json['recordings'][0]['assetId'] = 'zarami-hafs-002-v1',
      );
      rejects((json) => json['schemaVersion'] = 2);
    },
  );
  test('trusted delivery URLs reject host/path/id/transform and credential tricks', () {
    for (final url in [
      'http://res.cloudinary.com/yw5eprsc/video/upload/zarami-001.mp3',
      'https://res.cloudinary.com.evil.invalid/yw5eprsc/video/upload/zarami-001.mp3',
      'https://res.cloudinary.com@evil.invalid/yw5eprsc/video/upload/zarami-001.mp3',
      'https://res.cloudinary.com/yw5eprsc/video/upload/zarami-002.mp3',
      'https://res.cloudinary.com/yw5eprsc/video/upload/e_volume:0/zarami-001.mp3',
      'https://res.cloudinary.com/yw5eprsc/video/upload/zarami-001.mp3?token=x',
      'https://res.cloudinary.com/yw5eprsc/video/upload/%7Aarami-001.mp3',
    ]) {
      final json = jsonDecode(source) as Map<String, dynamic>;
      json['recordings'][0]['url'] = url;
      expect(
        () => Catalog.parse(jsonEncode(json)),
        throwsFormatException,
        reason: url,
      );
    }
  });
}
