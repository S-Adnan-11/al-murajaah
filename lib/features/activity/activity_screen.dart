import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import 'activity_overview.dart';

String localDate(DateTime time) =>
    '${time.year.toString().padLeft(4, '0')}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';

String listeningDuration(int ms) {
  if (ms <= 0) return '0 min';
  if (ms < 60000) return '<1 min';
  return '${ms ~/ 60000} min';
}

String recordedListening(DailyActivityData? day) =>
    day == null ? 'No recorded time' : listeningDuration(day.playedWallMs);

int listeningStreak(List<DailyActivityData> days, DateTime today) {
  final qualified = days
      .where((d) => d.qualified == 1)
      .map((d) => d.localDate)
      .toSet();
  var date = DateTime.utc(today.year, today.month, today.day);
  if (!qualified.contains(localDate(date))) {
    date = date.subtract(const Duration(days: 1));
  }
  var count = 0;
  while (qualified.contains(localDate(date))) {
    count++;
    date = date.subtract(const Duration(days: 1));
  }
  return count;
}

/// Distinct from saved-goal qualification. Use only recorded daily credits;
/// UTC arithmetic here steps calendar dates without DST-length assumptions.
int currentListeningStreak(List<DailyActivityData> days, DateTime today) {
  final qualified = days
      .where((d) => d.playedWallMs >= 60000)
      .map((d) => d.localDate)
      .toSet();
  var date = DateTime.utc(today.year, today.month, today.day);
  if (!qualified.contains(localDate(date))) {
    date = DateTime.utc(date.year, date.month, date.day - 1);
  }
  var count = 0;
  while (qualified.contains(localDate(date))) {
    count++;
    date = DateTime.utc(date.year, date.month, date.day - 1);
  }
  return count;
}

void showListeningStreakDetails(BuildContext context) => showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('Listening streak'),
    content: const Text(
      'One minute of credited listening on a local calendar date qualifies that day. If today is still in progress, your streak through yesterday stays available to continue. A missed day breaks the streak. Only recorded activity counts; daily goals are separate.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(ctx),
        child: const Text('Close'),
      ),
    ],
  ),
);

class ListeningStreakBadge extends StatefulWidget {
  const ListeningStreakBadge({super.key, required this.db, required this.open});
  final AppDatabase db;
  final VoidCallback open;
  @override
  State<ListeningStreakBadge> createState() => _ListeningStreakBadgeState();
}

class _ListeningStreakBadgeState extends State<ListeningStreakBadge>
    with WidgetsBindingObserver {
  late final _days = widget.db.select(widget.db.dailyActivity).watch();
  Timer? _timer;
  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _timer?.cancel();
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: _days,
    builder: (context, snapshot) {
      final count = snapshot.hasData
          ? currentListeningStreak(snapshot.data!, DateTime.now())
          : null;
      return Tooltip(
        message:
            'Listening streak · ${count ?? 'unavailable'} days. Open Activity',
        child: TextButton(
          onPressed: widget.open,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Semantics(
            label:
                'Listening streak: ${count ?? 'unavailable'} days. Open Activity',
            button: true,
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_outlined, size: 20),
                const SizedBox(width: 3),
                Text('${count ?? '–'}'),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> saveDailyGoal(AppDatabase db, int minutes) async {
  if (minutes < 0 || minutes > 240) throw ArgumentError('Invalid daily goal');
  await db.customStatement(
    'UPDATE app_settings SET daily_goal_ms=?,updated_utc_ms=? WHERE id=1',
    [minutes * 60000, DateTime.now().toUtc().millisecondsSinceEpoch],
  );
  db.markTablesUpdated([db.appSettings]);
}

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.db, this.saveError});
  final AppDatabase db;
  final ValueNotifier<String?>? saveError;
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with WidgetsBindingObserver {
  late final _days = widget.db.select(widget.db.dailyActivity).watch();
  late final _settings = widget.db.select(widget.db.appSettings).watchSingle();
  Timer? _dateTimer;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startDateTimer();
  }

  void _startDateTimer() {
    _dateTimer?.cancel();
    _dateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _dateTimer?.cancel();
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _startDateTimer();
    }
  }

  @override
  void dispose() {
    _dateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: _settings,
    builder: (context, settings) => StreamBuilder(
      stream: _days,
      builder: (context, snapshot) {
        if (snapshot.hasError || settings.hasError) {
          return const Center(
            child: Text('Activity is unavailable. Reopen to retry.'),
          );
        }
        if (!snapshot.hasData || !settings.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ActivityOverview(
          days: snapshot.data!,
          configuredGoalMs: settings.data!.dailyGoalMs,
          error: _error,
          saveError: widget.saveError,
          onGoalChanged: (value) async {
            try {
              await saveDailyGoal(widget.db, value);
              if (mounted) setState(() => _error = null);
            } catch (_) {
              if (mounted) {
                setState(() => _error = 'Goal could not be saved. Try again.');
              }
            }
          },
        );
      },
    ),
  );
}

class TodayActivity extends StatefulWidget {
  const TodayActivity({super.key, required this.db, required this.open});
  final AppDatabase db;
  final VoidCallback open;
  @override
  State<TodayActivity> createState() => _TodayActivityState();
}

class _TodayActivityState extends State<TodayActivity>
    with WidgetsBindingObserver {
  late final _days = widget.db.select(widget.db.dailyActivity).watch();
  Timer? _dateTimer;
  void _startDateTimer() {
    _dateTimer?.cancel();
    _dateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startDateTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _dateTimer?.cancel();
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _startDateTimer();
    }
  }

  @override
  void dispose() {
    _dateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: _days,
    builder: (context, snapshot) {
      final date = localDate(DateTime.now());
      final matches = snapshot.data?.where((d) => d.localDate == date);
      final played = matches?.isNotEmpty == true
          ? matches!.first.playedWallMs
          : 0;
      return Card(
        child: ListTile(
          leading: const Icon(Icons.bar_chart_rounded),
          title: const Text('Today’s listening'),
          subtitle: Text(
            snapshot.hasError
                ? 'Activity unavailable'
                : listeningDuration(played),
          ),
          trailing: const Icon(Icons.arrow_forward_rounded),
          onTap: widget.open,
        ),
      );
    },
  );
}
