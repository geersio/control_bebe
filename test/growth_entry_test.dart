import 'package:control_bebe/core/utils/growth_change_guard.dart';
import 'package:control_bebe/core/utils/measurement_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseLooseDecimal', () {
    test('accepts comma or dot as decimal separator', () {
      expect(parseLooseDecimal('4,5'), 4.5);
      expect(parseLooseDecimal('4.5'), 4.5);
      expect(parseLooseDecimal(' 58,0 '), 58.0);
    });

    test('rejects mixed or multiple separators', () {
      expect(parseLooseDecimal('4.5,2'), isNull);
      expect(parseLooseDecimal('1,234.5'), isNull);
      expect(parseLooseDecimal('4..5'), isNull);
      expect(parseLooseDecimal('4,,5'), isNull);
    });

    test('returns null for empty or non-numeric', () {
      expect(parseLooseDecimal(''), isNull);
      expect(parseLooseDecimal('abc'), isNull);
    });
  });

  group('formatDecimalForInput', () {
    test('trims trailing zeros and switches comma for Spanish', () {
      expect(formatDecimalForInput(4.5, maxDecimals: 2), '4.5');
      expect(
        formatDecimalForInput(4.5, maxDecimals: 2, useCommaDecimal: true),
        '4,5',
      );
      expect(
        formatDecimalForInput(58.0, maxDecimals: 1, useCommaDecimal: true),
        '58',
      );
    });
  });

  group('isSuddenWeightChange', () {
    final previousAt = DateTime(2026, 8, 15, 10);

    test('warns when a same-day jump is far above scale noise', () {
      expect(
        isSuddenWeightChange(
          previousKg: 4.5,
          previousAt: previousAt,
          nextKg: 5.2,
          now: previousAt.add(const Duration(hours: 2)),
        ),
        isTrue,
      );
    });

    test('does not warn for a modest same-day change', () {
      expect(
        isSuddenWeightChange(
          previousKg: 4.5,
          previousAt: previousAt,
          nextKg: 4.62,
          now: previousAt.add(const Duration(hours: 6)),
        ),
        isFalse,
      );
    });

    test('does not warn after the 14-day window', () {
      expect(
        isSuddenWeightChange(
          previousKg: 4.5,
          previousAt: previousAt,
          nextKg: 6.0,
          now: previousAt.add(const Duration(days: 15)),
        ),
        isFalse,
      );
    });
  });

  group('isSuddenHeightChange', () {
    final previousAt = DateTime(2026, 8, 15, 10);

    test('warns when height jumps several cm in a day', () {
      expect(
        isSuddenHeightChange(
          previousCm: 58,
          previousAt: previousAt,
          nextCm: 64,
          now: previousAt.add(const Duration(days: 1)),
        ),
        isTrue,
      );
    });

    test('does not warn for typical measurement noise', () {
      expect(
        isSuddenHeightChange(
          previousCm: 58,
          previousAt: previousAt,
          nextCm: 58.8,
          now: previousAt.add(const Duration(days: 1)),
        ),
        isFalse,
      );
    });
  });
}
