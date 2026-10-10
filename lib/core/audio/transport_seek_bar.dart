import 'dart:async';

import 'package:flutter/material.dart';

import 'session_spec.dart';

/// A transport gesture previews only presentation. Native seeking happens once
/// on release, including taps, keyboard adjustments and accessibility actions.
class TransportSeekBar extends StatefulWidget {
  const TransportSeekBar({
    super.key,
    required this.spec,
    required this.positionMs,
    required this.enabled,
    required this.onSeek,
    required this.positionLabels,
    required this.semanticFormatter,
    this.selectionStartMs,
    this.selectionEndMs,
    this.selectionMode = false,
  });
  final SessionSpec? spec;
  final int positionMs;
  final bool enabled;
  final Future<void> Function(int) onSeek;
  final Widget Function(int) positionLabels;
  final String Function(double) semanticFormatter;
  final int? selectionStartMs, selectionEndMs;
  final bool selectionMode;

  @override
  State<TransportSeekBar> createState() => _TransportSeekBarState();
}

class _TransportSeekBarState extends State<TransportSeekBar> {
  int? _preview;
  int _request = 0;
  bool _dragging = false;
  int _clamp(double value) =>
      value.round().clamp(0, widget.spec?.lengthMs ?? 1);

  @override
  void didUpdateWidget(TransportSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSpec = oldWidget.spec, current = widget.spec;
    if (!widget.enabled ||
        oldSpec == null ||
        current == null ||
        !oldSpec.sameItem(current) ||
        oldSpec.startMs != current.startMs ||
        oldSpec.endMs != current.endMs) {
      ++_request;
      _preview = null;
      _dragging = false;
    }
  }

  void _begin(double value) {
    ++_request;
    setState(() {
      _dragging = true;
      _preview = _clamp(value);
    });
  }

  void _change(double value) {
    if (_dragging) setState(() => _preview = _clamp(value));
  }

  Future<void> _finish(double value) async {
    if (!_dragging || !widget.enabled) return;
    final request = _request;
    final target = _clamp(value);
    setState(() {
      _dragging = false;
      _preview = target;
    });
    try {
      await widget.onSeek(target);
    } catch (error) {
      debugPrint('TRANSPORT_SEEK_ERROR $error');
      if (mounted && request == _request) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Could not seek. Try again.')),
        );
      }
    } finally {
      if (mounted && request == _request) {
        setState(() => _preview = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = (_preview ?? widget.positionMs).clamp(
      0,
      widget.spec?.lengthMs ?? 1,
    );
    return Column(
      children: [
        Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top:
                    widget.selectionMode ||
                        widget.selectionStartMs != null ||
                        widget.selectionEndMs != null
                    ? 24
                    : 0,
              ),
              child: Slider(
                value: value.toDouble(),
                max: (widget.spec?.lengthMs ?? 1).toDouble(),
                onChangeStart: widget.enabled ? _begin : null,
                onChanged: widget.enabled ? _change : null,
                onChangeEnd: widget.enabled
                    ? (value) => unawaited(_finish(value))
                    : null,
                semanticFormatterCallback: widget.semanticFormatter,
              ),
            ),
            if (widget.selectionStartMs != null ||
                widget.selectionEndMs != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _PassageMarks(
                      widget.spec?.lengthMs ?? 1,
                      widget.selectionStartMs,
                      widget.selectionEndMs,
                      Theme.of(context).colorScheme,
                    ),
                  ),
                ),
              ),
          ],
        ),
        widget.positionLabels(value),
      ],
    );
  }
}

/// Passive boundary marks; the slider's round thumb is the only drag target.
class _PassageMarks extends CustomPainter {
  _PassageMarks(this.duration, this.start, this.end, this.colors);
  final int duration;
  final int? start, end;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    double x(int value) =>
        24 + (size.width - 48) * value.clamp(0, duration) / duration;
    if (start != null && end != null && end! > start!) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x(start!), 60, x(end!), 66),
          const Radius.circular(3),
        ),
        Paint()..color = colors.tertiary,
      );
    }
    for (final mark in [(start, 'A'), (end, 'B')]) {
      if (mark.$1 == null) continue;
      final pin = x(mark.$1!);
      final color = mark.$2 == 'A' ? colors.primary : colors.tertiary;
      canvas.drawLine(
        Offset(pin, 19),
        Offset(pin, 42),
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );
      var labelX = pin - 10;
      if (start != null && end != null && (x(end!) - x(start!)).abs() < 24) {
        labelX = mark.$2 == 'A' ? pin - 22 : pin + 2;
      }
      labelX = labelX.clamp(0, size.width - 20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(labelX, 0, 20, 20),
          const Radius.circular(4),
        ),
        Paint()..color = color,
      );
      final label = TextPainter(
        text: TextSpan(
          text: mark.$2,
          style: TextStyle(
            color: mark.$2 == 'A' ? colors.onPrimary : colors.onTertiary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(labelX + (20 - label.width) / 2, (20 - label.height) / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_PassageMarks old) =>
      duration != old.duration ||
      start != old.start ||
      end != old.end ||
      colors != old.colors;
}
