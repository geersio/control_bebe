/// Modelo de datos puro - sin dependencias de Isar.
class HeightRecord {
  final int? id;
  final double heightCm;
  final DateTime dateTime;

  /// true si el cambio está en cola local y aún no se ha confirmado en el servidor.
  final bool pendingRemoteSync;

  HeightRecord({
    this.id,
    required this.heightCm,
    required this.dateTime,
    this.pendingRemoteSync = false,
  });

  HeightRecord copyWith({
    int? id,
    double? heightCm,
    DateTime? dateTime,
    bool? pendingRemoteSync,
  }) => HeightRecord(
    id: id ?? this.id,
    heightCm: heightCm ?? this.heightCm,
    dateTime: dateTime ?? this.dateTime,
    pendingRemoteSync: pendingRemoteSync ?? this.pendingRemoteSync,
  );
}
