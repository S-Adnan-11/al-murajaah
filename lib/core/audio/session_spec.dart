/// Source coordinates are absolute; transport coordinates are clip-relative.
class SessionSpec {
  SessionSpec({
    required this.assetId,
    required this.durationMs,
    this.startMs = 0,
    int? endMs,
    this.playCount = 1,
    this.isPassage = false,
    this.gapMs = 0,
    this.speed = 1,
    this.passageId,
    this.passageTitle,
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
    if (!{0, 2000, 5000, 10000}.contains(gapMs) || (!isPassage && gapMs != 0)) {
      throw ArgumentError('Passage gaps must be 0, 2, 5 or 10 seconds.');
    }
    if (!speed.isFinite || speed < .5 || speed > 2.2) {
      throw ArgumentError('Playback speed must be between 0.5 and 2.2.');
    }
  }
  final String assetId;
  final int durationMs, startMs, endMs;
  final int? playCount;
  final bool isPassage;
  final int gapMs;
  final double speed;
  final String? passageId, passageTitle;

  bool get continuesToNext =>
      !isPassage &&
      playCount == 1 &&
      !RegExp(r'^zarami-hafs-114-v[1-9]\d*$').hasMatch(assetId);
  String get repeatOutcome => playCount == null
      ? 'Repeat continuously'
      : continuesToNext
      ? 'Play once, then next surah'
      : 'Play $playCount ${playCount == 1 ? 'time' : 'times'}, then stop';

  /// Settings and native codec padding are not an item's identity.
  bool sameItem(SessionSpec other) =>
      assetId == other.assetId &&
      isPassage == other.isPassage &&
      (!isPassage ||
          (passageId != null || other.passageId != null
              ? passageId == other.passageId
              : startMs == other.startMs && endMs == other.endMs));

  SessionSpec withCount(int? count) => SessionSpec(
    assetId: assetId,
    durationMs: durationMs,
    startMs: startMs,
    endMs: endMs,
    playCount: count,
    isPassage: isPassage,
    gapMs: gapMs,
    speed: speed,
    passageId: passageId,
    passageTitle: passageTitle,
  );
  SessionSpec withPassage(String id, String title) => SessionSpec(
    assetId: assetId,
    durationMs: durationMs,
    startMs: startMs,
    endMs: endMs,
    playCount: playCount,
    isPassage: isPassage,
    gapMs: gapMs,
    speed: speed,
    passageId: id,
    passageTitle: title,
  );
  SessionSpec withOptions({double? speed, int? gapMs}) => SessionSpec(
    assetId: assetId,
    durationMs: durationMs,
    startMs: startMs,
    endMs: endMs,
    playCount: playCount,
    isPassage: isPassage,
    gapMs: gapMs ?? this.gapMs,
    speed: speed ?? this.speed,
    passageId: passageId,
    passageTitle: passageTitle,
  );
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
    'gapMs': gapMs,
    // Omit defaults so existing legacy import identities stay unchanged.
    if (speed != 1) 'speed': speed,
    if (passageId != null) 'passageId': passageId,
    if (passageTitle != null) 'passageTitle': passageTitle,
  };
  factory SessionSpec.fromJson(Map<String, dynamic> json) => SessionSpec(
    assetId: json['assetId'] as String,
    durationMs: json['durationMs'] as int,
    startMs: json['startMs'] as int,
    endMs: json['endMs'] as int,
    playCount: json['playCount'] as int?,
    isPassage: json['isPassage'] as bool,
    gapMs: json['gapMs'] as int? ?? 0,
    speed: (json['speed'] as num?)?.toDouble() ?? 1,
    passageId: json['passageId'] as String?,
    passageTitle: json['passageTitle'] as String?,
  );
}
