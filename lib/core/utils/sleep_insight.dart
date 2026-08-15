import '../models/sleep_record.dart';
import 'next_sleep_prediction.dart';
import 'sleep_day_timeline.dart';
import 'sleep_history_tree.dart';
import 'sleep_home_summary.dart';
import 'sleep_usual_pattern.dart';

/// Días del gráfico «últimos 7 días» (incluye hoy).
const int kSleepInsightUsualDays = 7;

/// Un día cuenta como «lleno» si hay al menos esta cantidad de sueño
/// (excluye despertares nocturnos). ~8 h: un día de registro realista.
const int kSleepInsightFullDayMinSeconds = 8 * 3600;

/// Mínimo de sesiones cerradas (siesta/nocturno) en la ventana si no hay
/// ningún día lleno.
const int kSleepInsightUsualMinClosedRecords = 3;

/// Resumen para la pastilla «Análisis del sueño» del home.
class SleepInsightStats {
  /// Segundos dormidos hoy (día civil, partido en medianoche).
  final int todaySeconds;

  /// Media de segundos dormidos/día en los últimos [kSleepInsightUsualDays]
  /// (incluye hoy). Solo promedia días con algún registro.
  /// `null` si no hay datos suficientes (ni un día lleno ni varios registros).
  final int? usualDailySeconds;

  /// Totales por día civil de la ventana (índice 0 = hace 6 días, último = hoy).
  final List<int> last7DaysSeconds;

  /// Horario habitual (siestas / noche, mediana 14 días + frases).
  final UsualSleepPattern usualPattern;

  /// Predicción del próximo sueño; `null` si falta fecha de nacimiento
  /// o hay sesión abierta (entonces usar [openSession]).
  final NextSleepPrediction? nextSleep;

  /// Sesión abierta (durmiendo); si no es null, el home muestra «Durmiendo».
  final SleepRecord? openSession;

  /// Bloques y despertares que solapan el día civil (barra 00–24).
  final List<SleepRecord> todayTimelineRecords;

  /// Hay al menos un registro de sueño (cualquier tipo) en el historial.
  final bool hasAnySleepRecord;

  bool get hasTodaySleep => todaySeconds > 0;

  bool get hasUsualEstimate =>
      usualDailySeconds != null && usualDailySeconds! > 0;

  bool get hasUsualSlots => !usualPattern.isEmpty;

  bool get hasNextSleepPrediction => nextSleep != null;

  bool get isSleeping => openSession != null;

  const SleepInsightStats({
    required this.todaySeconds,
    required this.usualDailySeconds,
    required this.last7DaysSeconds,
    required this.usualPattern,
    required this.nextSleep,
    this.openSession,
    this.todayTimelineRecords = const [],
    this.hasAnySleepRecord = false,
  });

  factory SleepInsightStats.fromRecords({
    required List<SleepRecord> records,
    required DateTime now,
    DateTime? birthDate,
  }) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final windowStart = todayStart.subtract(
      const Duration(days: kSleepInsightUsualDays - 1),
    );
    final dailyTotals = <DateTime, int>{};
    final openSession = findOpenSleepSession(records);
    final todayTimelineRecords = sleepRecordsOverlappingCivilDay(records, now);
    final todaySeconds = sleepSecondsToday(todayTimelineRecords, now);

    var closedInWindow = 0;
    for (final record in records) {
      for (final entry in sleepSecondsByCivilDay(record, now: now).entries) {
        dailyTotals[entry.key] = (dailyTotals[entry.key] ?? 0) + entry.value;
      }
      if (_countsTowardUsualHistory(
        record,
        windowStart: windowStart,
        now: now,
      )) {
        closedInWindow++;
      }
    }

    // Hoy con sesión abierta: alinear con [todaySeconds].
    dailyTotals[todayStart] = todaySeconds;

    final last7DaysSeconds = List<int>.generate(kSleepInsightUsualDays, (i) {
      final day = todayStart.subtract(
        Duration(days: kSleepInsightUsualDays - 1 - i),
      );
      return dailyTotals[day] ?? 0;
    });

    var windowSum = 0;
    var daysWithData = 0;
    var hasFullDay = false;
    for (final secs in last7DaysSeconds) {
      if (secs <= 0) continue;
      windowSum += secs;
      daysWithData++;
      if (secs >= kSleepInsightFullDayMinSeconds) hasFullDay = true;
    }

    final hasEnoughHistory =
        hasFullDay || closedInWindow >= kSleepInsightUsualMinClosedRecords;
    final usualDailySeconds =
        hasEnoughHistory && daysWithData > 0
        ? (windowSum / daysWithData).round()
        : null;

    final usualPattern = computeUsualSleepPattern(records: records, now: now);

    final nextSleep = openSession != null
        ? null
        : predictNextSleep(
            records: records,
            now: now,
            birthDate: birthDate,
          );

    return SleepInsightStats(
      todaySeconds: todaySeconds,
      usualDailySeconds: usualDailySeconds,
      last7DaysSeconds: last7DaysSeconds,
      usualPattern: usualPattern,
      nextSleep: nextSleep,
      openSession: openSession,
      todayTimelineRecords: todayTimelineRecords,
      hasAnySleepRecord: records.isNotEmpty,
    );
  }
}

/// Siesta/nocturno cerrado cuya sesión cae (al menos en parte) en la ventana
/// de los últimos [kSleepInsightUsualDays] días (incluye hoy).
bool _countsTowardUsualHistory(
  SleepRecord record, {
  required DateTime windowStart,
  required DateTime now,
}) {
  if (record.isNightWaking || record.isOpen) return false;
  final end = record.endDateTime;
  if (end == null) return false;
  final windowEnd = DateTime(now.year, now.month, now.day)
      .add(const Duration(days: 1));
  return record.startDateTime.isBefore(windowEnd) && end.isAfter(windowStart);
}
