import '../models/enums.dart';
import '../models/sleep_record.dart';

/// Resumen de sueño para la pastilla del home.
class SleepHomeSummary {
  /// Segundos dormidos hoy (día civil 00:00–00:00; se parte si cruza medianoche).
  final int todaySeconds;

  /// Sueños nocturnos registrados hoy (solapan el día civil de hoy).
  final int todayNightCount;

  /// Siestas registradas hoy (solapan el día civil de hoy).
  final int todayNapCount;

  final DateTime? lastRecordedAt;

  /// Sesión abierta (durmiendo ahora), si existe.
  final SleepRecord? openSession;

  const SleepHomeSummary({
    required this.todaySeconds,
    required this.todayNightCount,
    required this.todayNapCount,
    this.lastRecordedAt,
    this.openSession,
  });

  bool get hasAnyRecord => lastRecordedAt != null || openSession != null;

  bool get isSleeping => openSession != null;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Segundos de [record] repartidos por día civil (00:00–00:00).
///
/// Si duerme de 22:00 a 07:00, las 2 h hasta medianoche van al día de inicio
/// y el resto al día siguiente. Sesiones abiertas usan [now] como fin.
Map<DateTime, int> sleepSecondsByCivilDay(
  SleepRecord record, {
  DateTime? now,
}) {
  if (record.isNightWaking) return const {};

  var cursor = record.startDateTime;
  final end = record.endDateTime ?? (now ?? DateTime.now());
  if (!end.isAfter(cursor)) return const {};

  final result = <DateTime, int>{};
  while (cursor.isBefore(end)) {
    final dayStart = _dateOnly(cursor);
    final nextMidnight = dayStart.add(const Duration(days: 1));
    final segmentEnd = end.isBefore(nextMidnight) ? end : nextMidnight;
    final secs = segmentEnd.difference(cursor).inSeconds;
    if (secs > 0) {
      result[dayStart] = (result[dayStart] ?? 0) + secs;
    }
    cursor = segmentEnd;
  }
  return result;
}

bool _overlapsCivilDay(SleepRecord record, DateTime dayStart, DateTime now) {
  final dayEnd = dayStart.add(const Duration(days: 1));
  final end = record.endDateTime ?? now;
  return record.startDateTime.isBefore(dayEnd) && end.isAfter(dayStart);
}

/// Calcula totales de hoy: horas (partidas en medianoche) y nº de nocturnos/siestas.
SleepHomeSummary buildSleepHomeSummary({
  required List<SleepRecord> records,
  required DateTime now,
}) {
  final todayStart = _dateOnly(now);

  var todaySeconds = 0;
  var todayNights = 0;
  var todayNaps = 0;
  DateTime? lastAt;
  SleepRecord? openSession;

  for (final r in records) {
    if (r.isNightWaking) continue;

    if (r.isOpen) {
      openSession ??= r;
      if (r.startDateTime.isAfter(openSession.startDateTime)) {
        openSession = r;
      }
    }

    final end = r.endDateTime ?? now;
    if (lastAt == null || end.isAfter(lastAt)) {
      lastAt = end;
    }

    if (_overlapsCivilDay(r, todayStart, now)) {
      if (r.type == SleepType.night) {
        todayNights++;
      } else if (r.type == SleepType.nap) {
        todayNaps++;
      }
    }

    todaySeconds += sleepSecondsByCivilDay(r, now: now)[todayStart] ?? 0;
  }

  return SleepHomeSummary(
    todaySeconds: todaySeconds,
    todayNightCount: todayNights,
    todayNapCount: todayNaps,
    lastRecordedAt: lastAt,
    openSession: openSession,
  );
}
