import 'dart:convert';

/// A fully validated, offline-readable catalog candidate. Loading it does not
/// install database rows, overwrite retained asset metadata or start a player.
class Catalog {
  Catalog._(this.recordings);
  final List<CatalogRecording> recordings;

  factory Catalog.parse(String source) {
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic> ||
        json['schemaVersion'] != 1 ||
        json['editionId'] != 'zarami-hafs-v1' ||
        json['reciter'] != 'Zarami' ||
        json['riwayah'] != 'Hafs' ||
        json['recordings'] is! List) {
      throw const FormatException('Unsupported catalog');
    }
    final rows = (json['recordings'] as List).map((value) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid recording');
      }
      return CatalogRecording._parse(value);
    }).toList();
    if (rows.length != 114 ||
        rows.map((r) => r.number).toSet().length != 114 ||
        rows.map((r) => r.assetId).toSet().length != 114) {
      throw const FormatException('Catalog requires each chapter exactly once');
    }
    rows.sort((a, b) => a.number.compareTo(b.number));
    return Catalog._(List.unmodifiable(rows));
  }

  CatalogRecording chapter(int number) =>
      recordings.singleWhere((r) => r.number == number);

  List<CatalogRecording> search(String query) {
    final key = _searchKey(query);
    return List.unmodifiable(
      recordings.where(
        (r) => [
          '${r.number}',
          r.name,
          r.arabicName,
          ...r.searchAliases,
        ].any((name) => _searchKey(name).contains(key)),
      ),
    );
  }

  static String _searchKey(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[āáàâä]'), 'a')
      .replaceAll(RegExp('[īíìîï]'), 'i')
      .replaceAll(RegExp('[ūúùûü]'), 'u')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[\u064b-\u065f\u0670]'), '')
      .replaceAll(RegExp(r'[^a-z0-9\u0621-\u064a]'), '')
      .replaceAll('aa', 'a')
      .replaceAll('ii', 'i');
}

class CatalogRecording {
  CatalogRecording._({
    required this.number,
    required this.version,
    required this.arabicName,
    required this.name,
    required this.searchAliases,
    required this.assetId,
    required this.url,
    required this.byteSize,
    required this.sha256,
    required this.durationMs,
    required this.available,
    required this.unavailableReason,
  });
  final int number, version, byteSize;
  final String arabicName, name, assetId, sha256;
  final List<String> searchAliases;
  final Uri url;
  final int? durationMs;
  final bool available;
  final String? unavailableReason;

  static CatalogRecording _parse(Map<String, dynamic> json) {
    int integer(String key) {
      if (json[key] is! int || (json[key] as int) <= 0) {
        throw FormatException('Invalid $key');
      }
      return json[key] as int;
    }

    String text(String key) {
      if (json[key] is! String || (json[key] as String).trim().isEmpty) {
        throw FormatException('Invalid $key');
      }
      return json[key] as String;
    }

    final number = integer('number');
    final version = integer('version');
    final suffix = number.toString().padLeft(3, '0');
    final id = text('assetId');
    final rawUrl = text('url');
    final hash = text('sha256');
    final aliases = json['searchAliases'];
    final status = json['availability'];
    final duration = json['durationMs'];
    final reason = json['unavailableReason'];
    // Exact delivery paths reject transforms, credentials, query strings,
    // encoded path tricks and a public ID belonging to a different chapter.
    final path = RegExp(
      '^https://res\\.cloudinary\\.com/yw5eprsc/video/upload/'
      '(?:v[0-9]+/)?zarami-$suffix\\.mp3\$',
    );
    if (number > 114 ||
        id != 'zarami-hafs-$suffix-v$version' ||
        !path.hasMatch(rawUrl) ||
        json['mimeType'] != 'audio/mpeg' ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash) ||
        aliases is! List ||
        aliases.any((a) => a is! String || a.trim().isEmpty) ||
        !{'published', 'unavailable'}.contains(status) ||
        (reason != null && reason is! String) ||
        (duration != null && (duration is! int || duration <= 0)) ||
        (status == 'published' && duration == null) ||
        (status == 'unavailable' &&
            (reason is! String || reason.trim().isEmpty))) {
      throw const FormatException('Invalid identity, delivery or availability');
    }
    return CatalogRecording._(
      number: number,
      version: version,
      arabicName: text('arabicName'),
      name: text('name'),
      searchAliases: List.unmodifiable(aliases.cast<String>()),
      assetId: id,
      url: Uri.parse(rawUrl),
      byteSize: integer('byteSize'),
      sha256: hash,
      durationMs: duration as int?,
      available: status == 'published',
      unavailableReason: reason as String?,
    );
  }
}

String playbackTime(int milliseconds) {
  final total = milliseconds ~/ 1000;
  final seconds = (total % 60).toString().padLeft(2, '0');
  if (total < 3600) return '${total ~/ 60}:$seconds';
  return '${total ~/ 3600}:${(total ~/ 60 % 60).toString().padLeft(2, '0')}:$seconds';
}
