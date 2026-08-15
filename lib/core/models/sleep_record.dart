import 'enums.dart';

/// Sentinel ISO en Firestore para sesiones abiertas (permite query por endDateTime).
const String kSleepOpenEndSentinelIso = '9999-12-31T00:00:00.000';

final DateTime kSleepOpenEndSentinel = DateTime(9999, 12, 31);

const Object _unset = Object();

/// Modelo de datos puro - sin dependencias de Isar.
class SleepRecord {
  final int? id;

  /// Hora de acostarse / inicio del sueño (o del despertar nocturno).
  final DateTime startDateTime;

  /// Fin del sueño / despertar. `null` = sesión abierta (aún durmiendo).
  final DateTime? endDateTime;

  /// Sueño nocturno, siesta o despertar nocturno.
  final SleepType type;

  /// Sueño padre de un [SleepType.nightWaking]; `null` si es independiente.
  final int? parentSleepId;

  /// true si el cambio está en cola local y aún no se ha confirmado en el servidor.
  final bool pendingRemoteSync;

  SleepRecord({
    this.id,
    required this.startDateTime,
    this.endDateTime,
    this.type = SleepType.night,
    this.parentSleepId,
    this.pendingRemoteSync = false,
  });

  bool get isOpen => endDateTime == null && type != SleepType.nightWaking;

  bool get isNightWaking => type == SleepType.nightWaking;

  bool get isSleepBlock =>
      type == SleepType.night || type == SleepType.nap;

  /// Clave de ordenación: abiertas arriba; resto por fin.
  DateTime get sortAt => endDateTime ?? kSleepOpenEndSentinel;

  /// Duración cerrada; si está abierta, segundos hasta [now].
  int durationSeconds([DateTime? now]) {
    final end = endDateTime ?? (now ?? DateTime.now());
    final s = end.difference(startDateTime).inSeconds;
    return s < 0 ? 0 : s;
  }

  SleepRecord copyWith({
    int? id,
    DateTime? startDateTime,
    Object? endDateTime = _unset,
    SleepType? type,
    Object? parentSleepId = _unset,
    bool? pendingRemoteSync,
  }) => SleepRecord(
    id: id ?? this.id,
    startDateTime: startDateTime ?? this.startDateTime,
    endDateTime: identical(endDateTime, _unset)
        ? this.endDateTime
        : endDateTime as DateTime?,
    type: type ?? this.type,
    parentSleepId: identical(parentSleepId, _unset)
        ? this.parentSleepId
        : parentSleepId as int?,
    pendingRemoteSync: pendingRemoteSync ?? this.pendingRemoteSync,
  );
}
