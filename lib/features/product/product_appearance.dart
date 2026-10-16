import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/themed_app.dart';
import '../../core/theme/product_components.dart';

class ProductAppearance extends StatelessWidget {
  const ProductAppearance({super.key});
  @override
  Widget build(BuildContext context) {
    final mode = AppearanceScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: AppSpace.page,
          children: [
            Text(
              'Make it comfortable',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a light or dark appearance, or follow your phone.',
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = (MediaQuery.textScalerOf(context).scale(14) / 14)
                    .clamp(1.0, 1.8);
                final columns =
                    ((constraints.maxWidth + 12) / (100 * scale + 12))
                        .floor()
                        .clamp(1, 3);
                final width =
                    (constraints.maxWidth - 12 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    for (final choice in [
                      ThemeMode.light,
                      ThemeMode.dark,
                      ThemeMode.system,
                    ])
                      SizedBox(
                        width: width,
                        child: ThemePreviewTile(
                          mode: choice,
                          selected: mode.value == choice,
                          onTap: mode.saving ? null : () => mode.select(choice),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (mode.saving)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Saving appearance…'),
              ),
            if (mode.saveError != null)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Your appearance could not be saved. Try again.'),
              ),
          ],
        ),
      ),
    );
  }
}

class ThemePreviewTile extends StatelessWidget {
  const ThemePreviewTile({
    super.key,
    required this.mode,
    required this.selected,
    this.onTap,
  });
  final ThemeMode mode;
  final bool selected;
  final VoidCallback? onTap;
  String get label => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System',
  };
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: ExcludeSemantics(
                    child: Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 22,
                      color: selected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AspectRatio(
                  aspectRatio: .72,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: CustomPaint(painter: _MiniatureHome(mode)),
                  ),
                ),
                const SizedBox(height: 12),
                ExcludeSemantics(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniatureHome extends CustomPainter {
  _MiniatureHome(this.mode);
  final ThemeMode mode;
  @override
  void paint(Canvas canvas, Size size) {
    void screen(AppPalette palette, Rect clip) {
      canvas.save();
      canvas.clipRect(clip);
      final w = size.width, h = size.height;
      final paint = Paint();
      void rect(
        double x,
        double y,
        double width,
        double height,
        Color color, [
        double radius = 3,
      ]) {
        paint.color = color;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x * w, y * h, width * w, height * h),
            Radius.circular(radius),
          ),
          paint,
        );
      }

      rect(0, 0, 1, 1, palette.background, 0);
      rect(.10, .08, .36, .035, palette.action);
      rect(.77, .08, .10, .035, palette.accent);
      rect(.10, .20, .69, .035, palette.text);
      rect(.10, .27, .79, .018, palette.secondaryText);
      rect(.10, .32, .61, .018, palette.secondaryText);
      rect(
        .08,
        .43,
        .84,
        .23,
        Color.lerp(palette.surface, palette.action, .10)!,
        5,
      );
      rect(.15, .48, .46, .025, palette.text);
      rect(.15, .56, .40, .055, palette.action);
      rect(.08, .70, .84, .12, palette.surface, 5);
      rect(.15, .75, .52, .02, palette.secondaryText);
      rect(0, .88, 1, .12, palette.surface, 0);
      for (var i = 0; i < 4; i++) {
        rect(
          .12 + i * .23,
          .93,
          .07,
          .025,
          i == 0 ? palette.action : palette.secondaryText,
        );
      }
      canvas.restore();
    }

    final bounds = Offset.zero & size;
    if (mode == ThemeMode.system) {
      screen(
        AppPalette.light,
        Rect.fromLTRB(0, 0, size.width / 2, size.height),
      );
      screen(
        AppPalette.dark,
        Rect.fromLTRB(size.width / 2, 0, size.width, size.height),
      );
    } else {
      screen(
        mode == ThemeMode.dark ? AppPalette.dark : AppPalette.light,
        bounds,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniatureHome oldDelegate) => mode != oldDelegate.mode;
}
