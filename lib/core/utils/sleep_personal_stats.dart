import 'dart:math' as math;

import '../models/enums.dart';
import '../models/sleep_record.dart';

/// Días de historial para aprender del bebé.
const int kSleepPersonalLookbackDays = 21;

/// Media vida del peso por recencia: una muestra de hace 7 días pesa la mitad
/// que una de hoy. Hace que el patrón nuevo mande sobre el viejo y que, si se
/// deja de registrar, el historial pierda fuerza y vuelva a mandar la edad.
const double kSleepPersonalRecencyHalfLifeDays = 7;

/// Frescura mínima (peso de la muestra más reciente) para aplicar reglas que
/// no son una mezcla gradual: nº de siestas y umbral de siesta corta.
const double kSleepPersonalMinFreshnessForRules = 0.5;

/// Muestras mínimas en una franja para empezar a mezclar con la regla de edad.
const int kSleepPersonalMinSamplesForBlend = 3;

/// Muestras a las que el peso personal alcanza el máximo.
const int kSleepPersonalFullBlendSamples = 10;

/// Peso máximo de la mediana personal vs regla de edad (0–1).
const double kSleepPersonalMaxBlendWeight = 0.7;

/// Con mucho historial y poca dispersión el techo sube: la tabla de edad ya no
/// aporta y solo dejaría un sesgo fijo.
const int kSleepPersonalHighConfidenceSamples = 20;
const double kSleepPersonalHighBlendWeight = 0.9;

/// Dispersión relativa (IQR / mediana) por debajo de la cual el bebé se
/// considera regular.
const double kSleepPersonalLowDispersionRatio = 0.35;

/// Vigilia mínima/máxima (min) para aceptar un intervalo despertar→sueño.
const int kSleepPersonalMinAwakeMinutes = 20;
const int kSleepPersonalMaxAwakeMinutes = 8 * 60;

/// Mitad de rango UI por defecto (±10 → 20 min totales).
const int kSleepPersonalDefaultHalfRangeMinutes = 10;
const int kSleepPersonalMinHalfRangeMinutes = 10;
const int kSleepPersonalMaxHalfRangeMinutes = 40;

/// Penalización aprendida acotada (regla binaria antigua, aún en uso mientras
/// no se conoce la duración habitual de siesta).
const int kSleepPersonalLearnedPenaltyMinMinutes = 5;
const int kSleepPersonalLearnedPenaltyMaxMinutes = 30;

/// Muestras mínimas para usar bedtime / despertar matutino aprendidos.
const int kSleepPersonalMinSamplesForSchedule = 3;

/// Días completos con siestas registradas para ajustar el nº de siestas.
const int kSleepPersonalMinDaysForNapCount = 5;

/// Siestas mínimas en el historial para aprender duración y umbral de siesta.
const int kSleepPersonalMinNapsForDuration = 8;

/// Límites para aceptar la duración de una siesta como muestra (min).
const int kSleepPersonalMinNapSampleMinutes = 5;
const int kSleepPersonalMaxNapSampleMinutes = 4 * 60;

/// Suelo del umbral aprendido de "siesta corta" y techo relativo a la edad.
const int kSleepPersonalMinShortNapThresholdMinutes = 20;
const double kSleepPersonalMaxShortNapThresholdFactor = 1.5;

/// Margen permitido al ajustar el nº de siestas respecto a la tabla de edad.
/// Asimétrico: quitar siestas adelanta el modo "a la cama pronto", así que se
/// permite una menos pero hasta dos más.
const int kSleepPersonalNapCountMinDelta = -1;
const int kSleepPersonalNapCountMaxDelta = 2;

/// Desviación mínima de una siesta respecto a su mediana para tenerla en
/// cuenta; por debajo es ruido.
const int kSleepPersonalMinNapDeviationMinutes = 10;

/// Cuánto se traslada la desviación de la siesta a la ventana siguiente
/// mientras no haya datos para aprender la proporción real.
const double kSleepPersonalDefaultNapDeviationSlope = 0.5;

/// Pares (siesta, vigilia siguiente) necesarios para aprender la proporción.
const int kSleepPersonalMinSamplesForNapSlope = 5;

  /// Ajuste máximo, en minutos, al acortar la vigilia tras una siesta corta.
  /// (Las siestas largas no alargan la ventana.)
  const int kSleepPersonalMaxNapDeviationAdjustMinutes = 45;

/// Franja de vigilia según hora del último despertar.
enum SleepWakeSlot { morning, midday, afternoon, evening }

SleepWakeSlot sleepWakeSlotForDateTime(DateTime dt) {
  final minutes = dt.hour * 60 + dt.minute;
  if (minutes < 11 * 60) return SleepWakeSlot.morning;
  if (minutes < 15 * 60) return SleepWakeSlot.midday;
  if (minutes < 18 * 60) return SleepWakeSlot.afternoon;
  return SleepWakeSlot.evening;
}

/// Estadísticas de vigilia de un grupo (franja horaria o nº de siesta).
class SlotWakeStats {
  final int sampleCount;
  final int? medianMinutes;
  final int? p25Minutes;
  final int? p75Minutes;

  /// Peso de la muestra más reciente (1 = de hoy, 0,5 = de hace una semana).
  final double freshness;

  const SlotWakeStats({
    required this.sampleCount,
    this.medianMinutes,
    this.p25Minutes,
    this.p75Minutes,
    this.freshness = 0,
  });

  static const empty = SlotWakeStats(sampleCount: 0);

  bool get hasBlendableData =>
      sampleCount >= kSleepPersonalMinSamplesForBlend &&
      medianMinutes != null &&
      freshness > 0;

  /// IQR relativo a la mediana; `null` si no hay datos suficientes.
  double? get relativeDispersion {
    final median = medianMinutes;
    final p25 = p25Minutes;
    final p75 = p75Minutes;
    if (median == null || median <= 0 || p25 == null || p75 == null) {
      return null;
    }
    return (p75 - p25) / median;
  }

  double get blendWeight => SleepPersonalStats.blendWeight(
    sampleCount: sampleCount,
    freshness: freshness,
    relativeDispersion: relativeDispersion,
  );
}

/// Perfil aprendido a partir del historial de sueño del bebé.
class SleepPersonalStats {
  /// Vigilia agrupada por franja horaria del despertar.
  final Map<SleepWakeSlot, SlotWakeStats> wakeBySlot;

  /// Vigilia agrupada por número de siesta del día (0 = antes de la primera).
  /// Es la misma clave que usa la tabla de edad, así que casa mejor; la franja
  /// horaria queda como red de seguridad cuando aquí no hay datos.
  final Map<int, SlotWakeStats> wakeByNapIndex;

  /// Minutos desde medianoche del despertar nocturno típico (mediana).
  final int? medianMorningWakeMinutesOfDay;
  final int morningWakeSampleCount;

  /// Minutos desde medianoche del inicio típico de sueño nocturno.
  final int? medianBedtimeMinutesOfDay;
  final int bedtimeSampleCount;

  /// Adelanto típico (min) tras siesta corta; `null` → usar default fijo.
  final int? learnedShortNapPenaltyMinutes;
  final int shortNapPenaltySampleCount;

  /// Mediana de siestas por día completo registrado.
  final int? medianNapsPerDay;
  final int napCountDaySampleCount;
  final double napCountFreshness;

  /// Duración de siesta: mediana y cuartiles (el p25 marca lo que es "corta").
  final int? medianNapMinutes;
  final int? p25NapMinutes;
  final int? p75NapMinutes;
  final int napDurationSampleCount;
  final double napDurationFreshness;

  /// Minutos de vigilia que se mueven por cada minuto que la siesta anterior
  /// se desvía de lo habitual. `null` → usar el valor por defecto.
  final double? learnedNapDeviationSlope;
  final int napDeviationSampleCount;

  const SleepPersonalStats({
    required this.wakeBySlot,
    required this.wakeByNapIndex,
    required this.medianMorningWakeMinutesOfDay,
    required this.morningWakeSampleCount,
    required this.medianBedtimeMinutesOfDay,
    required this.bedtimeSampleCount,
    required this.learnedShortNapPenaltyMinutes,
    required this.shortNapPenaltySampleCount,
    required this.medianNapsPerDay,
    required this.napCountDaySampleCount,
    required this.napCountFreshness,
    required this.medianNapMinutes,
    required this.p25NapMinutes,
    required this.p75NapMinutes,
    required this.napDurationSampleCount,
    required this.napDurationFreshness,
    required this.learnedNapDeviationSlope,
    required this.napDeviationSampleCount,
  });

  static const empty = SleepPersonalStats(
    wakeBySlot: {},
    wakeByNapIndex: {},
    medianMorningWakeMinutesOfDay: null,
    morningWakeSampleCount: 0,
    medianBedtimeMinutesOfDay: null,
    bedtimeSampleCount: 0,
    learnedShortNapPenaltyMinutes: null,
    shortNapPenaltySampleCount: 0,
    medianNapsPerDay: null,
    napCountDaySampleCount: 0,
    napCountFreshness: 0,
    medianNapMinutes: null,
    p25NapMinutes: null,
    p75NapMinutes: null,
    napDurationSampleCount: 0,
    napDurationFreshness: 0,
    learnedNapDeviationSlope: null,
    napDeviationSampleCount: 0,
  );

  SlotWakeStats statsFor(SleepWakeSlot slot) =>
      wakeBySlot[slot] ?? SlotWakeStats.empty;

  SlotWakeStats statsForNapIndex(int napIndex) =>
      wakeByNapIndex[napIndex] ?? SlotWakeStats.empty;

  /// Grupo con el que se personaliza: el del nº de siesta si tiene datos, y si
  /// no el de la franja horaria.
  SlotWakeStats resolveStats({required SleepWakeSlot slot, int? napIndex}) {
    if (napIndex != null) {
      final byIndex = statsForNapIndex(napIndex);
      if (byIndex.hasBlendableData) return byIndex;
    }
    return statsFor(slot);
  }

  /// Peso de la mediana personal frente a la tabla de edad.
  ///
  /// Sube con el número de muestras, baja con la antigüedad de la más reciente
  /// y solo pasa de [kSleepPersonalMaxBlendWeight] si además el bebé es
  /// regular.
  static double blendWeight({
    required int sampleCount,
    required double freshness,
    double? relativeDispersion,
  }) {
    if (sampleCount < kSleepPersonalMinSamplesForBlend || freshness <= 0) {
      return 0;
    }
    final ramp =
        ((sampleCount - kSleepPersonalMinSamplesForBlend) /
                (kSleepPersonalFullBlendSamples -
                    kSleepPersonalMinSamplesForBlend))
            .clamp(0.0, 1.0);
    var weight = ramp * kSleepPersonalMaxBlendWeight;

    final isRegular =
        relativeDispersion != null &&
        relativeDispersion <= kSleepPersonalLowDispersionRatio;
    if (weight >= kSleepPersonalMaxBlendWeight && isRegular) {
      final extra =
          ((sampleCount - kSleepPersonalFullBlendSamples) /
                  (kSleepPersonalHighConfidenceSamples -
                      kSleepPersonalFullBlendSamples))
              .clamp(0.0, 1.0);
      weight +=
          extra *
          (kSleepPersonalHighBlendWeight - kSleepPersonalMaxBlendWeight);
    }
    return weight * freshness.clamp(0.0, 1.0);
  }

  /// Ventana de vigilia personalizada y el peso con el que se ha personalizado.
  ({int minutes, double weight}) blendedWakeWindow({
    required int ageWindowMinutes,
    required SleepWakeSlot slot,
    int? napIndex,
  }) {
    final stats = resolveStats(slot: slot, napIndex: napIndex);
    final personal = stats.medianMinutes;
    if (personal == null || !stats.hasBlendableData) {
      return (minutes: ageWindowMinutes, weight: 0);
    }
    final w = stats.blendWeight;
    if (w <= 0) return (minutes: ageWindowMinutes, weight: 0);
    return (
      minutes: (ageWindowMinutes * (1 - w) + personal * w).round(),
      weight: w,
    );
  }

  /// Mezcla la siesta típica de la tabla de edad con la duración real.
  int blendedTypicalNapMinutes({required int ageTypicalNapMinutes}) {
    final median = medianNapMinutes;
    if (median == null || !hasLearnedNapDuration) return ageTypicalNapMinutes;
    final w = blendWeight(
      sampleCount: napDurationSampleCount,
      freshness: napDurationFreshness,
      relativeDispersion: _napDurationDispersion,
    );
    if (w <= 0) return ageTypicalNapMinutes;
    return (ageTypicalNapMinutes * (1 - w) + median * w).round();
  }

  double? get _napDurationDispersion {
    final median = medianNapMinutes;
    final p25 = p25NapMinutes;
    final p75 = p75NapMinutes;
    if (median == null || median <= 0 || p25 == null || p75 == null) {
      return null;
    }
    return (p75 - p25) / median;
  }

  /// Umbral de "siesta corta": el p25 del propio bebé, acotado para no llamar
  /// normal a una cabezada ni corta a una siesta larga.
  int shortNapThresholdMinutes({required int ageMinNapMinutes}) =>
      _shortNapThreshold(
        p25NapMinutes: p25NapMinutes,
        napDurationSampleCount: napDurationSampleCount,
        freshness: napDurationFreshness,
        ageMinNapMinutes: ageMinNapMinutes,
      );

  /// Minutos a sumar a la ventana si la siesta anterior fue más corta de lo
  /// habitual (valor ≤ 0). Las siestas largas no alargan la vigilia: en la
  /// práctica no implica que aguante más despierto. `null` si todavía no se
  /// conoce la duración habitual y hay que usar la regla binaria de siesta corta.
  int? napDeviationAdjustmentMinutes(int lastNapMinutes) {
    final median = medianNapMinutes;
    if (median == null || !hasLearnedNapDuration) return null;
    final deviation = lastNapMinutes - median;
    if (deviation >= -kSleepPersonalMinNapDeviationMinutes) return 0;
    final slope =
        learnedNapDeviationSlope ?? kSleepPersonalDefaultNapDeviationSlope;
    return (deviation * slope).round().clamp(
      -kSleepPersonalMaxNapDeviationAdjustMinutes,
      0,
    );
  }

  /// Mitades de rango UI (antes/después del target) según IQR o default.
  ({int before, int after}) displayHalfRanges({
    required SleepWakeSlot slot,
    int? napIndex,
  }) {
    final stats = resolveStats(slot: slot, napIndex: napIndex);
    final median = stats.medianMinutes;
    final p25 = stats.p25Minutes;
    final p75 = stats.p75Minutes;
    if (median == null ||
        p25 == null ||
        p75 == null ||
        !stats.hasBlendableData) {
      return (
        before: kSleepPersonalDefaultHalfRangeMinutes,
        after: kSleepPersonalDefaultHalfRangeMinutes,
      );
    }
    final before = (median - p25)
        .clamp(
          kSleepPersonalMinHalfRangeMinutes,
          kSleepPersonalMaxHalfRangeMinutes,
        )
        .toInt();
    final after = (p75 - median)
        .clamp(
          kSleepPersonalMinHalfRangeMinutes,
          kSleepPersonalMaxHalfRangeMinutes,
        )
        .toInt();
    return (before: before, after: after);
  }

  bool get hasLearnedMorningWake =>
      morningWakeSampleCount >= kSleepPersonalMinSamplesForSchedule &&
      medianMorningWakeMinutesOfDay != null;

  bool get hasLearnedBedtime =>
      bedtimeSampleCount >= kSleepPersonalMinSamplesForSchedule &&
      medianBedtimeMinutesOfDay != null;

  bool get hasLearnedShortNapPenalty =>
      shortNapPenaltySampleCount >= kSleepPersonalMinSamplesForBlend &&
      learnedShortNapPenaltyMinutes != null;

  bool get hasLearnedNapCount =>
      napCountDaySampleCount >= kSleepPersonalMinDaysForNapCount &&
      napCountFreshness >= kSleepPersonalMinFreshnessForRules &&
      medianNapsPerDay != null;

  bool get hasLearnedNapDuration =>
      napDurationSampleCount >= kSleepPersonalMinNapsForDuration &&
      napDurationFreshness > 0 &&
      medianNapMinutes != null;

  /// Construye stats desde registros en la ventana de lookback.
  factory SleepPersonalStats.fromRecords({
    required List<SleepRecord> records,
    required DateTime now,
    required int minNapMinutes,
    int lookbackDays = kSleepPersonalLookbackDays,
  }) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final from = todayStart.subtract(Duration(days: lookbackDays));

    final inWindow =
        records
            .where(
              (r) =>
                  r.isSleepBlock &&
                  r.endDateTime != null &&
                  !r.endDateTime!.isBefore(from) &&
                  r.endDateTime!.isBefore(now.add(const Duration(days: 1))),
            )
            .toList()
          ..sort((a, b) => a.endDateTime!.compareTo(b.endDateTime!));

    // Orden de cada siesta dentro de su día, para agrupar la vigilia por el
    // mismo criterio que la tabla de edad.
    final napStartsByDay = <DateTime, List<DateTime>>{};
    for (final record in inWindow) {
      if (record.type != SleepType.nap) continue;
      final start = record.startDateTime;
      final day = DateTime(start.year, start.month, start.day);
      (napStartsByDay[day] ??= <DateTime>[]).add(start);
    }
    for (final starts in napStartsByDay.values) {
      starts.sort();
    }
    int? napOrdinalOf(SleepRecord nap) {
      final start = nap.startDateTime;
      final day = DateTime(start.year, start.month, start.day);
      final index = napStartsByDay[day]?.indexOf(start) ?? -1;
      return index < 0 ? null : index;
    }

    final awakeBySlot = <SleepWakeSlot, _Samples>{
      for (final s in SleepWakeSlot.values) s: _Samples(),
    };
    final awakeByNapIndex = <int, _Samples>{};
    final morningWake = _Samples();
    final bedtime = _Samples();
    final napDurations = _Samples();
    final shortNapPenalties = _Samples();
    final napSlopes = _Samples();
    // Siestas por día civil, solo días ya cerrados (hoy va a medias).
    final napsPerDay = <DateTime, int>{};

    for (var i = 0; i < inWindow.length; i++) {
      final current = inWindow[i];
      final currentEnd = current.endDateTime!;
      final weight = _recencyWeight(currentEnd, todayStart);

      if (current.type == SleepType.night) {
        morningWake.add(_minutesOfDay(currentEnd), weight);
        bedtime.add(_bedtimeMinutesOfDay(current.startDateTime), weight);
      } else if (current.type == SleepType.nap) {
        final napMinutes = current.durationSeconds() ~/ 60;
        if (napMinutes >= kSleepPersonalMinNapSampleMinutes &&
            napMinutes <= kSleepPersonalMaxNapSampleMinutes) {
          napDurations.add(napMinutes, weight);
        }
        final day = DateTime(currentEnd.year, currentEnd.month, currentEnd.day);
        if (day.isBefore(todayStart)) {
          napsPerDay[day] = (napsPerDay[day] ?? 0) + 1;
        }
      }

      if (i + 1 >= inWindow.length) continue;
      final next = inWindow[i + 1];
      final awake = next.startDateTime.difference(currentEnd).inMinutes;
      if (awake < kSleepPersonalMinAwakeMinutes ||
          awake > kSleepPersonalMaxAwakeMinutes) {
        continue;
      }
      awakeBySlot[sleepWakeSlotForDateTime(currentEnd)]!.add(awake, weight);
      if (next.type == SleepType.nap) {
        final ordinal = napOrdinalOf(next);
        if (ordinal != null) {
          (awakeByNapIndex[ordinal] ??= _Samples()).add(awake, weight);
        }
      }
    }

    final wakeBySlot = <SleepWakeSlot, SlotWakeStats>{
      for (final slot in SleepWakeSlot.values)
        slot: awakeBySlot[slot]!.toStats(),
    };
    final wakeByNapIndex = <int, SlotWakeStats>{
      for (final entry in awakeByNapIndex.entries)
        entry.key: entry.value.toStats(),
    };

    final napStats = napDurations.toStats();
    final medianNap = napStats.medianMinutes;
    // El umbral de "siesta corta" se calcula antes del segundo pase para que
    // las penalizaciones se midan con el mismo criterio que luego se aplica.
    final shortNapThreshold = _shortNapThreshold(
      p25NapMinutes: napStats.p25Minutes,
      napDurationSampleCount: napStats.sampleCount,
      freshness: napStats.freshness,
      ageMinNapMinutes: minNapMinutes,
    );

    int? baselineFor(DateTime wakeUp, SleepRecord? next) {
      final ordinal = next != null && next.type == SleepType.nap
          ? napOrdinalOf(next)
          : null;
      if (ordinal != null) {
        final byIndex = wakeByNapIndex[ordinal];
        if (byIndex != null && byIndex.hasBlendableData) {
          return byIndex.medianMinutes;
        }
      }
      return wakeBySlot[sleepWakeSlotForDateTime(wakeUp)]?.medianMinutes;
    }

    // Segundo pase: separar las vigilias que siguen a una siesta normal de las
    // que siguen a una atípica. Comparar cada grupo con el otro evita que la
    // referencia se contamine con las propias muestras que se están midiendo.
    final normalAwakeByIndex = <int, _Samples>{};
    final normalAwakeBySlot = <SleepWakeSlot, _Samples>{
      for (final s in SleepWakeSlot.values) s: _Samples(),
    };
    final deviating =
        <
          ({
            int deviation,
            int awake,
            int? ordinal,
            SleepWakeSlot slot,
            double weight,
          })
        >[];

    for (var i = 0; i < inWindow.length; i++) {
      final current = inWindow[i];
      if (current.type != SleepType.nap) continue;
      if (i + 1 >= inWindow.length) continue;

      final next = inWindow[i + 1];
      final currentEnd = current.endDateTime!;
      final awake = next.startDateTime.difference(currentEnd).inMinutes;
      if (awake < kSleepPersonalMinAwakeMinutes ||
          awake > kSleepPersonalMaxAwakeMinutes) {
        continue;
      }

      final napMin = current.durationSeconds() ~/ 60;
      final weight = _recencyWeight(currentEnd, todayStart);
      final slot = sleepWakeSlotForDateTime(currentEnd);
      final ordinal = next.type == SleepType.nap ? napOrdinalOf(next) : null;

      if (medianNap != null) {
        final deviation = napMin - medianNap;
        if (deviation.abs() < kSleepPersonalMinNapDeviationMinutes) {
          if (ordinal != null) {
            (normalAwakeByIndex[ordinal] ??= _Samples()).add(awake, weight);
          }
          normalAwakeBySlot[slot]!.add(awake, weight);
        } else {
          deviating.add((
            deviation: deviation,
            awake: awake,
            ordinal: ordinal,
            slot: slot,
            weight: weight,
          ));
        }
      }

      if (napMin >= shortNapThreshold) continue;
      final baseline = baselineFor(currentEnd, next);
      if (baseline == null) continue;
      final advance = baseline - awake;
      if (advance >= kSleepPersonalLearnedPenaltyMinMinutes) {
        shortNapPenalties.add(
          advance
              .clamp(
                kSleepPersonalLearnedPenaltyMinMinutes,
                kSleepPersonalLearnedPenaltyMaxMinutes,
              )
              .toInt(),
          weight,
        );
      }
    }

    for (final sample in deviating) {
      final ordinal = sample.ordinal;
      final byIndex = ordinal == null ? null : normalAwakeByIndex[ordinal];
      final bucket =
          byIndex != null && byIndex.length >= kSleepPersonalMinSamplesForBlend
          ? byIndex
          : normalAwakeBySlot[sample.slot]!;
      if (bucket.length < kSleepPersonalMinSamplesForBlend) continue;
      final baseline = bucket.percentileDouble(0.5);
      if (baseline == null) continue;
      napSlopes.add(
        (sample.awake - baseline) / sample.deviation,
        sample.weight,
      );
    }

    final napsPerDaySamples = _Samples();
    for (final entry in napsPerDay.entries) {
      napsPerDaySamples.add(entry.value, _recencyWeight(entry.key, todayStart));
    }
    final napsPerDayStats = napsPerDaySamples.toStats();

    final slope = napSlopes.length >= kSleepPersonalMinSamplesForNapSlope
        ? napSlopes.percentileDouble(0.5)?.clamp(0.0, 1.0)
        : null;

    return SleepPersonalStats(
      wakeBySlot: wakeBySlot,
      wakeByNapIndex: wakeByNapIndex,
      medianMorningWakeMinutesOfDay: morningWake.percentile(0.5),
      morningWakeSampleCount: morningWake.length,
      medianBedtimeMinutesOfDay: bedtime.percentile(0.5),
      bedtimeSampleCount: bedtime.length,
      learnedShortNapPenaltyMinutes: shortNapPenalties.percentile(0.5),
      shortNapPenaltySampleCount: shortNapPenalties.length,
      medianNapsPerDay: napsPerDayStats.medianMinutes,
      napCountDaySampleCount: napsPerDayStats.sampleCount,
      napCountFreshness: napsPerDayStats.freshness,
      medianNapMinutes: medianNap,
      p25NapMinutes: napStats.p25Minutes,
      p75NapMinutes: napStats.p75Minutes,
      napDurationSampleCount: napStats.sampleCount,
      napDurationFreshness: napStats.freshness,
      learnedNapDeviationSlope: slope,
      napDeviationSampleCount: napSlopes.length,
    );
  }
}

int _shortNapThreshold({
  required int? p25NapMinutes,
  required int napDurationSampleCount,
  required double freshness,
  required int ageMinNapMinutes,
}) {
  if (p25NapMinutes == null ||
      napDurationSampleCount < kSleepPersonalMinNapsForDuration ||
      freshness < kSleepPersonalMinFreshnessForRules) {
    return ageMinNapMinutes;
  }
  final ceiling = (ageMinNapMinutes * kSleepPersonalMaxShortNapThresholdFactor)
      .round();
  if (ceiling <= kSleepPersonalMinShortNapThresholdMinutes) {
    return ageMinNapMinutes;
  }
  return p25NapMinutes.clamp(
    kSleepPersonalMinShortNapThresholdMinutes,
    ceiling,
  );
}

/// Peso por antigüedad: 1 hoy, 0,5 a una media vida, etc.
double _recencyWeight(DateTime sample, DateTime todayStart) {
  final sampleDay = DateTime(sample.year, sample.month, sample.day);
  final days = todayStart.difference(sampleDay).inDays;
  if (days <= 0) return 1;
  return math.pow(0.5, days / kSleepPersonalRecencyHalfLifeDays).toDouble();
}

int _minutesOfDay(DateTime dt) => dt.hour * 60 + dt.minute;

/// Hora de acostarse: si empieza de madrugada (&lt;12h), se trata como día previo +24h.
int _bedtimeMinutesOfDay(DateTime start) {
  final m = _minutesOfDay(start);
  if (start.hour < 12) return m + 24 * 60;
  return m;
}

/// Muestras con peso por recencia y percentiles ponderados.
class _Samples {
  final List<double> _values = [];
  final List<double> _weights = [];
  double _totalWeight = 0;
  double _maxWeight = 0;

  void add(num value, double weight) {
    if (weight <= 0) return;
    _values.add(value.toDouble());
    _weights.add(weight);
    _totalWeight += weight;
    if (weight > _maxWeight) _maxWeight = weight;
  }

  int get length => _values.length;

  /// Percentil ponderado: primer valor cuyo peso acumulado alcanza p·total.
  double? percentileDouble(double p) {
    if (_values.isEmpty) return null;
    final order = List<int>.generate(_values.length, (i) => i)
      ..sort((a, b) => _values[a].compareTo(_values[b]));
    final target = _totalWeight * p;
    var accumulated = 0.0;
    for (final i in order) {
      accumulated += _weights[i];
      if (accumulated >= target) return _values[i];
    }
    return _values[order.last];
  }

  int? percentile(double p) => percentileDouble(p)?.round();

  SlotWakeStats toStats() => SlotWakeStats(
    sampleCount: length,
    medianMinutes: percentile(0.5),
    p25Minutes: percentile(0.25),
    p75Minutes: percentile(0.75),
    freshness: _maxWeight,
  );
}

/// Peso de mezcla expuesto para tests (muestras de hoy).
double sleepPersonalBlendWeight(int sampleCount) =>
    SleepPersonalStats.blendWeight(sampleCount: sampleCount, freshness: 1);
