import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

Future<void> showConfirmation(
  BuildContext context, {
  required String message,
  bool discovery = false,
}) {
  final reduced = MediaQuery.disableAnimationsOf(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => MediaQuery(
      data: MediaQuery.of(dialogContext).copyWith(disableAnimations: reduced),
      child: ConfirmationOverlay(message: message, discovery: discovery),
    ),
  );
}

/// A bounded, silent celebration. It never owns playback or navigation outside
/// its own route, and leaves no animation or dismissal timer in the background.
class ConfirmationOverlay extends StatefulWidget {
  const ConfirmationOverlay({
    super.key,
    required this.message,
    this.discovery = false,
  });
  final String message;
  final bool discovery;
  @override
  State<ConfirmationOverlay> createState() => _ConfirmationOverlayState();
}

class _ConfirmationOverlayState extends State<ConfirmationOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _motion = AnimationController(
    vsync: this,
    duration: widget.discovery
        ? const Duration(milliseconds: 5500)
        : const Duration(milliseconds: 300),
  );
  Timer? _dismissal;
  bool _started = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dismissal = Timer(
      widget.discovery
          ? const Duration(milliseconds: 5500)
          : const Duration(seconds: 2),
      _close,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
    } else if (!_started) {
      _started = true;
      _motion.forward();
    }
  }

  void _close() {
    if (!mounted) return;
    _dismissal?.cancel();
    final route = ModalRoute.of(context);
    if (route != null && route.isActive) {
      Navigator.of(context).removeRoute(route);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _close();
    }
  }

  @override
  void dispose() {
    _dismissal?.cancel();
    _motion.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Dialog(
      child: Semantics(
        liveRegion: true,
        label: widget.message,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _close,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.discovery && !reduced)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _Confetti(_motion, [
                        colors.primary,
                        colors.secondary,
                        colors.onSurfaceVariant,
                      ]),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.discovery
                          ? Icons.auto_awesome_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 88,
                      color: widget.discovery
                          ? colors.secondary
                          : colors.primary,
                    ),
                    const SizedBox(height: 20),
                    ExcludeSemantics(
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Tap to dismiss', textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Confetti extends CustomPainter {
  _Confetti(this.motion, this.colors) : super(repaint: motion);
  final Animation<double> motion;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    final t = motion.value;
    for (var i = 0; i < 26; i++) {
      final phase = (i * .618) % 1;
      final x = size.width * (.05 + phase * .9);
      final y = size.height * (t * 1.3 - .2 + (i % 5) * .06);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(i + t * math.pi * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -5, 6, 10),
          const Radius.circular(2),
        ),
        Paint()
          ..color = colors[i % colors.length].withValues(
            alpha: (1 - t).clamp(0, 1),
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti oldDelegate) =>
      oldDelegate.motion != motion || oldDelegate.colors != colors;
}
