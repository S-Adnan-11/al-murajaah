import 'package:al_murajaah/features/activity/listening_meter.dart';
import 'package:flutter_test/flutter_test.dart';

const origin = 1791453600000;
ListeningSample sample(
  int elapsed,
  int position, {
  bool active = true,
  bool gap = false,
  int epoch = 1,
  int pass = 1,
  double speed = 1,
  int length = 10000,
  int offset = 0,
  int? utc,
}) => ListeningSample(
  elapsedMs: elapsed,
  utcMs: utc ?? origin + elapsed,
  offsetMinutes: offset,
  epoch: epoch,
  pass: pass,
  positionMs: position,
  lengthMs: length,
  speed: speed,
  active: active,
  inGap: gap,
);
int wall(List<MeasuredListening> credits) =>
    credits.fold(0, (s, c) => s + c.wallMs);

void main() {
  test('starts empty; wall time counts once even with duplicate callbacks', () {
    final meter = ListeningMeter();
    expect(meter.sample(sample(0, 0)), isEmpty);
    expect(wall(meter.sample(sample(1000, 1000))), 1000);
    expect(meter.sample(sample(1000, 1000)), isEmpty);
    expect(wall(meter.sample(sample(2000, 2000))), 1000);
  });
  test('pause and buffering exclude elapsed non-progressing time', () {
    final meter = ListeningMeter();
    meter.sample(sample(0, 0));
    expect(wall(meter.sample(sample(500, 500, active: false))), 500);
    expect(meter.sample(sample(5000, 500, active: false)), isEmpty);
    expect(meter.sample(sample(6000, 500)), isEmpty);
    expect(wall(meter.sample(sample(7000, 1500))), 1000);
    expect(
      meter.sample(sample(8000, 1500)),
      isEmpty,
      reason: 'no engine progress',
    );
  });
  test('forward and backward seek distance earns nothing and rebases', () {
    final meter = ListeningMeter();
    meter.sample(sample(0, 0));
    expect(meter.sample(sample(500, 9000, epoch: 2)), isEmpty);
    expect(wall(meter.sample(sample(1000, 9500, epoch: 2))), 500);
    expect(meter.sample(sample(1500, 2000, epoch: 3)), isEmpty);
    expect(wall(meter.sample(sample(2000, 2500, epoch: 3))), 500);
    expect(
      meter.sample(sample(2500, 9000, epoch: 3)),
      isEmpty,
      reason: 'unannounced jump is rejected',
    );
  });
  test('natural repeat tail/head count; repeat silence does not', () {
    final meter = ListeningMeter();
    meter.sample(sample(0, 9000));
    expect(
      wall(meter.sample(sample(1500, 10000, active: false, gap: true))),
      1000,
    );
    expect(
      meter.sample(sample(3500, 10000, active: false, gap: true)),
      isEmpty,
    );
    expect(wall(meter.sample(sample(4200, 200, pass: 2))), 200);
    expect(wall(meter.sample(sample(5200, 1200, pass: 2))), 1000);
  });
  test('gapless adjacent repeat retains its tail and new head', () {
    final meter = ListeningMeter();
    meter.sample(sample(0, 9000));
    expect(wall(meter.sample(sample(1200, 200, pass: 2))), 1200);
    expect(meter.sample(sample(2200, 200, pass: 2)), isEmpty);
  });
  test('completion credits last progressing fraction and stops', () {
    final meter = ListeningMeter();
    meter.sample(sample(0, 9500));
    expect(wall(meter.sample(sample(700, 10000, active: false))), 500);
    expect(meter.sample(sample(5000, 10000, active: false)), isEmpty);
  });
  test('0.75 and 1.25 speed each earn elapsed time, not source duration', () {
    for (final speed in [0.75, 1.25, 2.0, 2.2]) {
      final meter = ListeningMeter();
      meter.sample(sample(0, 0, speed: speed));
      expect(
        wall(meter.sample(sample(1000, (1000 * speed).round(), speed: speed))),
        1000,
      );
    }
    final meter = ListeningMeter();
    meter.sample(sample(0, 0));
    expect(meter.sample(sample(1000, 1000, speed: 1.25)), isEmpty);
    expect(wall(meter.sample(sample(2000, 2250, speed: 1.25))), 1000);
  });
  test(
    'background timer delay counts only verified progressing elapsed time',
    () {
      final meter = ListeningMeter();
      meter.sample(sample(0, 0, length: 600000));
      expect(wall(meter.sample(sample(60000, 60000, length: 600000))), 60000);
      meter.reset();
      expect(
        meter.sample(sample(3600000, 500000, length: 600000)),
        isEmpty,
        reason: 'restart cannot reconstruct historical activity',
      );
    },
  );
  test('local midnight splits exact wall milliseconds at observed offset', () {
    final start = DateTime.utc(2026, 10, 8, 22, 59, 59).millisecondsSinceEpoch;
    final credits = ListeningMeter.split(start, 3000, 60);
    expect(credits.map((c) => c.date), ['2026-10-08', '2026-10-09']);
    expect(credits.map((c) => c.wallMs), [1000, 2000]);
    expect(credits.every((c) => c.timezonePolicy.contains('UTC+60')), isTrue);
  });
  test(
    'travel/DST and clock corrections rebase without relocating credits',
    () {
      final meter = ListeningMeter();
      meter.sample(sample(0, 0, offset: 60));
      final credited = meter.sample(sample(1000, 1000, offset: 60));
      expect(wall(credited), 1000);
      expect(meter.sample(sample(2000, 2000, offset: 120)), isEmpty);
      expect(wall(meter.sample(sample(3000, 3000, offset: 120))), 1000);
      expect(
        meter.sample(sample(4000, 4000, offset: 120, utc: origin + 86400000)),
        isEmpty,
      );
      expect(credited.single.offsetMinutes, 60);
    },
  );
}
