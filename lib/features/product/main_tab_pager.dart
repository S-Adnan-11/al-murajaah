import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Retains visited tabs. Only the main surface participates in horizontal
/// gestures; Android's edge Back area and child horizontal controls take priority.
class MainTabPager extends StatefulWidget {
  const MainTabPager({
    super.key,
    required this.index,
    required this.onChanged,
    required this.pages,
  });
  final int index;
  final ValueChanged<int> onChanged;
  final List<Widget> pages;
  @override
  State<MainTabPager> createState() => _MainTabPagerState();
}

class _MainTabPagerState extends State<MainTabPager> {
  late final _pages = PageController(initialPage: widget.index);
  double _drag = 0;
  bool _swiping = false;
  @override
  void didUpdateWidget(MainTabPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index && !_swiping && _pages.hasClients) {
      _pages.jumpToPage(widget.index);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    gestures: {
      _InteriorHorizontalDrag:
          GestureRecognizerFactoryWithHandlers<_InteriorHorizontalDrag>(
            () => _InteriorHorizontalDrag(),
            (drag) {
              drag.width = MediaQuery.sizeOf(context).width;
              final padding = MediaQuery.systemGestureInsetsOf(context);
              drag.leftEdge = padding.left > 24 ? padding.left : 24;
              drag.rightEdge = padding.right > 24 ? padding.right : 24;
              drag.onStart = (_) => _drag = 0;
              drag.onUpdate = (details) => _drag += details.primaryDelta ?? 0;
              drag.onEnd = (details) async {
                final velocity = details.primaryVelocity ?? 0;
                if (_drag.abs() < 56 && velocity.abs() < 500) return;
                final next =
                    (widget.index +
                            ((_drag == 0 ? velocity : _drag) < 0 ? 1 : -1))
                        .clamp(0, widget.pages.length - 1);
                if (next == widget.index) return;
                FocusManager.instance.primaryFocus?.unfocus();
                _swiping = true;
                widget.onChanged(next);
                await _pages.animateToPage(
                  next,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                );
                _swiping = false;
                // Back or a navigation tap may arrive during the transition.
                if (mounted &&
                    _pages.hasClients &&
                    _pages.page?.round() != widget.index) {
                  _pages.jumpToPage(widget.index);
                }
              };
            },
          ),
    },
    child: PageView(
      controller: _pages,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < widget.pages.length; i++)
          _RetainedTab(key: ValueKey(i), child: widget.pages[i]),
      ],
    ),
  );
}

class _InteriorHorizontalDrag extends HorizontalDragGestureRecognizer {
  double width = 0, leftEdge = 24, rightEdge = 24;
  @override
  bool isPointerAllowed(PointerEvent event) =>
      event.position.dx > leftEdge &&
      event.position.dx < width - rightEdge &&
      super.isPointerAllowed(event);
}

class _RetainedTab extends StatefulWidget {
  const _RetainedTab({super.key, required this.child});
  final Widget child;
  @override
  State<_RetainedTab> createState() => _RetainedTabState();
}

class _RetainedTabState extends State<_RetainedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
