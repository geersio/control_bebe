import 'package:control_bebe/core/models/enums.dart';
import 'package:control_bebe/core/utils/infer_sleep_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inferSleepType', () {
    test('cruza medianoche → night', () {
      expect(
        inferSleepType(
          start: DateTime(2026, 7, 27, 22, 0),
          end: DateTime(2026, 7, 28, 6, 30),
        ),
        SleepType.night,
      );
    });

    test('siesta corta diurna → nap', () {
      expect(
        inferSleepType(
          start: DateTime(2026, 7, 28, 10, 0),
          end: DateTime(2026, 7, 28, 11, 15),
        ),
        SleepType.nap,
      );
    });

    test('bloque cerrado corto tras 18:00 → nap (puente/vespertina)', () {
      expect(
        inferSleepType(
          start: DateTime(2026, 7, 28, 20, 40),
          end: DateTime(2026, 7, 28, 21, 5),
        ),
        SleepType.nap,
      );
    });

    test('bloque cerrado largo en franja nocturna → night', () {
      expect(
        inferSleepType(
          start: DateTime(2026, 7, 28, 20, 0),
          end: DateTime(2026, 7, 28, 22, 0),
        ),
        SleepType.night,
      );
    });

    test('duración ≥ 3 h diurna → night', () {
      expect(
        inferSleepType(
          start: DateTime(2026, 7, 28, 12, 0),
          end: DateTime(2026, 7, 28, 15, 30),
        ),
        SleepType.night,
      );
    });

    test('sesión abierta por la tarde → nap', () {
      expect(
        inferSleepType(
          start: DateTime(2026, 7, 28, 14, 0),
          end: null,
          now: DateTime(2026, 7, 28, 14, 20),
        ),
        SleepType.nap,
      );
    });

    test('sesión abierta tras 18:00 → night', () {
      expect(
        inferSleepType(
          start: DateTime(2026, 7, 28, 20, 40),
          end: null,
          now: DateTime(2026, 7, 28, 20, 45),
        ),
        SleepType.night,
      );
    });
  });
}
