import 'package:flutter/foundation.dart';

import '../../app/product_dependencies.dart';
import '../../core/audio/prototype_handler.dart';
import '../../core/audio/session_spec.dart';
import '../../core/database/foundation_repository.dart';
import '../catalog/catalog.dart';
import '../catalog/catalog_repository.dart';
import 'passage_library.dart';

class SavedPlaybackUpdateException implements Exception {}

/// Viewed metadata is independent of the single handler's active session.
class ProductController extends ChangeNotifier {
  ProductController(this.handler, this.dependencies) {
    dependencies.downloads.addListener(_changed);
    handler.revision.addListener(_activeChanged);
    showActive();
  }
  final PrototypeHandler handler;
  final ProductDependencies dependencies;
  late final library = PassageLibrary(dependencies.downloads.db);
  CatalogRecording? selected;
  SessionSpec? viewedSpec;
  String? savedId;
  String draftTitle = '', draftNote = '';
  List<LibraryPassage> saved = [];
  final favorites = <String>{}, passageFavorites = <String>{};
  String? message;
  bool busy = false, _closed = false;
  int _intent = 0;
  SessionSpec? _pendingSpec;
  SessionSpec? _lastActive;
  void _activeChanged() {
    final active = handler.displaySession;
    if (active != null &&
        _lastActive != null &&
        !active.sameItem(_lastActive!) &&
        viewedSpec?.sameItem(_lastActive!) == true) {
      // Follow an automatic transition only from the previously active view.
      selected = _recording(active.assetId);
      viewedSpec = active;
      savedId = active.passageId;
      draftTitle = active.passageTitle ?? '';
      _changed();
    }
    if (active != null) _lastActive = active;
  }

  bool get viewedBusy =>
      busy && viewedSpec != null && _pendingSpec?.sameItem(viewedSpec!) == true;
  CatalogRecording? _recording(String? id) {
    for (final r in dependencies.catalog.recordings) {
      if (r.assetId == id) return r;
    }
    return null;
  }

  CatalogRecording? get activeRecording =>
      _recording(handler.displaySession?.assetId);
  String get activeName =>
      activeRecording?.name ??
      dependencies.assets[handler.displaySession?.assetId]?.name ??
      'Saved recording';
  bool get viewedIsActive =>
      viewedSpec != null &&
      handler.displaySession != null &&
      viewedSpec!.sameItem(handler.displaySession!);
  SessionSpec? get displayedSpec =>
      viewedIsActive ? handler.displaySession : viewedSpec;
  String get activeLabel => handler.displaySession?.isPassage == true
      ? '${handler.displaySession?.passageTitle ?? 'Passage'} · $activeName'
      : 'Full surah · $activeName';
  void _changed() {
    if (!_closed) notifyListeners();
  }

  Future<void> initialize() async {
    try {
      await library.importLegacy(handler.store);
      if (_closed) return;
      await refreshSaved();
      if (_closed) return;
      await dependencies.downloads.initialize();
    } catch (error) {
      debugPrint('PRODUCT_RESTORE_ERROR $error');
      message = 'Some saved library information could not be opened. Try reopening the app.';
    }
    _changed();
  }

  Future<void> refreshSaved() async {
    saved = await library.read();
    favorites.clear();
    passageFavorites.clear();
    for (final row
        in await dependencies.downloads.db
            .select(dependencies.downloads.db.favorites)
            .get()) {
      (row.type == 'surah' ? favorites : passageFavorites).add(row.targetId);
    }
    _changed();
  }

  Future<void> select(CatalogRecording recording) async {
    selected = recording;
    viewedSpec = recording.durationMs == null
        ? null
        : SessionSpec(
            assetId: recording.assetId,
            durationMs: recording.durationMs!,
          );
    savedId = null;
    message = recording.available ? null : recording.unavailableReason;
    draftTitle = '';
    draftNote = '';
    _changed();
  }

  void showActive() {
    _lastActive = handler.displaySession;
    selected = activeRecording;
    viewedSpec = handler.displaySession;
    savedId = handler.displaySession?.passageId;
    draftTitle = handler.displaySession?.passageTitle ?? '';
    _changed();
  }

  void viewSaved(LibraryPassage passage) {
    selected = _recording(passage.row.assetId);
    viewedSpec = passage.spec;
    savedId = passage.id;
    draftTitle = passage.title;
    draftNote = passage.row.note ?? '';
    message = passage.review
        ? 'Recording replaced. Review these saved timestamps; the original save is preserved. Original verified offline audio can still be used.'
        : null;
    _changed();
  }

  Future<void> playViewed({bool restart = false}) async {
    final request = restart ? viewedSpec : displayedSpec;
    if (request == null) return;
    final token = ++_intent;
    busy = true;
    _pendingSpec = request;
    message = null;
    _changed();
    try {
      if (!restart &&
          viewedIsActive &&
          !handler.completed &&
          handler.lastError == null &&
          handler.diagnostics['processingState'] != 'idle') {
        await handler.play();
      } else {
        await handler.loadAndStart(request);
      }
      if (token == _intent &&
          viewedSpec?.sameItem(request) == true &&
          handler.spec?.assetId == request.assetId) {
        viewedSpec = handler.spec;
      }
    } catch (error) {
      debugPrint('PRODUCT_PLAY_ERROR $error');
      if (token == _intent) message = 'Could not play this recording. Check your connection or verified download and try again.';
    } finally {
      if (token == _intent) {
        busy = false;
        _pendingSpec = null;
        _changed();
      }
    }
  }

  Future<void> pause() async {
    ++_intent;
    busy = false;
    _changed();
    await handler.pause();
  }

  Future<void> stop() async {
    ++_intent;
    busy = false;
    _changed();
    await handler.stop();
  }

  Future<void> toggle() =>
      viewedIsActive && (handler.playing || busy) ? pause() : playViewed();
  Future<void> toggleActive() =>
      handler.playing || handler.playRequested || busy
      ? pause()
      : handler.play();
  Future<void> seek(int relativeMs) async {
    if (viewedIsActive && !busy) {
      await handler.seek(Duration(milliseconds: relativeMs));
    }
  }

  void editPassage(SessionSpec draft) {
    viewedSpec = draft;
    _changed();
  }

  Future<void> applyPassage(int a, int b, int? count, {int gapMs = 0}) async {
    final view = displayedSpec;
    if (view == null) return;
    viewedSpec = SessionSpec(
      assetId: view.assetId,
      durationMs: view.durationMs,
      startMs: a,
      endMs: b,
      playCount: count,
      isPassage: true,
      gapMs: gapMs,
      speed: view.speed,
      passageId: view.passageId,
      passageTitle: view.passageTitle,
    );
    await playViewed(restart: true);
  }

  Future<void> changeCount(int? count) async {
    final view = displayedSpec;
    if (view == null) return;
    final active = viewedIsActive;
    message = null;
    viewedSpec = view.withCount(count);
    if (active) {
      await handler.updateCount(count);
      if (count != null && count <= handler.pass && !handler.completed) {
        message = view.isPassage || count != 1
            ? 'The new total is already reached. This play will finish, then stop.'
            : 'This play will finish, then continue to the next surah.';
      }
    }
    _changed();
  }

  Future<void> saveDraft(
    SessionSpec draft,
    String title, {
    String? note,
    bool create = false,
  }) async {
    final id = await library.save(
      title,
      draft,
      id: create ? null : savedId,
      note: note,
    );
    final revised = draft.withPassage(id, title.trim());
    savedId = id;
    viewedSpec = revised;
    draftTitle = title.trim();
    draftNote = note ?? '';
    try {
      await refreshSaved();
      message = null;
      if (!create) {
        await handler.applySavedPassage(revised);
        if (revised.playCount != null &&
            revised.playCount! <= handler.pass &&
            handler.spec?.sameItem(revised) == true &&
            !handler.completed) {
          message = 'The new total is already reached. This play will finish, then stop.';
        }
      }
    } catch (_) {
      throw SavedPlaybackUpdateException();
    }
  }

  Future<void> renamePassage(LibraryPassage passage, String title) async {
    await library.save(
      title,
      passage.spec,
      id: passage.id,
      note: passage.row.note,
    );
    final active = handler.spec;
    if (active?.sameItem(passage.spec) == true) {
      await handler.applySavedPassage(
        active!.withPassage(passage.id, title.trim()),
      );
    }
    await refreshSaved();
  }

  Future<void> save(
    String title, {
    String? note,
    bool duplicate = false,
  }) async {
    final view = displayedSpec;
    if (view == null) return;
    draftTitle = title;
    draftNote = note ?? '';
    final id = await library.save(
      title,
      view,
      id: duplicate ? null : savedId,
      note: note,
    );
    savedId = id;
    await refreshSaved();
    viewedSpec = saved.singleWhere((p) => p.id == id).spec;
  }

  Future<void> applyOptions({required double speed, required int gapMs}) async {
    final view = displayedSpec;
    if (view == null) return;
    final active = viewedIsActive;
    viewedSpec = view.withOptions(speed: speed, gapMs: gapMs);
    if (active && !busy) {
      final token = ++_intent;
      busy = true;
      _pendingSpec = view;
      _changed();
      try {
        await handler.updateOptions(speed: speed, gapMs: gapMs);
      } finally {
        if (token == _intent) {
          busy = false;
          _pendingSpec = null;
          _changed();
        }
      }
    }
    _changed();
  }

  Future<void> playFullViewed() async {
    final view = viewedSpec;
    if (view == null) return;
    viewedSpec = SessionSpec(
      assetId: view.assetId,
      durationMs: view.durationMs,
    );
    savedId = null;
    draftTitle = '';
    draftNote = '';
    await playViewed();
  }

  Future<void> favorite(CatalogRecording recording) async {
    final id = '${recording.number}',
        value = !favorites.contains('${recording.number}');
    await FoundationRepository(dependencies.downloads.db)
        .setFavorite('surah', id, value);
    await refreshSaved();
  }

  Future<void> favoritePassage(LibraryPassage p) async {
    await FoundationRepository(dependencies.downloads.db)
        .setFavorite('passage', p.id, !passageFavorites.contains(p.id));
    await refreshSaved();
  }

  bool localSourceInUse(CatalogRecording recording) =>
      (handler.spec?.assetId == recording.assetId && handler.usingLocal) ||
      (handler.loading && handler.displaySession?.assetId == recording.assetId);

  Future<int> deleteAudio(
    CatalogRecording recording, {
    bool stopLocal = false,
  }) async {
    if (localSourceInUse(recording)) {
      if (!stopLocal) {
        throw StateError('Confirm Stop & delete for the active source');
      }
      await stop();
    }
    return dependencies.downloads.delete(recording.audioAsset);
  }

  String get status {
    if (busy || handler.loading) return 'Loading audio…';
    if (handler.lastError != null) return 'Playback paused after an error';
    if (handler.completed) return 'Completed';
    final state = handler.diagnostics['processingState'];
    if (state == 'buffering' || state == 'loading') return 'Loading audio…';
    if (handler.inGap) return 'Between passes';
    return handler.progressing ? 'Playing' : 'Paused';
  }

  String get countLabel {
    final spec = handler.displaySession;
    if (spec == null) return 'Play once';
    final pass = handler.displaySession == handler.spec ? handler.pass : 1;
    return spec.playCount == null
        ? 'Pass $pass · Continuous'
        : 'Pass $pass of ${spec.playCount}';
  }

  @override
  void dispose() {
    _closed = true;
    dependencies.downloads.removeListener(_changed);
    handler.revision.removeListener(_activeChanged);
    super.dispose();
  }
}
