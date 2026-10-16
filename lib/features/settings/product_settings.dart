import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/theme/product_components.dart';
import '../../core/theme/home_text_controller.dart';
import '../activity/listening_recorder.dart';
import '../backup/backup_screen.dart';
import '../backup/metadata_backup.dart';
import '../../core/audio/prototype_handler.dart';
import '../support/developer_screen.dart';
import '../support/feedback_screen.dart';
import '../support/support_store.dart';
import '../support/credits_screen.dart';
import '../support/about_screen.dart';
import '../../core/audio/recording_source.dart';

class ProductSettings extends StatefulWidget {
  const ProductSettings({
    super.key,
    required this.db,
    required this.downloaded,
    this.listening,
    this.onImported,
    this.catalogWarning,
    this.handler,
    this.supportStore,
    this.openRecording,
    this.homeText,
  });
  final AppDatabase db;
  final VoidCallback downloaded;
  final ListeningRecorder? listening;
  final Future<void> Function()? onImported;
  final String? catalogWarning;
  final PrototypeHandler? handler;
  final SupportStore? supportStore;
  final void Function(RecordingSource, bool playNow)? openRecording;
  final HomeTextController? homeText;
  @override
  State<ProductSettings> createState() => _ProductSettingsState();
}

class _ProductSettingsState extends State<ProductSettings> {
  late final _settings = widget.db.select(widget.db.appSettings).watchSingle();
  late final _storage = widget.db
      .select(widget.db.downloads)
      .watch()
      .map(
        (rows) => rows
            .where((d) => d.state == 'verified')
            .fold<int>(0, (sum, d) => sum + d.receivedBytes),
      )
      .distinct();
  bool _saving = false;
  String? _error;
  Future<void> _save(String column, Object value) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.db.customStatement(
        'UPDATE app_settings SET $column=?,updated_utc_ms=? WHERE id=1',
        [value, DateTime.now().toUtc().millisecondsSinceEpoch],
      );
      widget.db.markTablesUpdated([widget.db.appSettings]);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Setting could not be saved. Your previous choice is retained.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _information(String title, String message) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      scrollable: true,
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: StreamBuilder(
      stream: _settings,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Settings unavailable. Reopen to retry.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final settings = snapshot.data!;
        final minutes = settings.dailyGoalMs ~/ 60000;
        final showSwitchIcons =
            MediaQuery.textScalerOf(context).scale(16) <= 22;
        return SafeArea(
          top: false,
          child: ListView(
            padding: AppSpace.page,
            children: [
              if (widget.catalogWarning != null) Text(widget.catalogWarning!),
              if (_error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              SettingsGroup(
                'Appearance',
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Theme'),
                    subtitle: Text(switch (settings.theme) {
                      'dark' => 'Dark',
                      'light' => 'Light',
                      _ => 'Follow system',
                    }),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/appearance'),
                  ),
                  SwitchListTile(
                    secondary: showSwitchIcons
                        ? const Icon(Icons.translate_rounded)
                        : null,
                    title: const Text('Alternate Home text'),
                    value: settings.alternateHomeText == 1,
                    onChanged: _saving
                        ? null
                        : (value) async {
                            final homeText = widget.homeText;
                            if (homeText == null) {
                              await _save('alternate_home_text', value ? 1 : 0);
                              return;
                            }
                            setState(() {
                              _saving = true;
                              _error = null;
                            });
                            try {
                              await homeText.setAlternating(value);
                            } catch (_) {
                              if (mounted) {
                                setState(
                                  () => _error = 'Setting could not be saved. Your previous choice is retained.',
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                  ),
                  SwitchListTile(
                    secondary: showSwitchIcons
                        ? const Icon(Icons.motion_photos_paused_outlined)
                        : null,
                    title: const Text('Reduce motion'),
                    subtitle: const Text('Keep decorative motion still'),
                    value: settings.reducedMotion == 1,
                    onChanged: _saving
                        ? null
                        : (value) => _save('reduced_motion', value ? 1 : 0),
                  ),
                  SwitchListTile(
                    secondary: showSwitchIcons
                        ? const Icon(Icons.blur_on_rounded)
                        : null,
                    title: const Text('Aurora background'),
                    subtitle: const Text('Subtle colour in the player'),
                    value: settings.auroraEnabled == 1,
                    onChanged: _saving
                        ? null
                        : (value) => _save('aurora_enabled', value ? 1 : 0),
                  ),
                ],
              ),
              SettingsGroup(
                'Listening',
                children: [
                  ListTile(
                    leading: const Icon(Icons.timelapse_rounded),
                    title: const Text('Min. fulfillment'),
                    subtitle: Text(minutes == 0 ? 'Off' : '$minutes min'),
                    trailing: const Icon(Icons.expand_more_rounded),
                    onTap: _saving
                        ? null
                        : () async {
                            final value = await showAppChoices<int>(
                              context: context,
                              title: 'Min. fulfillment',
                              value: minutes,
                              options: {
                                for (final option in {
                                  ...[0, 1, 5, 10, 15, 30, 60],
                                  minutes,
                                }.toList()..sort())
                                  option: option == 0 ? 'Off' : '$option min',
                              },
                            );
                            if (value != null && mounted) {
                              await _save('daily_goal_ms', value * 60000);
                            }
                          },
                  ),
                ],
              ),
              SettingsGroup(
                'Downloads & storage',
                children: [
                  SwitchListTile(
                    secondary: showSwitchIcons
                        ? const Icon(Icons.wifi_rounded)
                        : null,
                    title: const Text('Download on Wi-Fi only'),
                    subtitle: const Text('Applies to new downloads'),
                    value: settings.networkPolicy == 'wifi',
                    onChanged: _saving
                        ? null
                        : (value) =>
                              _save('network_policy', value ? 'wifi' : 'any'),
                  ),
                  StreamBuilder(
                    stream: _storage,
                    builder: (context, storage) => ListTile(
                      leading: const Icon(Icons.download_done_rounded),
                      title: const Text('Downloaded recordings'),
                      subtitle: Text(
                        storage.hasError
                            ? 'Storage information unavailable'
                            : '${((storage.data ?? 0) / 1048576).toStringAsFixed(1)} MB on this device',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: widget.downloaded,
                    ),
                  ),
                ],
              ),
              SettingsGroup(
                'Backup & data',
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined),
                    title: const Text('Backup & restore'),
                    subtitle: const Text(
                      'Passages, stars & activity · Audio excluded',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BackupScreen(
                          backup: MetadataBackup(widget.db),
                          listening: widget.listening,
                          onImported: widget.onImported,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SettingsGroup(
                'About & support',
                children: [
                  ListTile(
                    leading: const Icon(Icons.send_outlined),
                    title: const Text('Send feedback'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            FeedbackScreen(store: widget.supportStore),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.code_rounded),
                    title: const Text('Developer'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DeveloperScreen(
                          handler: widget.handler,
                          store: widget.supportStore,
                          openRecording: widget.openRecording,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.record_voice_over_outlined),
                    title: const Text('Credits'),
                    subtitle: const Text('Muhammad Bukar Zarami · Hafs'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreditsScreen(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy & help'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _information(
                      'Privacy & help',
                      'No account, microphone, contacts or location access is needed. Saves, settings, activity and diagnostics stay on your device until you choose to export them.\n\nFeedback sends only your message, category and any app/device details you review and choose to include. It goes through Cloudflare to public GitHub issues. Please do not include personal information. Providers may process request metadata.\n\nStreaming and downloads contact the audio host, which may retain request logs. There is no external analytics or crash reporting.\n\nAurora is optional and off by default. It becomes still when playback pauses, the player is hidden, the app is backgrounded or battery saver applies. Your phone’s reduced motion setting always takes priority.\n\nFor a recording or playback problem, use Audio diagnostics below. Include the surah and what happened when reporting an issue; export diagnostics only if you intend to share them.',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Font and software licenses'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Al-Murāja\'ah',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('About App'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AboutScreen(
                          developer: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DeveloperScreen(
                                handler: widget.handler,
                                store: widget.supportStore,
                                openRecording: widget.openRecording,
                              ),
                            ),
                          ),
                          credits: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CreditsScreen(),
                            ),
                          ),
                          feedback: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  FeedbackScreen(store: widget.supportStore),
                            ),
                          ),
                          licenses: () => showLicensePage(
                            context: context,
                            applicationName: "Al-Murāja'ah",
                          ),
                          privacy: () => _information(
                            'Privacy & help',
                            'Your saves, settings, listening activity and downloads are stored on this device. Audio streams and downloads come from Cloudinary, which may process request metadata.\n\nFeedback is optional and goes through Cloudflare to public GitHub issues. Your message and the app/device details you choose to include are public. Providers may process request metadata. Do not include personal information.\n\nThere are no accounts, advertising, external analytics or crash reporting. Diagnostics stay on the device until you choose to export and share them.',
                          ),
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Audio diagnostics'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/diagnostics'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
