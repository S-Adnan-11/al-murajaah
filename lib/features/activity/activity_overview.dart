import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/theme/product_components.dart';
import 'activity_screen.dart';
import '../product/duration_display.dart';

/// Presentation only: previews can supply isolated data without recording time.
class ActivityOverview extends StatelessWidget {
  const ActivityOverview({
    super.key,
    required this.days,
    required this.configuredGoalMs,
    required this.onGoalChanged,
    this.now,
    this.error,
    this.saveError,
    this.bestStreak = 0,
  });
  final List<DailyActivityData> days;
  final int configuredGoalMs;
  final ValueChanged<int> onGoalChanged;
  final DateTime? now;
  final String? error;
  final ValueNotifier<String?>? saveError;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final date = now ?? DateTime.now();
    final byDate = {for (final day in days) day.localDate: day};
    final today = byDate[localDate(date)];
    final played = today?.playedWallMs ?? 0;
    final goal = today?.goalMs ?? configuredGoalMs;
    final week = List.generate(
      7,
      (i) => DateTime.utc(date.year, date.month, date.day - 6 + i),
    );
    final weeklyMs = week.fold<int>(
      0,
      (total, day) => total + (byDate[localDate(day)]?.playedWallMs ?? 0),
    );
    final peak = week.fold<int>(
      1,
      (total, day) =>
          math.max(total, byDate[localDate(day)]?.playedWallMs ?? 0),
    );
    final streak = listeningStreak(days, date);
    final theme = Theme.of(context);
    final minutes = configuredGoalMs ~/ 60000;
    final localizations = MaterialLocalizations.of(context);
    return ListView(
      key: const PageStorageKey('activity'),
      padding: AppSpace.page,
      children: [
        Card(
          key: const ValueKey('today-listening-summary'),
          semanticContainer: false,
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ListeningTotal(
                  played,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                if (goal > 0) ...[
                  Semantics(
                    label:
                        'Fulfillment ${(played / goal * 100).clamp(0, 100).round()} percent',
                    child: LinearProgressIndicator(
                      value: (played / goal).clamp(0, 1),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Semantics(
                  label: goal == 0
                      ? 'Target off'
                      : played >= goal
                      ? 'Fulfilled'
                      : 'Fulfilling',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      Icon(
                        goal > 0 && played >= goal
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: goal > 0 && played >= goal
                            ? theme.brightness == Brightness.dark
                                  ? const Color(0xff7bdc9a)
                                  : const Color(0xff166534)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          goal == 0
                              ? 'Target off'
                              : played >= goal
                              ? 'Fulfilled'
                              : '${listeningDuration(goal)} fulfillment',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => showListeningStreakDetails(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_outlined,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Streak', style: theme.textTheme.bodyMedium),
                              Text(
                                '${currentListeningStreak(days, date)} ${currentListeningStreak(days, date) == 1 ? 'day' : 'days'}',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                children: [
                                  Icon(
                                    Icons.emoji_events_outlined,
                                    size: 18,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  Text(
                                    'Best Streak · $bestStreak ${bestStreak == 1 ? 'day' : 'days'}',
                                    style: theme.textTheme.labelLarge,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.info_outline_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (weeklyMs == 0) ...[
          const SizedBox(height: 16),
          Text(
            'No listening recorded this week. Play a surah or passage to begin.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 24),
        const SectionHeading('Last 7 days'),
        Card(
          semanticContainer: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListeningTotal(weeklyMs, style: theme.textTheme.headlineSmall),
                Text('Total listening time', style: theme.textTheme.bodySmall),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final scale =
                        MediaQuery.textScalerOf(context).scale(12) / 12;
                    final width = math.max(
                      constraints.maxWidth / 7,
                      40 * scale,
                    );
                    return SingleChildScrollView(
                      key: const PageStorageKey('weekly-listening-chart'),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final day in week)
                            _DayBar(
                              date: day,
                              record: byDate[localDate(day)],
                              today: localDate(day) == localDate(date),
                              peak: peak,
                              width: width,
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  key: const PageStorageKey('daily-listening-details'),
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Details'),
                  children: [
                    for (final day in week)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Tooltip(
                            message: listeningEquivalence(
                              byDate[localDate(day)]?.playedWallMs ?? 0,
                            ),
                            triggerMode: TooltipTriggerMode.tap,
                            child: Text(
                              '${localizations.formatMediumDate(day)} · ${recordedListening(byDate[localDate(day)])}',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (goal > 0) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.event_available_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                '$streak consecutive target ${streak == 1 ? 'fulfillment' : 'fulfillment'}',
              ),
              subtitle: Text(
                streak > 0 && today?.qualified != 1
                    ? 'Keep the consistency, every day counts.'
                    : 'Start now, every day counts.',
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        AppChoiceField<int>(
          value: minutes,
          label: 'Min. fulfillment',
          options: {
            for (final value in {
              ...[0, 1, 5, 10, 15, 30, 60],
              minutes,
            }.toList()..sort())
              value: value == 0 ? 'Off' : '$value min',
          },
          onChanged: (value) {
            if (value != null) onGoalChanged(value);
          },
        ),
        const SizedBox(height: 8),
        if (error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        if (saveError != null)
          ValueListenableBuilder(
            valueListenable: saveError!,
            builder: (_, value, _) => value == null
                ? const SizedBox.shrink()
                : Semantics(
                    liveRegion: true,
                    child: Text(
                      value,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
          ),
        const SizedBox(height: 16),
        ExpansionTile(
          key: const PageStorageKey('listening-methodology'),
          tilePadding: EdgeInsets.zero,
          title: const Text('How listening time works'),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Only time spent playing recitation counts. Pauses, buffering, repeat gaps, speed changes and seek jumps are excluded.',
            ),
            SizedBox(height: 12),
            Text(
              'Days use your device’s local date when measured. Credited dates stay fixed when you travel. Each day saves its target on its first listening credit.',
            ),
            SizedBox(height: 12),
            Text('A missed day is  “0 min”.'),
          ],
        ),
      ],
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.date,
    required this.record,
    required this.today,
    required this.peak,
    required this.width,
  });
  final DateTime date;
  final DailyActivityData? record;
  final bool today;
  final int peak;
  final double width;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label =
        '${MaterialLocalizations.of(context).formatFullDate(date)}${today ? ', today' : ''}: ${recordedListening(record)}';
    return Tooltip(
      message: '$label\n${listeningEquivalence(record?.playedWallMs ?? 0)}',
      triggerMode: TooltipTriggerMode.tap,
      excludeFromSemantics: true,
      child: Semantics(
        label: label,
        child: ExcludeSemantics(
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                SizedBox(
                  height: 96,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 20,
                      height: record == null
                          ? 3
                          : math.max(3, 96 * record!.playedWallMs / peak),
                      decoration: BoxDecoration(
                        color: record == null
                            ? colors.outlineVariant
                            : today
                            ? colors.primary
                            : colors.primary.withValues(alpha: .50),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  const [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ][date.weekday - 1],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: today ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(
                  height: 12,
                  child: today
                      ? Center(
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
