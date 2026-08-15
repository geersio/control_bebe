import '../models/diaper_record.dart';

/// Ventana fija de comparación: últimos 7 días vs 7 días anteriores.
const int kDiaperSpendWindowDays = 7;

enum DiaperSpendWeekComparison { more, less, same }

/// Media de pañales/día y delta vs la semana anterior.
class DiaperSpendInsightStats {
  final bool hasAnyRecord;
  final int currentWeekCount;
  final int previousWeekCount;
  final double currentDailyAverage;
  final double previousDailyAverage;
  final double averageDelta;
  final DiaperSpendWeekComparison comparison;

  bool get hasCurrentData => currentWeekCount > 0;

  const DiaperSpendInsightStats({
    required this.hasAnyRecord,
    required this.currentWeekCount,
    required this.previousWeekCount,
    required this.currentDailyAverage,
    required this.previousDailyAverage,
    required this.averageDelta,
    required this.comparison,
  });

  /// Media aritmética: total de cambios en la ventana ÷ 7 días calendario
  /// (incluye días sin registro como 0 implícito en el denominador).
  /// Comparación: media actual − media de los 7 días inmediatamente anteriores.
  factory DiaperSpendInsightStats.fromRecords({
    required List<DiaperRecord> records,
    required DateTime now,
  }) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final currentStart = todayStart.subtract(
      Duration(days: kDiaperSpendWindowDays - 1),
    );
    final previousStart = currentStart.subtract(
      const Duration(days: kDiaperSpendWindowDays),
    );

    var currentCount = 0;
    var previousCount = 0;
    for (final record in records) {
      final date = record.dateTime;
      if (!date.isBefore(currentStart) && date.isBefore(tomorrowStart)) {
        currentCount++;
      } else if (!date.isBefore(previousStart) && date.isBefore(currentStart)) {
        previousCount++;
      }
    }

    final currentAverage = currentCount / kDiaperSpendWindowDays;
    final previousAverage = previousCount / kDiaperSpendWindowDays;
    final diff = currentAverage - previousAverage;
    final comparison = diff.abs() < 0.05
        ? DiaperSpendWeekComparison.same
        : diff > 0
            ? DiaperSpendWeekComparison.more
            : DiaperSpendWeekComparison.less;

    return DiaperSpendInsightStats(
      hasAnyRecord: records.isNotEmpty,
      currentWeekCount: currentCount,
      previousWeekCount: previousCount,
      currentDailyAverage: currentAverage,
      previousDailyAverage: previousAverage,
      averageDelta: diff,
      comparison: comparison,
    );
  }
}
