import '../models/enums.dart';
import 'next_sleep_prediction.dart';
import 'sleep_personal_stats.dart';

/// Duración mínima (min) para clasificar como nocturno por longitud sola.
const int kInferNightMinDurationMinutes = 180;

/// En franja nocturna, duración mínima (min) de un bloque **cerrado** para
/// contarlo como nocturno (evita siestas/puentes de tarde-noche cortos).
const int kInferNightMinDurationInWindowMinutes = 90;

/// Inicio de la franja nocturna por defecto (18:00), si no hay bedtime aprendido.
const int kInferNightWindowStartDefaultMinutes = 18 * 60;

/// Fin de la madrugada por defecto (05:00) si no hay despertar aprendido.
const int kInferNightWindowEndDefaultMinutes = 5 * 60;

/// Adelanto (min) respecto al bedtime típico para abrir la franja nocturna.
const int kInferBedtimeLeadMinutes = 90;

int _minutesOfDay(DateTime dt) => dt.hour * 60 + dt.minute;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _inNightWindow({
  required int startMin,
  required int windowStart,
  required int windowEnd,
}) {
  if (windowStart <= windowEnd) {
    return startMin >= windowStart && startMin < windowEnd;
  }
  return startMin >= windowStart || startMin < windowEnd;
}

({int windowStart, int windowEnd}) _nightWindow(SleepPersonalStats? personal) {
  final bedtime = personal?.hasLearnedBedtime == true
      ? personal!.medianBedtimeMinutesOfDay!
      : (kUsualBedtimeHour * 60 + kUsualBedtimeMinute);
  final morning = personal?.hasLearnedMorningWake == true
      ? personal!.medianMorningWakeMinutesOfDay!
      : (kDefaultMorningWakeHour * 60 + kDefaultMorningWakeMinute);

  final nightStart = (bedtime - kInferBedtimeLeadMinutes)
      .clamp(kInferNightWindowStartDefaultMinutes - 60, bedtime)
      .toInt();
  final windowStart = personal?.hasLearnedBedtime == true
      ? nightStart
      : kInferNightWindowStartDefaultMinutes;
  final windowEnd = personal?.hasLearnedMorningWake == true
      ? morning
      : kInferNightWindowEndDefaultMinutes;
  return (windowStart: windowStart, windowEnd: windowEnd);
}

/// Infiere siesta vs sueño nocturno a partir de horas (y stats personales opcionales).
///
/// Reglas (en orden):
/// 1. Cruza medianoche civil → nocturno.
/// 2. Duración ≥ [kInferNightMinDurationMinutes] (3 h) → nocturno.
/// 3. Sesión **abierta** con inicio en franja nocturna → nocturno
///    (asumimos que es el tramo de noche en curso).
/// 4. Sesión **cerrada** con inicio en franja nocturna **y** duración
///    ≥ [kInferNightMinDurationInWindowMinutes] (90 min) → nocturno.
///    Si es corta (p. ej. 20:40–21:05) → siesta / puente.
/// 5. Resto → siesta.
SleepType inferSleepType({
  required DateTime start,
  DateTime? end,
  DateTime? now,
  SleepPersonalStats? personalStats,
}) {
  final reference = now ?? DateTime.now();
  final effectiveEnd = end ?? reference;
  final durationMin = effectiveEnd.difference(start).inMinutes;
  final isOpen = end == null;

  if (end != null && _dateOnly(end) != _dateOnly(start)) {
    return SleepType.night;
  }

  if (durationMin >= kInferNightMinDurationMinutes) {
    return SleepType.night;
  }

  final window = _nightWindow(personalStats);
  final inNightWindow = _inNightWindow(
    startMin: _minutesOfDay(start),
    windowStart: window.windowStart,
    windowEnd: window.windowEnd,
  );

  if (!inNightWindow) return SleepType.nap;

  // Abierta en franja nocturna → nocturno hasta que se cierre y se reevalúe.
  if (isOpen) return SleepType.night;

  // Cerrada: solo nocturno si dura lo suficiente (siesta vespertina / puente si no).
  if (durationMin >= kInferNightMinDurationInWindowMinutes) {
    return SleepType.night;
  }
  return SleepType.nap;
}
