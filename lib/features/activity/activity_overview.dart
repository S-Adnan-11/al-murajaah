import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/theme/product_components.dart';
import 'activity_screen.dart';

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
  });
  final List<DailyActivityData> days;
  final int configuredGoalMs;
  final ValueChanged<int> onGoalChanged;
  final DateTime? now;
  final String? error;
  final ValueNotifier<String?>? saveError;

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
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today’s listening', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  listeningDuration(played),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                if (goal > 0) ...[
                  Semantics(
                    label:
                        'Daily goal ${(played / goal * 100).clamp(0, 100).round()} percent',
                    child: LinearProgressIndicator(
                      value: (played / goal).clamp(0, 1),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    today?.qualified == 1
                        ? 'Today’s goal reached'
                        : '${listeningDuration(goal)} daily goal',
                  ),
                ] else
                  const Text('Daily goal is off'),
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
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current listening streak',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                '${currentListeningStreak(days, date)} ${currentListeningStreak(days, date) == 1 ? 'day' : 'days'}',
                                style: theme.textTheme.titleLarge,
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
                Text(
                  listeningDuration(weeklyMs),
                  style: theme.textTheme.headlineSmall,
                ),
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
                Text(
                  'Tap a day for its listening time.',
                  style: theme.textTheme.bodySmall,
                ),
                ExpansionTile(
                  key: const PageStorageKey('daily-listening-details'),
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Daily details'),
                  children: [
                    for (final day in week)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${localizations.formatMediumDate(day)} · ${recordedListening(byDate[localDate(day)])}',
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
                '$streak consecutive goal ${streak == 1 ? 'day' : 'days'}',
              ),
              subtitle: Text(
                streak > 0 && today?.qualified != 1
                    ? 'Continue today. Each day qualifies by reaching its saved goal.'
                    : 'Each day qualifies by reaching its saved listening goal.',
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        AppChoiceField<int>(
          value: minutes,
          label: 'Daily goal',
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
        Text(
          'A day saves its goal with its first listening credit. Changes leave saved daily goals unchanged.',
          style: theme.textTheme.bodySmall,
        ),
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
              'Only time spent playing recitation counts. Pauses, buffering, repeat gaps and seek jumps are excluded. Speed changes do not multiply minutes.',
            ),
            SizedBox(height: 12),
            Text(
              'Days use your device’s local date when measured. Credited dates stay fixed when you travel. Each day saves its goal on its first listening credit; later goal changes do not rewrite it.',
            ),
            SizedBox(height: 12),
            Text(
              'Tracking began with the Activity update. Earlier listening is not reconstructed. A missing day says “No recorded time”; it cannot establish whether you listened before tracking began.',
            ),
            SizedBox(height: 12),
            Text(
              'Totals update about every 15 seconds and when playback stops. A sudden shutdown can lose the last unsaved interval.',
            ),
            SizedBox(height: 12),
            Text(
              'Listening time measures playback, not attention or memorization. Activity stays on this device unless you export a backup.',
            ),
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
      message: label,
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
