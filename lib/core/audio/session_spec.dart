/// Source coordinates are absolute; transport coordinates are clip-relative.
class SessionSpec {
  SessionSpec({
    required this.assetId,
    required this.durationMs,
    this.startMs = 0,
    int? endMs,
    this.playCount = 1,
    this.isPassage = false,
  }) : endMs = endMs ?? durationMs {
    if (durationMs <= 0 ||
        startMs < 0 ||
        this.endMs > durationMs ||
        this.endMs - startMs < 1000) {
      throw ArgumentError(
        'Require 0 <= A < B <= duration, at least one second.',
      );
    }
    if (playCount != null && (playCount! < 1 || playCount! > 999)) {
      throw ArgumentError('Play count must be 1–999, or continuous.');
    }
    if (!isPassage && (startMs != 0 || this.endMs != durationMs)) {
      throw ArgumentError('Full surah must cover the entire recording.');
    }
  }
  final String assetId;
  final int durationMs, startMs, endMs;
  final int? playCount;
  final bool isPassage;
  int get lengthMs => endMs - startMs;
  int sourceToRelative(int sourceMs) => (sourceMs - startMs).clamp(0, lengthMs);
  int relativeToSource(int relativeMs) =>
      startMs + relativeMs.clamp(0, lengthMs);
  int passAtIndex(int index) {
    if (index < 0 || (playCount != null && index >= playCount!)) {
      throw RangeError('Queue index outside the series.');
    }
    return index + 1;
  }

  Map<String, dynamic> toJson() => {
    'assetId': assetId,
    'durationMs': durationMs,
    'startMs': startMs,
    'endMs': endMs,
    'playCount': playCount,
    'isPassage': isPassage,
  };
  factory SessionSpec.fromJson(Map<String, dynamic> json) => SessionSpec(
    assetId: json['assetId'] as String,
    durationMs: json['durationMs'] as int,
    startMs: json['startMs'] as int,
    endMs: json['endMs'] as int,
    playCount: json['playCount'] as int?,
    isPassage: json['isPassage'] as bool,
  );
}
