/// Standalone passage-length copy only. Never use for source coordinates,
/// transport time, validation, accounting or persistence.
String passageLengthLabel(int ms) =>
    ms < 60000 ? '${ms ~/ 1000} sec' : '${(ms + 30000) ~/ 60000} min';

/// Listening labels retain V20's completed-minute policy. Split once, after
/// rounding, without changing credited time, goal attainment or stored values.
int listeningMinutes(int ms) => ms <= 0 ? 0 : ms ~/ 60000;
String listeningDuration(int ms) {
  final minutes = listeningMinutes(ms);
  if (ms > 0 && minutes == 0) return '<1 min';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return hours == 0
      ? '$minutes min'
      : remainder == 0
      ? '$hours hr'
      : '$hours hr $remainder min';
}

String listeningEquivalence(int ms) =>
    '${listeningDuration(ms)}\n${listeningMinutes(ms)} min';
