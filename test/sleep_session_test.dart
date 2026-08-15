import 'package:control_bebe/core/models/enums.dart';
import 'package:control_bebe/core/models/sleep_record.dart';
import 'package:control_bebe/core/utils/sleep_history_tree.dart';
import 'package:control_bebe/core/utils/sleep_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final nightStart = DateTime(2026, 7, 27, 21, 0);
  final nightEnd = DateTime(2026, 7, 28, 7, 0);

  test('agrupa despertares bajo el sueño padre', () {
    final night = SleepRecord(
      id: 1,
      startDateTime: nightStart,
      endDateTime: nightEnd,
      type: SleepType.night,
    );
    final waking = SleepRecord(
      id: 2,
      startDateTime: DateTime(2026, 7, 28, 2, 10),
      endDateTime: DateTime(2026, 7, 28, 2, 35),
      type: SleepType.nightWaking,
      parentSleepId: 1,
    );
    final entries = buildSleepHistoryEntries([night, waking]);
    expect(entries, hasLength(1));
    expect(entries.first.wakings, hasLength(1));
    expect(entries.first.wakingMinutes, 25);
  });

  test('despertar sin padre queda independiente', () {
    final waking = SleepRecord(
      id: 2,
      startDateTime: DateTime(2026, 7, 28, 2, 10),
      endDateTime: DateTime(2026, 7, 28, 2, 35),
      type: SleepType.nightWaking,
    );
    final entries = buildSleepHistoryEntries([waking]);
    expect(entries, hasLength(1));
    expect(entries.first.sleep.isNightWaking, isTrue);
    expect(entries.first.wakings, isEmpty);
  });

  test('historial omite sesión abierta hasta cerrarla', () {
    final open = SleepRecord(
      id: 9,
      startDateTime: DateTime(2026, 7, 28, 14, 0),
      endDateTime: null,
      type: SleepType.nap,
    );
    final closed = SleepRecord(
      id: 1,
      startDateTime: nightStart,
      endDateTime: nightEnd,
      type: SleepType.night,
    );
    final entries = buildSleepHistoryEntries([open, closed]);
    expect(entries, hasLength(1));
    expect(entries.first.sleep.id, 1);
    expect(entries.first.sleep.isOpen, isFalse);
  });

  test('numera siestas del día por orden de inicio', () {
    final day = DateTime(2026, 7, 28);
    final nap2 = SleepRecord(
      id: 2,
      startDateTime: day.add(const Duration(hours: 13)),
      endDateTime: day.add(const Duration(hours: 14, minutes: 30)),
      type: SleepType.nap,
    );
    final nap1 = SleepRecord(
      id: 1,
      startDateTime: day.add(const Duration(hours: 10)),
      endDateTime: day.add(const Duration(hours: 11)),
      type: SleepType.nap,
    );
    final napNextDay = SleepRecord(
      id: 3,
      startDateTime: day.add(const Duration(days: 1, hours: 10)),
      endDateTime: day.add(const Duration(days: 1, hours: 11)),
      type: SleepType.nap,
    );
    final night = SleepRecord(
      id: 4,
      startDateTime: nightStart,
      endDateTime: nightEnd,
      type: SleepType.night,
    );

    final numbers = napNumbersByDay([nap2, nap1, napNextDay, night]);
    expect(numbers[sleepRecordIdentity(nap1)], 1);
    expect(numbers[sleepRecordIdentity(nap2)], 2);
    expect(numbers[sleepRecordIdentity(napNextDay)], 1);
    expect(numbers.containsKey(sleepRecordIdentity(night)), isFalse);
  });

  test('historial omite despertares de sesión abierta', () {
    final open = SleepRecord(
      id: 1,
      startDateTime: nightStart,
      endDateTime: null,
      type: SleepType.night,
    );
    final waking = SleepRecord(
      id: 2,
      startDateTime: DateTime(2026, 7, 28, 2, 10),
      endDateTime: DateTime(2026, 7, 28, 2, 35),
      type: SleepType.nightWaking,
      parentSleepId: 1,
    );
    expect(buildSleepHistoryEntries([open, waking]), isEmpty);
  });

  test('insight muestra sesión abierta y no predice', () {
    final open = SleepRecord(
      id: 9,
      startDateTime: DateTime(2026, 7, 28, 14, 0),
      endDateTime: null,
      type: SleepType.nap,
    );
    final stats = SleepInsightStats.fromRecords(
      records: [open],
      now: DateTime(2026, 7, 28, 14, 30),
      birthDate: DateTime(2026, 1, 1),
    );
    expect(stats.isSleeping, isTrue);
    expect(stats.openSession?.id, 9);
    expect(stats.nextSleep, isNull);
    expect(stats.todaySeconds, greaterThan(0));
  });

  test('media diaria oculta con un solo registro corto', () {
    final nap = SleepRecord(
      id: 1,
      startDateTime: DateTime(2026, 7, 27, 10, 0),
      endDateTime: DateTime(2026, 7, 27, 10, 40),
      type: SleepType.nap,
    );
    final stats = SleepInsightStats.fromRecords(
      records: [nap],
      now: DateTime(2026, 7, 28, 12, 0),
      birthDate: DateTime(2026, 1, 1),
    );
    expect(stats.hasUsualEstimate, isFalse);
    expect(stats.usualDailySeconds, isNull);
  });

  test('media diaria visible con un día sustancial', () {
    // 22:00→08:00 → 8 h el día 27 (previo a hoy).
    final night = SleepRecord(
      id: 1,
      startDateTime: DateTime(2026, 7, 26, 22, 0),
      endDateTime: DateTime(2026, 7, 27, 8, 0),
      type: SleepType.night,
    );
    final stats = SleepInsightStats.fromRecords(
      records: [night],
      now: DateTime(2026, 7, 28, 12, 0),
      birthDate: DateTime(2026, 1, 1),
    );
    expect(stats.hasUsualEstimate, isTrue);
    // 2 h (día 26) + 8 h (día 27) = 10 h → media / 2 días con datos.
    expect(stats.usualDailySeconds, (10 * 3600 / 2).round());
  });

  test('media diaria visible con varios registros cortos', () {
    final records = [
      for (var i = 0; i < 3; i++)
        SleepRecord(
          id: i + 1,
          startDateTime: DateTime(2026, 7, 27, 9 + i, 0),
          endDateTime: DateTime(2026, 7, 27, 9 + i, 30),
          type: SleepType.nap,
        ),
    ];
    final stats = SleepInsightStats.fromRecords(
      records: records,
      now: DateTime(2026, 7, 28, 12, 0),
      birthDate: DateTime(2026, 1, 1),
    );
    expect(stats.hasUsualEstimate, isTrue);
    // Tres siestas el mismo día → 1 día con datos.
    expect(stats.usualDailySeconds, 3 * 30 * 60);
  });
}
