import '../models/enums.dart';
import '../models/sleep_record.dart';
import 'sleep_history_tree.dart';

/// Segmento de sueño en la barra 00–24 del día civil.
class SleepDayTimelineSegment {
  /// Inicio en [0, 1] respecto al día (00:00 → 0).
  final double start;

  /// Fin en [0, 1] (24:00 → 1).
  final double end;

  /// `true` = nocturno; `false` = siesta.
  final bool isNight;

  const SleepDayTimelineSegment({
    required this.start,
    required this.end,
    required this.isNight,
  });
}

DateTime _dayStartOf(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Registros que solapan el día civil de [now] (bloques + despertares).
List<SleepRecord> sleepRecordsOverlappingCivilDay(
  List<SleepRecord> records,
  DateTime now,
) {
  final dayStart = _dayStartOf(now);
  final dayEnd = dayStart.add(const Duration(days: 1));
  return records.where((r) {
    final end = r.endDateTime ?? now;
    return r.startDateTime.isBefore(dayEnd) && end.isAfter(dayStart);
  }).toList();
}

/// Segundos dormidos hoy (sin despertares), usando [now] como fin de abiertas.
int sleepSecondsToday(List<SleepRecord> records, DateTime now) {
  final segments = buildSleepDayTimelineSegments(records: records, now: now);
  const daySeconds = 24 * 3600;
  var total = 0;
  for (final s in segments) {
    total += ((s.end - s.start) * daySeconds).round();
  }
  return total;
}

/// Construye segmentos de la barra del día; los despertares nocturnos dejan hueco.
List<SleepDayTimelineSegment> buildSleepDayTimelineSegments({
  required List<SleepRecord> records,
  required DateTime now,
}) {
  final dayStart = _dayStartOf(now);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final daySeconds = dayEnd.difference(dayStart).inSeconds;
  if (daySeconds <= 0) return const [];

  final entries = buildSleepHistoryEntries(records, includeOpen: true);
  final segments = <SleepDayTimelineSegment>[];

  for (final entry in entries) {
    final sleep = entry.sleep;
    if (!sleep.isSleepBlock) continue;

    final rawEnd = sleep.endDateTime ?? now;
    final clipStart = sleep.startDateTime.isAfter(dayStart)
        ? sleep.startDateTime
        : dayStart;
    final clipEnd = rawEnd.isBefore(dayEnd) ? rawEnd : dayEnd;
    if (!clipEnd.isAfter(clipStart)) continue;

    final wakingGaps = <(DateTime, DateTime)>[];
    for (final w in entry.wakings) {
      final wEnd = w.endDateTime;
      if (wEnd == null) continue;
      final gStart = w.startDateTime.isAfter(clipStart)
          ? w.startDateTime
          : clipStart;
      final gEnd = wEnd.isBefore(clipEnd) ? wEnd : clipEnd;
      if (gEnd.isAfter(gStart)) wakingGaps.add((gStart, gEnd));
    }
    wakingGaps.sort((a, b) => a.$1.compareTo(b.$1));

    var cursor = clipStart;
    for (final (gStart, gEnd) in wakingGaps) {
      if (gStart.isAfter(cursor)) {
        _addSegment(
          segments,
          dayStart: dayStart,
          daySeconds: daySeconds,
          start: cursor,
          end: gStart,
          isNight: sleep.type == SleepType.night,
        );
      }
      if (gEnd.isAfter(cursor)) cursor = gEnd;
    }
    if (clipEnd.isAfter(cursor)) {
      _addSegment(
        segments,
        dayStart: dayStart,
        daySeconds: daySeconds,
        start: cursor,
        end: clipEnd,
        isNight: sleep.type == SleepType.night,
      );
    }
  }

  segments.sort((a, b) => a.start.compareTo(b.start));
  return segments;
}

void _addSegment(
  List<SleepDayTimelineSegment> out, {
  required DateTime dayStart,
  required int daySeconds,
  required DateTime start,
  required DateTime end,
  required bool isNight,
}) {
  final s = start.difference(dayStart).inSeconds / daySeconds;
  final e = end.difference(dayStart).inSeconds / daySeconds;
  if (e - s < 1 / daySeconds) return;
  out.add(
    SleepDayTimelineSegment(
      start: s.clamp(0.0, 1.0),
      end: e.clamp(0.0, 1.0),
      isNight: isNight,
    ),
  );
}
