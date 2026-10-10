import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../../app/product_dependencies.dart';
import '../../core/audio/prototype_handler.dart';
import '../../core/audio/session_spec.dart';
import '../../core/audio/transport_seek_bar.dart';
import '../../core/theme/arabic_name.dart';
import '../../core/theme/product_components.dart';
import '../catalog/catalog.dart';
import '../catalog/catalog_repository.dart';
import '../activity/activity_screen.dart';
import '../settings/product_settings.dart';
import 'aurora_backdrop.dart';
import 'product_controller.dart';
import 'passage_editor.dart';
import 'saved_sheet.dart';
import 'playback_options.dart';
import 'passage_library.dart';
import 'duration_display.dart';
import 'main_tab_pager.dart';

class ProductShell extends StatefulWidget {
  const ProductShell({
    super.key,
    required this.handler,
    required this.dependencies,
  });
  final PrototypeHandler handler;
  final ProductDependencies dependencies;
  @override
  State<ProductShell> createState() => _ProductShellState();
}

class _ProductShellState extends State<ProductShell> {
  late final controller = ProductController(
    widget.handler,
    widget.dependencies,
  );
  int tab = 0;
  bool player = false, onlyDownloaded = false, onlyFavorites = false;
  bool starredScreen = false, editing = false;
  StreamSubscription<bool>? notificationClicks;
  String query = '';
  final search = TextEditingController();
  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
    unawaited(controller.initialize());
    notificationClicks = AudioService.notificationClicked.listen((clicked) {
      if (clicked && mounted && !editing) {
        Navigator.of(context).popUntil((route) => route is PageRoute);
        starredScreen = false;
        _openCurrent();
      }
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    notificationClicks?.cancel();
    controller.dispose();
    search.dispose();
    super.dispose();
  }

  void _open(CatalogRecording recording) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => player = true);
    unawaited(controller.select(recording));
  }

  void _openCurrent() {
    controller.showActive();
    setState(() => player = true);
  }

  void _openSaved(
    LibraryPassage passage, {
    bool playNow = false,
    bool edit = false,
  }) {
    controller.viewSaved(passage);
    setState(() => player = true);
    if (playNow) unawaited(controller.playViewed(restart: true));
    if (edit) unawaited(_passage(edit: true));
  }

  void _allSurahs() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      tab = 1;
      starredScreen = false;
      player = false;
      onlyFavorites = false;
      onlyDownloaded = false;
      query = '';
      search.clear();
    });
  }

  void _filteredSurahs({bool downloaded = false, bool favorites = false}) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      tab = 1;
      starredScreen = false;
      player = false;
      onlyDownloaded = downloaded;
      onlyFavorites = favorites;
      query = '';
      search.clear();
    });
  }

  void _playRow(CatalogRecording recording) {
    _open(recording);
    unawaited(controller.playViewed(restart: true));
  }

  Future<void> _download(CatalogRecording recording) async {
    try {
      await widget.dependencies.downloads.enqueue(recording.audioAsset);
    } catch (error) {
      if (mounted) _notice('Download could not be queued. Try again.');
    }
  }

  void _notice(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
  Future<void> _delete(CatalogRecording recording) async {
    final local = controller.localSourceInUse(recording);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete downloaded ${recording.name}?'),
        content: Text(
          local
              ? 'Playback will stop. Your saved passages and recording information will remain.'
              : 'Your saved passages and recording information will remain. You can download it again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(local ? 'Stop & delete' : 'Delete download'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final bytes = await controller.deleteAudio(recording, stopLocal: local);
      if (mounted) _notice('${(bytes / 1000000).toStringAsFixed(1)} MB freed');
    } catch (error) {
      if (mounted) _notice('Download could not be deleted. Try again.');
    }
  }

  Future<void> _passage({bool edit = false}) async {
    final view = controller.displayedSpec;
    if (view == null) return;
    final spec = editorSourceSpec(view, controller.selected?.durationMs);
    FocusManager.instance.primaryFocus?.unfocus();
    final existing = controller.saved
        .where((p) => p.id == controller.savedId)
        .firstOrNull;
    PlaybackPreview? preview;
    editing = true;
    bool ownsOriginal() => widget.handler.spec?.sameItem(view) == true;
    bool ownsPreview() =>
        preview?.ownsPlayback == true &&
        widget.handler.spec?.assetId == spec.assetId;
    int listeningPosition() {
      final current = widget.handler.spec;
      return current != null && (ownsOriginal() || ownsPreview())
          ? current
                .relativeToSource(widget.handler.position.inMilliseconds)
                .clamp(0, spec.durationMs)
          : spec.startMs;
    }

    Future<void> audition(int target, {required bool play}) async {
      final start = target.clamp(0, spec.durationMs - 1000);
      await (preview ??= widget.handler.beginPreview()).preview(
        SessionSpec(
          assetId: spec.assetId,
          durationMs: spec.durationMs,
          startMs: start,
          endMs: spec.durationMs,
          isPassage: true,
          speed: spec.speed,
          passageTitle: 'Passage selection preview',
        ),
        autoPlay: play,
      );
      if (target > start && ownsPreview()) {
        await preview!.seek(Duration(milliseconds: target - start));
      }
    }

    Future<void> seekInSurah(int target) async {
      final current = widget.handler.spec;
      final ours = ownsOriginal() || ownsPreview();
      if (current != null &&
          ours &&
          target >= current.startMs &&
          target <= current.endMs) {
        if (ownsPreview()) {
          await preview!.seek(Duration(milliseconds: target - current.startMs));
        } else {
          await controller.seek(target - current.startMs);
        }
      } else {
        await audition(target, play: ours && widget.handler.playing);
      }
    }

    Future<void> toggleSelection() async {
      if (ownsPreview()) {
        await preview!.setPlaying(!widget.handler.playing);
      } else if (ownsOriginal()) {
        await controller.toggle();
      } else {
        await audition(listeningPosition(), play: true);
      }
    }

    final draft = await Navigator.of(context).push<PassageDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ListenableBuilder(
          listenable: Listenable.merge([widget.handler.revision, controller]),
          builder: (_, _) => StreamBuilder<Duration>(
            stream: widget.handler.positionStream,
            builder: (_, _) => PassageEditor(
              spec: spec,
              sourcePositionMs: listeningPosition(),
              recordingName: controller.selected?.name ?? 'Saved recording',
              playing:
                  (ownsOriginal() || ownsPreview()) && widget.handler.playing,
              previewing: ownsPreview(),
              playbackStatus: ownsOriginal()
                  ? controller.status
                  : 'Listen or seek to choose your passage',
              onSeek: seekInSurah,
              onToggle: toggleSelection,
              title: edit ? (existing?.title ?? controller.draftTitle) : '',
              note: edit ? (existing?.row.note ?? controller.draftNote) : '',
              editing: edit,
              active: ownsOriginal(),
              onPreview: (clip) async {
                // A preview is temporary and never saves or edits the main draft.
                await (preview ??= widget.handler.beginPreview()).preview(clip);
              },
            ),
          ),
        ),
      ),
    );
    editing = false;
    if (draft != null && mounted) {
      try {
        if (!draft.play) await preview?.restore();
        await controller.saveDraft(
          draft.spec,
          draft.title,
          note: draft.note,
          create: !edit,
        );
        if (draft.play) {
          preview?.commit();
          await controller.playViewed(restart: true);
        }
        if (mounted) {
          _notice('Passage saved');
        }
      } catch (error) {
        await preview?.restore();
        if (mounted) {
          _notice(
            error is SavedPlaybackUpdateException
                ? 'Passage saved, but the player or library could not be refreshed. Reopen it to check the new range.'
                : 'Passage could not be saved. Your saved passage is unchanged. Please try again.',
          );
        }
      }
    } else {
      await preview?.restore();
      controller.editPassage(view);
    }
  }

  Future<void> _count(int result) async {
    final spec = controller.displayedSpec;
    if (spec == null) return;
    if (mounted) {
      if (result == -2) {
        final input = TextEditingController(text: '${spec.playCount ?? 3}');
        String? error;
        final custom = await showDialog<int>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, refresh) => AlertDialog(
              title: const Text('Custom repeats'),
              scrollable: true,
              content: Semantics(
                label: 'Total plays, including the first play',
                child: TextField(
                  controller: input,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Repeats (1–999)',
                    prefixIcon: const Icon(Icons.loop_rounded),
                    errorText: error,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final n = int.tryParse(input.text);
                    if (n == null || n < 1 || n > 999) {
                      refresh(() => error = 'Enter 1–999');
                      return;
                    }
                    FocusScope.of(ctx).unfocus();
                    Navigator.pop(ctx, n);
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
        );
        if (custom != null) await controller.changeCount(custom);
      } else {
        await controller.changeCount(result == 0 ? null : result);
      }
    }
  }

  Future<void> _options() async {
    final view = controller.displayedSpec;
    if (view == null) return;
    final result = await showModalBottomSheet<SessionSpec>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlaybackOptions(
        spec: view,
        active: controller.viewedIsActive,
        canSleep: controller.viewedIsActive,
        sleepLabel: widget.handler.sleepLabel,
        finishCurrentPass: widget.handler.sleepFinishesPass,
        onSleep: (minutes, finish) => controller.viewedIsActive
            ? widget.handler.setSleepTimer(
                minutes <= 0 ? null : Duration(minutes: minutes),
                afterPass: minutes == -1,
                finishCurrentPass: finish,
              )
            : Future.value(),
      ),
    );
    if (result != null && mounted) {
      try {
        await controller.applyOptions(speed: result.speed, gapMs: result.gapMs);
      } catch (_) {
        if (mounted) _notice('Could not apply playback options. Try again.');
      }
    }
  }

  void _saved({bool starred = false}) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      player = false;
      starredScreen = starred;
      tab = starred ? 0 : 2;
    });
  }

  void _settings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (settingsContext) => ProductSettings(
          db: widget.dependencies.downloads.db,
          listening: widget.dependencies.listening,
          catalogWarning: widget.dependencies.catalogWarning,
          onImported: controller.refreshSaved,
          downloaded: () {
            Navigator.of(settingsContext).pop();
            _filteredSurahs(downloaded: true);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.handler.displaySession;
    return PopScope(
      canPop:
          !player &&
          !starredScreen &&
          tab == 0 &&
          MediaQuery.viewInsetsOf(context).bottom == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (MediaQuery.viewInsetsOf(context).bottom > 0) {
            FocusManager.instance.primaryFocus?.unfocus();
            return;
          }
          setState(() {
            if (player) {
              player = false;
            } else {
              starredScreen = false;
              tab = 0;
            }
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: MediaQuery.textScalerOf(context).scale(16) > 22
              ? 96
              : 64,
          leading: player || starredScreen
              ? IconButton(
                  tooltip: player ? 'Close player' : 'Back to Home',
                  icon: Icon(
                    player
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.arrow_back,
                  ),
                  onPressed: () => setState(() {
                    if (player) {
                      player = false;
                    } else {
                      starredScreen = false;
                    }
                  }),
                )
              : null,
          title: Text(
            player
                ? 'Player'
                : starredScreen
                ? 'Starred'
                : tab == 2
                ? 'Saved passages'
                : tab == 0
                ? (MediaQuery.textScalerOf(context).scale(16) > 22
                      ? 'Home'
                      : 'Al-Muraja’ah')
                : tab == 3
                ? 'Activity'
                : 'Surahs',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (!player && !starredScreen && tab == 0)
              ListeningStreakBadge(
                db: widget.dependencies.downloads.db,
                open: () => setState(() => tab = 3),
              ),
            IconButton(
              tooltip: 'Settings',
              onPressed: _settings,
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            if (controller.message != null)
              MaterialBanner(
                content: Text(controller.message!),
                actions: [
                  TextButton(
                    onPressed: () {
                      controller.message = null;
                      _refresh();
                    },
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Offstage(
                    offstage: player || starredScreen,
                    child: TickerMode(
                      enabled: !player && !starredScreen,
                      child: MainTabPager(
                        index: tab,
                        onChanged: (value) => setState(() => tab = value),
                        pages: [
                          _home(context),
                          _surahs(context),
                          SavedSheet(
                            controller: controller,
                            open: (passage, playNow, edit) => _openSaved(
                              passage,
                              playNow: playNow,
                              edit: edit,
                            ),
                          ),
                          ActivityScreen(
                            db: widget.dependencies.downloads.db,
                            saveError: widget.dependencies.listening?.error,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (player)
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        ListenableBuilder(
                          listenable: widget.handler.revision,
                          builder: (_, _) => StreamBuilder<Duration>(
                            stream: widget.handler.positionStream,
                            builder: (_, _) =>
                                _player(context, controller.selected, spec),
                          ),
                        ),
                      ],
                    ),
                  if (starredScreen && !player)
                    SavedSheet(
                      key: const ValueKey('combined-starred'),
                      controller: controller,
                      combinedStarred: starredScreen,
                      openSurah: (recording, playNow) =>
                          playNow ? _playRow(recording) : _open(recording),
                      open: (passage, playNow, edit) =>
                          _openSaved(passage, playNow: playNow, edit: edit),
                    ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: player
            ? null
            : SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (spec != null)
                      ListenableBuilder(
                        listenable: widget.handler.revision,
                        builder: (_, _) => _miniPlayer(context),
                      ),
                    NavigationBar(
                      selectedIndex: tab,
                      onDestinationSelected: (value) {
                        if (value == 2) {
                          _saved();
                          return;
                        }
                        setState(() {
                          tab = value;
                          starredScreen = false;
                        });
                        if (value == 1) _allSurahs();
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home_rounded),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.menu_book_outlined),
                          selectedIcon: Icon(Icons.menu_book_rounded),
                          label: 'Surahs',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.bookmark_border_rounded),
                          label: 'Saved',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.bar_chart_rounded),
                          label: 'Activity',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _home(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final recent = List<LibraryPassage>.of(controller.saved)
      ..sort((a, b) => b.row.updatedUtcMs.compareTo(a.row.updatedUtcMs));
    return ListView(
      key: const PageStorageKey('product-home'),
      padding: AppSpace.page,
      children: [
        Text(
          'At your own pace',
          style: text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text('A little revision, every day.', style: text.bodyMedium),
        const SizedBox(height: 24),
        ListenableBuilder(
          listenable: widget.handler.revision,
          builder: (context, _) => _continueListening(context),
        ),
        const SizedBox(height: 16),
        TodayActivity(
          db: widget.dependencies.downloads.db,
          open: () => setState(() {
            tab = 3;
            starredScreen = false;
          }),
        ),
        const SizedBox(height: 24),
        Wrap(
          key: const ValueKey('home-library-shortcuts'),
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: _allSurahs,
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Browse all surahs'),
            ),
            TextButton.icon(
              onPressed: () => _saved(starred: true),
              icon: const Icon(Icons.star_border_rounded),
              label: const Text('Starred'),
            ),
            TextButton.icon(
              onPressed: () => _filteredSurahs(downloaded: true),
              icon: const Icon(Icons.download_done_rounded),
              label: const Text('Downloads'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (controller.saved.isNotEmpty) ...[
          SectionHeading(
            'Recent passages',
            action: TextButton(
              onPressed: _saved,
              child: const Text('View all'),
            ),
          ),
          for (final passage in recent.take(3)) ...[
            CollectionTile(
              title: passage.title,
              starred: controller.passageFavorites.contains(passage.id),
              details:
                  '${passage.recordingName} · ${playbackTime(passage.spec.startMs)} – ${playbackTime(passage.spec.endMs)}',
              warning: passage.review
                  ? 'Recording/timestamps need review'
                  : null,
              onOpen: () => _openSaved(passage),
              actions: [
                IconButton(
                  tooltip: 'Play ${passage.title}',
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: () => _openSaved(passage, playNow: true),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.gap),
          ],
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _continueListening(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final current = controller.activeRecording;
    if (widget.handler.displaySession == null) {
      return Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: ListTile(
          leading: const Icon(Icons.headphones_rounded),
          title: const Text('Begin listening'),
          subtitle: const Text('Choose a surah to get started'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _allSurahs,
        ),
      );
    }
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your listening',
                    style: text.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                if (current != null)
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ArabicName(current.arabicName),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text(_activeTitle, style: text.titleLarge)),
                const SizedBox(width: 8),
                PlaybackStateIndicator(
                  label: controller.status,
                  progressing: widget.handler.progressing,
                  loading: widget.handler.loading,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.handler.displaySession!.isPassage
                  ? '${controller.activeName} · Zarami'
                  : 'Zarami · Hafs',
              style: text.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('continue-listening'),
              onPressed: () {
                _openCurrent();
                if (!widget.handler.playRequested && !widget.handler.loading) {
                  unawaited(controller.playViewed());
                }
              },
              icon: Icon(
                widget.handler.playRequested
                    ? Icons.open_in_full_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: const Text('Continue listening'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _surahs(BuildContext context) {
    final queue = widget.dependencies.downloads;
    final rows = widget.dependencies.catalog
        .search(query)
        .where(
          (r) =>
              (!onlyDownloaded || queue.entry(r.assetId).state == 'verified') &&
              (!onlyFavorites || controller.favorites.contains('${r.number}')),
        )
        .toList();
    return CustomScrollView(
      key: const PageStorageKey('product-surahs'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: search,
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    labelText: 'Search surahs',
                    hintText: 'Name or number',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: !onlyDownloaded && !onlyFavorites,
                      onSelected: (_) => _allSurahs(),
                    ),
                    FilterChip(
                      label: const Text('Downloaded'),
                      selected: onlyDownloaded,
                      onSelected: (value) =>
                          setState(() => onlyDownloaded = value),
                    ),
                    FilterChip(
                      label: const Text('Starred'),
                      selected: onlyFavorites,
                      onSelected: (value) =>
                          setState(() => onlyFavorites = value),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Zarami · Hafs · ${rows.length} surahs',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (rows.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyCollection(
              icon: Icons.search_rounded,
              title: 'No matching surahs',
              message: 'Try another name or filter.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.gap),
              itemBuilder: (context, index) {
                final recording = rows[index],
                    download = queue.entry(rows[index].assetId);
                return Column(
                  children: [
                    CollectionTile(
                      title: recording.name,
                      details: recording.available
                          ? '${playbackTime(recording.durationMs!)}${{'none', 'verified'}.contains(download.state) ? '' : ' · ${download.label}'}'
                          : 'Recording under review',
                      heading: Align(
                        alignment: Alignment.centerRight,
                        child: ArabicName(recording.arabicName),
                      ),
                      leading: SurahNumberBadge(recording.number),
                      starred: controller.favorites.contains(
                        '${recording.number}',
                      ),
                      onOpen: recording.available
                          ? () => _open(recording)
                          : null,
                      actions: [
                        if (recording.available)
                          IconButton(
                            tooltip: download.state == 'verified'
                                ? 'Delete download ${recording.name}'
                                : download.active
                                ? 'Cancel download ${recording.name}'
                                : download.state == 'failed'
                                ? 'Retry download ${recording.name}'
                                : 'Download ${recording.name}',
                            icon: Icon(
                              download.state == 'verified'
                                  ? Icons.delete_outline_rounded
                                  : download.active
                                  ? Icons.close_rounded
                                  : download.state == 'failed'
                                  ? Icons.refresh_rounded
                                  : Icons.download_rounded,
                            ),
                            onPressed: download.state == 'verified'
                                ? () => _delete(recording)
                                : download.active
                                ? () => queue.cancel(recording.assetId)
                                : () => _download(recording),
                          ),
                        IconButton(
                          tooltip: 'Play ${recording.name}',
                          onPressed: recording.available
                              ? () => _playRow(recording)
                              : null,
                          icon: const Icon(Icons.play_arrow_rounded),
                        ),
                      ],
                    ),
                    if (download.active)
                      LinearProgressIndicator(
                        value: download.state == 'verifying'
                            ? null
                            : download.received / recording.byteSize,
                      ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _player(
    BuildContext context,
    CatalogRecording? recording,
    SessionSpec? spec,
  ) {
    final text = Theme.of(context).textTheme,
        colors = Theme.of(context).colorScheme;
    spec = controller.displayedSpec;
    final isActive = controller.viewedIsActive;
    final savedPassage = controller.saved
        .where((p) => p.id == controller.savedId)
        .firstOrNull;
    final position = (isActive ? widget.handler.position.inMilliseconds : 0)
        .clamp(0, spec?.lengthMs ?? 0);
    final ready = spec != null;
    final passageTitle = isActive
        ? spec?.passageTitle ?? controller.draftTitle
        : savedPassage?.title ?? controller.draftTitle;
    final download = recording == null
        ? null
        : widget.dependencies.downloads.entry(recording.assetId);
    return SafeArea(
      top: false,
      child: ListView(
        key: const PageStorageKey('product-player'),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [const Color(0xff005351), colors.surface]
                    : [const Color(0xff91ded8), colors.surface],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ListenableBuilder(
                    listenable: widget.handler.revision,
                    builder: (_, _) => AuroraBackdrop(
                      db: widget.dependencies.downloads.db,
                      playing: widget.handler.progressing,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.headphones_rounded,
                        size: 40,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 10),
                      if (recording != null) ArabicName(recording.arabicName),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              spec?.isPassage == true && passageTitle.isNotEmpty
                                  ? passageTitle
                                  : recording?.name ?? 'Saved recording',
                              textAlign: TextAlign.center,
                              style: text.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PlaybackStateIndicator(
                            label: controller.viewedBusy
                                ? 'Loading audio…'
                                : isActive
                                ? controller.status
                                : 'Ready to play',
                            progressing: isActive && widget.handler.progressing,
                            loading:
                                controller.viewedBusy ||
                                (isActive && widget.handler.loading),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (spec?.isPassage == true && passageTitle.isNotEmpty)
                        Text(
                          recording?.name ?? 'Saved recording',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium,
                        ),
                      Text('Zarami · Hafs', style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Chip(
              label: Text(
                spec?.isPassage == true
                    ? 'Passage · ${playbackTime(spec!.startMs)}–${playbackTime(spec.endMs)}'
                    : 'Full surah',
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!isActive && widget.handler.displaySession != null)
            TextButton.icon(
              onPressed: _openCurrent,
              icon: PlaybackStateIndicator(
                label: controller.status,
                progressing: widget.handler.progressing,
                loading: widget.handler.loading,
              ),
              label: Text(_activeTitle, textAlign: TextAlign.center),
            ),
          TransportSeekBar(
            spec: spec,
            positionMs: position,
            enabled:
                ready &&
                isActive &&
                !controller.busy &&
                !widget.handler.loading,
            onSeek: controller.seek,
            semanticFormatter: (value) =>
                '${playbackTime(value.round())} into ${spec?.isPassage == true ? 'passage' : 'surah'}',
            positionLabels: (preview) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(playbackTime(preview))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        spec == null ? '–:––' : playbackTime(spec.lengthMs),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                if (spec?.isPassage == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'In full surah ${playbackTime(spec!.relativeToSource(preview))} · Passage length ${passageLengthLabel(spec.lengthMs)}',
                      textAlign: TextAlign.center,
                      style: text.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: 'Back 10 seconds',
                iconSize: 32,
                onPressed:
                    ready &&
                        isActive &&
                        !controller.busy &&
                        !widget.handler.loading
                    ? () => unawaited(controller.seek(position - 10000))
                    : null,
                icon: const Icon(Icons.replay_10_rounded),
              ),
              SizedBox(
                width: 76,
                height: 76,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  onPressed: ready
                      ? () => unawaited(
                          controller.viewedBusy ||
                                  (isActive && widget.handler.playRequested)
                              ? controller.pause()
                              : controller.playViewed(),
                        )
                      : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        controller.viewedBusy ||
                                (isActive && widget.handler.playRequested)
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 42,
                        semanticLabel:
                            controller.viewedBusy ||
                                (isActive && widget.handler.playRequested)
                            ? 'Pause playback'
                            : isActive && widget.handler.completed
                            ? 'Replay'
                            : 'Play recording',
                      ),
                      if (controller.viewedBusy ||
                          (isActive && widget.handler.loading))
                        const SizedBox(
                          width: 62,
                          height: 62,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Forward 10 seconds',
                iconSize: 32,
                onPressed: ready && isActive && !controller.busy
                    ? () => unawaited(controller.seek(position + 10000))
                    : null,
                icon: const Icon(Icons.forward_10_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: ready ? _passage : null,
                icon: const Icon(Icons.content_cut_rounded),
                label: const Text('Set passage'),
              ),
              if (savedPassage != null)
                TextButton.icon(
                  onPressed: ready ? () => _passage(edit: true) : null,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit passage'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppChoiceField<int>(
                    label: 'Repeats',
                    leading: RepeatCountIcon(spec?.playCount),
                    selectedText: spec?.playCount == null ? 'Continuous' : '',
                    semanticLabel: spec?.playCount == null
                        ? 'Continuous total plays'
                        : '${spec!.playCount} total plays. ${spec.repeatOutcome}',
                    value: spec?.playCount ?? 0,
                    options: {
                      for (final count in {
                        1,
                        3,
                        5,
                        10,
                        33,
                        if (spec?.playCount != null) spec!.playCount!,
                      }.toList()..sort())
                        count: '$count',
                      0: 'Continuous',
                      -2: 'Custom',
                    },
                    onChanged:
                        ready &&
                            !controller.viewedBusy &&
                            !(isActive && widget.handler.loading)
                        ? (count) {
                            if (count != null) unawaited(_count(count));
                          }
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    spec?.repeatOutcome ?? 'Play once, then next surah',
                    style: text.bodySmall,
                  ),
                  if (isActive)
                    Text(controller.countLabel, style: text.labelLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isActive || controller.viewedBusy)
                TextButton.icon(
                  onPressed: () => unawaited(controller.stop()),
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop'),
                ),
              if (isActive)
                TextButton.icon(
                  onPressed: ready && widget.handler.spec != null
                      ? _options
                      : null,
                  icon: const Icon(Icons.bedtime_outlined),
                  label: Text('Sleep: ${widget.handler.sleepLabel}'),
                ),
              TextButton.icon(
                onPressed: ready ? _options : null,
                icon: const Icon(Icons.tune_rounded),
                label: Text('Options · ${spec?.speed ?? 1}×'),
              ),
              if (spec?.isPassage == true)
                TextButton(
                  onPressed: () => unawaited(controller.playFullViewed()),
                  child: const Text('Play full surah'),
                ),
              if (recording != null && spec?.isPassage != true)
                TextButton.icon(
                  onPressed: () => unawaited(controller.favorite(recording)),
                  icon: Icon(
                    controller.favorites.contains('${recording.number}')
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                  ),
                  label: Text(
                    controller.favorites.contains('${recording.number}')
                        ? 'Unstar surah'
                        : 'Star surah',
                  ),
                ),
              if (savedPassage != null)
                TextButton.icon(
                  onPressed: () =>
                      unawaited(controller.favoritePassage(savedPassage)),
                  icon: Icon(
                    controller.passageFavorites.contains(controller.savedId)
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                  ),
                  label: Text(
                    controller.passageFavorites.contains(controller.savedId)
                        ? 'Unstar passage'
                        : 'Star passage',
                  ),
                ),
            ],
          ),
          if (recording != null && download != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(download.label, style: text.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      '${(recording.byteSize / 1000000).toStringAsFixed(1)} MB · Offline playback after download',
                    ),
                    if (download.active)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(
                          value: download.state == 'verifying'
                              ? null
                              : download.received / recording.byteSize,
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (download.state == 'verified')
                      OutlinedButton.icon(
                        onPressed: () => _delete(recording),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete download'),
                      )
                    else if (download.active)
                      OutlinedButton(
                        onPressed: () => widget.dependencies.downloads.cancel(
                          recording.assetId,
                        ),
                        child: const Text('Cancel download'),
                      )
                    else
                      FilledButton.icon(
                        onPressed: () => _download(recording),
                        icon: const Icon(Icons.download_rounded),
                        label: Text(
                          download.state == 'failed'
                              ? 'Retry download'
                              : 'Download',
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String get _activeTitle {
    final title = widget.handler.displaySession?.passageTitle?.trim();
    return widget.handler.displaySession?.isPassage == true
        ? (title == null || title.isEmpty
              ? '${controller.activeName} passage'
              : title)
        : controller.activeName;
  }

  Widget _miniPlayer(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: InkWell(
      key: const ValueKey('mini-player-open'),
      onTap: _openCurrent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            PlaybackStateIndicator(
              label: controller.status,
              progressing: widget.handler.progressing,
              loading: widget.handler.loading,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activeTitle,
                    style: Theme.of(context).textTheme.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.handler.displaySession?.isPassage == true ? '${controller.activeName} · ' : ''}Zarami · ${controller.status}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: widget.handler.playRequested
                  ? 'Pause playback'
                  : 'Resume playback',
              onPressed: () => unawaited(controller.toggleActive()),
              icon: Icon(
                widget.handler.playRequested
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
