import '../models/enums.dart';
import '../models/sleep_record.dart';

/// Ventana actual del patrón habitual.
const int kSleepUsualPatternLookbackDays = 14;

/// Necesario para comparar con la ventana anterior (tendencia).
const int kSleepUsualPatternHistoryDays = kSleepUsualPatternLookbackDays * 2;

/// Muestras mínimas para mostrar la fila (0–2 → desaparece).
const int kSleepUsualPatternMinSamplesToShow = 3;

/// Por debajo → frase de espera.
const int kSleepUsualPatternMinSamplesForInsight = 5;

/// Frecuencia mínima (sobre [kSleepUsualPatternLookbackDays]) para no usar
/// frase de frecuencia. 85% de 14 ≈ 11.9 → hacen falta ≥ 12 días.
const double kSleepUsualPatternFrequencyThreshold = 0.85;

/// Umbral de retraso de inicio vs semana anterior (min).
const int kSleepUsualPatternTrendStartDeltaMinutes = 40;

/// Umbral de acortamiento de duración vs semana anterior (min).
const int kSleepUsualPatternTrendDurationDeltaMinutes = 20;

/// Caída mínima de días vs ventana anterior para tendencia de frecuencia.
const int kSleepUsualPatternTrendFewerDaysDelta = 3;

/// Nombre de franja según la hora habitual de inicio.
enum UsualSleepSlotKind { morningNap, middayNap, afternoonNap, catnap, night }

/// Tipo de frase bajo el nombre (gana la primera condición que aplique).
enum UsualSleepPhraseKind {
  /// &lt; 5 registros.
  waiting,

  /// 7–11 de 14: frecuencia + hora.
  frequencyWithTime,

  /// 3–6 de 14: solo frecuencia (tras el filtro de espera, queda 5–6).
  frequencyOnly,

  /// Menos días que la ventana anterior.
  trendFewerDays,

  /// Empieza ≥ 40 min más tarde.
  trendStartsLater,

  /// Dura menos que la ventana anterior.
  trendShorterDuration,

  /// Dispersión baja.
  regularityAlmostAlways,

  /// Dispersión media.
  regularityUsuallyBetween,

  /// Dispersión alta.
  regularityMayBetween,
}

/// Slot listo para UI.
class UsualSleepSlot {
  final UsualSleepSlotKind kind;

  /// Posición de la siesta dentro de su franja (1 = nombre sin sufijo).
  final int occurrenceIndex;
  final int sampleCount;
  final int lookbackDays;
  final int medianDurationSeconds;

  /// Mediana de inicio redondeada a 5 min.
  final int medianStartMinutesOfDay;

  /// Mediana de fin (inicio + duración), redondeada a 5 min (puede ≥ 1440).
  final int medianEndMinutesOfDay;

  final UsualSleepPhraseKind phraseKind;

  /// Hora redondeada a 5 min (mediana o ancla de frase).
  final int? phraseTimeMinutes;

  /// Extremo inferior del rango (P25 redondeado), si aplica.
  final int? phraseRangeStartMinutes;

  /// Extremo superior del rango (P75 redondeado), si aplica.
  final int? phraseRangeEndMinutes;

  /// Minutos de retraso para tendencia (redondeados a 5).
  final int? trendDeltaMinutes;

  const UsualSleepSlot({
    required this.kind,
    this.occurrenceIndex = 1,
    required this.sampleCount,
    required this.lookbackDays,
    required this.medianDurationSeconds,
    required this.medianStartMinutesOfDay,
    required this.medianEndMinutesOfDay,
    required this.phraseKind,
    this.phraseTimeMinutes,
    this.phraseRangeStartMinutes,
    this.phraseRangeEndMinutes,
    this.trendDeltaMinutes,
  });

  bool get isNight => kind == UsualSleepSlotKind.night;

  bool get isNap => !isNight;
}

/// Siesta que casi ha desaparecido (0–2 días actuales, sí en la ventana previa).
class UsualSleepAbandonedNap {
  final UsualSleepSlotKind kind;
  final int occurrenceIndex;

  const UsualSleepAbandonedNap({required this.kind, this.occurrenceIndex = 1});
}

/// Resultado del patrón habitual (ventana actual + notas).
class UsualSleepPattern {
  final List<UsualSleepSlot> slots;
  final List<UsualSleepAbandonedNap> abandonedNaps;

  /// Días de la ventana con al menos un sueño cerrado.
  final int completeDays;
  final int lookbackDays;

  const UsualSleepPattern({
    required this.slots,
    required this.abandonedNaps,
    required this.completeDays,
    this.lookbackDays = kSleepUsualPatternLookbackDays,
  });

  bool get isEmpty => slots.isEmpty && abandonedNaps.isEmpty;

  bool get hasFullLookback => completeDays >= lookbackDays;
}

/// Calcula el patrón habitual (mediana / IQR) sobre 14 días + tendencia vs 14 previos.
UsualSleepPattern computeUsualSleepPattern({
  required List<SleepRecord> records,
  required DateTime now,
  int lookbackDays = kSleepUsualPatternLookbackDays,
}) {
  final todayStart = DateTime(now.year, now.month, now.day);
  final currentStart = todayStart.subtract(Duration(days: lookbackDays - 1));
  final previousStart = currentStart.subtract(Duration(days: lookbackDays));

  final current = _collectWindow(
    records: records,
    windowStart: currentStart,
    dayCount: lookbackDays,
  );
  final previous = _collectWindow(
    records: records,
    windowStart: previousStart,
    dayCount: lookbackDays,
  );

  final slots = <UsualSleepSlot>[];
  final abandoned = <UsualSleepAbandonedNap>[];

  for (final kind in UsualSleepSlotKind.values) {
    final currentBuckets = current.byKind[kind] ?? const <_KindBucket>[];
    final previousBuckets = previous.byKind[kind] ?? const <_KindBucket>[];
    final occurrenceCount = currentBuckets.length > previousBuckets.length
        ? currentBuckets.length
        : previousBuckets.length;

    for (
      var occurrenceIndex = 0;
      occurrenceIndex < occurrenceCount;
      occurrenceIndex++
    ) {
      final cur = occurrenceIndex < currentBuckets.length
          ? currentBuckets[occurrenceIndex]
          : null;
      final prev = occurrenceIndex < previousBuckets.length
          ? previousBuckets[occurrenceIndex]
          : null;
      final samples = cur?.starts.length ?? 0;
      final prevSamples = prev?.starts.length ?? 0;

      if (samples < kSleepUsualPatternMinSamplesToShow) {
        if (samples <= 2 &&
            prevSamples >= kSleepUsualPatternMinSamplesToShow &&
            kind != UsualSleepSlotKind.night) {
          abandoned.add(
            UsualSleepAbandonedNap(
              kind: kind,
              occurrenceIndex: occurrenceIndex + 1,
            ),
          );
        }
        continue;
      }

      final starts = cur!.starts;
      final durations = cur.durations;
      final medianStart = _percentile(starts, 0.5)!;
      final p25 = _percentile(starts, 0.25)!;
      final p75 = _percentile(starts, 0.75)!;
      final medianDuration = _percentile(durations, 0.5)!;
      final dispersion = p75 - p25;

      final phrase = _resolvePhrase(
        kind: kind,
        sampleCount: samples,
        lookbackDays: lookbackDays,
        medianStart: medianStart,
        startP25: p25,
        startP75: p75,
        dispersion: dispersion,
        medianDurationSeconds: medianDuration,
        previousSampleCount: prevSamples,
        previousMedianStart: prev == null || prev.starts.isEmpty
            ? null
            : _percentile(prev.starts, 0.5),
        previousMedianDurationSeconds: prev == null || prev.durations.isEmpty
            ? null
            : _percentile(prev.durations, 0.5),
      );

      final startRounded = roundMinutesToFive(medianStart);
      final endRounded = roundMinutesToFive(medianStart + medianDuration ~/ 60);

      slots.add(
        UsualSleepSlot(
          kind: kind,
          occurrenceIndex: occurrenceIndex + 1,
          sampleCount: samples,
          lookbackDays: lookbackDays,
          medianDurationSeconds: medianDuration,
          medianStartMinutesOfDay: startRounded,
          medianEndMinutesOfDay: endRounded,
          phraseKind: phrase.kind,
          phraseTimeMinutes: phrase.timeMinutes,
          phraseRangeStartMinutes: phrase.rangeStart,
          phraseRangeEndMinutes: phrase.rangeEnd,
          trendDeltaMinutes: phrase.trendDelta,
        ),
      );
    }
  }

  // Orden visual: siestas por hora típica, noche al final.
  slots.sort((a, b) {
    if (a.isNight && !b.isNight) return 1;
    if (!a.isNight && b.isNight) return -1;
    final kindComparison = a.kind.index.compareTo(b.kind.index);
    if (kindComparison != 0) return kindComparison;
    return a.occurrenceIndex.compareTo(b.occurrenceIndex);
  });

  final cappedSlots = _capNapSlotsToDailyMax(
    slots,
    maxNapsPerDay: current.maxNapsPerDay,
  );

  return UsualSleepPattern(
    slots: cappedSlots,
    abandonedNaps: abandoned,
    completeDays: current.completeDays,
    lookbackDays: lookbackDays,
  );
}

class _PhraseResolved {
  final UsualSleepPhraseKind kind;
  final int? timeMinutes;
  final int? rangeStart;
  final int? rangeEnd;
  final int? trendDelta;

  const _PhraseResolved({
    required this.kind,
    this.timeMinutes,
    this.rangeStart,
    this.rangeEnd,
    this.trendDelta,
  });
}

_PhraseResolved _resolvePhrase({
  required UsualSleepSlotKind kind,
  required int sampleCount,
  required int lookbackDays,
  required int medianStart,
  required int startP25,
  required int startP75,
  required int dispersion,
  required int medianDurationSeconds,
  required int previousSampleCount,
  required int? previousMedianStart,
  required int? previousMedianDurationSeconds,
}) {
  final roundedMedian = roundMinutesToFive(medianStart);
  final roundedP25 = roundMinutesToFive(startP25);
  final roundedP75 = roundMinutesToFive(startP75);
  final isNight = kind == UsualSleepSlotKind.night;

  // 1) Pocos datos
  if (sampleCount < kSleepUsualPatternMinSamplesForInsight) {
    return const _PhraseResolved(kind: UsualSleepPhraseKind.waiting);
  }

  // 2) Baja frecuencia (&lt; 85% de la ventana)
  final freqRatio = sampleCount / lookbackDays;
  if (freqRatio < kSleepUsualPatternFrequencyThreshold) {
    if (sampleCount <= 6) {
      return const _PhraseResolved(kind: UsualSleepPhraseKind.frequencyOnly);
    }
    return _PhraseResolved(
      kind: UsualSleepPhraseKind.frequencyWithTime,
      timeMinutes: roundedMedian,
    );
  }

  // 3) Tendencia fuerte vs ventana anterior
  if (previousSampleCount >= kSleepUsualPatternMinSamplesToShow) {
    if (previousSampleCount - sampleCount >=
        kSleepUsualPatternTrendFewerDaysDelta) {
      return const _PhraseResolved(kind: UsualSleepPhraseKind.trendFewerDays);
    }
    if (previousMedianStart != null) {
      final delta = medianStart - previousMedianStart;
      if (delta >= kSleepUsualPatternTrendStartDeltaMinutes) {
        return _PhraseResolved(
          kind: UsualSleepPhraseKind.trendStartsLater,
          trendDelta: roundMinutesToFive(delta),
        );
      }
    }
    if (previousMedianDurationSeconds != null) {
      final deltaMin =
          (previousMedianDurationSeconds - medianDurationSeconds) ~/ 60;
      if (deltaMin >= kSleepUsualPatternTrendDurationDeltaMinutes) {
        return const _PhraseResolved(
          kind: UsualSleepPhraseKind.trendShorterDuration,
        );
      }
    }
  }

  // 4) Regularidad (dispersión de inicio)
  final lowMax = isNight ? 15 : 20;
  final midMax = isNight ? 35 : 45;
  if (dispersion <= lowMax) {
    return _PhraseResolved(
      kind: UsualSleepPhraseKind.regularityAlmostAlways,
      timeMinutes: roundedMedian,
    );
  }
  if (dispersion <= midMax) {
    return _PhraseResolved(
      kind: UsualSleepPhraseKind.regularityUsuallyBetween,
      rangeStart: roundedP25,
      rangeEnd: roundedP75,
    );
  }
  return _PhraseResolved(
    kind: UsualSleepPhraseKind.regularityMayBetween,
    rangeStart: roundedP25,
    rangeEnd: roundedP75,
  );
}

class _KindBucket {
  final List<int> starts = [];
  final List<int> durations = [];
}

class _WindowCollection {
  final Map<UsualSleepSlotKind, List<_KindBucket>> byKind;
  final int completeDays;

  /// Máximo de siestas en un solo día de la ventana (0 si no hubo).
  final int maxNapsPerDay;

  const _WindowCollection({
    required this.byKind,
    required this.completeDays,
    this.maxNapsPerDay = 0,
  });
}

_WindowCollection _collectWindow({
  required List<SleepRecord> records,
  required DateTime windowStart,
  required int dayCount,
}) {
  final byKind = {
    for (final k in UsualSleepSlotKind.values) k: <_KindBucket>[],
  };
  var completeDays = 0;
  var maxNapsPerDay = 0;

  for (var dayOffset = 0; dayOffset < dayCount; dayOffset++) {
    final day = windowStart.add(Duration(days: dayOffset));
    final dayEnd = day.add(const Duration(days: 1));

    final naps = <SleepRecord>[];
    SleepRecord? night;
    var hadSleep = false;

    for (final record in records) {
      if (!record.isSleepBlock || record.isOpen) continue;
      final end = record.endDateTime;
      if (end == null) continue;
      if (record.startDateTime.isBefore(day) ||
          !record.startDateTime.isBefore(dayEnd)) {
        continue;
      }
      hadSleep = true;
      if (record.type == SleepType.nap) {
        naps.add(record);
      } else if (record.type == SleepType.night) {
        if (night == null ||
            record.durationSeconds() > night.durationSeconds()) {
          night = record;
        }
      }
    }

    if (hadSleep) completeDays++;
    if (naps.length > maxNapsPerDay) maxNapsPerDay = naps.length;

    final napsByKind = <UsualSleepSlotKind, List<SleepRecord>>{};
    for (final nap in naps) {
      final kind = napKindForStartMinutes(_minutesOfDay(nap.startDateTime));
      (napsByKind[kind] ??= []).add(nap);
    }
    for (final entry in napsByKind.entries) {
      final sortedNaps = entry.value
        ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      final buckets = byKind[entry.key]!;
      for (var i = 0; i < sortedNaps.length; i++) {
        if (buckets.length <= i) buckets.add(_KindBucket());
        final nap = sortedNaps[i];
        buckets[i].starts.add(_minutesOfDay(nap.startDateTime));
        buckets[i].durations.add(nap.durationSeconds());
      }
    }

    if (night != null) {
      final nightBuckets = byKind[UsualSleepSlotKind.night]!;
      if (nightBuckets.isEmpty) nightBuckets.add(_KindBucket());
      nightBuckets.first.starts.add(_minutesOfDay(night.startDateTime));
      nightBuckets.first.durations.add(night.durationSeconds());
    }
  }

  return _WindowCollection(
    byKind: byKind,
    completeDays: completeDays,
    maxNapsPerDay: maxNapsPerDay,
  );
}

/// Si el agrupado por franja genera más filas que siestas reales en un día,
/// se quedan las más frecuentes (y más tempranas a igualdad).
List<UsualSleepSlot> _capNapSlotsToDailyMax(
  List<UsualSleepSlot> slots, {
  required int maxNapsPerDay,
}) {
  if (maxNapsPerDay <= 0) return slots;
  final naps = slots.where((s) => s.isNap).toList();
  final nights = slots.where((s) => s.isNight).toList();
  if (naps.length <= maxNapsPerDay) return slots;

  naps.sort((a, b) {
    final bySamples = b.sampleCount.compareTo(a.sampleCount);
    if (bySamples != 0) return bySamples;
    return a.medianStartMinutesOfDay.compareTo(b.medianStartMinutesOfDay);
  });
  final kept = naps.take(maxNapsPerDay).toList()
    ..sort((a, b) {
      final kindComparison = a.kind.index.compareTo(b.kind.index);
      if (kindComparison != 0) return kindComparison;
      return a.occurrenceIndex.compareTo(b.occurrenceIndex);
    });
  return [...kept, ...nights];
}

UsualSleepSlotKind napKindForStartMinutes(int minutesOfDay) {
  final m = ((minutesOfDay % (24 * 60)) + (24 * 60)) % (24 * 60);
  if (m < 11 * 60) return UsualSleepSlotKind.morningNap;
  if (m < 14 * 60 + 30) return UsualSleepSlotKind.middayNap;
  if (m < 17 * 60 + 30) return UsualSleepSlotKind.afternoonNap;
  return UsualSleepSlotKind.catnap;
}

/// Redondeo al múltiplo de 5 minutos más cercano (0…1435+).
int roundMinutesToFive(int minutes) {
  if (minutes < 0) return 0;
  return ((minutes + 2) ~/ 5) * 5;
}

int _minutesOfDay(DateTime dt) => dt.hour * 60 + dt.minute;

int? _percentile(List<int> values, double p) {
  if (values.isEmpty) return null;
  final sorted = List<int>.from(values)..sort();
  if (sorted.length == 1) return sorted.first;
  final rank = (sorted.length - 1) * p;
  final low = rank.floor();
  final high = rank.ceil();
  if (low == high) return sorted[low];
  final weight = rank - low;
  return (sorted[low] * (1 - weight) + sorted[high] * weight).round();
}
