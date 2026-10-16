import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

import '../../core/audio/prototype_handler.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/product_components.dart';
import 'support_content.dart';
import 'support_store.dart';
import 'confirmation_overlay.dart';
import '../../core/audio/recording_source.dart';

class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({
    super.key,
    this.handler,
    this.store,
    this.openRecording,
  });
  final PrototypeHandler? handler;
  final SupportStore? store;
  final void Function(RecordingSource, bool playNow)? openRecording;
  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen>
    with WidgetsBindingObserver {
  late final Future<SupportStore> _store = widget.store == null
      ? SupportStore.open()
      : Future.value(widget.store);
  int _taps = 0;
  bool _found = false, _opening = false;
  Timer? _idle;
  int _visit = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final data = await (await _store).read();
      if (mounted) setState(() => _found = data['originDiscovered'] == true);
    } catch (_) {
      /* Discovery remains available if local preferences fail. */
    }
  }

  void _tap() {
    _idle?.cancel();
    _idle = Timer(const Duration(seconds: 4), () => _taps = 0);
    if (++_taps == 7) unawaited(_discover());
  }

  Future<void> _discover() async {
    if (_opening) return;
    _taps = 0;
    _idle?.cancel();
    _opening = true;
    final visit = _visit;
    try {
      final store = await _store;
      await store.update('originDiscovered', true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discovery could not be remembered on this device.'),
          ),
        );
      }
    }
    if (mounted &&
        visit == _visit &&
        ModalRoute.of(context)?.isCurrent == true &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.hidden) {
      setState(() => _found = true);
      await _openStory(celebrate: true);
    }
    _opening = false;
  }

  Future<void> _openStory({bool celebrate = false}) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => OriginScreen(
            handler: widget.handler,
            openRecording: widget.openRecording,
            celebrate: celebrate,
          ),
        ),
      );
  Future<void> _website(String url) async {
    try {
      await const MethodChannel('dev.almurajaah/support')
          .invokeMethod<void>('openWebsite', url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Website could not be opened.')),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      ++_visit;
      _idle?.cancel();
      _taps = 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Developer')),
    body: ListView(
      padding: AppSpace.page,
      children: [
        Center(
          child: Semantics(
            label: 'Al-Murāja\'ah mark',
            button: true,
            customSemanticsActions: {
              const CustomSemanticsAction(label: 'Discover Where it began'):
                  _discover,
            },
            child: InkWell(
              key: const ValueKey('developer-mark'),
              onTap: _tap,
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: BrandMark(size: 160),
              ),
            ),
          ),
        ),
        Text(
          'Al-Murāja\'ah.',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const Text('Developed by S. Adnan', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const Text('s-adnan.dev'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => _website(developerWebsite),
          ),
        ),
        const SizedBox(height: AppSpace.gap),
        Card(
          child: ListTile(
            leading: const Icon(Icons.code_rounded),
            title: const Text('GitHub'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => _website(developerGithub),
          ),
        ),
        if (_found)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton.icon(
              onPressed: _openStory,
              icon: const Icon(Icons.auto_stories_outlined),
              label: const Text('Where it began'),
            ),
          ),
      ],
    ),
  );
}

class OriginScreen extends StatefulWidget {
  const OriginScreen({
    super.key,
    this.handler,
    this.openRecording,
    this.celebrate = false,
  });
  final PrototypeHandler? handler;
  final void Function(RecordingSource, bool playNow)? openRecording;
  final bool celebrate;
  @override
  State<OriginScreen> createState() => _OriginScreenState();
}

class _OriginScreenState extends State<OriginScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.celebrate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          unawaited(
            showConfirmation(
              context,
              message: 'Masha Allah, you found it!',
              discovery: true,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Where it began')),
      body: ListView(
        padding: AppSpace.page,
        children: [
          const Center(child: BrandMark(size: 112)),
          const SizedBox(height: AppSpace.section),
          for (final paragraph in originStory.split('\n\n')) ...[
            Builder(
              builder: (context) {
                final arabic = RegExp(r'^[\u0600-\u06ff]')
                    .hasMatch(paragraph.trimLeft());
                final quote = paragraph.startsWith('“');
                return Container(
                  padding: quote ? const EdgeInsets.all(16) : EdgeInsets.zero,
                  decoration: quote
                      ? BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border(
                            left: BorderSide(
                              color: theme.colorScheme.secondary,
                              width: 3,
                            ),
                          ),
                        )
                      : null,
                  child: Text.rich(
                    storySpan(paragraph),
                    textDirection: arabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: arabic
                        ? theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'NotoSansArabic',
                            height: 1.8,
                            color: theme.colorScheme.secondary,
                          )
                        : quote
                        ? theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          )
                        : theme.textTheme.bodyLarge,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: AppSpace.gap),
          const SectionHeading('Recitations'),
          for (final recording in storyRecordings.where((r) => r.valid)) ...[
            CollectionTile(
              title: recording.name,
              details: recording.asset.reciter,
              onOpen: widget.openRecording == null
                  ? null
                  : () => widget.openRecording!(recording, false),
              actions: [
                IconButton(
                  tooltip: 'Play ${recording.name}',
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: widget.openRecording == null
                      ? null
                      : () => widget.openRecording!(recording, true),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.gap),
          ],
        ],
      ),
    );
  }
}

/// Preserve the owner's text exactly; only existing date spans are styled.
TextSpan storySpan(String paragraph) {
  final spans = <InlineSpan>[];
  var end = 0;
  for (final match in RegExp(
    r'\b\d{2}\.\d{2}\.\d{4}\b',
  ).allMatches(paragraph)) {
    spans.add(TextSpan(text: paragraph.substring(end, match.start)));
    spans.add(
      TextSpan(
        text: match.group(0),
        style: const TextStyle(fontStyle: FontStyle.italic),
      ),
    );
    end = match.end;
  }
  spans.add(TextSpan(text: paragraph.substring(end)));
  return TextSpan(children: spans);
}
