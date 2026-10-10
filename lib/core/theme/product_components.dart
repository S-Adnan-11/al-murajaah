import 'package:flutter/material.dart';

class PlaybackStateIndicator extends StatelessWidget {
  const PlaybackStateIndicator({
    super.key,
    required this.label,
    required this.progressing,
    this.loading = false,
  });
  final String label;
  final bool progressing, loading;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Icon(
          loading
              ? Icons.hourglass_top_rounded
              : progressing
              ? Icons.graphic_eq_rounded
              : label == 'Ready to play'
              ? Icons.play_circle_outline_rounded
              : Icons.pause_circle_outline_rounded,
          size: 22,
          color: progressing
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

/// The Settings options box, shared by all simple single-choice selectors.
Future<T?> showAppChoices<T>({
  required BuildContext context,
  required String title,
  required T value,
  required Map<T, String> options,
}) => showDialog<T>(
  context: context,
  builder: (ctx) => SimpleDialog(
    title: Text(title),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Theme.of(ctx).colorScheme.outlineVariant),
    ),
    children: [
      for (final option in options.entries)
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, option.key),
          child: Semantics(
            selected: option.key == value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: option.key == value
                    ? Theme.of(ctx).colorScheme.primaryContainer
                    : null,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    option.key == value
                        ? Icons.check_rounded
                        : Icons.circle_outlined,
                    size: 20,
                    color: option.key == value
                        ? Theme.of(ctx).colorScheme.primary
                        : Theme.of(ctx).colorScheme.outlineVariant,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(option.value)),
                ],
              ),
            ),
          ),
        ),
    ],
  ),
);

class AppChoiceField<T> extends StatelessWidget {
  const AppChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.leading,
    this.semanticLabel,
    this.selectedText,
  });
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T?>? onChanged;
  final Widget? leading;
  final String? semanticLabel;
  final String? selectedText;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onChanged == null
            ? null
            : () async {
                final selected = await showAppChoices<T>(
                  context: context,
                  title: label,
                  value: value,
                  options: options,
                );
                if (selected != null && context.mounted) onChanged!(selected);
              },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            enabled: onChanged != null,
            fillColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Text(
                  selectedText ?? options[value] ?? '',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every number reserves the same column, including at enlarged text sizes.
class SurahNumberBadge extends StatelessWidget {
  const SurahNumberBadge(this.number, {super.key});
  final int number;
  @override
  Widget build(BuildContext context) {
    final side =
        44 *
        (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
          1.0,
          double.infinity,
        );
    final theme = Theme.of(context);
    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary,
      ),
      child: Text(
        '$number',
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class RepeatCountIcon extends StatelessWidget {
  const RepeatCountIcon(this.count, {super.key});
  final int? count;
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final inside = count != null && count! <= 99 && scale <= 1.3;
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.loop_rounded, size: 34, color: colors.primary),
                if (inside)
                  Container(
                    color: colors.primaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (count != null && !inside) ...[
            const SizedBox(width: 8),
            Text('$count'),
          ],
        ],
      ),
    );
  }
}

abstract final class AppSpace {
  static const double small = 8;
  static const double gap = 12;
  static const double section = 24;
  static const page = EdgeInsets.fromLTRB(16, 16, 16, 24);
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        ?action,
      ],
    ),
  );
}

/// A collection item has separate opening and playback actions. At large text
/// sizes the actions move below the content instead of squeezing its name.
class CollectionTile extends StatelessWidget {
  const CollectionTile({
    super.key,
    required this.title,
    required this.details,
    required this.onOpen,
    required this.actions,
    this.leading,
    this.heading,
    this.warning,
    this.starred = false,
  });
  final String title, details;
  final VoidCallback? onOpen;
  final List<Widget> actions;
  final Widget? leading, heading;
  final String? warning;
  final bool starred;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final separate = MediaQuery.textScalerOf(context).scale(16) > 22;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (heading != null) ...[heading!, const SizedBox(height: 4)],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            if (starred)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 3),
                child: Semantics(
                  label: 'Starred',
                  child: Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          details,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (warning != null) ...[
          const SizedBox(height: 8),
          Text(warning!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
    );
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Expanded(child: content),
                  if (!separate) ...[const SizedBox(width: 4), ...actions],
                ],
              ),
              if (separate)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyCollection extends StatelessWidget {
  const EmptyCollection({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup(this.title, {super.key, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: SectionHeading(title),
        ),
        Card(
          semanticContainer: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: children),
          ),
        ),
      ],
    ),
  );
}
