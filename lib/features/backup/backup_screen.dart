import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/themed_app.dart';
import '../../core/theme/product_components.dart';
import '../activity/listening_recorder.dart';
import 'metadata_backup.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({
    super.key,
    required this.backup,
    this.listening,
    this.onImported,
  });
  final MetadataBackup backup;
  final ListeningRecorder? listening;
  final Future<void> Function()? onImported;
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  static const _documents = MethodChannel('dev.almurajaah/metadata');
  bool _busy = false, _applySettings = false;
  BackupPreview? _preview;
  String? _message;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } on FormatException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => _message = 'File backup is not available on this platform yet.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Backup operation could not finish. Your existing data is retained. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _run(() async {
    await widget.listening?.flush();
    final text = await widget.backup.export();
    final base = await getApplicationSupportDirectory();
    final directory = Directory('${base.path}/metadata-backups');
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}/al-murajaah-backup-${DateTime.now().toUtc().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(text, flush: true);
    try {
      final saved = await _documents.invokeMethod<bool>('saveBackup', {
        'path': file.path,
      });
      if (mounted) {
        setState(
          () => _message = saved == true
              ? 'Metadata backup saved and verified. Audio files are excluded.'
              : 'Export cancelled.',
        );
      }
    } finally {
      await file.delete();
    }
  });

  Future<void> _open() => _run(() async {
    if (mounted) setState(() => _preview = null);
    final text = await _documents.invokeMethod<String>('openBackup');
    if (text == null) return;
    final preview = await widget.backup.preview(text);
    if (mounted) {
      setState(() {
        _preview = preview;
        _applySettings = false;
      });
    }
  });

  Future<void> _import() => _run(() async {
    final preview = _preview;
    if (preview == null) return;
    final appearance = AppearanceScope.of(context);
    final result = await widget.backup.import(
      preview,
      applySettings: _applySettings,
    );
    var refreshMessage = '';
    if (_applySettings) {
      final theme = (preview.data['settings'] as BackupRow)['theme'] as String;
      if (!await appearance.select(ThemeMode.values.byName(theme))) {
        refreshMessage = ' Reopen to refresh appearance.';
      }
    }
    try {
      await widget.onImported?.call();
    } catch (_) {
      refreshMessage += ' Reopen to refresh the saved library.';
    }
    if (mounted) {
      setState(() {
        _preview = null;
        _message =
            'Imported ${result.passages} passages and ${result.events} listening entries. ${result.conflicts} conflicting passages kept unchanged. Existing audio and downloads retained.$refreshMessage';
      });
    }
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Backup & restore')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: AppSpace.page,
        children: [
          Text(
            'Keep your library safe',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Back up passages, stars, settings and measured listening time. Audio files are excluded; download recordings separately on a new device.',
          ),
          const SizedBox(height: 12),
          const Text(
            'A backup contains passage names, notes and listening habits. Choose where to save it and share it only as intended.',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.save_alt_rounded),
            label: const Text('Export metadata backup'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _open,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Choose backup to import'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(),
            ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Semantics(liveRegion: true, child: Text(_message!)),
            ),
          if (_preview case final preview?) ...[
            const SizedBox(height: 24),
            Text(
              'Review import',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              '${preview.newPassages} new passages · ${preview.samePassages} unchanged duplicates',
            ),
            Text(
              '${preview.newEvents} new listening entries · ${preview.duplicateEvents} duplicates skipped',
            ),
            Text(
              '${preview.conflicts.length} passage conflicts: your current versions will be kept.',
            ),
            for (final title in preview.conflicts.take(20))
              Text('Keep current: $title'),
            const SizedBox(height: 12),
            const Text(
              'Stars are added. Existing saves, day goals, activity, downloads and playback are preserved. Importing the same backup again does not add listening time twice.',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Apply settings from backup'),
              subtitle: const Text(
                'Off keeps your current theme, motion, goal and download policy.',
              ),
              value: _applySettings,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _applySettings = value),
            ),
            FilledButton(
              onPressed: _busy ? null : _import,
              child: const Text('Import reviewed metadata'),
            ),
            TextButton(
              onPressed: _busy ? null : () => setState(() => _preview = null),
              child: const Text('Cancel import'),
            ),
          ],
        ],
      ),
    ),
  );
}
