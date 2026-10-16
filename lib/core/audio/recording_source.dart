import 'sample_catalog.dart';

/// Playback metadata independent of the canonical surah collection.
abstract class RecordingSource {
  const RecordingSource();
  String get assetId;
  String get name;
  int? get durationMs;
  int get byteSize;
  SampleAsset get audioAsset;
  bool get available;
  String? get unavailableReason;
  String get arabicName => '';
  int? get number => null;
  bool get isOrigin => number == null;
  String get credit => [
    audioAsset.reciter,
    if (audioAsset.riwayah != null) audioAsset.riwayah!,
  ].join(' · ');
}
