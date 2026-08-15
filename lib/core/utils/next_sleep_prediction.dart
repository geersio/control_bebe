import '../models/enums.dart';
import '../models/sleep_record.dart';
import 'baby_age_calendar.dart';
import 'sleep_personal_stats.dart';

/// Despertar por defecto si no hay registros hoy ni mediana aprendida (07:00).
const int kDefaultMorningWakeHour = 7;
const int kDefaultMorningWakeMinute = 0;

/// Umbral habitual de acostarse si no hay bedtime aprendido (19:30).
const int kUsualBedtimeHour = 19;
const int kUsualBedtimeMinute = 30;

/// Umbral de early bedtime por defecto cuando se agotan las ventanas (18:00).
const int kEarlyBedtimeHour = 18;
const int kEarlyBedtimeMinute = 0;

/// Minutos antes del bedtime personal/habitual para early bedtime.
const int kEarlyBedtimeLeadMinutes = 90;

/// Suelo/techo del umbral early bedtime (minutos desde medianoche).
const int kEarlyBedtimeFloorMinutes = 17 * 60;
const int kEarlyBedtimeCeilMinutes = 18 * 60 + 30;

/// Penalización fija si la última siesta fue corta y no hay aprendizaje.
const int kShortNapWindowPenaltyMinutes = 15;

/// Rango corto por defecto (solo documentación / tests legacy).
const int kNextSleepDisplayRangeMinutes =
    kSleepPersonalDefaultHalfRangeMinutes * 2;

/// Tipo de predicción del siguiente sueño.
enum NextSleepKind {
  /// Próxima siesta (incluye siesta puente / catnap).
  nextNap,

  /// Hora de acostarse (habitual o early bedtime).
  bedtime,
}

/// Códigos de razón (la UI localiza el texto).
enum NextSleepReasonCode {
  /// Cálculo estándar de ventana.
  standard,

  /// Ventana acortada por siesta corta anterior.
  shortenedWindowAfterShortNap,

  /// @Deprecated Conservado por compatibilidad; ya no se emite (las siestas
  /// largas no alargan la vigilia).
  extendedWindowAfterLongNap,

  /// target ≥ umbral de acostarse → noche.
  bedtimeByUsualThreshold,

  /// Ventanas de siesta agotadas y target &lt; early → siesta puente.
  catnapAfterWindowsExhausted,

  /// Ventanas agotadas y target ≥ early → acostarse temprano.
  earlyBedtimeAfterWindowsExhausted,

  /// Se usó un despertar asumido al no haber registros hoy.
  defaultMorningWakeUsed,
}

/// Regla de ventanas de sueño según edad en meses de calendario.
class SleepAgeWakeRule {
  /// Mes mínimo inclusive.
  final int minMonthsInclusive;

  /// Mes máximo inclusive; `null` = sin techo (último tramo).
  final int? maxMonthsInclusive;

  /// Ventanas de vigilia en minutos (una por siesta del día).
  final List<int> wakeWindowsMinutes;

  /// Duración mínima de siesta; por debajo se aplica penalización.
  final int minNapMinutes;

  /// Duración típica de siesta a esta edad (para estimar el horario del día).
  final int typicalNapMinutes;

  /// Horquilla de sueño total en 24 h (horas), según AASM/AAP.
  final int dailySleepHoursMin;
  final int dailySleepHoursMax;

  const SleepAgeWakeRule({
    required this.minMonthsInclusive,
    required this.maxMonthsInclusive,
    required this.wakeWindowsMinutes,
    required this.minNapMinutes,
    required this.typicalNapMinutes,
    required this.dailySleepHoursMin,
    required this.dailySleepHoursMax,
  });

  bool matchesAgeMonths(int ageMonths) {
    if (ageMonths < minMonthsInclusive) return false;
    final max = maxMonthsInclusive;
    if (max == null) return true;
    return ageMonths <= max;
  }
}

/// Tabla de configuración por edad (meses de calendario inclusivos).
///
/// Valores según la guía orientativa de la AAP y la AASM: siestas/día,
/// ventana de vigilia y sueño total en 24 h por tramo de edad.
const List<SleepAgeWakeRule> kSleepAgeWakeRules = [
  // 0–1 mes · 4–6 siestas · vigilia 45–60 min · 14–17 h.
  SleepAgeWakeRule(
    minMonthsInclusive: 0,
    maxMonthsInclusive: 0,
    wakeWindowsMinutes: [45, 50, 55, 60, 60],
    minNapMinutes: 30,
    typicalNapMinutes: 90,
    dailySleepHoursMin: 14,
    dailySleepHoursMax: 17,
  ),
  // 1–3 meses · 4–5 siestas · vigilia 1–1,5 h · 14–17 h.
  SleepAgeWakeRule(
    minMonthsInclusive: 1,
    maxMonthsInclusive: 2,
    wakeWindowsMinutes: [60, 70, 75, 85, 90],
    minNapMinutes: 35,
    typicalNapMinutes: 75,
    dailySleepHoursMin: 14,
    dailySleepHoursMax: 17,
  ),
  // 3–4 meses · 3–4 siestas · vigilia 1,5–2 h · 14–16 h.
  SleepAgeWakeRule(
    minMonthsInclusive: 3,
    maxMonthsInclusive: 3,
    wakeWindowsMinutes: [90, 100, 110, 120],
    minNapMinutes: 40,
    typicalNapMinutes: 70,
    dailySleepHoursMin: 14,
    dailySleepHoursMax: 16,
  ),
  // 4–6 meses · 3 siestas · vigilia 2–2,5 h · 12–16 h.
  SleepAgeWakeRule(
    minMonthsInclusive: 4,
    maxMonthsInclusive: 5,
    wakeWindowsMinutes: [120, 135, 150],
    minNapMinutes: 45,
    typicalNapMinutes: 70,
    dailySleepHoursMin: 12,
    dailySleepHoursMax: 16,
  ),
  // 6–9 meses · 2–3 siestas · vigilia 2,5–3 h · 12–15 h.
  SleepAgeWakeRule(
    minMonthsInclusive: 6,
    maxMonthsInclusive: 8,
    wakeWindowsMinutes: [150, 165, 180],
    minNapMinutes: 45,
    typicalNapMinutes: 60,
    dailySleepHoursMin: 12,
    dailySleepHoursMax: 15,
  ),
  // 9–12 meses · 2 siestas · vigilia 3–4 h · 12–15 h.
  SleepAgeWakeRule(
    minMonthsInclusive: 9,
    maxMonthsInclusive: 11,
    wakeWindowsMinutes: [180, 210],
    minNapMinutes: 45,
    typicalNapMinutes: 75,
    dailySleepHoursMin: 12,
    dailySleepHoursMax: 15,
  ),
  // 12–15 meses · 1–2 siestas · vigilia 3–4,5 h · 11–14 h.
  SleepAgeWakeRule(
    minMonthsInclusive: 12,
    maxMonthsInclusive: 14,
    wakeWindowsMinutes: [180, 240],
    minNapMinutes: 45,
    typicalNapMinutes: 75,
    dailySleepHoursMin: 11,
    dailySleepHoursMax: 14,
  ),
  // 15–18 meses · 1 siesta (a veces 2) · vigilia 4–5 h · 11–14 h.
  SleepAgeWakeRule(
    minMonthsInclusive: 15,
    maxMonthsInclusive: 17,
    wakeWindowsMinutes: [270],
    minNapMinutes: 60,
    typicalNapMinutes: 120,
    dailySleepHoursMin: 11,
    dailySleepHoursMax: 14,
  ),
  // 18–24 meses (y 2–3 años) · 1 siesta · vigilia 5–6 h · 11–14 h.
  SleepAgeWakeRule(
    minMonthsInclusive: 18,
    maxMonthsInclusive: 35,
    wakeWindowsMinutes: [300],
    minNapMinutes: 60,
    typicalNapMinutes: 120,
    dailySleepHoursMin: 11,
    dailySleepHoursMax: 14,
  ),
  // 3 años en adelante · 1 siesta o ninguna · 10–13 h (AASM 3–5 años).
  SleepAgeWakeRule(
    minMonthsInclusive: 36,
    maxMonthsInclusive: null,
    wakeWindowsMinutes: [360],
    minNapMinutes: 45,
    typicalNapMinutes: 90,
    dailySleepHoursMin: 10,
    dailySleepHoursMax: 13,
  ),
];

/// Resultado de la predicción del próximo sueño.
class NextSleepPrediction {
  final NextSleepKind kind;
  final NextSleepReasonCode reasonCode;
  final DateTime targetTime;
  final DateTime windowStart;
  final DateTime windowEnd;

  /// Minutos desde [now] hasta [targetTime] (negativo si ya pasó).
  final int minutesFromNow;

  final DateTime lastWakeUp;
  final int windowIndex;

  /// Ventana de la tabla de edad (antes del blend).
  final int ageWindowMinutes;

  /// Ventana tras blend con mediana personal.
  final int baseWindowMinutes;

  /// Ventana final tras penalización por siesta corta.
  final int adjustedWindowMinutes;

  final int ageMonths;
  final bool usedDefaultMorningWake;
  final bool windowsExhausted;

  /// Franja usada para personalización / IQR.
  final SleepWakeSlot wakeSlot;

  /// Peso del historial personal en la ventana (0…0.9).
  final double personalizationWeight;

  /// Minutos sumados a la ventana por la siesta anterior: negativo si fue más
  /// corta de lo habitual, positivo si fue más larga, 0 si no hubo ajuste.
  final int napAdjustmentMinutes;

  /// Minutos despierto desde [lastWakeUp] hasta el momento del cálculo.
  final int awakeMinutesNow;

  /// true si bedtime/despertar/ventana usan datos del bebé.
  final bool isPersonalized;

  const NextSleepPrediction({
    required this.kind,
    required this.reasonCode,
    required this.targetTime,
    required this.windowStart,
    required this.windowEnd,
    required this.minutesFromNow,
    required this.lastWakeUp,
    required this.windowIndex,
    required this.ageWindowMinutes,
    required this.baseWindowMinutes,
    required this.adjustedWindowMinutes,
    required this.ageMonths,
    required this.usedDefaultMorningWake,
    required this.windowsExhausted,
    required this.wakeSlot,
    required this.personalizationWeight,
    required this.napAdjustmentMinutes,
    required this.awakeMinutesNow,
    required this.isPersonalized,
  });

  bool get isPast => minutesFromNow < 0;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _atMinutesOfDay(DateTime day, int minutesOfDay) {
  final normalized = minutesOfDay >= 24 * 60
      ? minutesOfDay - 24 * 60
      : minutesOfDay;
  final h = normalized ~/ 60;
  final m = normalized % 60;
  return DateTime(day.year, day.month, day.day, h, m);
}

bool _endsOnCivilDay(SleepRecord record, DateTime dayStart) {
  final end = record.endDateTime;
  if (end == null) return false;
  final endDay = _dateOnly(end);
  return endDay == dayStart;
}

/// Regla de ventanas para [ageMonths] (meses de calendario).
SleepAgeWakeRule sleepAgeWakeRuleForMonths(int ageMonths) {
  final clamped = ageMonths < 0 ? 0 : ageMonths;
  for (final rule in kSleepAgeWakeRules) {
    if (rule.matchesAgeMonths(clamped)) return rule;
  }
  return kSleepAgeWakeRules.last;
}

/// Ventanas del día ajustadas al número de siestas que hace el bebé de verdad.
///
/// La tabla de edad fija cuántas siestas se esperan, y al superarlas la
/// predicción cambia a siesta puente / acostarse pronto. Si el historial
/// muestra de forma sostenida otro número de siestas, se estira o se recorta
/// la lista (dentro de un margen) para no dar el día por agotado antes de
/// tiempo ni al revés.
List<int> effectiveWakeWindowsMinutes({
  required SleepAgeWakeRule rule,
  required SleepPersonalStats personal,
}) {
  final base = rule.wakeWindowsMinutes;
  if (base.isEmpty || !personal.hasLearnedNapCount) return base;

  final minCount = base.length + kSleepPersonalNapCountMinDelta;
  final maxCount = base.length + kSleepPersonalNapCountMaxDelta;
  final target = personal.medianNapsPerDay!.clamp(
    minCount < 1 ? 1 : minCount,
    maxCount,
  );
  if (target == base.length) return base;

  if (target > base.length) {
    return [...base, ...List.filled(target - base.length, base.last)];
  }
  // Menos siestas: se quitan las intermedias y se conserva la última, que es
  // la vigilia más larga y la que lleva hasta la noche.
  return [...base.take(target - 1), base.last];
}

/// Índice por hora del día (usa [reference] = ahora, para detectar siestas no
/// registradas). Reconstruye el horario teórico del día desde
/// [morningWakeMinutesOfDay] encadenando [wakeWindowsMinutes] con siestas de
/// [typicalNapMinutes], y cuenta cuántas ya deberían haber terminado.
int nextSleepTimeIndex({
  required DateTime reference,
  required List<int> wakeWindowsMinutes,
  required int typicalNapMinutes,
  int morningWakeMinutesOfDay =
      kDefaultMorningWakeHour * 60 + kDefaultMorningWakeMinute,
}) {
  if (wakeWindowsMinutes.isEmpty) return 0;
  final last = wakeWindowsMinutes.length - 1;
  final minutes = reference.hour * 60 + reference.minute;
  var cursor = morningWakeMinutesOfDay;
  var index = 0;
  for (var i = 0; i < wakeWindowsMinutes.length; i++) {
    final napEnd = cursor + wakeWindowsMinutes[i] + typicalNapMinutes;
    if (napEnd > minutes) break;
    cursor = napEnd;
    index = i + 1;
  }
  return index.clamp(0, last);
}

int _defaultUsualBedtimeMinutes() =>
    kUsualBedtimeHour * 60 + kUsualBedtimeMinute;

int _defaultEarlyBedtimeMinutes() =>
    kEarlyBedtimeHour * 60 + kEarlyBedtimeMinute;

/// Predice el próximo sueño. Devuelve `null` si no hay [birthDate].
NextSleepPrediction? predictNextSleep({
  required List<SleepRecord> records,
  required DateTime now,
  required DateTime? birthDate,
  SleepPersonalStats? personalStats,
  int defaultMorningHour = kDefaultMorningWakeHour,
  int defaultMorningMinute = kDefaultMorningWakeMinute,
}) {
  if (birthDate == null) return null;

  final ageMonths = BabyAgeCalendar.monthsAndDaysAt(birthDate, now).months;
  final rule = sleepAgeWakeRuleForMonths(ageMonths);
  if (rule.wakeWindowsMinutes.isEmpty) return null;

  final personal =
      personalStats ??
      SleepPersonalStats.fromRecords(
        records: records,
        now: now,
        minNapMinutes: rule.minNapMinutes,
      );

  final windows = effectiveWakeWindowsMinutes(rule: rule, personal: personal);

  final todayStart = _dateOnly(now);

  final todayNaps =
      records
          .where(
            (r) =>
                r.type == SleepType.nap &&
                r.endDateTime != null &&
                _endsOnCivilDay(r, todayStart),
          )
          .toList()
        ..sort((a, b) => a.endDateTime!.compareTo(b.endDateTime!));

  final todayNightEnds =
      records
          .where(
            (r) =>
                r.type == SleepType.night &&
                r.endDateTime != null &&
                _endsOnCivilDay(r, todayStart),
          )
          .toList()
        ..sort((a, b) => a.endDateTime!.compareTo(b.endDateTime!));

  // Último despertar = fin más reciente entre siestas y nocturnos cerrados hoy.
  DateTime? lastWakeUp;
  var usedDefaultMorningWake = false;
  final lastNapEnd = todayNaps.isEmpty ? null : todayNaps.last.endDateTime;
  final lastNightEnd = todayNightEnds.isEmpty
      ? null
      : todayNightEnds.last.endDateTime;
  if (lastNapEnd != null && lastNightEnd != null) {
    lastWakeUp = lastNapEnd.isAfter(lastNightEnd) ? lastNapEnd : lastNightEnd;
  } else {
    lastWakeUp = lastNapEnd ?? lastNightEnd;
  }

  if (lastWakeUp == null) {
    final morningMinutes = personal.hasLearnedMorningWake
        ? personal.medianMorningWakeMinutesOfDay!
        : (defaultMorningHour * 60 + defaultMorningMinute);
    lastWakeUp = _atMinutesOfDay(todayStart, morningMinutes);
    usedDefaultMorningWake = true;
  }

  final countIndex = todayNaps.length;
  final timeIndex = nextSleepTimeIndex(
    reference: now,
    wakeWindowsMinutes: windows,
    typicalNapMinutes: personal.blendedTypicalNapMinutes(
      ageTypicalNapMinutes: rule.typicalNapMinutes,
    ),
    morningWakeMinutesOfDay: personal.hasLearnedMorningWake
        ? personal.medianMorningWakeMinutesOfDay!
        : (defaultMorningHour * 60 + defaultMorningMinute),
  );
  final windowsExhausted = countIndex >= windows.length;
  final finalIndex =
      (windowsExhausted
              ? windows.length - 1
              : (countIndex > timeIndex ? countIndex : timeIndex))
          .clamp(0, windows.length - 1);

  final wakeSlot = sleepWakeSlotForDateTime(lastWakeUp);
  final ageWindow = windows[finalIndex];
  final blended = personal.blendedWakeWindow(
    ageWindowMinutes: ageWindow,
    slot: wakeSlot,
    napIndex: finalIndex,
  );
  final baseWindow = blended.minutes;
  final personalizationWeight = blended.weight;

  var adjustedWindow = baseWindow;
  var napAdjustment = 0;
  var usedLearnedNapAdjustment = false;
  var reasonCode = usedDefaultMorningWake
      ? NextSleepReasonCode.defaultMorningWakeUsed
      : NextSleepReasonCode.standard;

  if (todayNaps.isNotEmpty && lastWakeUp == todayNaps.last.endDateTime) {
    final lastNapMinutes = todayNaps.last.durationSeconds() ~/ 60;
    final learned = personal.napDeviationAdjustmentMinutes(lastNapMinutes);
    if (learned != null) {
      // Solo acorta si la siesta fue más corta de lo habitual; las largas no
      // alargan la vigilia.
      napAdjustment = learned;
      usedLearnedNapAdjustment = learned < 0;
    } else {
      final shortNapThreshold = personal.shortNapThresholdMinutes(
        ageMinNapMinutes: rule.minNapMinutes,
      );
      if (lastNapMinutes < shortNapThreshold) {
        napAdjustment = -(personal.hasLearnedShortNapPenalty
            ? personal.learnedShortNapPenaltyMinutes!
            : kShortNapWindowPenaltyMinutes);
      }
    }

    if (napAdjustment < 0) {
      adjustedWindow = baseWindow + napAdjustment;
      if (adjustedWindow < 0) adjustedWindow = 0;
      reasonCode = NextSleepReasonCode.shortenedWindowAfterShortNap;
    }
  }

  final targetTime = lastWakeUp.add(Duration(minutes: adjustedWindow));

  final usualBedtimeMinutes = personal.hasLearnedBedtime
      ? personal.medianBedtimeMinutesOfDay!
      : _defaultUsualBedtimeMinutes();
  final earlyFromBedtime = (usualBedtimeMinutes - kEarlyBedtimeLeadMinutes)
      .clamp(kEarlyBedtimeFloorMinutes, kEarlyBedtimeCeilMinutes)
      .toInt();
  final earlyBedtimeMinutes = personal.hasLearnedBedtime
      ? earlyFromBedtime
      : _defaultEarlyBedtimeMinutes();

  final usualBedtime = _atMinutesOfDay(todayStart, usualBedtimeMinutes);
  final earlyBedtime = _atMinutesOfDay(todayStart, earlyBedtimeMinutes);

  late final NextSleepKind kind;
  if (windowsExhausted) {
    // Si ya conocemos cuántas siestas hace el bebé y las ha hecho, no inventar
    // una 6ª (u otra) siesta puente: toca acostarse.
    final personalMax = personal.medianNapsPerDay;
    final reachedPersonalMax =
        personal.hasLearnedNapCount &&
        personalMax != null &&
        countIndex >= personalMax;
    if (reachedPersonalMax || !targetTime.isBefore(earlyBedtime)) {
      kind = NextSleepKind.bedtime;
      reasonCode = NextSleepReasonCode.earlyBedtimeAfterWindowsExhausted;
    } else {
      kind = NextSleepKind.nextNap;
      reasonCode = NextSleepReasonCode.catnapAfterWindowsExhausted;
    }
  } else if (!targetTime.isBefore(usualBedtime)) {
    kind = NextSleepKind.bedtime;
    reasonCode = NextSleepReasonCode.bedtimeByUsualThreshold;
  } else {
    kind = NextSleepKind.nextNap;
  }

  final ranges = personal.displayHalfRanges(
    slot: wakeSlot,
    napIndex: finalIndex,
  );
  final windowStart = targetTime.subtract(Duration(minutes: ranges.before));
  final windowEnd = targetTime.add(Duration(minutes: ranges.after));
  final minutesFromNow = targetTime.difference(now).inMinutes;
  final awakeMinutesNow = now.difference(lastWakeUp).inMinutes;

  final isPersonalized =
      personalizationWeight > 0 ||
      (usedDefaultMorningWake && personal.hasLearnedMorningWake) ||
      personal.hasLearnedBedtime ||
      usedLearnedNapAdjustment ||
      (napAdjustment != 0 && personal.hasLearnedShortNapPenalty) ||
      windows.length != rule.wakeWindowsMinutes.length;

  return NextSleepPrediction(
    kind: kind,
    reasonCode: reasonCode,
    targetTime: targetTime,
    windowStart: windowStart,
    windowEnd: windowEnd,
    minutesFromNow: minutesFromNow,
    lastWakeUp: lastWakeUp,
    windowIndex: finalIndex,
    ageWindowMinutes: ageWindow,
    baseWindowMinutes: baseWindow,
    adjustedWindowMinutes: adjustedWindow,
    ageMonths: ageMonths,
    usedDefaultMorningWake: usedDefaultMorningWake,
    windowsExhausted: windowsExhausted,
    wakeSlot: wakeSlot,
    personalizationWeight: personalizationWeight,
    napAdjustmentMinutes: napAdjustment,
    awakeMinutesNow: awakeMinutesNow < 0 ? 0 : awakeMinutesNow,
    isPersonalized: isPersonalized,
  );
}
