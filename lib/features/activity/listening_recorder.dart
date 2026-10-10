import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/database/app_database.dart';
import '../../core/database/foundation_repository.dart';
import '../product/passage_library.dart';
import 'listening_meter.dart';

class _Credit {
  _Credit(
    this.id,
    this.session,
    this.asset,
    this.passage,
    this.speed,
    this.startedUtcMs,
    this.interval,
    this.goalMs,
  );
  final String id, session, asset;
  final String? passage;
  final double speed;
  final int startedUtcMs, goalMs;
  MeasuredListening interval;
  bool locked = false;
}

/// Observes the sole audio handler. SQL work never enters its command queue.
/// Retries reuse exact IDs; a hard kill loses only the uncommitted interval.
class ListeningRecorder {
  ListeningRecorder(this.db) {
    _settings = db
        .select(db.appSettings)
        .watchSingle()
        .listen(
          (settings) => _goalMs = settings.dailyGoalMs,
          onError: (Object failure) =>
              error.value = 'Activity settings unavailable.',
        );
  }
  final AppDatabase db;
  final ListeningMeter _meter = ListeningMeter();
  final ValueNotifier<String?> error = ValueNotifier(null);
  late final StreamSubscription<AppSetting> _settings;
  final List<_Credit> _pending = [];
  Future<void> _writes = Future.value();
  int _goalMs = 300000, _lastFlush = 0, _startedUtcMs = 0;
  String? _item, _session;
  bool _closed = false;

  void observe(ListeningSample sample, String asset, String? passage) {
    if (_closed) return;
    final item = '$asset/${passage ?? ''}';
    if (_item != item) {
      _meter.reset();
      _item = item;
      _session = null;
      _startedUtcMs = 0;
    }
    final intervals = _meter.sample(sample);
    if (intervals.isNotEmpty) {
      _session ??= PassageLibrary.newId();
      if (_startedUtcMs == 0) _startedUtcMs = intervals.first.utcMs;
      for (final interval in intervals) {
        final last = _pending.isEmpty ? null : _pending.last;
        if (last != null &&
            !last.locked &&
            last.session == _session &&
            last.speed == sample.speed &&
            last.goalMs == _goalMs &&
            last.interval.date == interval.date &&
            last.interval.offsetMinutes == interval.offsetMinutes) {
          last.interval = MeasuredListening(
            interval.date,
            interval.offsetMinutes,
            last.interval.wallMs + interval.wallMs,
            last.interval.utcMs,
          );
          continue;
        }
        _pending.add(
          _Credit(
            PassageLibrary.newId(),
            _session!,
            asset,
            passage,
            sample.speed,
            _startedUtcMs,
            interval,
            _goalMs,
          ),
        );
      }
    }
    if (!sample.active || sample.elapsedMs - _lastFlush >= 15000) {
      _lastFlush = sample.elapsedMs;
      unawaited(flush());
    }
  }

  void rebase() {
    _meter.reset();
    unawaited(flush());
  }

  Future<void> flush() {
    // Do not accumulate queued copies or write per playback position event.
    final result = _writes.then((_) async {
      if (_pending.isEmpty) return;
      final batch = List<_Credit>.of(_pending);
      for (final credit in batch) {
        credit.locked = true;
      }
      try {
        await db.transaction(() async {
          for (final credit in batch) {
            final passageExists =
                credit.passage == null ||
                await (db.select(db.savedPassages)
                          ..where((p) => p.id.equals(credit.passage!)))
                        .getSingleOrNull() !=
                    null;
            await db.customStatement(
              'INSERT OR IGNORE INTO listening_sessions '
              '(id,asset_id,passage_id,started_utc_ms,speed) VALUES (?,?,?,?,?)',
              [
                credit.session,
                credit.asset,
                passageExists ? credit.passage : null,
                credit.startedUtcMs,
                credit.speed,
              ],
            );
            await FoundationRepository(db).creditMeasuredInterval(
              eventId: credit.id,
              sessionId: credit.session,
              localDate: credit.interval.date,
              timezonePolicy: credit.interval.timezonePolicy,
              wallMs: credit.interval.wallMs,
              goalMs: credit.goalMs,
              utcMs: credit.interval.utcMs,
            );
          }
        });
        final ids = batch.map((c) => c.id).toSet();
        _pending.removeWhere((c) => ids.contains(c.id));
        error.value = null;
      } catch (_) {
        // Audio remains usable. Pending measured credits retry with same IDs.
        error.value =
            'Listening time could not be saved. Retrying automatically.';
      }
    });
    _writes = result;
    return result;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _settings.cancel();
    await flush();
    error.dispose();
  }
}
