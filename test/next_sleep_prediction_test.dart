import 'package:flutter_test/flutter_test.dart';

import 'package:control_bebe/core/models/enums.dart';
import 'package:control_bebe/core/models/sleep_record.dart';
import 'package:control_bebe/core/utils/next_sleep_prediction.dart';
import 'package:control_bebe/core/utils/sleep_personal_stats.dart';

SleepRecord _nap({required DateTime start, required DateTime end}) =>
    SleepRecord(startDateTime: start, endDateTime: end, type: SleepType.nap);

SleepRecord _night({required DateTime start, required DateTime end}) =>
    SleepRecord(startDateTime: start, endDateTime: end, type: SleepType.night);

void main() {
  // Bebé de 5 meses → ventanas [120, 135, 150], mín. siesta 45, siesta típica 70.
  final birthDate = DateTime(2025, 12, 15);

  group('predictNextSleep (reglas base)', () {
    test('cálculo estándar con siestas registradas', () {
      final now = DateTime(2026, 5, 15, 14, 0);
      final prediction = predictNextSleep(
        birthDate: birthDate,
        now: now,
        records: [
          _night(
            start: DateTime(2026, 5, 14, 21, 0),
            end: DateTime(2026, 5, 15, 7, 0),
          ),
          _nap(
            start: DateTime(2026, 5, 15, 8, 0),
            end: DateTime(2026, 5, 15, 9, 0),
          ),
          _nap(
            start: DateTime(2026, 5, 15, 11, 0),
            end: DateTime(2026, 5, 15, 12, 0),
          ),
        ],
        // Sin historial previo → sin blend.
        personalStats: SleepPersonalStats.empty,
      );

      expect(prediction, isNotNull);
      expect(prediction!.windowIndex, 2);
      expect(prediction.ageWindowMinutes, 150);
      expect(prediction.baseWindowMinutes, 150);
      expect(prediction.adjustedWindowMinutes, 150);
      expect(prediction.lastWakeUp, DateTime(2026, 5, 15, 12, 0));
      expect(prediction.targetTime, DateTime(2026, 5, 15, 14, 30));
      expect(prediction.kind, NextSleepKind.nextNap);
      expect(prediction.reasonCode, NextSleepReasonCode.standard);
      expect(
        prediction.windowStart,
        prediction.targetTime.subtract(
          const Duration(minutes: kSleepPersonalDefaultHalfRangeMinutes),
        ),
      );
      expect(
        prediction.windowEnd,
        prediction.targetTime.add(
          const Duration(minutes: kSleepPersonalDefaultHalfRangeMinutes),
        ),
      );
    });

    test('penalización fija -15 min tras siesta corta sin aprendizaje', () {
      final now = DateTime(2026, 5, 15, 11, 30);
      final prediction = predictNextSleep(
        birthDate: birthDate,
        now: now,
        personalStats: SleepPersonalStats.empty,
        records: [
          _night(
            start: DateTime(2026, 5, 14, 21, 0),
            end: DateTime(2026, 5, 15, 7, 0),
          ),
          _nap(
            start: DateTime(2026, 5, 15, 8, 30),
            end: DateTime(2026, 5, 15, 9, 0),
          ),
        ],
      );

      expect(prediction, isNotNull);
      expect(prediction!.windowIndex, 1);
      expect(prediction.baseWindowMinutes, 135);
      expect(prediction.adjustedWindowMinutes, 120);
      expect(prediction.napAdjustmentMinutes, -15);
      expect(prediction.targetTime, DateTime(2026, 5, 15, 11, 0));
      expect(
        prediction.reasonCode,
        NextSleepReasonCode.shortenedWindowAfterShortNap,
      );
      expect(prediction.isPast, isTrue);
    });

    test('salto de índice si no se registra la 1ª siesta', () {
      final now = DateTime(2026, 5, 15, 13, 0);
      final prediction = predictNextSleep(
        birthDate: birthDate,
        now: now,
        personalStats: SleepPersonalStats.empty,
        records: [
          _night(
            start: DateTime(2026, 5, 14, 21, 0),
            end: DateTime(2026, 5, 15, 7, 0),
          ),
        ],
      );

      expect(prediction, isNotNull);
      expect(prediction!.windowIndex, 1);
      expect(prediction.baseWindowMinutes, 135);
      expect(prediction.lastWakeUp, DateTime(2026, 5, 15, 7, 0));
      expect(prediction.targetTime, DateTime(2026, 5, 15, 9, 15));
      expect(prediction.kind, NextSleepKind.nextNap);
    });

    test('último despertar = fin más reciente (siesta o nocturno)', () {
      final now = DateTime(2026, 7, 28, 21, 10);
      final prediction = predictNextSleep(
        birthDate: birthDate,
        now: now,
        personalStats: SleepPersonalStats.empty,
        records: [
          _nap(
            start: DateTime(2026, 7, 28, 17, 10),
            end: DateTime(2026, 7, 28, 18, 20),
          ),
          // Siesta vespertina corta (como el caso real 20:40–21:05).
          _nap(
            start: DateTime(2026, 7, 28, 20, 40),
            end: DateTime(2026, 7, 28, 21, 5),
          ),
        ],
      );

      expect(prediction, isNotNull);
      expect(prediction!.lastWakeUp, DateTime(2026, 7, 28, 21, 5));
      expect(
        prediction.lastWakeUp.isAfter(DateTime(2026, 7, 28, 18, 20)),
        isTrue,
      );
    });

    test('nocturno que termina después de una siesta manda como lastWake', () {
      final now = DateTime(2026, 5, 15, 8, 0);
      final prediction = predictNextSleep(
        birthDate: birthDate,
        now: now,
        personalStats: SleepPersonalStats.empty,
        records: [
          _nap(
            start: DateTime(2026, 5, 14, 16, 0),
            end: DateTime(2026, 5, 14, 17, 0),
          ),
          _night(
            start: DateTime(2026, 5, 14, 20, 0),
            end: DateTime(2026, 5, 15, 7, 0),
          ),
        ],
      );

      expect(prediction, isNotNull);
      // El nap termina el día 14; el night termina hoy 7:00 → manda 7:00.
      expect(prediction!.lastWakeUp, DateTime(2026, 5, 15, 7, 0));
    });

    test('transición a BEDTIME cuando target ≥ 19:30', () {
      final birth8m = DateTime(2025, 9, 15);
      final now = DateTime(2026, 5, 15, 18, 0);
      final prediction = predictNextSleep(
        birthDate: birth8m,
        now: now,
        personalStats: SleepPersonalStats.empty,
        records: [
          _night(
            start: DateTime(2026, 5, 14, 21, 0),
            end: DateTime(2026, 5, 15, 7, 0),
          ),
          _nap(
            start: DateTime(2026, 5, 15, 9, 0),
            end: DateTime(2026, 5, 15, 10, 0),
          ),
          _nap(
            start: DateTime(2026, 5, 15, 15, 30),
            end: DateTime(2026, 5, 15, 16, 30),
          ),
        ],
      );

      expect(prediction, isNotNull);
      expect(prediction!.targetTime, DateTime(2026, 5, 15, 19, 30));
      expect(prediction.kind, NextSleepKind.bedtime);
      expect(
        prediction.reasonCode,
        NextSleepReasonCode.bedtimeByUsualThreshold,
      );
    });

    test('ventanas agotadas y target < 18:00 → siesta puente', () {
      final birthNewborn = DateTime(2026, 4, 1);
      final now = DateTime(2026, 5, 15, 16, 0);
      final prediction = predictNextSleep(
        birthDate: birthNewborn,
        now: now,
        personalStats: SleepPersonalStats.empty,
        records: [
          _night(
            start: DateTime(2026, 5, 14, 21, 0),
            end: DateTime(2026, 5, 15, 7, 0),
          ),
          // 1 mes → 5 ventanas: hacen falta 5 siestas para agotarlas.
          for (final endHour in [8, 10, 11, 13, 15])
            _nap(
              start: DateTime(2026, 5, 15, endHour - 1, 0),
              end: DateTime(2026, 5, 15, endHour, 0),
            ),
        ],
      );

      expect(prediction, isNotNull);
      expect(prediction!.windowsExhausted, isTrue);
      expect(prediction.targetTime, DateTime(2026, 5, 15, 16, 30));
      expect(prediction.kind, NextSleepKind.nextNap);
      expect(
        prediction.reasonCode,
        NextSleepReasonCode.catnapAfterWindowsExhausted,
      );
    });

    test('ventanas agotadas y target ≥ 18:00 → early bedtime', () {
      final birthNewborn = DateTime(2026, 4, 1);
      final now = DateTime(2026, 5, 15, 17, 30);
      final prediction = predictNextSleep(
        birthDate: birthNewborn,
        now: now,
        personalStats: SleepPersonalStats.empty,
        records: [
          _night(
            start: DateTime(2026, 5, 14, 21, 0),
            end: DateTime(2026, 5, 15, 7, 0),
          ),
          for (final end in [
            DateTime(2026, 5, 15, 9, 0),
            DateTime(2026, 5, 15, 10, 0),
            DateTime(2026, 5, 15, 11, 0),
            DateTime(2026, 5, 15, 13, 0),
            DateTime(2026, 5, 15, 17, 0),
          ])
            _nap(start: end.subtract(const Duration(minutes: 50)), end: end),
        ],
      );

      expect(prediction, isNotNull);
      expect(prediction!.targetTime, DateTime(2026, 5, 15, 18, 30));
      expect(prediction.kind, NextSleepKind.bedtime);
      expect(
        prediction.reasonCode,
        NextSleepReasonCode.earlyBedtimeAfterWindowsExhausted,
      );
    });

    test('sin fecha de nacimiento → null', () {
      expect(
        predictNextSleep(
          birthDate: null,
          now: DateTime(2026, 5, 15, 12),
          records: const [],
        ),
        isNull,
      );
    });
  });

  group('nº de siestas aprendido', () {
    // Genera [napsPerDay] siestas de 60 min al día durante [days] días previos.
    List<SleepRecord> history({
      required DateTime today,
      required int days,
      required int napsPerDay,
    }) {
      final records = <SleepRecord>[];
      for (var d = 1; d <= days; d++) {
        final day = today.subtract(Duration(days: d));
        records.add(
          _night(
            start: DateTime(day.year, day.month, day.day - 1, 20, 0),
            end: DateTime(day.year, day.month, day.day, 7, 0),
          ),
        );
        for (var n = 0; n < napsPerDay; n++) {
          final start = DateTime(day.year, day.month, day.day, 8 + n * 2, 0);
          records.add(
            _nap(start: start, end: start.add(const Duration(minutes: 60))),
          );
        }
      }
      return records;
    }

    test('menos de 5 días registrados → manda la tabla de edad', () {
      final today = DateTime(2026, 5, 15);
      final stats = SleepPersonalStats.fromRecords(
        records: history(today: today, days: 3, napsPerDay: 7),
        now: DateTime(2026, 5, 15, 12),
        minNapMinutes: 35,
      );

      expect(stats.hasLearnedNapCount, isFalse);
      expect(
        effectiveWakeWindowsMinutes(
          rule: sleepAgeWakeRuleForMonths(1),
          personal: stats,
        ),
        sleepAgeWakeRuleForMonths(1).wakeWindowsMinutes,
      );
    });

    test('bebé que hace más siestas estira las ventanas (máx. +2)', () {
      final today = DateTime(2026, 5, 15);
      final stats = SleepPersonalStats.fromRecords(
        records: history(today: today, days: 10, napsPerDay: 7),
        now: DateTime(2026, 5, 15, 12),
        minNapMinutes: 35,
      );

      expect(stats.medianNapsPerDay, 7);
      expect(stats.hasLearnedNapCount, isTrue);
      // 1 mes → [60,70,75,85,90]; 7 siestas se recorta a 5+2 repitiendo la última.
      expect(
        effectiveWakeWindowsMinutes(
          rule: sleepAgeWakeRuleForMonths(1),
          personal: stats,
        ),
        [60, 70, 75, 85, 90, 90, 90],
      );
    });

    test('bebé que hace menos siestas conserva la última ventana', () {
      final today = DateTime(2026, 5, 15);
      final stats = SleepPersonalStats.fromRecords(
        records: history(today: today, days: 10, napsPerDay: 2),
        now: DateTime(2026, 5, 15, 12),
        minNapMinutes: 45,
      );

      expect(stats.medianNapsPerDay, 2);
      // 5 meses → [120,135,150]; 2 siestas → primera + última.
      expect(
        effectiveWakeWindowsMinutes(
          rule: sleepAgeWakeRuleForMonths(5),
          personal: stats,
        ),
        [120, 150],
      );
    });

    test('las ventanas extra evitan la siesta puente prematura', () {
      final today = DateTime(2026, 5, 15);
      final past = history(today: today, days: 10, napsPerDay: 7);
      final todayRecords = [
        _night(
          start: DateTime(2026, 5, 14, 20, 0),
          end: DateTime(2026, 5, 15, 7, 0),
        ),
        for (final endHour in [8, 10, 11, 13, 15])
          _nap(
            start: DateTime(2026, 5, 15, endHour - 1, 0),
            end: DateTime(2026, 5, 15, endHour, 0),
          ),
      ];

      final prediction = predictNextSleep(
        birthDate: DateTime(2026, 4, 1),
        now: DateTime(2026, 5, 15, 16, 0),
        records: [...past, ...todayRecords],
      );

      expect(prediction, isNotNull);
      expect(prediction!.windowsExhausted, isFalse);
      expect(prediction.kind, NextSleepKind.nextNap);
      expect(
        prediction.reasonCode,
        isNot(NextSleepReasonCode.catnapAfterWindowsExhausted),
      );
      expect(prediction.isPersonalized, isTrue);
    });

    test('tras la mediana personal de siestas no inventa otra puente', () {
      final today = DateTime(2026, 5, 15);
      // Mediana aprendida = 5 (máx. real del bebé).
      final past = history(today: today, days: 10, napsPerDay: 5);
      final todayRecords = [
        _night(
          start: DateTime(2026, 5, 14, 20, 0),
          end: DateTime(2026, 5, 15, 7, 0),
        ),
        for (final endHour in [8, 10, 11, 13, 15])
          _nap(
            start: DateTime(2026, 5, 15, endHour - 1, 0),
            end: DateTime(2026, 5, 15, endHour, 0),
          ),
      ];

      final prediction = predictNextSleep(
        birthDate: DateTime(2026, 4, 1),
        now: DateTime(2026, 5, 15, 16, 0),
        records: [...past, ...todayRecords],
      );

      expect(prediction, isNotNull);
      expect(prediction!.windowsExhausted, isTrue);
      expect(prediction.kind, NextSleepKind.bedtime);
      expect(
        prediction.reasonCode,
        NextSleepReasonCode.earlyBedtimeAfterWindowsExhausted,
      );
    });
  });

  group('duración de siesta aprendida', () {
    List<SleepRecord> napsOf({
      required DateTime today,
      required int days,
      required int minutes,
    }) {
      final records = <SleepRecord>[];
      for (var d = 1; d <= days; d++) {
        final day = today.subtract(Duration(days: d));
        for (var n = 0; n < 3; n++) {
          final start = DateTime(day.year, day.month, day.day, 8 + n * 3, 0);
          records.add(
            _nap(
              start: start,
              end: start.add(Duration(minutes: minutes)),
            ),
          );
        }
      }
      return records;
    }

    test('con pocas siestas se mantienen los valores de la tabla', () {
      final stats = SleepPersonalStats.fromRecords(
        records: napsOf(today: DateTime(2026, 5, 15), days: 2, minutes: 30),
        now: DateTime(2026, 5, 15, 12),
        minNapMinutes: 45,
      );

      expect(stats.hasLearnedNapDuration, isFalse);
      expect(stats.blendedTypicalNapMinutes(ageTypicalNapMinutes: 70), 70);
      expect(stats.shortNapThresholdMinutes(ageMinNapMinutes: 45), 45);
    });

    test('siestas cortas bajan el umbral y la siesta típica', () {
      final stats = SleepPersonalStats.fromRecords(
        records: napsOf(today: DateTime(2026, 5, 15), days: 6, minutes: 30),
        now: DateTime(2026, 5, 15, 12),
        minNapMinutes: 45,
      );

      expect(stats.hasLearnedNapDuration, isTrue);
      expect(stats.medianNapMinutes, 30);
      expect(stats.blendedTypicalNapMinutes(ageTypicalNapMinutes: 70), 39);
      expect(stats.shortNapThresholdMinutes(ageMinNapMinutes: 45), 30);
    });

    test('el umbral no sube más de 1,5× el valor de la edad', () {
      final stats = SleepPersonalStats.fromRecords(
        records: napsOf(today: DateTime(2026, 5, 15), days: 6, minutes: 120),
        now: DateTime(2026, 5, 15, 12),
        minNapMinutes: 45,
      );

      expect(stats.p25NapMinutes, 120);
      expect(stats.shortNapThresholdMinutes(ageMinNapMinutes: 45), 68);
    });

    test(
      'una siesta corta para la edad ya no penaliza si es normal para él',
      () {
        final history = napsOf(
          today: DateTime(2026, 5, 15),
          days: 6,
          minutes: 35,
        );
        final prediction = predictNextSleep(
          birthDate: DateTime(2025, 12, 15),
          now: DateTime(2026, 5, 15, 11, 0),
          records: [
            ...history,
            _night(
              start: DateTime(2026, 5, 14, 21, 0),
              end: DateTime(2026, 5, 15, 7, 0),
            ),
            _nap(
              start: DateTime(2026, 5, 15, 9, 0),
              end: DateTime(2026, 5, 15, 9, 35),
            ),
          ],
        );

        // 35 min está por debajo del mínimo de la tabla (45) pero es lo habitual
        // en este bebé, así que no se recorta la siguiente ventana.
        expect(prediction, isNotNull);
        expect(prediction!.napAdjustmentMinutes, 0);
        expect(
          prediction.reasonCode,
          isNot(NextSleepReasonCode.shortenedWindowAfterShortNap),
        );
      },
    );
  });

  group('SleepPersonalStats + blend', () {
    test('blendWeight crece desde 3 hasta 10 muestras', () {
      expect(sleepPersonalBlendWeight(2), 0);
      expect(sleepPersonalBlendWeight(3), 0);
      expect(sleepPersonalBlendWeight(10), kSleepPersonalMaxBlendWeight);
      expect(
        sleepPersonalBlendWeight(6),
        closeTo(kSleepPersonalMaxBlendWeight * 3 / 7, 0.001),
      );
    });

    test('mediana de vigilia por franja y IQR', () {
      final now = DateTime(2026, 5, 15, 12);
      // 5 intervalos mañana: 90,100,110,120,130 → mediana 110, p25≈100, p75≈120
      final records = <SleepRecord>[];
      for (var d = 1; d <= 5; d++) {
        final day = DateTime(2026, 5, d);
        records.add(
          _night(
            start: day.subtract(const Duration(hours: 3)),
            end: DateTime(day.year, day.month, day.day, 7, 0),
          ),
        );
        final awake = 90 + (d - 1) * 10;
        final napStart = DateTime(
          day.year,
          day.month,
          day.day,
          7,
          0,
        ).add(Duration(minutes: awake));
        records.add(
          _nap(start: napStart, end: napStart.add(const Duration(minutes: 50))),
        );
      }

      final stats = SleepPersonalStats.fromRecords(
        records: records,
        now: now,
        minNapMinutes: 45,
      );
      final morning = stats.statsFor(SleepWakeSlot.morning);
      expect(morning.sampleCount, 5);
      expect(morning.medianMinutes, 110);
      expect(morning.p25Minutes, 100);
      expect(morning.p75Minutes, 120);
    });

    test('ventana personal mezclada acorta predicción vs solo edad', () {
      final now = DateTime(2026, 5, 15, 9, 30);
      // Historial: mañanas con vigilia corta (~80 min), ≥3 muestras.
      final history = <SleepRecord>[];
      for (var d = 1; d <= 8; d++) {
        final day = DateTime(2026, 5, d);
        history.add(
          _night(
            start: day.subtract(const Duration(hours: 3)),
            end: DateTime(day.year, day.month, day.day, 7, 0),
          ),
        );
        history.add(
          _nap(
            start: DateTime(day.year, day.month, day.day, 8, 20),
            end: DateTime(day.year, day.month, day.day, 9, 10),
          ),
        );
      }
      // Hoy: solo despertar nocturno.
      history.add(
        _night(
          start: DateTime(2026, 5, 14, 21, 0),
          end: DateTime(2026, 5, 15, 7, 0),
        ),
      );

      final personal = SleepPersonalStats.fromRecords(
        records: history,
        now: now,
        minNapMinutes: 45,
      );
      final morning = personal.statsFor(SleepWakeSlot.morning);
      expect(morning.sampleCount, greaterThanOrEqualTo(3));
      expect(morning.medianMinutes, 80);

      final prediction = predictNextSleep(
        birthDate: birthDate,
        now: now,
        records: history,
        personalStats: personal,
      );

      expect(prediction, isNotNull);
      // Edad índice 0 (mañana, sin siestas, timeIndex 0) → 120; blend con 80.
      expect(prediction!.ageWindowMinutes, 120);
      expect(prediction.baseWindowMinutes, lessThan(120));
      expect(prediction.personalizationWeight, greaterThan(0));
      expect(prediction.isPersonalized, isTrue);
      // Rango IQR ±(110-100 style) → aquí mediana 80, p25/p75 del set.
      expect(
        prediction.windowEnd.difference(prediction.windowStart).inMinutes,
        greaterThanOrEqualTo(kSleepPersonalDefaultHalfRangeMinutes * 2),
      );
    });

    test('despertar matutino aprendido sustituye 07:00', () {
      final now = DateTime(2026, 5, 15, 9, 0);
      final history = <SleepRecord>[];
      for (var d = 1; d <= 5; d++) {
        final day = DateTime(2026, 5, d);
        history.add(
          _night(
            start: day.subtract(const Duration(hours: 2)),
            end: DateTime(day.year, day.month, day.day, 6, 30),
          ),
        );
      }

      final personal = SleepPersonalStats.fromRecords(
        records: history,
        now: now,
        minNapMinutes: 45,
      );
      expect(personal.hasLearnedMorningWake, isTrue);
      expect(personal.medianMorningWakeMinutesOfDay, 6 * 60 + 30);

      final prediction = predictNextSleep(
        birthDate: birthDate,
        now: now,
        records: const [],
        personalStats: personal,
      );

      expect(prediction, isNotNull);
      expect(prediction!.usedDefaultMorningWake, isTrue);
      expect(prediction.lastWakeUp, DateTime(2026, 5, 15, 6, 30));
      expect(prediction.isPersonalized, isTrue);
    });

    test('bedtime aprendido adelanta el umbral de noche', () {
      final birth8m = DateTime(2025, 9, 15);
      final now = DateTime(2026, 5, 15, 17, 0);
      final history = <SleepRecord>[];
      for (var d = 1; d <= 5; d++) {
        final day = DateTime(2026, 5, d);
        history.add(
          _night(
            start: DateTime(day.year, day.month, day.day, 19, 0),
            end: DateTime(day.year, day.month, day.day + 1, 7, 0),
          ),
        );
      }
      history.addAll([
        _night(
          start: DateTime(2026, 5, 14, 19, 0),
          end: DateTime(2026, 5, 15, 7, 0),
        ),
        _nap(
          start: DateTime(2026, 5, 15, 9, 0),
          end: DateTime(2026, 5, 15, 10, 0),
        ),
        _nap(
          start: DateTime(2026, 5, 15, 14, 0),
          end: DateTime(2026, 5, 15, 15, 0),
        ),
      ]);

      final personal = SleepPersonalStats.fromRecords(
        records: history,
        now: now,
        minNapMinutes: 45,
      );
      expect(personal.hasLearnedBedtime, isTrue);
      expect(personal.medianBedtimeMinutesOfDay, 19 * 60);

      // 8m ventanas [150,165,180]; count=2,time=2 → 180; 15:00+180=18:00
      // usual aprendido 19:00 → 18:00 < 19:00 → aún siesta
      // Con target 18:00 y bedtime 19:00 no es bedtime aún.
      // Subir last wake: 16:00+180=19:00 → bedtime
      final prediction = predictNextSleep(
        birthDate: birth8m,
        now: now,
        records: [
          _night(
            start: DateTime(2026, 5, 14, 19, 0),
            end: DateTime(2026, 5, 15, 7, 0),
          ),
          _nap(
            start: DateTime(2026, 5, 15, 9, 0),
            end: DateTime(2026, 5, 15, 10, 0),
          ),
          _nap(
            start: DateTime(2026, 5, 15, 15, 0),
            end: DateTime(2026, 5, 15, 16, 0),
          ),
        ],
        personalStats: personal,
      );

      expect(prediction, isNotNull);
      expect(prediction!.targetTime, DateTime(2026, 5, 15, 19, 0));
      expect(prediction.kind, NextSleepKind.bedtime);
    });

    test('una siesta más corta de lo habitual acorta la ventana', () {
      final now = DateTime(2026, 5, 15, 11, 0);
      final history = <SleepRecord>[];
      // Varias mañanas con vigilia normal 120 tras siesta larga,
      // y tras siesta corta la siguiente llega ~25 min antes.
      for (var d = 1; d <= 6; d++) {
        final day = DateTime(2026, 5, d);
        history.add(
          _night(
            start: day.subtract(const Duration(hours: 3)),
            end: DateTime(day.year, day.month, day.day, 7, 0),
          ),
        );
        // Siesta corta 30 min
        history.add(
          _nap(
            start: DateTime(day.year, day.month, day.day, 8, 0),
            end: DateTime(day.year, day.month, day.day, 8, 30),
          ),
        );
        // Siguiente sueño 95 min después (baseline mañana ~120 → advance ~25)
        // Need morning awake samples for baseline: wake 7:00 → first nap.
        // Actually first awake is 7→8 = 60 min morning slot.
        // After short nap at 8:30, next at 8:30+95=10:05 → midday slot awake.
        history.add(
          _nap(
            start: DateTime(day.year, day.month, day.day, 10, 5),
            end: DateTime(day.year, day.month, day.day, 11, 0),
          ),
        );
      }
      // Añadir vigilias midday "normales" de 120 para baseline del slot
      for (var d = 1; d <= 6; d++) {
        final day = DateTime(2026, 4, d);
        history.add(
          _nap(
            start: DateTime(day.year, day.month, day.day, 11, 0),
            end: DateTime(day.year, day.month, day.day, 12, 0),
          ),
        );
        history.add(
          _nap(
            start: DateTime(day.year, day.month, day.day, 14, 0),
            end: DateTime(day.year, day.month, day.day, 14, 45),
          ),
        );
      }

      final personal = SleepPersonalStats.fromRecords(
        records: history,
        now: now,
        minNapMinutes: 45,
      );

      // Hoy: despertar + siesta de 15 min, la mitad de lo habitual en él.
      final today = [
        _night(
          start: DateTime(2026, 5, 14, 21, 0),
          end: DateTime(2026, 5, 15, 7, 0),
        ),
        _nap(
          start: DateTime(2026, 5, 15, 8, 30),
          end: DateTime(2026, 5, 15, 8, 45),
        ),
      ];

      final prediction = predictNextSleep(
        birthDate: birthDate,
        now: now,
        records: [...history, ...today],
        personalStats: personal,
      );

      // Sus siestas habituales son de 30 min, así que 15 sí se queda corta.
      expect(prediction, isNotNull);
      expect(prediction!.napAdjustmentMinutes, lessThan(0));
      expect(
        prediction.napAdjustmentMinutes.abs(),
        lessThanOrEqualTo(kSleepPersonalMaxNapDeviationAdjustMinutes),
      );
      expect(
        prediction.reasonCode,
        NextSleepReasonCode.shortenedWindowAfterShortNap,
      );
    });
  });

  group('ajuste continuo por la siesta anterior', () {
    // 14 días de rutina fija: despertar 7:00 y tres siestas de 60 min con
    // vigilias de 120 min. Bebé de 5 meses.
    List<SleepRecord> routine(DateTime today) {
      final records = <SleepRecord>[];
      for (var d = 1; d <= 14; d++) {
        final day = today.subtract(Duration(days: d));
        records.add(
          _night(
            start: DateTime(day.year, day.month, day.day - 1, 20, 0),
            end: DateTime(day.year, day.month, day.day, 7, 0),
          ),
        );
        for (final hour in [9, 12, 15]) {
          records.add(
            _nap(
              start: DateTime(day.year, day.month, day.day, hour, 0),
              end: DateTime(day.year, day.month, day.day, hour + 1, 0),
            ),
          );
        }
      }
      return records;
    }

    NextSleepPrediction? predictAfterNapOf(int napMinutes, DateTime now) {
      final today = DateTime(2026, 5, 15);
      final napStart = DateTime(2026, 5, 15, 9, 0);
      return predictNextSleep(
        birthDate: DateTime(2025, 12, 15),
        now: now,
        records: [
          ...routine(today),
          _night(
            start: DateTime(2026, 5, 14, 20, 0),
            end: DateTime(2026, 5, 15, 7, 0),
          ),
          _nap(
            start: napStart,
            end: napStart.add(Duration(minutes: napMinutes)),
          ),
        ],
      );
    }

    test('una siesta 30 min corta acorta la ventana 15 min', () {
      final prediction = predictAfterNapOf(30, DateTime(2026, 5, 15, 11, 0));

      expect(prediction, isNotNull);
      expect(prediction!.napAdjustmentMinutes, -15);
      expect(
        prediction.reasonCode,
        NextSleepReasonCode.shortenedWindowAfterShortNap,
      );
    });

    test('una siesta larga no alarga la ventana', () {
      final prediction = predictAfterNapOf(100, DateTime(2026, 5, 15, 12, 0));

      expect(prediction, isNotNull);
      expect(prediction!.napAdjustmentMinutes, 0);
      expect(prediction.reasonCode, NextSleepReasonCode.standard);
    });

    test('una desviación pequeña no mueve nada', () {
      final prediction = predictAfterNapOf(65, DateTime(2026, 5, 15, 11, 0));

      expect(prediction, isNotNull);
      expect(prediction!.napAdjustmentMinutes, 0);
      expect(prediction.reasonCode, NextSleepReasonCode.standard);
    });

    test('la proporción se aprende del propio bebé', () {
      // Días pares: 1ª siesta de 60 min y después 120 min despierto.
      // Días impares: 1ª siesta de 30 min y después solo 90 min despierto.
      // La vigilia se mueve minuto a minuto con la siesta → pendiente 1.
      final records = <SleepRecord>[];
      for (var d = 1; d <= 12; d++) {
        final day = DateTime(2026, 5, 15).subtract(Duration(days: d));
        final isShortDay = d.isOdd;
        final napMinutes = isShortDay ? 30 : 60;
        final awakeMinutes = isShortDay ? 90 : 120;
        records.add(
          _night(
            start: DateTime(day.year, day.month, day.day - 1, 20, 0),
            end: DateTime(day.year, day.month, day.day, 7, 0),
          ),
        );
        final firstNapEnd = DateTime(
          day.year,
          day.month,
          day.day,
          8,
          0,
        ).add(Duration(minutes: napMinutes));
        records.add(
          _nap(
            start: DateTime(day.year, day.month, day.day, 8, 0),
            end: firstNapEnd,
          ),
        );
        final secondNapStart = firstNapEnd.add(Duration(minutes: awakeMinutes));
        records.add(
          _nap(
            start: secondNapStart,
            end: secondNapStart.add(const Duration(minutes: 60)),
          ),
        );
      }

      final stats = SleepPersonalStats.fromRecords(
        records: records,
        now: DateTime(2026, 5, 15, 12),
        minNapMinutes: 45,
      );

      expect(stats.medianNapMinutes, 60);
      expect(stats.learnedNapDeviationSlope, closeTo(1, 0.05));
      // Con pendiente 1, media hora menos de siesta es media hora menos de
      // vigilia, en vez de los 15 min del valor por defecto.
      expect(stats.napDeviationAdjustmentMinutes(30), -30);
    });
  });

  group('recencia y frescura', () {
    test('la mediana sigue al patrón nuevo, no al viejo', () {
      final now = DateTime(2026, 5, 15, 12);
      final records = <SleepRecord>[];
      // Patrón viejo (hace 15–21 días): vigilia matutina de 150 min.
      // Patrón nuevo (últimos 5 días): 90 min.
      void addDay(int daysAgo, int awakeMinutes) {
        final day = DateTime(2026, 5, 15).subtract(Duration(days: daysAgo));
        records.add(
          _night(
            start: DateTime(day.year, day.month, day.day - 1, 20, 0),
            end: DateTime(day.year, day.month, day.day, 7, 0),
          ),
        );
        final napStart = DateTime(
          day.year,
          day.month,
          day.day,
          7,
          0,
        ).add(Duration(minutes: awakeMinutes));
        records.add(
          _nap(start: napStart, end: napStart.add(const Duration(hours: 1))),
        );
      }

      for (var d = 15; d <= 21; d++) {
        addDay(d, 150);
      }
      for (var d = 1; d <= 5; d++) {
        addDay(d, 90);
      }

      final stats = SleepPersonalStats.fromRecords(
        records: records,
        now: now,
        minNapMinutes: 45,
      );

      // Sin pesos la mediana sería 150 (7 muestras viejas contra 5 nuevas).
      expect(stats.statsForNapIndex(0).sampleCount, 12);
      expect(stats.statsForNapIndex(0).medianMinutes, 90);
    });

    test('si se deja de registrar, la tabla recupera peso', () {
      final records = <SleepRecord>[];
      for (var d = 15; d <= 20; d++) {
        final day = DateTime(2026, 5, 15).subtract(Duration(days: d));
        records.add(
          _night(
            start: DateTime(day.year, day.month, day.day - 1, 20, 0),
            end: DateTime(day.year, day.month, day.day, 7, 0),
          ),
        );
        for (final hour in [9, 12, 15]) {
          records.add(
            _nap(
              start: DateTime(day.year, day.month, day.day, hour, 0),
              end: DateTime(day.year, day.month, day.day, hour + 1, 0),
            ),
          );
        }
      }

      final stale = SleepPersonalStats.fromRecords(
        records: records,
        now: DateTime(2026, 5, 15, 12),
        minNapMinutes: 45,
      );
      final fresh = SleepPersonalStats.fromRecords(
        records: records,
        now: DateTime(2026, 5, 1, 12),
        minNapMinutes: 45,
      );

      // Mismos datos, vistos dos semanas después: menos peso y sin reglas.
      expect(fresh.hasLearnedNapCount, isTrue);
      expect(stale.hasLearnedNapCount, isFalse);
      expect(
        stale.statsForNapIndex(0).blendWeight,
        lessThan(fresh.statsForNapIndex(0).blendWeight),
      );
    });

    test('el techo sube del 70 % solo con mucho historial y regularidad', () {
      expect(sleepPersonalBlendWeight(10), kSleepPersonalMaxBlendWeight);
      expect(
        SleepPersonalStats.blendWeight(
          sampleCount: 20,
          freshness: 1,
          relativeDispersion: 0.1,
        ),
        kSleepPersonalHighBlendWeight,
      );
      // Bebé irregular: se queda en el techo normal.
      expect(
        SleepPersonalStats.blendWeight(
          sampleCount: 20,
          freshness: 1,
          relativeDispersion: 0.8,
        ),
        kSleepPersonalMaxBlendWeight,
      );
      // La frescura escala el resultado.
      expect(
        SleepPersonalStats.blendWeight(sampleCount: 10, freshness: 0.5),
        kSleepPersonalMaxBlendWeight / 2,
      );
    });
  });

  group('vigilia por número de siesta', () {
    test('separa la 1ª y la 2ª ventana aunque caigan en la misma franja', () {
      final now = DateTime(2026, 5, 15, 12);
      final records = <SleepRecord>[];
      for (var d = 1; d <= 8; d++) {
        final day = DateTime(2026, 5, 15).subtract(Duration(days: d));
        records.add(
          _night(
            start: DateTime(day.year, day.month, day.day - 1, 20, 0),
            end: DateTime(day.year, day.month, day.day, 6, 0),
          ),
        );
        // Despertar 6:00 → 1ª siesta a las 7:00 (vigilia 60).
        records.add(
          _nap(
            start: DateTime(day.year, day.month, day.day, 7, 0),
            end: DateTime(day.year, day.month, day.day, 8, 0),
          ),
        );
        // Despertar 8:00 → 2ª siesta a las 10:00 (vigilia 120).
        records.add(
          _nap(
            start: DateTime(day.year, day.month, day.day, 10, 0),
            end: DateTime(day.year, day.month, day.day, 11, 0),
          ),
        );
      }

      final stats = SleepPersonalStats.fromRecords(
        records: records,
        now: now,
        minNapMinutes: 45,
      );

      // Los dos despertares caen en la franja "mañana", que las mezcla.
      expect(stats.statsForNapIndex(0).medianMinutes, 60);
      expect(stats.statsForNapIndex(1).medianMinutes, 120);
      expect(
        stats
            .resolveStats(slot: SleepWakeSlot.morning, napIndex: 0)
            .medianMinutes,
        60,
      );
      expect(
        stats
            .resolveStats(slot: SleepWakeSlot.morning, napIndex: 1)
            .medianMinutes,
        120,
      );
      // La franja horaria, en cambio, mete las dos ventanas en el mismo saco.
      final morning = stats.statsFor(SleepWakeSlot.morning);
      expect(morning.sampleCount, 16);
      expect(morning.p25Minutes, 60);
      expect(morning.p75Minutes, 120);
    });

    test('sin datos para ese índice se usa la franja horaria', () {
      final now = DateTime(2026, 5, 15, 12);
      final records = <SleepRecord>[];
      for (var d = 1; d <= 6; d++) {
        final day = DateTime(2026, 5, 15).subtract(Duration(days: d));
        records.add(
          _night(
            start: DateTime(day.year, day.month, day.day - 1, 20, 0),
            end: DateTime(day.year, day.month, day.day, 7, 0),
          ),
        );
        records.add(
          _nap(
            start: DateTime(day.year, day.month, day.day, 9, 0),
            end: DateTime(day.year, day.month, day.day, 10, 0),
          ),
        );
      }

      final stats = SleepPersonalStats.fromRecords(
        records: records,
        now: now,
        minNapMinutes: 45,
      );

      expect(stats.statsForNapIndex(3).hasBlendableData, isFalse);
      expect(
        stats
            .resolveStats(slot: SleepWakeSlot.morning, napIndex: 3)
            .medianMinutes,
        stats.statsFor(SleepWakeSlot.morning).medianMinutes,
      );
    });
  });
}
