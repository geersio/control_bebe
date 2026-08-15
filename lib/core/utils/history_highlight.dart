import 'package:flutter/material.dart';

import '../models/diaper_record.dart';
import '../models/enums.dart';
import '../models/feeding_record.dart';
import '../models/height_record.dart';
import '../models/sleep_record.dart';
import '../models/weight_record.dart';
import '../theme/app_theme.dart';

/// Claves estables para resaltar una ficha del historial recién añadida.
abstract final class HistoryHighlightKeys {
  static String diaper(DiaperRecord record) =>
      'd_${record.type.index}_${record.dateTime.millisecondsSinceEpoch ~/ 1000}';

  static String weight(WeightRecord record) =>
      'w_${record.weightKg.toStringAsFixed(3)}_'
      '${record.dateTime.millisecondsSinceEpoch ~/ 1000}';

  static String height(HeightRecord record) =>
      'h_${record.heightCm.toStringAsFixed(2)}_'
      '${record.dateTime.millisecondsSinceEpoch ~/ 1000}';

  static String feeding(FeedingRecord record) =>
      'f_${record.type.index}_${record.dateTime.millisecondsSinceEpoch ~/ 1000}';

  static String sleep(SleepRecord record) =>
      's_${record.type.index}_'
      '${record.startDateTime.millisecondsSinceEpoch ~/ 1000}_'
      '${record.endDateTime == null ? 0 : record.endDateTime!.millisecondsSinceEpoch ~/ 1000}_'
      '${record.parentSleepId ?? 0}';

  static bool recordsMatchWithinSeconds(
    DateTime a,
    DateTime b, {
    int seconds = 3,
  }) => a.difference(b).inSeconds.abs() <= seconds;

  /// Solo el eco en stream del registro pendiente (misma marca temporal exacta).
  static bool diaperMatchesPending(DiaperRecord r, DiaperRecord p) =>
      r.type == p.type &&
      r.dateTime.millisecondsSinceEpoch == p.dateTime.millisecondsSinceEpoch;

  static bool weightMatchesPending(WeightRecord r, WeightRecord p) =>
      (r.weightKg - p.weightKg).abs() < 0.0001 &&
      r.dateTime.millisecondsSinceEpoch == p.dateTime.millisecondsSinceEpoch;

  static bool heightMatchesPending(HeightRecord r, HeightRecord p) =>
      (r.heightCm - p.heightCm).abs() < 0.0001 &&
      r.dateTime.millisecondsSinceEpoch == p.dateTime.millisecondsSinceEpoch;

  static bool feedingMatchesPending(FeedingRecord r, FeedingRecord p) =>
      r.type == p.type &&
      r.dateTime.millisecondsSinceEpoch == p.dateTime.millisecondsSinceEpoch;

  static bool sleepMatchesPending(SleepRecord r, SleepRecord p) =>
      r.type == p.type &&
      r.startDateTime.millisecondsSinceEpoch ==
          p.startDateTime.millisecondsSinceEpoch &&
      r.endDateTime?.millisecondsSinceEpoch ==
          p.endDateTime?.millisecondsSinceEpoch &&
      r.parentSleepId == p.parentSleepId;
}

/// Oculta en el stream el registro pendiente hasta [onSavedVisible].
List<T> hidePendingHistoryRecord<T>({
  required List<T> records,
  required bool awaitingReveal,
  required T? pending,
  required bool Function(T record, T pending) matchesPending,
}) {
  if (!awaitingReveal || pending == null) return records;
  return records.where((r) => !matchesPending(r, pending)).toList();
}

/// Registra y expira resaltados del historial en el estado de una pestaña.
mixin HistoryHighlightState<T extends StatefulWidget> on State<T> {
  final Set<String> _historyHighlightKeys = {};

  bool isHistoryHighlighted(String key) => _historyHighlightKeys.contains(key);

  void markHistoryHighlight(String key) {
    if (_historyHighlightKeys.contains(key)) return;
    setState(() => _historyHighlightKeys.add(key));
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_historyHighlightKeys.remove(key)) setState(() {});
    });
  }
}

Color diaperHistoryAccent(DiaperType type) => switch (type) {
  DiaperType.wet => AppTheme.diaperHistoryWetAccent,
  DiaperType.dirty => AppTheme.diaperHistoryDirtyAccent,
  DiaperType.both => AppTheme.diaperHistoryBothAccent,
};

Color feedingHistoryAccent(FeedingType type) => switch (type) {
  FeedingType.leftBreast => AppTheme.feedingHistoryLeftAccent,
  FeedingType.rightBreast => AppTheme.feedingHistoryRightAccent,
  FeedingType.bottle => AppTheme.feedingHistoryBottleAccent,
  FeedingType.solidFood => AppTheme.feedingHistorySolidAccent,
};

Color sleepHistoryAccent([SleepType type = SleepType.night]) => switch (type) {
  SleepType.night => AppTheme.sleepHistoryNightAccent,
  SleepType.nap => AppTheme.sleepHistoryNapAccent,
  SleepType.nightWaking => AppTheme.sleepHistoryNightWakingAccent,
};
