import 'package:flutter_test/flutter_test.dart';

import 'package:control_bebe/core/models/baby_profile.dart';
import 'package:control_bebe/core/models/diaper_record.dart';
import 'package:control_bebe/core/models/enums.dart';
import 'package:control_bebe/core/models/feeding_record.dart';
import 'package:control_bebe/core/models/sleep_record.dart';
import 'package:control_bebe/features/export/models/pediatric_report_data.dart';

void main() {
  test('hasSufficientHistoryForComparison requiere 60 días de cobertura', () {
    final now = DateTime(2026, 6, 12);
    final birth = DateTime(2026, 1, 1);

    final shortHistory = PediatricReportData(
      baby: BabyProfile(name: 'Test', isMale: true, birthDate: birth),
      weightRecords: [],
      feedingsHistory: [
        FeedingRecord(
          type: FeedingType.bottle,
          dateTime: now.subtract(const Duration(days: 20)),
          amountMl: 100,
        ),
      ],
      diapersHistory: [],
      generatedAt: now,
    );
    expect(
      shortHistory.hasSufficientHistoryForComparison(kReportLongPeriodDays),
      isFalse,
    );

    final longHistory = PediatricReportData(
      baby: BabyProfile(name: 'Test', isMale: true, birthDate: birth),
      weightRecords: [],
      feedingsHistory: [
        FeedingRecord(
          type: FeedingType.bottle,
          dateTime: now.subtract(const Duration(days: 70)),
          amountMl: 100,
        ),
        FeedingRecord(
          type: FeedingType.bottle,
          dateTime: now.subtract(const Duration(days: 5)),
          amountMl: 120,
        ),
      ],
      diapersHistory: [],
      generatedAt: now,
    );
    expect(
      longHistory.hasSufficientHistoryForComparison(kReportLongPeriodDays),
      isTrue,
    );
  });

  test('daysWithoutStool cuenta mixtos (both) como deposición', () {
    final now = DateTime(2026, 6, 12, 15);
    final birth = DateTime(2026, 1, 1);
    final baby = BabyProfile(name: 'Test', isMale: true, birthDate: birth);

    final data = PediatricReportData(
      baby: baby,
      weightRecords: [],
      feedingsHistory: [],
      diapersHistory: [
        DiaperRecord(type: DiaperType.wet, dateTime: DateTime(2026, 6, 12, 9)),
        DiaperRecord(
          type: DiaperType.both,
          dateTime: DateTime(2026, 6, 11, 14),
        ),
        DiaperRecord(type: DiaperType.dirty, dateTime: DateTime(2026, 6, 9, 8)),
        DiaperRecord(type: DiaperType.wet, dateTime: DateTime(2026, 6, 8, 10)),
      ],
      generatedAt: now,
    );

    // Ventana 7 días: 6–12 jun. Con deposición el 9 (sucio) y 11 (mixto).
    expect(data.daysWithoutStool(7), 5);
  });

  test('daysWithoutStool ignora pañales solo mojados', () {
    final now = DateTime(2026, 6, 12);
    final data = PediatricReportData(
      baby: BabyProfile(
        name: 'Test',
        isMale: true,
        birthDate: DateTime(2026, 1, 1),
      ),
      weightRecords: [],
      feedingsHistory: [],
      diapersHistory: [
        for (var d = 6; d <= 12; d++)
          DiaperRecord(type: DiaperType.wet, dateTime: DateTime(2026, 6, d)),
      ],
      generatedAt: now,
    );
    expect(data.daysWithoutStool(7), 7);
  });

  test('promedio biberón 7d ≠ 30d cuando el histórico diverge', () {
    final now = DateTime(2026, 6, 12);
    final data = PediatricReportData(
      baby: BabyProfile(
        name: 'Test',
        isMale: true,
        birthDate: DateTime(2026, 1, 1),
      ),
      weightRecords: [],
      feedingsHistory: [
        // Últimos 7 días: 7 × 634 ml ≈ 4438 ml → ~634 ml/día
        for (var i = 0; i < 7; i++)
          FeedingRecord(
            type: FeedingType.bottle,
            dateTime: now.subtract(Duration(days: i)),
            amountMl: 634,
          ),
        // Días 8–30: volumen alto para empujar la media de 30 días
        for (var i = 7; i < 30; i++)
          FeedingRecord(
            type: FeedingType.bottle,
            dateTime: now.subtract(Duration(days: i)),
            amountMl: 700,
          ),
      ],
      diapersHistory: [],
      generatedAt: now,
    );

    final stats7 = data.periodStats(kReportActivityDays);
    final stats30 = data.periodStats(kReportLongPeriodDays);
    expect(stats7.averageBottleMlPerDay.round(), 634);
    expect(stats30.averageBottleMlPerDay.round(), isNot(634));
  });

  test('cobertura de alimentación: días con registro / ventana', () {
    final now = DateTime(2026, 6, 12);
    final data = PediatricReportData(
      baby: BabyProfile(
        name: 'Test',
        isMale: true,
        birthDate: DateTime(2026, 1, 1),
      ),
      weightRecords: [],
      feedingsHistory: [
        FeedingRecord(type: FeedingType.bottle, dateTime: now, amountMl: 100),
        FeedingRecord(
          type: FeedingType.bottle,
          dateTime: now.subtract(const Duration(days: 1)),
          amountMl: 100,
        ),
        // Mismo día: no cuenta dos veces
        FeedingRecord(
          type: FeedingType.bottle,
          dateTime: now.subtract(const Duration(hours: 2)),
          amountMl: 80,
        ),
      ],
      diapersHistory: [],
      generatedAt: now,
    );

    expect(data.daysWithFeeding(7), 2);
    expect(data.feedingCoverageIsLow(7), isTrue);
    expect(data.feedingCoverageRatio(7), closeTo(2 / 7, 1e-9));
  });

  test('cobertura alta (>=70%) no se considera baja', () {
    final now = DateTime(2026, 6, 12);
    final data = PediatricReportData(
      baby: BabyProfile(
        name: 'Test',
        isMale: true,
        birthDate: DateTime(2026, 1, 1),
      ),
      weightRecords: [],
      feedingsHistory: [
        for (var i = 0; i < 5; i++)
          FeedingRecord(
            type: FeedingType.bottle,
            dateTime: now.subtract(Duration(days: i)),
            amountMl: 100,
          ),
      ],
      diapersHistory: [],
      generatedAt: now,
    );

    // 5/7 ≈ 71.4% >= 70%
    expect(data.feedingCoverageIsLow(7), isFalse);
  });

  test('sueño reparte una sesión nocturna entre días civiles', () {
    final now = DateTime(2026, 6, 12, 12);
    final data = PediatricReportData(
      baby: BabyProfile(
        name: 'Test',
        isMale: true,
        birthDate: DateTime(2026, 1, 1),
      ),
      weightRecords: [],
      feedingsHistory: [],
      diapersHistory: [],
      sleepHistory: [
        SleepRecord(
          startDateTime: DateTime(2026, 6, 10, 22),
          endDateTime: DateTime(2026, 6, 11, 7),
          type: SleepType.night,
        ),
      ],
      generatedAt: now,
    );

    final daily = data.sleepSecondsPerDay(7);
    expect(daily[4], 2 * 3600);
    expect(daily[5], 7 * 3600);
    expect(data.sleepPeriodStats(7).totalSleepSeconds, 9 * 3600);
    expect(data.daysWithSleep(7), 2);
  });

  test('despertares no suman sueño pero sí tiempo despierto', () {
    final now = DateTime(2026, 6, 12, 10);
    final data = PediatricReportData(
      baby: BabyProfile(
        name: 'Test',
        isMale: true,
        birthDate: DateTime(2026, 1, 1),
      ),
      weightRecords: [],
      feedingsHistory: [],
      diapersHistory: [],
      sleepHistory: [
        SleepRecord(
          startDateTime: DateTime(2026, 6, 11, 22),
          endDateTime: DateTime(2026, 6, 12, 7),
          type: SleepType.night,
        ),
        SleepRecord(
          startDateTime: DateTime(2026, 6, 12, 2),
          endDateTime: DateTime(2026, 6, 12, 2, 20),
          type: SleepType.nightWaking,
        ),
      ],
      generatedAt: now,
    );

    final stats = data.sleepPeriodStats(7);
    expect(stats.totalSleepSeconds, 9 * 3600);
    expect(stats.nightWakingCount, 1);
    expect(stats.totalNightWakingSeconds, 20 * 60);
  });

  test('sesión de sueño abierta se calcula hasta la hora del informe', () {
    final now = DateTime(2026, 6, 12, 6);
    final data = PediatricReportData(
      baby: BabyProfile(
        name: 'Test',
        isMale: true,
        birthDate: DateTime(2026, 1, 1),
      ),
      weightRecords: [],
      feedingsHistory: [],
      diapersHistory: [],
      sleepHistory: [
        SleepRecord(
          startDateTime: DateTime(2026, 6, 11, 22),
          type: SleepType.night,
        ),
      ],
      generatedAt: now,
    );

    expect(data.sleepPeriodStats(7).totalSleepSeconds, 8 * 3600);
  });
}
