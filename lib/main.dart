import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/audio/prototype_handler.dart';
import 'core/audio/android_diagnostics.dart';
import 'core/audio/prototype_store.dart';
import 'core/audio/sample_catalog.dart';
import 'core/audio/session_spec.dart';

Future<PrototypeHandler> createHandler(PrototypeStore store) async {
  final handler = await AudioService.init<PrototypeHandler>(
    builder: () => PrototypeHandler(store),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'dev.almurajaah.diagnostic.audio',
      androidNotificationChannelName: 'Passage playback',
      androidStopForegroundOnPause: false,
    ),
  );
  await handler.initialize();
  return handler;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DiagnosticBootstrap());
}

/// Draw a focusable Flutter window before storage, native media initialization
/// or retained-file verification. A pending/failed restore stays visible.
class DiagnosticBootstrap extends StatefulWidget {
  const DiagnosticBootstrap({super.key, this.loader});
  final Future<PrototypeHandler> Function(void Function(String))? loader;
  @override
  State<DiagnosticBootstrap> createState() => _DiagnosticBootstrapState();
}

class _DiagnosticBootstrapState extends State<DiagnosticBootstrap> {
  PrototypeHandler? handler;
  Object? error;
  String status = 'Starting audio diagnostics…';
  final clock = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  void _status(String value) {
    if (mounted) setState(() => status = value);
  }

  Future<void> _initialize() async {
    final firstFrameMs = clock.elapsedMilliseconds;
    debugPrint('STARTUP_FIRST_FRAME elapsedMs=$firstFrameMs');
    try {
      final load = widget.loader;
      late PrototypeHandler result;
      if (load != null) {
        result = await load(_status);
      } else {
        _status('Opening saved audio data…');
        final store = await PrototypeStore.open();
        _status('Starting the native player and restoring a paused session…');
        result = await createHandler(store);
      }
      result.recordDiagnostic(
        'startup-ui-firstFrameMs=$firstFrameMs readyMs=${clock.elapsedMilliseconds}',
      );
      if (mounted) setState(() => handler = result);
    } catch (failure) {
      debugPrint(
        'STARTUP_ERROR elapsedMs=${clock.elapsedMilliseconds} $failure',
      );
      if (mounted) setState(() => error = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (handler != null) return DiagnosticApp(handler: handler!);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Al-Muraja'ah • Audio proof")),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              if (error == null) const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Text(error == null ? status : 'Audio setup failed: $error'),
              if (error != null)
                const Text('Close and reopen to retry audio setup.'),
            ],
          ),
        ),
      ),
    );
  }
}

class DiagnosticApp extends StatelessWidget {
  const DiagnosticApp({super.key, required this.handler});
  final PrototypeHandler handler;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "Al-Muraja'ah diagnostic",
    theme: ThemeData(colorSchemeSeed: const Color(0xff087c7b)),
    home: DiagnosticScreen(handler: handler),
  );
}

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key, required this.handler});
  final PrototypeHandler handler;
  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  PrototypeHandler get h => widget.handler;
  SampleAsset selected = samples.first;
  final a = TextEditingController(text: '2');
  final b = TextEditingController(text: '5');
  final title = TextEditingController(text: 'Diagnostic passage');
  int? count = 1;
  bool busy = false;
  bool downloading = false;
  bool exporting = false;
  String message = 'Load a recording to establish duration.';
  List<SavedPassage> saved = [];
  @override
  void initState() {
    super.initState();
    _refreshSaved();
  }

  Future<void> _refreshSaved() async {
    try {
      final result = await h.store.passages();
      if (mounted) setState(() => saved = result);
    } catch (error) {
      if (mounted) {
        setState(() => message = 'Saved passages could not be read: $error');
      }
    }
  }

  Future<void> download() async {
    final asset = selected;
    setState(() => downloading = true);
    var stage = 'downloading';
    final clock = Stopwatch()..start();
    h.recordDiagnostic('download-start ${asset.id}');
    try {
      await h.store.download(asset, (received, total) {
        if (mounted) {
          setState(() {
            message = stage == 'verifying'
                ? 'Verifying ${asset.name} SHA-256… Playback controls remain available.'
                : 'Downloading ${asset.name} ${(received * 100 / total).toStringAsFixed(0)}%';
          });
        }
      }, onStage: (value) => stage = value);
      h.recordDiagnostic(
        'download-verified ${asset.id} elapsedMs=${clock.elapsedMilliseconds}',
      );
      if (mounted) {
        setState(
          () => message =
              'Verified byte size and SHA-256. Load again to use local audio.',
        );
      }
    } catch (error) {
      h.recordDiagnostic('download-failed ${asset.id}: $error');
      if (mounted) setState(() => message = 'Download failed: $error');
    } finally {
      if (mounted) setState(() => downloading = false);
    }
  }

  Future<void> exportFile() async {
    setState(() => exporting = true);
    try {
      final platform = await AndroidDiagnostics.platformEvidence();
      final file = await h.exportDiagnosticFile(platform);
      final saved = await AndroidDiagnostics.saveFile(file);
      if (mounted) {
        setState(
          () => message = saved == null
              ? 'Export canceled; internal complete copy retained.'
              : 'Saved complete diagnostic file: ${file.bytes} bytes; SHA-256 ${file.sha256}',
        );
      }
    } catch (error) {
      if (mounted) setState(() => message = 'Diagnostic export failed: $error');
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> action(Future<void> Function() operation) async {
    // Playback commands end editing. Clear the scope's focus history before
    // disabling buttons, so completion cannot restore focus to A/B and reopen
    // the keyboard after a previously dismissed editing session.
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    try {
      await operation();
    } catch (error) {
      if (mounted) setState(() => message = error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  SessionSpec draft() {
    final duration = h.durations[selected.id];
    if (duration == null) throw StateError('Load this recording first.');
    return SessionSpec(
      assetId: selected.id,
      durationMs: duration,
      startMs: (double.parse(a.text) * 1000).round(),
      endMs: (double.parse(b.text) * 1000).round(),
      playCount: count,
      isPassage: true,
    );
  }

  @override
  void dispose() {
    a.dispose();
    b.dispose();
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Al-Muraja'ah • Audio proof")),
    body: ValueListenableBuilder<int>(
      valueListenable: h.revision,
      builder: (context, _, child) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Stage 1 diagnostic. Physical-phone acceptance is pending.',
          ),
          DropdownButton<SampleAsset>(
            value: selected,
            isExpanded: true,
            items: samples
                .map(
                  (asset) =>
                      DropdownMenuItem(value: asset, child: Text(asset.name)),
                )
                .toList(),
            onChanged: busy
                ? null
                : (asset) => setState(() {
                    selected = asset!;
                    message = 'Load this recording.';
                  }),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () => action(() async {
                    final duration = await h.inspect(selected);
                    if (mounted) {
                      setState(
                        () => message =
                            'Duration ${(duration / 1000).toStringAsFixed(3)} seconds; ${h.usingLocal ? 'verified local' : 'stream'}',
                      );
                    }
                  }),
            child: const Text('Load recording'),
          ),
          DropdownButton<bool>(
            value: h.forceStreaming,
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                value: false,
                child: Text('Prefer verified local file'),
              ),
              DropdownMenuItem(
                value: true,
                child: Text('Force exact URL stream'),
              ),
            ],
            onChanged: busy
                ? null
                : (value) => setState(() {
                    h.forceStreaming = value!;
                    message = 'Source choice applies on Load or Start. Retained files are preserved.';
                  }),
          ),
          Text(message),
          if (h.lastError != null)
            Text(h.lastError!, style: const TextStyle(color: Colors.red)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: a,
                  decoration: const InputDecoration(
                    labelText: 'A: source seconds',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: b,
                  decoration: const InputDecoration(
                    labelText: 'B: source seconds',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          DropdownButton<int>(
            value: count,
            isExpanded: true,
            items: [1, 3, 10, null]
                .map(
                  (n) => DropdownMenuItem<int>(
                    value: n,
                    child: Text(n == null ? 'Continuous' : '$n total passes'),
                  ),
                )
                .toList(),
            onChanged: busy ? null : (n) => setState(() => count = n),
          ),
          FilledButton(
            onPressed: busy ? null : () => action(() => h.start(draft())),
            child: const Text('Start passage / restart at pass 1'),
          ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () => action(() async {
                    final duration =
                        h.durations[selected.id] ?? await h.inspect(selected);
                    await h.start(
                      SessionSpec(assetId: selected.id, durationMs: duration),
                    );
                  }),
            child: const Text('Play full surah once'),
          ),
          Text(
            h.spec == null
                ? 'No session'
                : '${assetById(h.spec!.assetId).name} • ${h.spec!.isPassage ? 'Passage Loop' : 'Full surah'} • pass ${h.pass} of ${h.spec!.playCount ?? 'continuous'} • ${h.usingLocal ? 'local' : 'stream'}',
          ),
          StreamBuilder<Duration>(
            stream: h.positionStream,
            initialData: h.position,
            builder: (context, position) {
              // Read the current event with the current queue index. A retained
              // StreamBuilder value can briefly belong to the previous item.
              final relative = h.position.inMilliseconds;
              final length = h.spec?.lengthMs ?? 1;
              return Column(
                children: [
                  Text(
                    'Scope ${(relative / 1000).toStringAsFixed(1)}s / ${(length / 1000).toStringAsFixed(1)}s; source ${((h.spec?.relativeToSource(relative) ?? 0) / 1000).toStringAsFixed(1)}s',
                  ),
                  Slider(
                    value: relative.clamp(0, length).toDouble(),
                    min: 0,
                    max: length.toDouble(),
                    onChanged: busy || h.spec == null
                        ? null
                        : (v) => action(
                            () => h.seek(Duration(milliseconds: v.round())),
                          ),
                  ),
                ],
              );
            },
          ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: busy
                    ? null
                    : () => action(() => h.playing ? h.pause() : h.play()),
                child: Text(
                  h.completed
                      ? 'Replay'
                      : h.playing
                      ? 'Pause'
                      : 'Play',
                ),
              ),
              OutlinedButton(
                onPressed: busy ? null : () => action(h.stop),
                child: const Text('Stop'),
              ),
            ],
          ),
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Saved passage name'),
          ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () => action(() async {
                    await h.store.savePassage(title.text, draft());
                    await _refreshSaved();
                  }),
            child: const Text('Save passage'),
          ),
          for (final passage in saved)
            ListTile(
              title: Text(passage.title),
              subtitle: Text(assetById(passage.spec.assetId).name),
              onTap: busy
                  ? null
                  : () => action(() async {
                      await h.inspect(assetById(passage.spec.assetId));
                      await h.start(passage.spec);
                    }),
            ),
          OutlinedButton(
            onPressed: busy || downloading ? null : download,
            child: const Text('Download and verify full recording'),
          ),
          const Text(
            'Foreground download experiment; keep this screen open. Gaps, speed controls and sleep timer are pending.',
          ),
          const Divider(),
          Text(
            'Engine: ${h.diagnostics['processingState']} • speed ${h.diagnostics['speed']} • pitch ${h.diagnostics['pitch']}',
          ),
          const Text(
            'Progress and pass describe the player timeline; audible output needs listening verification.',
          ),
          OutlinedButton(
            onPressed: () {
              h.recordDiagnostic('HUMAN_AUDIBLE_PROBLEM');
              setState(
                () => message =
                    'Listening problem timestamp recorded; playback continues.',
              );
            },
            child: const Text('Mark audible problem (keep playing)'),
          ),
          OutlinedButton(
            onPressed: () async {
              final payload = h.diagnosticExport;
              final bytes = utf8.encode(payload);
              await Clipboard.setData(ClipboardData(text: payload));
              final copied = await Clipboard.getData('text/plain');
              final roundTripMatches = copied?.text == payload;
              h.recordDiagnostic(
                'clipboard-export bytes=${bytes.length} readbackMatches=$roundTripMatches',
              );
              if (mounted) {
                setState(
                  () => message =
                      'Recent snapshot copied: ${bytes.length} bytes; SHA-256 ${sha256.convert(bytes)}; clipboard readback ${roundTripMatches ? 'matches' : 'DOES NOT MATCH'}. Use complete-file export for stored logs.',
                );
              }
            },
            child: const Text('Copy audio diagnostics'),
          ),
          OutlinedButton(
            onPressed: exporting ? null : exportFile,
            child: Text(
              exporting
                  ? 'Preparing diagnostic file…'
                  : 'Export complete diagnostic file',
            ),
          ),
          const Text('Recent engine events'),
          for (final line in h.events.value.reversed.take(12))
            Text(line, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}
