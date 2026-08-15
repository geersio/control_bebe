import 'package:control_bebe/core/models/enums.dart';
import 'package:control_bebe/core/models/sleep_record.dart';
import 'package:control_bebe/core/utils/sleep_day_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 28, 14, 0);
  final day = DateTime(2026, 7, 28);

  test('nocturno cruzando medianoche + siesta; despertar deja hueco', () {
    final night = SleepRecord(
      id: 1,
      startDateTime: DateTime(2026, 7, 27, 22, 0),
      endDateTime: DateTime(2026, 7, 28, 7, 0),
      type: SleepType.night,
    );
    final waking = SleepRecord(
      id: 2,
      startDateTime: DateTime(2026, 7, 28, 2, 0),
      endDateTime: DateTime(2026, 7, 28, 2, 30),
      type: SleepType.nightWaking,
      parentSleepId: 1,
    );
    final nap = SleepRecord(
      id: 3,
      startDateTime: DateTime(2026, 7, 28, 9, 0),
      endDateTime: DateTime(2026, 7, 28, 10, 0),
      type: SleepType.nap,
    );

    final segments = buildSleepDayTimelineSegments(
      records: [night, waking, nap],
      now: now,
    );

    expect(segments, hasLength(3));
    // 00:00–02:00 nocturno
    expect(segments[0].isNight, isTrue);
    expect(segments[0].start, closeTo(0, 0.001));
    expect(segments[0].end, closeTo(2 / 24, 0.001));
    // 02:30–07:00 nocturno
    expect(segments[1].isNight, isTrue);
    expect(segments[1].start, closeTo(2.5 / 24, 0.001));
    expect(segments[1].end, closeTo(7 / 24, 0.001));
    // 09:00–10:00 siesta
    expect(segments[2].isNight, isFalse);
    expect(segments[2].start, closeTo(9 / 24, 0.001));
    expect(segments[2].end, closeTo(10 / 24, 0.001));

    // Total hoy: 2h + 4.5h + 1h = 7.5h (despertar no cuenta)
    expect(sleepSecondsToday([night, waking, nap], now), 7.5 * 3600);
  });

  test('sesión abierta se alarga hasta now', () {
    final open = SleepRecord(
      id: 9,
      startDateTime: DateTime(2026, 7, 28, 13, 0),
      endDateTime: null,
      type: SleepType.nap,
    );
    final segments = buildSleepDayTimelineSegments(
      records: [open],
      now: now,
    );
    expect(segments, hasLength(1));
    expect(segments.first.isNight, isFalse);
    expect(segments.first.start, closeTo(13 / 24, 0.001));
    expect(segments.first.end, closeTo(14 / 24, 0.001));
  });

  test('día sin registros → sin segmentos y 0 segundos', () {
    expect(
      buildSleepDayTimelineSegments(records: const [], now: now),
      isEmpty,
    );
    expect(sleepSecondsToday(const [], now), 0);
    expect(sleepRecordsOverlappingCivilDay(const [], day), isEmpty);
  });
}
