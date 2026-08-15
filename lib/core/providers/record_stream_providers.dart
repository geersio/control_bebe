import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/isar_service.dart';
import '../models/diaper_record.dart';
import '../models/feeding_record.dart';
import '../models/height_record.dart';
import '../models/sleep_record.dart';
import '../models/weight_record.dart';
import '../utils/history_calendar_window.dart';
import '../utils/home_insight_windows.dart';
import 'baby_profile_provider.dart';

// --- Ventana de días consultada en Firestore (ampliable al hacer scroll) ---

final feedingHistoryFirestoreDaysProvider = StateProvider<int>(
  (_) => kHistoryPaginationInitialDays,
);

final diaperHistoryFirestoreDaysProvider = StateProvider<int>(
  (_) => kHistoryPaginationInitialDays,
);

final sleepHistoryFirestoreDaysProvider = StateProvider<int>(
  (_) => kHistoryPaginationInitialDays,
);

/// Ventana real del listener Firestore: al menos lo que pide el home, o más
/// si el historial ya expandió con scroll (un solo query por colección).
int feedingStreamCalendarDays(int firestoreDays) =>
    math.max(firestoreDays, kHomeFeedingStreamMinCalendarDays);

int diaperStreamCalendarDays(int firestoreDays) =>
    math.max(firestoreDays, kHomeDiaperStreamMinCalendarDays);

int sleepStreamCalendarDays(int firestoreDays) =>
    math.max(firestoreDays, kHomeSleepStreamMinCalendarDays);

/// Cuántas pesadas recientes se muestran en el historial de Peso (ampliable al hacer scroll).
final weightHistoryVisibleLimitProvider = StateProvider<int>(
  (_) => kWeightHistoryInitialVisible,
);

/// Cuántos registros recientes de crecimiento se muestran en el historial.
final growthHistoryVisibleLimitProvider = StateProvider<int>(
  (_) => kWeightHistoryInitialVisible,
);

/// Vuelve a 3 días de ventana (alimentación/pañales/sueño), reinicia el historial de peso a
/// [kWeightHistoryInitialVisible] pesadas, e invalida streams (p. ej. tras logout).
void resetRecordHistoryFirestoreDays(WidgetRef ref) {
  ref.read(feedingHistoryFirestoreDaysProvider.notifier).state =
      kHistoryPaginationInitialDays;
  ref.read(diaperHistoryFirestoreDaysProvider.notifier).state =
      kHistoryPaginationInitialDays;
  ref.read(sleepHistoryFirestoreDaysProvider.notifier).state =
      kHistoryPaginationInitialDays;
  ref.read(weightHistoryVisibleLimitProvider.notifier).state =
      kWeightHistoryInitialVisible;
  ref.read(growthHistoryVisibleLimitProvider.notifier).state =
      kWeightHistoryInitialVisible;
  ref.invalidate(hasOlderFeedingRecordsProvider);
  ref.invalidate(hasOlderDiaperRecordsProvider);
  ref.invalidate(hasOlderSleepRecordsProvider);
  ref.invalidate(weightRecordsForChartStreamProvider);
  ref.invalidate(heightRecordsStreamProvider);
  ref.invalidate(babyProfileProvider);
}

/// Primer snapshot del stream de peso (misma fuente que la pestaña Peso / gráfica).
Future<List<WeightRecord>> waitForWeightChartRecords(WidgetRef ref) {
  return ref.read(weightRecordsForChartStreamProvider.future);
}

// --- Streams acotados por fecha (menos lecturas que la colección completa) ---

/// Serie completa: gráfica, resumen (último peso / tendencia) y percentiles.
final weightRecordsForChartStreamProvider = StreamProvider<List<WeightRecord>>((
  ref,
) {
  return IsarService.watchAllWeightRecords();
});

final heightRecordsStreamProvider = StreamProvider<List<HeightRecord>>((ref) {
  return IsarService.watchAllHeightRecords();
});

final diaperRecordsStreamProvider = StreamProvider<List<DiaperRecord>>((ref) {
  final firestoreDays = ref.watch(diaperHistoryFirestoreDaysProvider);
  final start = historyWindowStartForDays(
    diaperStreamCalendarDays(firestoreDays),
  );
  return IsarService.watchDiaperRecordsSince(start);
});

final feedingRecordsStreamProvider = StreamProvider<List<FeedingRecord>>((ref) {
  final firestoreDays = ref.watch(feedingHistoryFirestoreDaysProvider);
  final start = historyWindowStartForDays(
    feedingStreamCalendarDays(firestoreDays),
  );
  return IsarService.watchFeedingRecordsSince(start);
});

final sleepRecordsStreamProvider = StreamProvider<List<SleepRecord>>((ref) {
  final firestoreDays = ref.watch(sleepHistoryFirestoreDaysProvider);
  final start = historyWindowStartForDays(
    sleepStreamCalendarDays(firestoreDays),
  );
  return IsarService.watchSleepRecordsSince(start);
});

// --- ¿Hay datos anteriores a la ventana visible del historial? (consulta barata limit 1) ---

final hasOlderFeedingRecordsProvider = FutureProvider<bool>((ref) async {
  final firestoreDays = ref.watch(feedingHistoryFirestoreDaysProvider);
  final streamDays = feedingStreamCalendarDays(firestoreDays);
  // Más días ya en el stream (home min) pero aún no visibles en el historial.
  if (firestoreDays < streamDays) return true;
  final start = historyWindowStartForDays(streamDays);
  return IsarService.hasFeedingRecordStrictlyBefore(start);
});

final hasOlderDiaperRecordsProvider = FutureProvider<bool>((ref) async {
  final firestoreDays = ref.watch(diaperHistoryFirestoreDaysProvider);
  final streamDays = diaperStreamCalendarDays(firestoreDays);
  if (firestoreDays < streamDays) return true;
  final start = historyWindowStartForDays(streamDays);
  return IsarService.hasDiaperRecordStrictlyBefore(start);
});

final hasOlderSleepRecordsProvider = FutureProvider<bool>((ref) async {
  final firestoreDays = ref.watch(sleepHistoryFirestoreDaysProvider);
  final streamDays = sleepStreamCalendarDays(firestoreDays);
  if (firestoreDays < streamDays) return true;
  final start = historyWindowStartForDays(streamDays);
  return IsarService.hasSleepRecordStrictlyBefore(start);
});
