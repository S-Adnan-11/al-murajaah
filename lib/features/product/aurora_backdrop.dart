import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/database/app_database.dart';

/// Repaints its own boundary only. It has no audio/position timer and never
/// rebuilds player content per frame. Default off; unavailable power state is
/// conservatively static (including platforms without the Android adapter).
class AuroraBackdrop extends StatefulWidget {
  const AuroraBackdrop({super.key, required this.db, required this.playing});
  final AppDatabase db;
  final bool playing;
  @override
  State<AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<AuroraBackdrop>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 32),
  );
  late final StreamSubscription<AppSetting> _settings;
  bool _enabled = false, _reduced = true, _powerSave = true, _foreground = true;
  bool _visible = true, _systemReduced = true, _tickerEnabled = true;
  Timer? _powerTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings = widget.db
        .select(widget.db.appSettings)
        .watchSingle()
        .listen(
          (settings) {
            if (!mounted) return;
            final changed =
                _enabled != (settings.auroraEnabled == 1) ||
                _reduced != (settings.reducedMotion == 1);
            _enabled = settings.auroraEnabled == 1;
            _reduced = settings.reducedMotion == 1;
            _sync();
            if (changed) setState(() {});
          },
          onError: (Object _) {
            _enabled = false;
            _sync();
            if (mounted) setState(() {});
          },
        );
    unawaited(_readPower());
  }

  Future<void> _readPower() async {
    var powerSave = true;
    try {
      powerSave =
          await const MethodChannel('dev.almurajaah/metadata')
              .invokeMethod<bool>('powerSaveMode') ??
          true;
    } catch (_) {
      /* static fallback */
    }
    if (!mounted) return;
    _powerSave = powerSave;
    _sync();
  }

  void _sync() {
    final animate =
        _enabled &&
        !_reduced &&
        !_systemReduced &&
        !_powerSave &&
        _foreground &&
        _visible &&
        _tickerEnabled &&
        widget.playing;
    if (animate) {
      if (!_animation.isAnimating) _animation.repeat();
    } else {
      _animation.stop();
    }
    // Check battery changes only while the optional decoration is visible.
    final checkPower =
        _enabled &&
        !_reduced &&
        !_systemReduced &&
        _foreground &&
        _visible &&
        widget.playing;
    if (checkPower) {
      _powerTimer ??= Timer.periodic(
        const Duration(seconds: 30),
        (_) => unawaited(_readPower()),
      );
    } else {
      _powerTimer?.cancel();
      _powerTimer = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = ModalRoute.of(context)?.isCurrent ?? true;
    _systemReduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _sync();
  }

  @override
  void didUpdateWidget(AuroraBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
    if (_foreground) unawaited(_readPower());
  }

  @override
  void dispose() {
    _settings.cancel();
    _powerTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _enabled
      ? ExcludeSemantics(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _AuroraPainter(
                  _animation,
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).brightness == Brightness.dark,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        )
      : const SizedBox.shrink();
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.animation, this.primary, this.secondary, this.dark)
    : super(repaint: animation);
  final Animation<double> animation;
  final Color primary, secondary;
  final bool dark;
  // Shared topology; only the coordinates change with the slow tide.
  static final _ribbonIndices = <int>[
    for (var column = 0; column < 32; column++)
      for (var row = 0; row < 6; row++) ...[
        column * 7 + row,
        (column + 1) * 7 + row,
        column * 7 + row + 1,
        column * 7 + row + 1,
        (column + 1) * 7 + row,
        (column + 1) * 7 + row + 1,
      ],
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final phase = animation.value * math.pi * 2;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // Vertex alpha fades both sides of each curved ribbon and its ends.
    // Three related curtains share one slow tide, with no blur or saveLayer.
    for (var ribbon = 0; ribbon < 3; ribbon++) {
      final positions = <Offset>[];
      final colors = <Color>[];
      final color = const [
        Color(0xff20b8ae),
        Color(0xff54dddf),
        Color(0xff079eaf),
      ][ribbon];
      final tide = math.sin(phase + ribbon * .32);
      final bend = math.cos(phase + ribbon * .32);
      final alpha = dark ? [.30, .34, .23][ribbon] : [.24, .30, .20][ribbon];
      for (var column = 0; column <= 32; column++) {
        final t = column / 32;
        final x = size.width * t;
        final center =
            size.height *
            (.16 +
                ribbon * .29 +
                tide * .055 +
                math.sin(t * math.pi * 1.7 + bend * .12) *
                    (.11 + ribbon * .018));
        final endFade = math.pow(math.sin(math.pi * t), .7).toDouble();
        for (var row = 0; row <= 6; row++) {
          final across = row / 6;
          positions.add(Offset(x, center + (across - .5) * size.height * .48));
          final edgeFade = math.pow(math.sin(math.pi * across), 2).toDouble();
          colors.add(color.withValues(alpha: alpha * endFade * edgeFade));
        }
      }
      final vertices = ui.Vertices(
        ui.VertexMode.triangles,
        positions,
        colors: colors,
        indices: _ribbonIndices,
      );
      canvas.drawVertices(vertices, BlendMode.dst, Paint());
      vertices.dispose();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) =>
      primary != oldDelegate.primary ||
      secondary != oldDelegate.secondary ||
      dark != oldDelegate.dark;
}
