/// Standalone passage-length copy only. Never use for source coordinates,
/// transport time, validation, accounting or persistence.
String passageLengthLabel(int ms) =>
    ms < 60000 ? '${ms ~/ 1000} sec' : '${(ms + 30000) ~/ 60000} min';
