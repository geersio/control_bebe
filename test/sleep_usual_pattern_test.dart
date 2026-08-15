import 'package:flutter_test/flutter_test.dart';

import 'package:control_bebe/core/models/enums.dart';
import 'package:control_bebe/core/models/sleep_record.dart';
import 'package:control_bebe/core/utils/sleep_usual_pattern.dart';

SleepRecord _nap({required DateTime start, required DateTime end}) =>
    SleepRecord(startDateTime: start, endDateTime: end, type: SleepType.nap);

SleepRecord _night({required DateTime start, required DateTime end}) =>
    SleepRecord(startDateTime: start, endDateTime: end, type: SleepType.night);

void main() {
  group('roundMinutesToFive', () {
    test('redondea al múltiplo de 5', () {
      expect(roundMinutesToFive(9 * 60 + 32), 9 * 60 + 30);
      expect(roundMinutesToFive(9 * 60 + 33), 9 * 60 + 35);
      expect(roundMinutesToFive(18 * 60 + 45), 18 * 60 + 45);
    });
  });

  group('napKindForStartMinutes', () {
    test('clasifica por franja', () {
      expect(
        napKindForStartMinutes(9 * 60 + 30),
        UsualSleepSlotKind.morningNap,
      );
      expect(
        napKindForStartMinutes(12 * 60 + 36),
        UsualSleepSlotKind.middayNap,
      );
      expect(
        napKindForStartMinutes(15 * 60 + 25),
        UsualSleepSlotKind.afternoonNap,
      );
      expect(napKindForStartMinutes(18 * 60 + 43), UsualSleepSlotKind.catnap);
    });
  });

  group('computeUsualSleepPattern', () {
    test('regularidad baja → casi siempre sobre la mediana', () {
      final now = DateTime(2026, 8, 3, 18, 0);
      final records = <SleepRecord>[];

      // 12 días con siesta de mañana estable → pasa frecuencia (≥12/14).
      for (var d = 0; d < 12; d++) {
        final day = DateTime(2026, 7, 23).add(Duration(days: d));
        records.add(
          _nap(
            start: DateTime(day.year, day.month, day.day, 9, 30),
            end: DateTime(day.year, day.month, day.day, 10, 45),
          ),
        );
        records.add(
          _night(
            start: DateTime(day.year, day.month, day.day, 21, 0),
            end: DateTime(
              day.year,
              day.month,
              day.day,
              21,
              0,
            ).add(const Duration(hours: 10)),
          ),
        );
      }

      final pattern = computeUsualSleepPattern(records: records, now: now);
      final morning = pattern.slots.firstWhere(
        (s) => s.kind == UsualSleepSlotKind.morningNap,
      );

      expect(morning.phraseKind, UsualSleepPhraseKind.regularityAlmostAlways);
      expect(morning.medianStartMinutesOfDay, 9 * 60 + 30);
      expect(morning.medianEndMinutesOfDay, 10 * 60 + 45);
      expect(morning.medianDurationSeconds, 75 * 60);
    });

    test('baja frecuencia 9/14 → frase con hora', () {
      final now = DateTime(2026, 8, 3, 18, 0);
      final records = <SleepRecord>[];

      for (var d = 0; d < 9; d++) {
        final day = DateTime(2026, 7, 26).add(Duration(days: d));
        records.add(
          _nap(
            start: DateTime(day.year, day.month, day.day, 18, 45),
            end: DateTime(day.year, day.month, day.day, 19, 20),
          ),
        );
      }

      final pattern = computeUsualSleepPattern(records: records, now: now);
      final catnap = pattern.slots.single;

      expect(catnap.kind, UsualSleepSlotKind.catnap);
      expect(catnap.phraseKind, UsualSleepPhraseKind.frequencyWithTime);
      expect(catnap.sampleCount, 9);
    });

    test('menos de 5 muestras → waiting', () {
      final now = DateTime(2026, 8, 3, 12, 0);
      final records = <SleepRecord>[];
      for (var d = 0; d < 4; d++) {
        final day = DateTime(2026, 7, 31).add(Duration(days: d));
        records.add(
          _nap(
            start: DateTime(day.year, day.month, day.day, 10, 0),
            end: DateTime(day.year, day.month, day.day, 11, 0),
          ),
        );
      }

      final pattern = computeUsualSleepPattern(records: records, now: now);
      expect(pattern.slots.single.phraseKind, UsualSleepPhraseKind.waiting);
    });

    test('muestra una segunda siesta habitual dentro de la misma franja', () {
      final now = DateTime(2026, 8, 3, 18, 0);
      final records = <SleepRecord>[];

      for (var d = 0; d < 4; d++) {
        final day = DateTime(2026, 7, 31).add(Duration(days: d));
        records.add(
          _nap(
            start: DateTime(day.year, day.month, day.day, 8, 0),
            end: DateTime(day.year, day.month, day.day, 8, 40),
          ),
        );
        if (d < 3) {
          records.add(
            _nap(
              start: DateTime(day.year, day.month, day.day, 10, 0),
              end: DateTime(day.year, day.month, day.day, 10, 30),
            ),
          );
        }
      }

      final pattern = computeUsualSleepPattern(records: records, now: now);
      final morningSlots = pattern.slots
          .where((slot) => slot.kind == UsualSleepSlotKind.morningNap)
          .toList();

      expect(morningSlots, hasLength(2));
      expect(morningSlots[0].occurrenceIndex, 1);
      expect(morningSlots[0].sampleCount, 4);
      expect(morningSlots[1].occurrenceIndex, 2);
      expect(morningSlots[1].sampleCount, 3);
      expect(morningSlots[1].medianStartMinutesOfDay, 10 * 60);
    });

    test('no muestra más siestas habituales que el máximo real por día', () {
      final now = DateTime(2026, 8, 3, 18, 0);
      final records = <SleepRecord>[];

      // 12 días con exactamente 5 siestas, pero repartidas de forma que
      // mañana y mediodía tienen a veces 2 → sin tope saldrían 6 filas.
      for (var d = 0; d < 12; d++) {
        final day = DateTime(2026, 7, 23).add(Duration(days: d));
        final doubleMorning = d.isEven;
        if (doubleMorning) {
          records.addAll([
            _nap(
              start: DateTime(day.year, day.month, day.day, 8, 0),
              end: DateTime(day.year, day.month, day.day, 8, 40),
            ),
            _nap(
              start: DateTime(day.year, day.month, day.day, 10, 0),
              end: DateTime(day.year, day.month, day.day, 10, 40),
            ),
            _nap(
              start: DateTime(day.year, day.month, day.day, 13, 0),
              end: DateTime(day.year, day.month, day.day, 13, 40),
            ),
            _nap(
              start: DateTime(day.year, day.month, day.day, 16, 0),
              end: DateTime(day.year, day.month, day.day, 16, 40),
            ),
            _nap(
              start: DateTime(day.year, day.month, day.day, 18, 30),
              end: DateTime(day.year, day.month, day.day, 19, 0),
            ),
          ]);
        } else {
          records.addAll([
            _nap(
              start: DateTime(day.year, day.month, day.day, 9, 0),
              end: DateTime(day.year, day.month, day.day, 9, 40),
            ),
            _nap(
              start: DateTime(day.year, day.month, day.day, 12, 0),
              end: DateTime(day.year, day.month, day.day, 12, 40),
            ),
            _nap(
              start: DateTime(day.year, day.month, day.day, 13, 30),
              end: DateTime(day.year, day.month, day.day, 14, 10),
            ),
            _nap(
              start: DateTime(day.year, day.month, day.day, 16, 0),
              end: DateTime(day.year, day.month, day.day, 16, 40),
            ),
            _nap(
              start: DateTime(day.year, day.month, day.day, 18, 30),
              end: DateTime(day.year, day.month, day.day, 19, 0),
            ),
          ]);
        }
      }

      final pattern = computeUsualSleepPattern(records: records, now: now);
      final napSlots = pattern.slots.where((s) => s.isNap).toList();
      expect(napSlots.length, lessThanOrEqualTo(5));
    });

    test('0–2 días actuales tras historial previo → abandoned', () {
      final now = DateTime(2026, 8, 3, 12, 0);
      final records = <SleepRecord>[];

      // Ventana previa (hace 15–28 días): catnap frecuente.
      for (var d = 0; d < 10; d++) {
        final day = DateTime(2026, 7, 6).add(Duration(days: d));
        records.add(
          _nap(
            start: DateTime(day.year, day.month, day.day, 18, 30),
            end: DateTime(day.year, day.month, day.day, 19, 0),
          ),
        );
      }
      // Ventana actual: solo 1 catnap.
      records.add(
        _nap(
          start: DateTime(2026, 8, 1, 18, 30),
          end: DateTime(2026, 8, 1, 19, 0),
        ),
      );

      final pattern = computeUsualSleepPattern(records: records, now: now);
      expect(
        pattern.slots.any((s) => s.kind == UsualSleepSlotKind.catnap),
        isFalse,
      );
      expect(
        pattern.abandonedNaps.any((a) => a.kind == UsualSleepSlotKind.catnap),
        isTrue,
      );
    });
  });
}
