import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'duration_display.dart';

import '../../core/audio/session_spec.dart';
import '../../core/audio/transport_seek_bar.dart';
import '../catalog/catalog.dart';

class PassageDraft {
  const PassageDraft(this.spec, this.play, this.title, this.note);
  final SessionSpec spec;
  final bool play;
  final String title, note;
}

int parseSourceTime(String text) {
  final parts = text.trim().split(':');
  if (parts.isEmpty || parts.length > 3) throw const FormatException('Time');
  double seconds = 0;
  for (var i = 0; i < parts.length; i++) {
    final n = double.parse(parts[i]);
    if (!n.isFinite ||
        n < 0 ||
        (parts.length > 1 && i > 0 && n >= 60) ||
        (i < parts.length - 1 && n != n.truncateToDouble())) {
      throw const FormatException('Time');
    }
    seconds = seconds * 60 + n;
  }
  return (seconds * 1000).round();
}

/// Full-recording native duration may include codec padding. Editor boundaries
/// use the verified catalog duration; existing passage intervals stay intact.
SessionSpec editorSourceSpec(SessionSpec view, int? catalogDuration) =>
    !view.isPassage && catalogDuration != null
    ? SessionSpec(
        assetId: view.assetId,
        durationMs: catalogDuration,
        playCount: view.playCount,
        speed: view.speed,
      )
    : view;

class PassageEditor extends StatefulWidget {
  const PassageEditor({
    super.key,
    required this.spec,
    this.sourcePositionMs = 0,
    this.title = '',
    this.note = '',
    this.onPreview,
    this.editing = false,
    this.active = false,
    this.recordingName = '',
    this.playing = false,
    this.previewing = false,
    this.playbackStatus = 'Ready to listen',
    this.onSeek,
    this.onToggle,
  });
  final SessionSpec spec;
  final int sourcePositionMs;
  final String title, note;
  final bool editing, active;
  final Future<void> Function(SessionSpec)? onPreview;
  final String recordingName, playbackStatus;
  final bool playing, previewing;
  final Future<void> Function(int)? onSeek;
  final Future<void> Function()? onToggle;
  @override
  State<PassageEditor> createState() => _PassageEditorState();
}

class _PassageEditorState extends State<PassageEditor> {
  late final a = TextEditingController(
    text: (widget.spec.startMs / 1000).toStringAsFixed(3),
  );
  late final b = TextEditingController(
    text: (widget.spec.endMs / 1000).toStringAsFixed(3),
  );
  late final count = TextEditingController(
    text: '${widget.spec.playCount ?? 3}',
  );
  late final title = TextEditingController(text: widget.title),
      note = TextEditingController(text: widget.note);
  late bool continuous = widget.spec.playCount == null;
  late int gap = widget.spec.gapMs;
  late bool aMarked = widget.editing, bMarked = widget.editing;
  late bool naming = widget.editing;
  final nameKey = GlobalKey();
  final nameFocus = FocusNode();
  bool _allowClose = false, _confirming = false;
  bool get _dirty =>
      (!widget.editing && (aMarked || bMarked)) ||
      a.text != (widget.spec.startMs / 1000).toStringAsFixed(3) ||
      b.text != (widget.spec.endMs / 1000).toStringAsFixed(3) ||
      count.text != '${widget.spec.playCount ?? 3}' ||
      continuous != (widget.spec.playCount == null) ||
      gap != widget.spec.gapMs ||
      title.text != widget.title ||
      note.text != widget.note;
  Future<void> _close() async {
    if (_confirming) return;
    FocusScope.of(context).unfocus();
    _confirming = true;
    final discard =
        !_dirty ||
        await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Discard passage edits?'),
                content: Text(
                  widget.editing
                      ? 'Your saved passage stays unchanged.'
                      : 'Your new passage will not be saved.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Keep editing'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Discard edits'),
                  ),
                ],
              ),
            ) ==
            true;
    _confirming = false;
    if (discard && mounted) {
      setState(() => _allowClose = true);
      await Future<void>.delayed(Duration.zero);
      if (mounted) Navigator.pop(context);
    }
  }

  String? error;
  @override
  void dispose() {
    a.dispose();
    b.dispose();
    count.dispose();
    title.dispose();
    note.dispose();
    nameFocus.dispose();
    super.dispose();
  }

  int get start {
    try {
      return parseSourceTime(a.text);
    } catch (_) {
      return -1;
    }
  }

  int get end {
    try {
      return parseSourceTime(b.text);
    } catch (_) {
      return -1;
    }
  }

  void _set(int startMs, int endMs) {
    a.text = (startMs / 1000).toStringAsFixed(3);
    b.text = (endMs / 1000).toStringAsFixed(3);
    setState(() {
      aMarked = true;
      bMarked = true;
      error = null;
    });
  }

  void _mark(bool atEnd, int position) {
    (atEnd ? b : a).text = (position.clamp(0, widget.spec.durationMs) / 1000)
        .toStringAsFixed(3);
    setState(() {
      if (atEnd) {
        bMarked = true;
      } else {
        aMarked = true;
      }
      error = aMarked && bMarked && end - start < 1000
          ? 'Set end B at least one second after start A.'
          : null;
    });
  }

  bool get validRange =>
      aMarked &&
      bMarked &&
      start >= 0 &&
      end <= widget.spec.durationMs &&
      end - start >= 1000;
  String _exact(int value) =>
      '${playbackTime(value)}.${(value % 1000).toString().padLeft(3, '0')}';
  Future<void> _name() async {
    if (!validRange) return;
    setState(() => naming = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted && nameKey.currentContext != null) {
      await Scrollable.ensureVisible(
        nameKey.currentContext!,
        duration: Duration.zero,
      );
      if (mounted) nameFocus.requestFocus();
    }
  }

  SessionSpec _spec() => SessionSpec(
    assetId: widget.spec.assetId,
    durationMs: widget.spec.durationMs,
    startMs: start,
    endMs: end,
    isPassage: true,
    playCount: continuous ? null : int.parse(count.text),
    gapMs: gap,
    speed: widget.spec.speed,
    passageId: widget.spec.passageId,
    passageTitle: widget.spec.passageTitle,
  );
  void _apply(bool play) {
    try {
      if (!validRange) throw ArgumentError('Mark a valid start and end.');
      final spec = _spec();
      if (title.text.trim().isEmpty) {
        throw ArgumentError('Name this passage before saving.');
      }
      FocusScope.of(context).unfocus();
      setState(() => _allowClose = true);
      Navigator.pop(
        context,
        PassageDraft(spec, play, title.text.trim(), note.text),
      );
    } catch (_) {
      setState(
        () => error =
            'Name the passage, set A/B at least one second apart within the ${widget.spec.isOrigin ? 'recording' : 'surah'}, and use 1–999 total plays.',
      );
    }
  }

  Future<void> _preview(bool atEnd) async {
    try {
      final spec = _spec();
      final s = atEnd ? max(spec.startMs, spec.endMs - 2000) : spec.startMs;
      final e = atEnd ? spec.endMs : min(spec.endMs, spec.startMs + 2000);
      FocusScope.of(context).unfocus();
      await widget.onPreview?.call(
        SessionSpec(
          assetId: spec.assetId,
          durationMs: spec.durationMs,
          startMs: s,
          endMs: e,
          isPassage: true,
          speed: spec.speed,
          passageTitle: 'Boundary preview',
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Enter valid boundaries before previewing.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.spec.durationMs;
    final colors = Theme.of(context).colorScheme;
    final full = SessionSpec(
      assetId: widget.spec.assetId,
      durationMs: duration,
    );
    return PopScope<PassageDraft>(
      canPop: _allowClose,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (MediaQuery.viewInsetsOf(context).bottom > 0) {
            FocusScope.of(context).unfocus();
          } else {
            _close();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Cancel passage selection',
            onPressed: _close,
            icon: const Icon(Icons.close),
          ),
          title: Text(widget.editing ? 'Edit passage' : 'Set passage'),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.recordingName.isNotEmpty)
                Text(
                  widget.recordingName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              const SizedBox(height: 12),
              Text(
                '${widget.spec.isOrigin ? 'Recording' : 'Full surah'} timeline',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                widget.previewing
                    ? 'Temporary preview · playback returns when you close'
                    : widget.playbackStatus,
              ),
              TransportSeekBar(
                spec: full,
                selectionMode: true,
                selectionStartMs: aMarked && start >= 0 ? start : null,
                selectionEndMs: bMarked && end >= 0 ? end : null,
                positionMs: widget.sourcePositionMs,
                enabled: widget.onSeek != null,
                onSeek: widget.onSeek ?? (_) async {},
                semanticFormatter: (v) =>
                    '${playbackTime(v.round())} in ${widget.spec.sourceLabel}',
                positionLabels: (value) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${playbackTime(value)} / ${playbackTime(duration)}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _mark(false, value),
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text('Set start · A'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _mark(true, value),
                          icon: const Icon(Icons.flag),
                          label: const Text('Set end · B'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Back 10 seconds',
                    onPressed: widget.onSeek == null
                        ? null
                        : () => unawaited(
                            widget.onSeek!(
                              (widget.sourcePositionMs - 10000).clamp(
                                0,
                                duration,
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.replay_10),
                  ),
                  FilledButton.icon(
                    onPressed: widget.onToggle == null
                        ? null
                        : () => unawaited(widget.onToggle!()),
                    icon: Icon(widget.playing ? Icons.pause : Icons.play_arrow),
                    label: Text(
                      widget.playing
                          ? 'Pause playback'
                          : widget.previewing
                          ? 'Play preview'
                          : widget.active
                          ? 'Play recording'
                          : 'Listen here',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Forward 10 seconds',
                    onPressed: widget.onSeek == null
                        ? null
                        : () => unawaited(
                            widget.onSeek!(
                              (widget.sourcePositionMs + 10000).clamp(
                                0,
                                duration,
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.forward_10),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                !aMarked
                    ? 'Listen or seek, then mark your start with A.'
                    : !bMarked
                    ? 'Keep listening or seek, then mark your end with B.'
                    : 'A/B are draft boundaries until you save.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        aMarked && start >= 0
                            ? 'A · ${_exact(start)}'
                            : 'A · Start not set',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bMarked && end >= 0
                            ? 'B · ${_exact(end)}'
                            : 'B · End not set',
                      ),
                      if (validRange)
                        Text(
                          'Passage length: ${passageLengthLabel(end - start)}',
                        ),
                    ],
                  ),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(error!, style: TextStyle(color: colors.error)),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: !validRange || widget.onPreview == null
                        ? null
                        : () => _preview(false),
                    icon: const Icon(Icons.hearing),
                    label: const Text('Preview start'),
                  ),
                  TextButton.icon(
                    onPressed: !validRange || widget.onPreview == null
                        ? null
                        : () => _preview(true),
                    icon: const Icon(Icons.hearing),
                    label: const Text('Preview end'),
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text('Fine-tune'),
                subtitle: const Text('Exact times and small adjustments'),
                childrenPadding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  Text(
                    'Times are measured from the start of the ${widget.spec.sourceLabel}.',
                  ),
                  for (final field in [
                    (a, 'A · time in ${widget.spec.sourceLabel}', true),
                    (b, 'B · time in ${widget.spec.sourceLabel}', false),
                  ]) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: field.$1,
                      keyboardType: TextInputType.datetime,
                      onChanged: (_) => setState(() {
                        if (field.$3) {
                          aMarked = true;
                        } else {
                          bMarked = true;
                        }
                        error = null;
                      }),
                      decoration: InputDecoration(
                        labelText: field.$2,
                        hintText: 'Seconds or mm:ss.sss',
                      ),
                    ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final delta in [-1000, -100, 100, 1000])
                          TextButton(
                            onPressed: () {
                              final next = (field.$3 ? start : end) + delta;
                              if (field.$3) {
                                _set(next.clamp(0, max(0, end - 1000)), end);
                              } else {
                                _set(
                                  start,
                                  next.clamp(
                                    min(duration, start + 1000),
                                    duration,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              '${field.$3 ? 'A' : 'B'} ${delta > 0 ? '+' : ''}${delta / 1000}s',
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
              if (naming) ...[
                const SizedBox(height: 16),
                Text(
                  widget.editing
                      ? 'Save updates this passage. Playback stays in range, or moves to A.'
                      : 'Save keeps playback. Save & play starts this new passage at A.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  key: nameKey,
                  focusNode: nameFocus,
                  controller: title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Passage name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('Repeat options'),
                  subtitle: Text(
                    continuous
                        ? 'Continuous · ${gap ~/ 1000}s gap'
                        : '${count.text} total plays · ${gap ~/ 1000}s gap',
                  ),
                  children: [
                    Semantics(
                      label: 'Total plays, including the first play',
                      child: TextField(
                        controller: count,
                        enabled: !continuous,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Repeats',
                          prefixIcon: Icon(Icons.loop_rounded),
                        ),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Continuous'),
                      value: continuous,
                      onChanged: (v) => setState(() => continuous = v),
                    ),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: gap,
                      decoration: const InputDecoration(
                        labelText: 'Gap between passes',
                      ),
                      items: [
                        for (final g in [0, 2000, 5000, 10000])
                          DropdownMenuItem(
                            value: g,
                            child: Text('${g ~/ 1000} seconds'),
                          ),
                      ],
                      onChanged: (v) => setState(() => gap = v!),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(onPressed: _close, child: const Text('Cancel')),
                  if (!naming)
                    FilledButton(
                      onPressed: validRange ? _name : null,
                      child: const Text('Name & save'),
                    ),
                  if (naming && !widget.editing)
                    OutlinedButton(
                      onPressed: () => _apply(false),
                      child: const Text('Save'),
                    ),
                  if (naming && widget.editing)
                    FilledButton(
                      onPressed: () => _apply(false),
                      child: const Text('Save'),
                    ),
                  if (naming && !widget.editing)
                    FilledButton(
                      onPressed: () => _apply(true),
                      child: const Text('Save & play'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
