import 'dart:io';

import 'package:flutter/services.dart';

import '../core/audio/prototype_store.dart';
import '../core/audio/sample_catalog.dart';
import '../core/database/app_database.dart';
import '../features/catalog/catalog.dart';
import '../features/activity/listening_recorder.dart';
import '../features/catalog/catalog_repository.dart';
import '../features/downloads/audio_files.dart';
import '../features/downloads/download_queue.dart';
import '../features/downloads/transfer_backend.dart';

class ProductDependencies {
  ProductDependencies(
    this.catalog,
    this.assets,
    this.downloads, {
    this.catalogWarning,
    this.retiredAssets = const {},
    this.listening,
  });
  final Catalog catalog;
  final Map<String, SampleAsset> assets;
  final DownloadQueue downloads;
  final String? catalogWarning;
  final Set<String> retiredAssets;
  final ListeningRecorder? listening;

  static Future<ProductDependencies> open(
    AppDatabase database,
    PrototypeStore store,
  ) async {
    final repository = CatalogRepository(database);
    Catalog catalog;
    String? warning;
    try {
      catalog = Catalog.parse(
        await rootBundle.loadString('assets/catalog/zarami.json'),
      );
      await repository.install(catalog);
    } catch (_) {
      final previous = await repository.load();
      if (previous == null) rethrow;
      catalog = previous;
      warning = 'Your saved library is available. The catalog update could not be applied.';
    }
    final registry = <String, SampleAsset>{
      for (final asset in await repository.retainedPlaybackAssets())
        asset.id: asset,
      for (final asset in samples) asset.id: asset,
      for (final recording in catalog.recordings)
        recording.assetId: recording.audioAsset,
    };
    final files = AudioFiles(
      Directory(store.root.parent.path),
      legacy: store.root,
    );
    final queue = DownloadQueue(
      database,
      files,
      AndroidTransferBackend(),
      registry,
      retiredAssets: await repository.retiredAssets(),
    );
    return ProductDependencies(
      catalog,
      Map.unmodifiable(registry),
      queue,
      catalogWarning: warning,
      retiredAssets: await repository.retiredAssets(),
      listening: ListeningRecorder(database),
    );
  }
}
