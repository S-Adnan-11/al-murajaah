/// Diagnostic samples only. The other 111 recordings are not fabricated.
class SampleAsset {
  const SampleAsset(this.id, this.name, this.url, this.bytes, this.sha256);
  final String id, name, url, sha256;
  final int bytes;
}

const samples = <SampleAsset>[
  SampleAsset(
    'zarami-hafs-001-v1',
    'Al-Fatihah',
    'https://res.cloudinary.com/yw5eprsc/video/upload/v1790678116/zarami-001.mp3',
    1368372,
    'ccaa00d39b1572d8b88186f7d2a32b26d27688d5c50c3a8fd47cd3eb7c3d4bd2',
  ),
  SampleAsset(
    'zarami-hafs-009-v1',
    'At-Tawbah',
    'https://res.cloudinary.com/yw5eprsc/video/upload/v1790678122/zarami-009.mp3',
    68895110,
    'ab8a6312f18e29332cf311d5412e022c2d2d8baf4dba8f4bdb6193c2a1c4f0fc',
  ),
  SampleAsset(
    'zarami-hafs-104-v1',
    'Al-Humazah',
    'https://res.cloudinary.com/yw5eprsc/video/upload/v1790678116/zarami-104.mp3',
    1191579,
    '60bf6de7f5b417e0a4571946be96c1e348ba7ed10062ff9a47202ef928ae7eca',
  ),
];

SampleAsset assetById(String id) =>
    samples.firstWhere((asset) => asset.id == id);
