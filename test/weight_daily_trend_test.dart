import 'package:control_bebe/core/models/weight_record.dart';
import 'package:control_bebe/core/utils/weight_daily_trend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dailyWeightTrendLinearRegressionGramsPerDay', () {
    test('uses current 7-day trend when enough recent weights exist', () {
      final now = DateTime(2026, 6, 4, 12);
      final records = [
        WeightRecord(weightKg: 5.2, dateTime: now),
        WeightRecord(
          weightKg: 5.0,
          dateTime: now.subtract(const Duration(days: 4)),
        ),
        WeightRecord(
          weightKg: 4.8,
          dateTime: now.subtract(const Duration(days: 30)),
        ),
      ];

      final trend = dailyWeightTrendLinearRegressionGramsPerDay(
        records,
        now: now,
      );

      expect(trend, closeTo(50, 0.001));
    });

    test('compares an isolated recent weight with the previous record', () {
      final now = DateTime(2026, 6, 4, 12);
      final records = [
        WeightRecord(
          weightKg: 5.4,
          dateTime: now.subtract(const Duration(days: 2)),
        ),
        WeightRecord(
          weightKg: 5.2,
          dateTime: now.subtract(const Duration(days: 20)),
        ),
        WeightRecord(
          weightKg: 5.0,
          dateTime: now.subtract(const Duration(days: 24)),
        ),
      ];

      final trend = dailyWeightTrendLinearRegressionGramsPerDay(
        records,
        now: now,
      );

      expect(trend, closeTo(11.111, 0.001));
    });

    test(
      'falls back to the last known 7-day trend when no recent weights exist',
      () {
        final now = DateTime(2026, 6, 4, 12);
        final records = [
          WeightRecord(
            weightKg: 5.2,
            dateTime: now.subtract(const Duration(days: 20)),
          ),
          WeightRecord(
            weightKg: 5.0,
            dateTime: now.subtract(const Duration(days: 24)),
          ),
        ];

        final trend = dailyWeightTrendLinearRegressionGramsPerDay(
          records,
          now: now,
        );

        expect(trend, closeTo(50, 0.001));
      },
    );

    test('returns null when no record pair can define a trend', () {
      final now = DateTime(2026, 6, 4, 12);
      final records = [
        WeightRecord(
          weightKg: 5.4,
          dateTime: now.subtract(const Duration(days: 2)),
        ),
      ];

      final trend = dailyWeightTrendLinearRegressionGramsPerDay(
        records,
        now: now,
      );

      expect(trend, isNull);
    });
  });
}
