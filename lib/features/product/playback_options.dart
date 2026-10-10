import 'package:flutter/material.dart';

import '../../core/audio/session_spec.dart';

class PlaybackOptions extends StatefulWidget {
  const PlaybackOptions({
    super.key,
    required this.spec,
    required this.active,
    required this.sleepLabel,
    required this.finishCurrentPass,
    required this.canSleep,
    required this.onSleep,
  });
  final SessionSpec spec;
  final bool active, finishCurrentPass, canSleep;
  final String sleepLabel;
  final Future<void> Function(int minutes, bool finishPass) onSleep;
  @override
  State<PlaybackOptions> createState() => _PlaybackOptionsState();
}

class _PlaybackOptionsState extends State<PlaybackOptions> {
  late double speed = widget.spec.speed;
  late int gap = widget.spec.gapMs;
  late bool finish = widget.finishCurrentPass;
  late String sleep = widget.sleepLabel;
  bool changingTimer = false;
  String? error;
  Future<void> _timer(int minutes) async {
    setState(() {
      changingTimer = true;
      error = null;
    });
    try {
      await widget.onSleep(minutes, finish);
      if (mounted) {
        setState(
          () => sleep = minutes == 0
              ? 'Off'
              : minutes == -1
              ? 'After this pass'
              : '$minutes minutes',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Could not change the sleep timer. Try again.');
      }
    } finally {
      if (mounted) setState(() => changingTimer = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playback options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              widget.active
                  ? 'Speed keeps your pass and position. Changing a gap starts a new series at pass 1.'
                  : 'Options change this viewed draft. Explicit Play starts it.',
            ),
            const SizedBox(height: 16),
            const Text('Playback speed'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final rate in <double>{
                  .75,
                  .9,
                  1,
                  1.25,
                  1.50,
                  1.85,
                  2.00,
                  2.20,
                  speed,
                }.toList()..sort())
                  ChoiceChip(
                    label: Text('${rate.toStringAsFixed(2)}×'),
                    selected: speed == rate,
                    onSelected: (_) => setState(() => speed = rate),
                  ),
              ],
            ),
            if (widget.spec.isPassage) ...[
              const SizedBox(height: 12),
              const Text('Gap between passes'),
              Wrap(
                spacing: 8,
                children: [
                  for (final ms in [0, 2000, 5000, 10000])
                    ChoiceChip(
                      label: Text('${ms ~/ 1000}s'),
                      selected: gap == ms,
                      onSelected: (_) => setState(() => gap = ms),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(
                  context,
                  widget.spec.withOptions(speed: speed, gapMs: gap),
                );
              },
              child: const Text('Apply speed and gap'),
            ),
            if (widget.active && widget.canSleep) ...[
              const Divider(height: 32),
              Text('Sleep timer · active audio: $sleep'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final m in [0, 15, 30, 60, -1])
                    OutlinedButton(
                      onPressed: !widget.canSleep || changingTimer
                          ? null
                          : () => _timer(m),
                      child: Text(
                        m == 0
                            ? 'Off'
                            : m == -1
                            ? 'After this pass'
                            : '$m minutes',
                      ),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Finish current pass at deadline'),
                subtitle: const Text(
                  'When off, pause immediately at the deadline. Applies when you select a timed duration.',
                ),
                value: finish,
                onChanged: changingTimer
                    ? null
                    : (v) => setState(() => finish = v),
              ),
            ],
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
  );
}
