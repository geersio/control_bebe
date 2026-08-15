import '../../../core/db/isar_service.dart';
import '../../../core/models/baby_profile.dart';
import '../../../core/models/diaper_record.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/feeding_record.dart';
import '../../../core/models/height_record.dart';
import '../../../core/models/sleep_record.dart';
import '../../../core/models/weight_record.dart';
import '../../../core/percentiles_data.dart';
import '../../../core/utils/baby_age_calendar.dart';
import '../../../core/utils/breast_intake_estimate.dart';
import '../../../core/utils/sleep_home_summary.dart';
import '../../../core/utils/weight_daily_trend.dart';

/// Días de actividad (tomas y pañales) resumidos en el bloque principal.
const int kReportActivityDays = 7;

/// Ventanas ampliadas al final del informe.
const int kReportMidPeriodDays = 15;
const int kReportLongPeriodDays = 30;

/// Histórico cargado para comparativas (30 días actuales + 30 anteriores).
const int kReportHistoryDays = 60;

/// Umbral de cobertura de registro: por debajo, las medias se atenúan.
const double kReportMinCoverageRatio = 0.70;

/// Sucio o mixto (mojado + sucio) cuenta como deposición.
bool diaperTypeIncludesStool(DiaperType type) =>
    type == DiaperType.dirty || type == DiaperType.both;

/// Estadísticas de alimentación y pañales en una ventana de [days] días
/// terminando en [periodEnd] (solo la fecha, sin hora).
class ReportPeriodStats {
  final int days;
  final int feedCount;
  final int breastFeedCount;
  final int leftBreastCount;
  final int rightBreastCount;
  final int bottleFeedCount;
  final int solidFeedCount;
  final int totalBottleMl;
  final int totalBreastSeconds;
  final double estimatedLeftBreastMl;
  final double estimatedRightBreastMl;
  final int diaperCount;
  final int wetDiaperCount;
  final int dirtyDiaperCount;
  final int bothDiaperCount;

  const ReportPeriodStats({
    required this.days,
    this.feedCount = 0,
    this.breastFeedCount = 0,
    this.leftBreastCount = 0,
    this.rightBreastCount = 0,
    this.bottleFeedCount = 0,
    this.solidFeedCount = 0,
    this.totalBottleMl = 0,
    this.totalBreastSeconds = 0,
    this.estimatedLeftBreastMl = 0,
    this.estimatedRightBreastMl = 0,
    this.diaperCount = 0,
    this.wetDiaperCount = 0,
    this.dirtyDiaperCount = 0,
    this.bothDiaperCount = 0,
  });

  double get averageFeedsPerDay => feedCount / days;
  double get averageDiapersPerDay => diaperCount / days;
  double get averageBottleMlPerDay => totalBottleMl / days;
  double get averageBreastMinutesPerDay => totalBreastSeconds / 60 / days;
  double get averageWetDiapersPerDay => wetDiaperCount / days;
  double get averageStoolDiapersPerDay =>
      (dirtyDiaperCount + bothDiaperCount) / days;
  double get estimatedBreastMlPerDay =>
      (estimatedLeftBreastMl + estimatedRightBreastMl) / days;

  int get stoolDiaperCount => dirtyDiaperCount + bothDiaperCount;

  bool get hasFeedingData => feedCount > 0;
  bool get hasDiaperData => diaperCount > 0;

  int percentOfBreastSide(int count) =>
      breastFeedCount == 0 ? 0 : ((count / breastFeedCount) * 100).round();

  int percentOfDiapers(int count) =>
      diaperCount == 0 ? 0 : ((count / diaperCount) * 100).round();
}

/// Estadísticas de sueño en una ventana de [days] días civiles.
class SleepPeriodStats {
  final int days;
  final int totalSleepSeconds;
  final int nightSleepCount;
  final int napCount;
  final int nightWakingCount;
  final int totalNightWakingSeconds;
  final int daysWithSleepData;

  const SleepPeriodStats({
    required this.days,
    this.totalSleepSeconds = 0,
    this.nightSleepCount = 0,
    this.napCount = 0,
    this.nightWakingCount = 0,
    this.totalNightWakingSeconds = 0,
    this.daysWithSleepData = 0,
  });

  bool get hasSleepData => daysWithSleepData > 0;

  double get averageSleepHoursPerRecordedDay =>
      daysWithSleepData == 0 ? 0 : totalSleepSeconds / 3600 / daysWithSleepData;

  double get averageNapsPerRecordedDay =>
      daysWithSleepData == 0 ? 0 : napCount / daysWithSleepData;

  double get averageNightWakingsPerRecordedDay =>
      daysWithSleepData == 0 ? 0 : nightWakingCount / daysWithSleepData;
}

/// Snapshot de datos para el informe del pediatra.
class PediatricReportData {
  final BabyProfile baby;
  final List<WeightRecord> weightRecords;
  final List<HeightRecord> heightRecords;
  final List<FeedingRecord> feedingsHistory;
  final List<DiaperRecord> diapersHistory;
  final List<SleepRecord> sleepHistory;
  final DateTime generatedAt;

  PediatricReportData({
    required this.baby,
    required this.weightRecords,
    this.heightRecords = const [],
    required this.feedingsHistory,
    required this.diapersHistory,
    this.sleepHistory = const [],
    required this.generatedAt,
  });

  static Future<PediatricReportData?> load() async {
    final baby = await IsarService.getBabyProfile();
    if (baby == null) return null;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final historyStart = todayStart.subtract(
      const Duration(days: kReportHistoryDays - 1),
    );

    final weights = await IsarService.getWeightRecords();
    final heights = await IsarService.getHeightRecords();
    final feedings = await IsarService.getFeedingRecordsSince(historyStart);
    final diapers = await IsarService.getDiaperRecordsSince(historyStart);
    final sleeps = await IsarService.getSleepRecordsSince(historyStart);

    weights.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    heights.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return PediatricReportData(
      baby: baby,
      weightRecords: weights,
      heightRecords: heights,
      feedingsHistory: feedings,
      diapersHistory: diapers,
      sleepHistory: sleeps,
      generatedAt: now,
    );
  }

  DateTime get _periodEnd =>
      DateTime(generatedAt.year, generatedAt.month, generatedAt.day);

  bool _isInInclusiveRange(DateTime dateTime, DateTime start, DateTime end) {
    final d = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  List<FeedingRecord> _feedingsInLastDays(int days) {
    final end = _periodEnd;
    final start = end.subtract(Duration(days: days - 1));
    return feedingsHistory
        .where((f) => _isInInclusiveRange(f.dateTime, start, end))
        .toList();
  }

  List<DiaperRecord> _diapersInLastDays(int days) {
    final end = _periodEnd;
    final start = end.subtract(Duration(days: days - 1));
    return diapersHistory
        .where((d) => _isInInclusiveRange(d.dateTime, start, end))
        .toList();
  }

  ReportPeriodStats periodStats(int days) {
    final feedings = _feedingsInLastDays(days);
    final diapers = _diapersInLastDays(days);

    var leftBreast = 0;
    var rightBreast = 0;
    var breastSeconds = 0;
    var leftMl = 0.0;
    var rightMl = 0.0;

    for (final f in feedings) {
      if (f.type == FeedingType.leftBreast) {
        leftBreast++;
        breastSeconds += f.durationSeconds ?? 0;
        leftMl += BreastIntakeEstimate.fromRecord(f);
      } else if (f.type == FeedingType.rightBreast) {
        rightBreast++;
        breastSeconds += f.durationSeconds ?? 0;
        rightMl += BreastIntakeEstimate.fromRecord(f);
      }
    }

    return ReportPeriodStats(
      days: days,
      feedCount: feedings.length,
      breastFeedCount: leftBreast + rightBreast,
      leftBreastCount: leftBreast,
      rightBreastCount: rightBreast,
      bottleFeedCount: feedings
          .where((f) => f.type == FeedingType.bottle)
          .length,
      solidFeedCount: feedings
          .where((f) => f.type == FeedingType.solidFood)
          .length,
      totalBottleMl: feedings
          .where((f) => f.type == FeedingType.bottle)
          .fold(0, (sum, f) => sum + (f.amountMl ?? 0)),
      totalBreastSeconds: breastSeconds,
      estimatedLeftBreastMl: leftMl,
      estimatedRightBreastMl: rightMl,
      diaperCount: diapers.length,
      wetDiaperCount: diapers.where((d) => d.type == DiaperType.wet).length,
      dirtyDiaperCount: diapers.where((d) => d.type == DiaperType.dirty).length,
      bothDiaperCount: diapers.where((d) => d.type == DiaperType.both).length,
    );
  }

  ReportPeriodStats previousPeriodStats(int days) {
    final currentEnd = _periodEnd.subtract(Duration(days: days));
    final currentStart = currentEnd.subtract(Duration(days: days - 1));

    final feedings = feedingsHistory
        .where((f) => _isInInclusiveRange(f.dateTime, currentStart, currentEnd))
        .toList();
    final diapers = diapersHistory
        .where((d) => _isInInclusiveRange(d.dateTime, currentStart, currentEnd))
        .toList();

    var leftBreast = 0;
    var rightBreast = 0;
    var breastSeconds = 0;
    var leftMl = 0.0;
    var rightMl = 0.0;

    for (final f in feedings) {
      if (f.type == FeedingType.leftBreast) {
        leftBreast++;
        breastSeconds += f.durationSeconds ?? 0;
        leftMl += BreastIntakeEstimate.fromRecord(f);
      } else if (f.type == FeedingType.rightBreast) {
        rightBreast++;
        breastSeconds += f.durationSeconds ?? 0;
        rightMl += BreastIntakeEstimate.fromRecord(f);
      }
    }

    return ReportPeriodStats(
      days: days,
      feedCount: feedings.length,
      breastFeedCount: leftBreast + rightBreast,
      leftBreastCount: leftBreast,
      rightBreastCount: rightBreast,
      bottleFeedCount: feedings
          .where((f) => f.type == FeedingType.bottle)
          .length,
      solidFeedCount: feedings
          .where((f) => f.type == FeedingType.solidFood)
          .length,
      totalBottleMl: feedings
          .where((f) => f.type == FeedingType.bottle)
          .fold(0, (sum, f) => sum + (f.amountMl ?? 0)),
      totalBreastSeconds: breastSeconds,
      estimatedLeftBreastMl: leftMl,
      estimatedRightBreastMl: rightMl,
      diaperCount: diapers.length,
      wetDiaperCount: diapers.where((d) => d.type == DiaperType.wet).length,
      dirtyDiaperCount: diapers.where((d) => d.type == DiaperType.dirty).length,
      bothDiaperCount: diapers.where((d) => d.type == DiaperType.both).length,
    );
  }

  SleepPeriodStats sleepPeriodStats(int days) {
    final end = _periodEnd;
    final start = end.subtract(Duration(days: days - 1));
    return _sleepStatsForRange(start, end, days);
  }

  SleepPeriodStats previousSleepPeriodStats(int days) {
    final end = _periodEnd.subtract(Duration(days: days));
    final start = end.subtract(Duration(days: days - 1));
    return _sleepStatsForRange(start, end, days);
  }

  SleepPeriodStats _sleepStatsForRange(DateTime start, DateTime end, int days) {
    var totalSeconds = 0;
    var nights = 0;
    var naps = 0;
    var wakings = 0;
    var wakingSeconds = 0;
    final recordedDays = <String>{};

    for (final record in sleepHistory) {
      final recordEnd = record.endDateTime ?? generatedAt;
      final rangeEndExclusive = end.add(const Duration(days: 1));
      final overlaps =
          record.startDateTime.isBefore(rangeEndExclusive) &&
          recordEnd.isAfter(start);
      if (!overlaps) continue;

      if (record.isNightWaking) {
        if (_isInInclusiveRange(record.startDateTime, start, end)) {
          wakings++;
          wakingSeconds += record.durationSeconds(generatedAt);
        }
        continue;
      }

      if (record.type == SleepType.night) {
        nights++;
      } else if (record.type == SleepType.nap) {
        naps++;
      }

      final byDay = sleepSecondsByCivilDay(record, now: generatedAt);
      for (final entry in byDay.entries) {
        if (!_isInInclusiveRange(entry.key, start, end)) continue;
        totalSeconds += entry.value;
        if (entry.value > 0) recordedDays.add(_dayKey(entry.key));
      }
    }

    return SleepPeriodStats(
      days: days,
      totalSleepSeconds: totalSeconds,
      nightSleepCount: nights,
      napCount: naps,
      nightWakingCount: wakings,
      totalNightWakingSeconds: wakingSeconds,
      daysWithSleepData: recordedDays.length,
    );
  }

  /// Segundos dormidos por día civil, del más antiguo al más reciente.
  List<int> sleepSecondsPerDay(int days) {
    final totals = List<int>.filled(days, 0);
    final start = _periodEnd.subtract(Duration(days: days - 1));
    final indexByDay = <String, int>{
      for (var i = 0; i < days; i++) _dayKey(start.add(Duration(days: i))): i,
    };

    for (final record in sleepHistory) {
      for (final entry in sleepSecondsByCivilDay(
        record,
        now: generatedAt,
      ).entries) {
        final index = indexByDay[_dayKey(entry.key)];
        if (index != null) totals[index] += entry.value;
      }
    }
    return totals;
  }

  static int? percentChange(double current, double previous) {
    if (previous == 0) return current == 0 ? 0 : null;
    return ((current - previous) / previous * 100).round();
  }

  DateTime? get _earliestActivityDay {
    DateTime? earliest;
    void consider(DateTime dt) {
      final d = DateTime(dt.year, dt.month, dt.day);
      if (earliest == null || d.isBefore(earliest!)) earliest = d;
    }

    for (final f in feedingsHistory) {
      consider(f.dateTime);
    }
    for (final d in diapersHistory) {
      consider(d.dateTime);
    }
    return earliest;
  }

  /// true si hay registros que cubren el periodo anterior (p. ej. 60 días para
  /// comparar 30 vs 30).
  bool hasSufficientHistoryForComparison(int days) {
    final earliest = _earliestActivityDay;
    if (earliest == null) return false;
    final previousStart = _periodEnd.subtract(Duration(days: days * 2 - 1));
    return !earliest.isAfter(previousStart);
  }

  bool hasSufficientSleepHistoryForComparison(int days) {
    if (sleepHistory.isEmpty) return false;
    final earliest = sleepHistory
        .map(
          (record) => DateTime(
            record.startDateTime.year,
            record.startDateTime.month,
            record.startDateTime.day,
          ),
        )
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final previousStart = _periodEnd.subtract(Duration(days: days * 2 - 1));
    return !earliest.isAfter(previousStart);
  }

  bool previousPeriodHasFeedingData(int days) =>
      previousPeriodStats(days).hasFeedingData;

  bool previousPeriodHasDiaperData(int days) =>
      previousPeriodStats(days).hasDiaperData;

  bool previousPeriodHasSleepData(int days) =>
      previousSleepPeriodStats(days).hasSleepData;

  WeightRecord? get latestWeight =>
      weightRecords.isEmpty ? null : weightRecords.last;

  HeightRecord? get latestHeight =>
      heightRecords.isEmpty ? null : heightRecords.last;

  int? get daysSinceLastWeighIn {
    final latest = latestWeight;
    if (latest == null) return null;
    final latestDay = DateTime(
      latest.dateTime.year,
      latest.dateTime.month,
      latest.dateTime.day,
    );
    return _periodEnd.difference(latestDay).inDays;
  }

  int? get daysSinceLastHeight {
    final latest = latestHeight;
    if (latest == null) return null;
    final latestDay = DateTime(
      latest.dateTime.year,
      latest.dateTime.month,
      latest.dateTime.day,
    );
    return _periodEnd.difference(latestDay).inDays;
  }

  WeightForAgePercentileEstimate? get currentHeightPercentile {
    final latest = latestHeight;
    if (latest == null) return null;
    return heightPercentileAt(latest);
  }

  WeightForAgePercentileEstimate? heightPercentileAt(HeightRecord record) {
    final age = BabyAgeCalendar.fractionalMonthsAt(
      baby.birthDate,
      record.dateTime,
    );
    return PercentilesData.estimateHeightPercentile(
      isMale: baby.isMale,
      ageInMonths: age,
      heightCm: record.heightCm,
    );
  }

  int? get gramsSinceLastWeighIn {
    if (weightRecords.length < 2) return null;
    final latest = weightRecords.last;
    final previous = weightRecords[weightRecords.length - 2];
    return ((latest.weightKg - previous.weightKg) * 1000).round();
  }

  WeightForAgePercentileEstimate? percentileAt(WeightRecord record) {
    final age = BabyAgeCalendar.fractionalMonthsAt(
      baby.birthDate,
      record.dateTime,
    );
    return PercentilesData.estimateWeightPercentile(
      isMale: baby.isMale,
      ageInMonths: age,
      weightKg: record.weightKg,
    );
  }

  WeightForAgePercentileEstimate? get currentPercentile {
    final latest = latestWeight;
    if (latest == null) return null;
    return percentileAt(latest);
  }

  WeightForAgePercentileEstimate? get previousPercentile {
    if (weightRecords.length < 2) return null;
    return percentileAt(weightRecords[weightRecords.length - 2]);
  }

  /// Diferencia en puntos de percentil (actual - anterior). Solo si ambos
  /// tienen valor numérico en tabla.
  double? get percentilePointDelta {
    final current = currentPercentile;
    final previous = previousPercentile;
    if (current == null ||
        previous == null ||
        current.percentile == null ||
        previous.percentile == null ||
        current.isBelowTable ||
        current.isAboveTable ||
        previous.isBelowTable ||
        previous.isAboveTable) {
      return null;
    }
    return current.percentile! - previous.percentile!;
  }

  double? weightTrendGramsPerDay(int days) =>
      dailyWeightTrendLinearRegressionGramsPerDay(
        weightRecords,
        now: generatedAt,
        window: Duration(days: days),
      );

  int? weightGainGrams(int days) {
    if (weightRecords.isEmpty) return null;
    final target = generatedAt.subtract(Duration(days: days));
    WeightRecord? baseline;
    for (final record in weightRecords) {
      if (!record.dateTime.isAfter(target)) baseline = record;
    }
    final latest = weightRecords.last;
    if (baseline == null ||
        baseline.dateTime.isAtSameMomentAs(latest.dateTime)) {
      return null;
    }
    return ((latest.weightKg - baseline.weightKg) * 1000).round();
  }

  double? averageFeedIntervalMinutes(int days) {
    final feeds = _feedingsInLastDays(days)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    if (feeds.length < 2) return null;
    var total = 0.0;
    for (var i = 1; i < feeds.length; i++) {
      total += feeds[i].dateTime
          .difference(feeds[i - 1].dateTime)
          .inMinutes
          .toDouble();
    }
    return total / (feeds.length - 1);
  }

  int? longestFeedGapMinutes(int days) {
    final feeds = _feedingsInLastDays(days)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    if (feeds.length < 2) return null;
    var maxGap = 0;
    for (var i = 1; i < feeds.length; i++) {
      final gap = feeds[i].dateTime.difference(feeds[i - 1].dateTime).inMinutes;
      if (gap > maxGap) maxGap = gap;
    }
    return maxGap;
  }

  double? averageBreastSessionMinutes(int days) {
    final stats = periodStats(days);
    if (stats.breastFeedCount == 0) return null;
    return stats.totalBreastSeconds / 60 / stats.breastFeedCount;
  }

  DateTime? get firstSolidFoodDate {
    DateTime? earliest;
    for (final f in feedingsHistory) {
      if (f.type != FeedingType.solidFood) continue;
      if (earliest == null || f.dateTime.isBefore(earliest)) {
        earliest = f.dateTime;
      }
    }
    return earliest;
  }

  int daysWithoutStool(int days) {
    final end = _periodEnd;
    final start = end.subtract(Duration(days: days - 1));
    final periodDiapers = _diapersInLastDays(days);
    var count = 0;
    for (var i = 0; i < days; i++) {
      final day = DateTime(
        start.year,
        start.month,
        start.day,
      ).add(Duration(days: i));
      final hasStool = periodDiapers.any(
        (d) =>
            diaperTypeIncludesStool(d.type) &&
            _isInInclusiveRange(d.dateTime, day, day),
      );
      if (!hasStool) count++;
    }
    return count;
  }

  /// Días de la ventana con al menos una toma registrada.
  int daysWithFeeding(int days) {
    final seen = <String>{};
    for (final f in _feedingsInLastDays(days)) {
      seen.add(_dayKey(f.dateTime));
    }
    return seen.length;
  }

  /// Días de la ventana con al menos un cambio de pañal registrado.
  int daysWithDiaper(int days) {
    final seen = <String>{};
    for (final d in _diapersInLastDays(days)) {
      seen.add(_dayKey(d.dateTime));
    }
    return seen.length;
  }

  double feedingCoverageRatio(int days) => daysWithFeeding(days) / days;

  double diaperCoverageRatio(int days) => daysWithDiaper(days) / days;

  bool feedingCoverageIsLow(int days) =>
      feedingCoverageRatio(days) < kReportMinCoverageRatio;

  bool diaperCoverageIsLow(int days) =>
      diaperCoverageRatio(days) < kReportMinCoverageRatio;

  int daysWithSleep(int days) => sleepPeriodStats(days).daysWithSleepData;

  double sleepCoverageRatio(int days) => daysWithSleep(days) / days;

  bool sleepCoverageIsLow(int days) =>
      sleepCoverageRatio(days) < kReportMinCoverageRatio;

  static String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  int get breastFeedCount => periodStats(kReportActivityDays).breastFeedCount;
  int get bottleFeedCount => periodStats(kReportActivityDays).bottleFeedCount;
  int get solidFeedCount => periodStats(kReportActivityDays).solidFeedCount;
  int get totalFeedCount => periodStats(kReportActivityDays).feedCount;
  double get averageFeedsPerDay =>
      periodStats(kReportActivityDays).averageFeedsPerDay;
  int get totalBottleMl => periodStats(kReportActivityDays).totalBottleMl;
  double get averageBottleMlPerDay =>
      periodStats(kReportActivityDays).averageBottleMlPerDay;
  int get totalBreastSeconds =>
      periodStats(kReportActivityDays).totalBreastSeconds;
  double get averageBreastMinutesPerDay =>
      periodStats(kReportActivityDays).averageBreastMinutesPerDay;

  int percentOfFeeds(int count) {
    final total = totalFeedCount;
    return total == 0 ? 0 : ((count / total) * 100).round();
  }

  int get wetDiaperCount => periodStats(kReportActivityDays).wetDiaperCount;
  int get dirtyDiaperCount => periodStats(kReportActivityDays).dirtyDiaperCount;
  int get bothDiaperCount => periodStats(kReportActivityDays).bothDiaperCount;
  int get totalDiaperCount => periodStats(kReportActivityDays).diaperCount;
  double get averageDiapersPerDay =>
      periodStats(kReportActivityDays).averageDiapersPerDay;
}
