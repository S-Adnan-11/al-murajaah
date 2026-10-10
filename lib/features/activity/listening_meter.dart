import 'dart:math' as math;

/// A handler-owned observation, never a UI position delta or seek distance.
class ListeningSample {
  const ListeningSample({
    required this.elapsedMs,
    required this.utcMs,
    required this.offsetMinutes,
    required this.epoch,
    required this.pass,
    required this.positionMs,
    required this.lengthMs,
    required this.speed,
    required this.active,
    required this.inGap,
  });
  final int elapsedMs, utcMs, offsetMinutes, epoch, pass, positionMs, lengthMs;
  final double speed;
  final bool active, inGap;
}

class MeasuredListening {
  const MeasuredListening(
    this.date,
    this.offsetMinutes,
    this.wallMs,
    this.utcMs,
  );
  final String date;
  final int offsetMinutes, wallMs, utcMs;
  String get timezonePolicy =>
      'device-local-at-credit:UTC${offsetMinutes >= 0 ? '+' : ''}$offsetMinutes';
}

/// Monotonic wall time, bounded by engine progress at the observed speed.
/// Discontinuities rebase. Adjacent natural passes credit only recitation,
/// including the tail before a gap; silence never earns time.
class ListeningMeter {
  ListeningSample? _previous;
  void reset() => _previous = null;

  List<MeasuredListening> sample(ListeningSample next) {
    final previous = _previous;
    _previous = next;
    if (previous == null ||
        previous.epoch != next.epoch ||
        previous.speed != next.speed ||
        previous.lengthMs != next.lengthMs ||
        previous.offsetMinutes != next.offsetMinutes) {
      return const [];
    }
    final elapsed = next.elapsedMs - previous.elapsedMs;
    if (elapsed <= 0) return const [];
    // Clock changes cannot manufacture duration or relocate old credits.
    if (((next.utcMs - previous.utcMs) - elapsed).abs() > 2000) {
      return const [];
    }
    var progress = 0;
    if (previous.active && !previous.inGap) {
      if (next.pass == previous.pass) {
        progress =
            (next.inGap ? previous.lengthMs : next.positionMs) -
            previous.positionMs;
      } else if (next.pass == previous.pass + 1) {
        progress = previous.lengthMs - previous.positionMs;
        if (next.active && !next.inGap) progress += next.positionMs;
      }
    } else if (previous.inGap &&
        next.active &&
        !next.inGap &&
        next.pass == previous.pass + 1) {
      progress = next.positionMs;
    }
    final expected = elapsed * previous.speed;
    if (progress <= 0 || progress > expected + 250) return const [];
    final wall = math.min(elapsed, (progress / previous.speed).round());
    if (wall <= 0) return const [];
    // Recitation tail belongs before silence, new-pass head belongs after it.
    final start = previous.inGap ? next.utcMs - wall : previous.utcMs;
    return split(start, wall, previous.offsetMinutes);
  }

  static List<MeasuredListening> split(int utcMs, int wallMs, int offset) {
    final result = <MeasuredListening>[];
    var cursor = utcMs;
    var remaining = wallMs;
    while (remaining > 0) {
      final local = DateTime.fromMillisecondsSinceEpoch(
        cursor + offset * 60000,
        isUtc: true,
      );
      final midnight =
          DateTime.utc(
            local.year,
            local.month,
            local.day + 1,
          ).millisecondsSinceEpoch -
          offset * 60000;
      final part = math.min(remaining, midnight - cursor);
      result.add(
        MeasuredListening(
          local.toIso8601String().substring(0, 10),
          offset,
          part,
          cursor,
        ),
      );
      cursor += part;
      remaining -= part;
    }
    return result;
  }
}
