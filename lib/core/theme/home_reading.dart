import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'home_text_controller.dart';

final appRouteObserver = RouteObserver<ModalRoute<dynamic>>();

/// One complete language at a time; no work while covered or outside Home.
class HomeReading extends StatefulWidget {
  const HomeReading({
    super.key,
    required this.active,
    required this.scroll,
    this.preferences,
  });
  final bool active;
  final ScrollController scroll;
  final HomeTextController? preferences;
  static const dwell = Duration(milliseconds: 6500);
  static const english = [
    'Let not! A day fades away...',
    'except that with it is Murāja’ah.',
    "if you're unable to revise, then recite.",
    "if you're unable to recite, then at least listen.",
  ];
  static const arabic = [
    'لَا تَدَعْ يَوْمًا يَمْضِي...',
    'إِلَّا وَلَكَ مَعَ القُرْآنِ صِلَةٌ؛.',
    'فَإِنْ لَمْ تَسْتَطِعْ أَنْ تُرَاجِعَ وَتَتَدَبَّرَ فَاقْرَأْ،',
    'وَإِنْ لَمْ تَسْتَطِعْ أَنْ تَقْرَأَ فَاسْتَمِعْ.',
  ];
  @override
  State<HomeReading> createState() => _HomeReadingState();
}

class _HomeReadingState extends State<HomeReading>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    value: 1,
  );
  Timer? _timer;
  late final _ownedPreferences = HomeTextController();
  HomeTextController get _preferences =>
      widget.preferences ?? _ownedPreferences;
  ModalRoute<dynamic>? _route;
  bool get _arabic => _preferences.arabic;
  bool _visible = false, _covered = false, _swapping = false;
  bool get _enabled =>
      widget.active &&
      _visible &&
      !_covered &&
      (_route?.secondaryAnimation?.isDismissed ?? true) &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.scroll.addListener(_visibility);
    _preferences.addListener(_preferenceChanged);
  }

  void _preferenceChanged() {
    if (!mounted) return;
    setState(() {});
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      _route?.secondaryAnimation?.removeStatusListener(_routeAnimationChanged);
      appRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) {
        appRouteObserver.subscribe(this, route);
        route.secondaryAnimation?.addStatusListener(_routeAnimationChanged);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _visibility());
  }

  @override
  void didUpdateWidget(HomeReading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences != widget.preferences) {
      (oldWidget.preferences ?? _ownedPreferences).removeListener(
        _preferenceChanged,
      );
      _preferences.addListener(_preferenceChanged);
    }
    if (oldWidget.scroll != widget.scroll) {
      oldWidget.scroll.removeListener(_visibility);
      widget.scroll.addListener(_visibility);
    }
    _sync();
    WidgetsBinding.instance.addPostFrameCallback((_) => _visibility());
  }

  void _visibility() {
    if (!mounted) return;
    final box = context.findRenderObject();
    final viewportObject = context
        .findAncestorRenderObjectOfType<RenderAbstractViewport>();
    final viewport = viewportObject is RenderBox
        ? viewportObject as RenderBox
        : null;
    if (box is RenderBox &&
        box.hasSize &&
        viewport is RenderBox &&
        viewport.hasSize) {
      final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
      _visible = top < viewport.size.height && top + box.size.height > 0;
    }
    _sync();
  }

  void _sync() {
    if (!_enabled ||
        !_preferences.alternating ||
        MediaQuery.accessibleNavigationOf(context)) {
      _timer?.cancel();
      _timer = null;
      _fade.stop(canceled: true);
      _fade.value = 1;
      return;
    }
    if (!_swapping &&
        _timer?.isActive != true &&
        !MediaQuery.accessibleNavigationOf(context)) {
      _timer = Timer(HomeReading.dwell, () => _swap(automatic: true));
    }
  }

  Future<void> _swap({bool automatic = false}) async {
    if (!mounted ||
        !_enabled ||
        _swapping ||
        (automatic && !_preferences.alternating)) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    _swapping = true;
    final reduced = MediaQuery.disableAnimationsOf(context);
    try {
      if (!reduced) await _fade.reverse().orCancel;
      if (!mounted || !_enabled || (automatic && !_preferences.alternating)) {
        return;
      }
      // Commit at the fully faded midpoint. Navigation before this point keeps
      // the outgoing language; after it, the incoming language is authoritative.
      await _preferences.commitLanguage(!_arabic);
      if (!reduced) await _fade.forward().orCancel;
    } on TickerCanceled {
      // Leaving the route cancels this transition without a delayed swap.
    } finally {
      _swapping = false;
      if (mounted) _sync();
    }
  }

  @override
  void didPushNext() {
    _covered = true;
    _sync();
  }

  void _routeAnimationChanged(AnimationStatus status) {
    if (mounted) _sync();
  }

  @override
  void didPopNext() {
    _covered = false;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _sync();

  @override
  void dispose() {
    _timer?.cancel();
    widget.scroll.removeListener(_visibility);
    appRouteObserver.unsubscribe(this);
    _route?.secondaryAnimation?.removeStatusListener(_routeAnimationChanged);
    WidgetsBinding.instance.removeObserver(this);
    _fade.dispose();
    _preferences.removeListener(_preferenceChanged);
    _ownedPreferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    TextStyle style(bool arabic, int index) =>
        (index == 0
                ? theme.textTheme.headlineSmall!
                : theme.textTheme.bodyMedium!)
            .copyWith(
              fontWeight: arabic
                  ? (index == 0 ? FontWeight.w700 : FontWeight.w500)
                  : (index == 0 ? FontWeight.w600 : null),
              fontFamily: arabic ? 'Cairo' : null,
              letterSpacing: arabic ? 0 : null,
              height: arabic ? 1.55 : (index == 0 ? 1.15 : 1.45),
            );
    return LayoutBuilder(
      builder: (context, constraints) {
        double height(bool arabic) {
          var total = 7.0;
          final lines = arabic ? HomeReading.arabic : HomeReading.english;
          for (var i = 0; i < lines.length; i++) {
            final painter = TextPainter(
              text: TextSpan(text: lines[i], style: style(arabic, i)),
              textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: constraints.maxWidth);
            total += painter.height;
            painter.dispose();
          }
          return total;
        }

        final lines = _arabic ? HomeReading.arabic : HomeReading.english;
        return Semantics(
          label: _arabic ? 'Read English' : 'Read Arabic',
          onTap: () => _swap(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(height(false), height(true)),
                ),
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < lines.length; i++) ...[
                        if (i == 1) const SizedBox(height: 7),
                        Text(
                          lines[i],
                          textDirection: _arabic
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          textAlign: _arabic ? TextAlign.right : TextAlign.left,
                          locale: _arabic
                              ? const Locale('ar')
                              : const Locale('en'),
                          style: style(_arabic, i),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (MediaQuery.accessibleNavigationOf(context))
                TextButton(
                  onPressed: () => _swap(),
                  child: Text(_arabic ? 'Read English' : 'Read Arabic'),
                ),
            ],
          ),
        );
      },
    );
  }
}
