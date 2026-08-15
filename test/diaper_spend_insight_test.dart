import 'package:flutter_test/flutter_test.dart';

import 'package:control_bebe/core/models/diaper_record.dart';
import 'package:control_bebe/core/models/enums.dart';
import 'package:control_bebe/core/utils/diaper_spend_insight.dart';

void main() {
  test('media 7 días: total cambios ÷ 7', () {
    final now = DateTime(2026, 6, 12, 18);
    final stats = DiaperSpendInsightStats.fromRecords(
      records: [
        for (var d = 6; d <= 12; d++)
          DiaperRecord(type: DiaperType.wet, dateTime: DateTime(2026, 6, d)),
      ],
      now: now,
    );
    expect(stats.currentWeekCount, 7);
    expect(stats.currentDailyAverage, 1.0);
  });

  test('delta vs semana anterior', () {
    final now = DateTime(2026, 6, 12);
    final stats = DiaperSpendInsightStats.fromRecords(
      records: [
        // Semana actual (6–12 jun): 14 cambios → 2.0/día
        for (var i = 0; i < 14; i++)
          DiaperRecord(
            type: DiaperType.wet,
            dateTime: DateTime(2026, 6, 6 + (i % 7)),
          ),
        // Semana anterior (30 may – 5 jun): 7 cambios → 1.0/día
        for (var d = 30; d <= 31; d++)
          DiaperRecord(type: DiaperType.wet, dateTime: DateTime(2026, 5, d)),
        for (var d = 1; d <= 5; d++)
          DiaperRecord(type: DiaperType.wet, dateTime: DateTime(2026, 6, d)),
      ],
      now: now,
    );
    expect(stats.currentDailyAverage, closeTo(2.0, 0.001));
    expect(stats.previousDailyAverage, closeTo(1.0, 0.001));
    expect(stats.averageDelta, closeTo(1.0, 0.001));
    expect(stats.comparison, DiaperSpendWeekComparison.more);
  });

  test('sin registros: hasAnyRecord es false', () {
    final stats = DiaperSpendInsightStats.fromRecords(
      records: const [],
      now: DateTime(2026, 6, 12),
    );
    expect(stats.hasAnyRecord, isFalse);
    expect(stats.currentWeekCount, 0);
    expect(stats.currentDailyAverage, 0);
  });
}
