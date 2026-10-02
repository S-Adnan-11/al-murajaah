import 'package:flutter_test/flutter_test.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';

void main() {
  test('counts include first pass and queue indices are bounded', () {
    for (final count in [1, 3, 10, 999]) {
      final spec = SessionSpec(
        assetId: 'test',
        durationMs: 10000,
        playCount: count,
      );
      expect(spec.passAtIndex(0), 1);
      expect(spec.passAtIndex(count - 1), count);
      expect(() => spec.passAtIndex(count), throwsRangeError);
    }
    for (final count in [0, -1, 1000]) {
      expect(
        () => SessionSpec(assetId: 'test', durationMs: 10000, playCount: count),
        throwsArgumentError,
      );
    }
    expect(
      SessionSpec(
        assetId: 'test',
        durationMs: 10000,
        playCount: null,
      ).playCount,
      isNull,
    );
  });
  test('reject unknown duration, reversed, short and out-of-file ranges', () {
    for (final bounds in [
      (0, 1000, 0),
      (-1, 2000, 10000),
      (5000, 4000, 10000),
      (0, 10001, 10000),
      (0, 999, 10000),
    ]) {
      expect(
        () => SessionSpec(
          assetId: 'test',
          startMs: bounds.$1,
          endMs: bounds.$2,
          durationMs: bounds.$3,
          isPassage: true,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => SessionSpec(assetId: 'test', durationMs: 10000, startMs: 1),
      throwsArgumentError,
    );
  });
  test('coordinate mapping clamps at A, exclusive B and near EOF', () {
    final spec = SessionSpec(
      assetId: 'test',
      durationMs: 938000,
      startMs: 745000,
      endMs: 938000,
      isPassage: true,
      playCount: 3,
    );
    expect(spec.lengthMs, 193000);
    expect(spec.sourceToRelative(745000), 0);
    expect(spec.sourceToRelative(937999), 192999);
    expect(spec.sourceToRelative(938000), 193000);
    expect(spec.relativeToSource(-100), 745000);
    expect(spec.relativeToSource(999999), 938000);
    expect(SessionSpec.fromJson(spec.toJson()).toJson(), spec.toJson());
    final full = SessionSpec(
      assetId: spec.assetId,
      durationMs: spec.durationMs,
    );
    expect(full.startMs, 0);
    expect(full.playCount, 1);
    expect(full.isPassage, false);
  });
}
