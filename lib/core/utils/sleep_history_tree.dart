import '../models/enums.dart';
import '../models/sleep_record.dart';

DateTime _civilDayKey(SleepRecord r) {
  final d = r.endDateTime ?? r.startDateTime;
  return DateTime(d.year, d.month, d.day);
}

/// Clave estable para mapear un registro (id o inicio+tipo si aún no hay id).
Object sleepRecordIdentity(SleepRecord r) =>
    r.id ??
    's${r.startDateTime.millisecondsSinceEpoch}_${r.type.index}';

/// Número de siesta del día civil (1 = primera), ordenado por inicio.
///
/// El día usa fin ?? inicio (igual que el agrupado del historial). Incluye
/// sesiones abiertas para que el número no salte al cerrarlas.
Map<Object, int> napNumbersByDay(List<SleepRecord> records) {
  final byDay = <DateTime, List<SleepRecord>>{};
  for (final r in records) {
    if (r.type != SleepType.nap) continue;
    byDay.putIfAbsent(_civilDayKey(r), () => []).add(r);
  }

  final result = <Object, int>{};
  for (final naps in byDay.values) {
    naps.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    for (var i = 0; i < naps.length; i++) {
      result[sleepRecordIdentity(naps[i])] = i + 1;
    }
  }
  return result;
}

/// Agrupa sueños (bloques) con sus despertares nocturnos hijos.
class SleepHistoryEntry {
  final SleepRecord sleep;
  final List<SleepRecord> wakings;

  const SleepHistoryEntry({
    required this.sleep,
    this.wakings = const [],
  });

  int get wakingCount => wakings.length;

  int get wakingMinutes {
    var secs = 0;
    for (final w in wakings) {
      secs += w.durationSeconds();
    }
    return (secs / 60).round();
  }
}

/// Encuentra el sueño padre de un intervalo de despertar (por id o solape temporal).
SleepRecord? findParentSleepForWaking({
  required List<SleepRecord> records,
  required DateTime start,
  required DateTime end,
}) {
  final blocks = records.where((r) => r.isSleepBlock).toList();
  final containing = blocks.where((r) {
    if (start.isBefore(r.startDateTime)) return false;
    if (r.isOpen) return !start.isBefore(r.startDateTime);
    final sleepEnd = r.endDateTime!;
    return !end.isAfter(sleepEnd);
  }).toList();

  if (containing.isEmpty) return null;

  containing.sort((a, b) {
    // Preferir sesión abierta, luego inicio más reciente.
    if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
    return b.startDateTime.compareTo(a.startDateTime);
  });
  return containing.first;
}

bool _wakingBelongsTo(SleepRecord sleep, SleepRecord waking) {
  if (!waking.isNightWaking) return false;
  if (sleep.id != null && waking.parentSleepId == sleep.id) return true;
  if (waking.parentSleepId != null) return false;
  final wEnd = waking.endDateTime;
  if (wEnd == null) return false;
  if (waking.startDateTime.isBefore(sleep.startDateTime)) return false;
  if (sleep.isOpen) return true;
  return !wEnd.isAfter(sleep.endDateTime!);
}

/// Construye entradas de historial: bloques con hijos + despertares huérfanos.
///
/// Por defecto omite sesiones abiertas (aún durmiendo); solo aparecen al
/// cerrarlas. Usa [includeOpen] en la barra del día / predicción en vivo.
List<SleepHistoryEntry> buildSleepHistoryEntries(
  List<SleepRecord> records, {
  bool includeOpen = false,
}) {
  final wakings = records.where((r) => r.isNightWaking).toList();
  final openBlocks = records.where((r) => r.isSleepBlock && r.isOpen).toList();
  final blocks =
      (includeOpen
              ? records.where((r) => r.isSleepBlock)
              : records.where((r) => r.isSleepBlock && !r.isOpen))
          .toList()
        ..sort((a, b) => b.sortAt.compareTo(a.sortAt));

  final claimed = <SleepRecord>{};
  final entries = <SleepHistoryEntry>[];

  for (final sleep in blocks) {
    final children = wakings.where((w) => _wakingBelongsTo(sleep, w)).toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    claimed.addAll(children);
    entries.add(SleepHistoryEntry(sleep: sleep, wakings: children));
  }

  final orphans = wakings.where((w) {
    if (claimed.contains(w)) return false;
    if (!includeOpen &&
        openBlocks.any((s) => _wakingBelongsTo(s, w))) {
      return false;
    }
    return true;
  }).toList()
    ..sort((a, b) => b.sortAt.compareTo(a.sortAt));
  for (final w in orphans) {
    entries.add(SleepHistoryEntry(sleep: w, wakings: const []));
  }

  entries.sort((a, b) => b.sleep.sortAt.compareTo(a.sleep.sortAt));
  return entries;
}

/// Sesión de sueño abierta más reciente, si existe.
SleepRecord? findOpenSleepSession(List<SleepRecord> records) {
  final open = records.where((r) => r.isOpen).toList()
    ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
  return open.isEmpty ? null : open.first;
}
