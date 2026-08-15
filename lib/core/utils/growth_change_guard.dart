/// Avisos suaves si una nueva medida se aleja demasiado de la anterior
/// en poco tiempo (típico de un error de tecleo: 4,5 → 45).

/// Ventana máxima para el aviso de peso: más allá el bebé puede haber
/// cambiado de verdad.
const Duration kWeightSuddenChangeWindow = Duration(days: 14);

/// Ventana máxima para el aviso de altura.
const Duration kHeightSuddenChangeWindow = Duration(days: 21);

/// Ruido de báscula + margen (gramos) aunque la pesada sea inmediata.
const double kWeightSuddenChangeBaseGrams = 180;

/// Ganancia/pérdida plausible máxima (g/día) para no avisar.
const double kWeightSuddenChangeGramsPerDay = 90;

/// Error de medición de talla (cm) aunque sea el mismo día.
const double kHeightSuddenChangeBaseCm = 1.2;

/// Crecimiento plausible máximo (cm/día) para no avisar.
const double kHeightSuddenChangeCmPerDay = 0.25;

double _elapsedDays(DateTime previousAt, DateTime now, Duration window) {
  final elapsed = now.difference(previousAt);
  if (elapsed.isNegative || elapsed > window) return -1;
  // Mismo día: no dejar el umbral en ~0 g/cm.
  return (elapsed.inMinutes / (60 * 24)).clamp(0.25, window.inDays.toDouble());
}

/// `true` si el nuevo peso se desvía mucho del anterior y ha pasado poco.
bool isSuddenWeightChange({
  required double previousKg,
  required DateTime previousAt,
  required double nextKg,
  DateTime? now,
}) {
  final days = _elapsedDays(
    previousAt,
    now ?? DateTime.now(),
    kWeightSuddenChangeWindow,
  );
  if (days < 0) return false;
  final deltaGrams = (nextKg - previousKg).abs() * 1000;
  final maxGrams =
      kWeightSuddenChangeBaseGrams + kWeightSuddenChangeGramsPerDay * days;
  return deltaGrams > maxGrams;
}

/// `true` si la nueva talla se desvía mucho de la anterior y ha pasado poco.
bool isSuddenHeightChange({
  required double previousCm,
  required DateTime previousAt,
  required double nextCm,
  DateTime? now,
}) {
  final days = _elapsedDays(
    previousAt,
    now ?? DateTime.now(),
    kHeightSuddenChangeWindow,
  );
  if (days < 0) return false;
  final deltaCm = (nextCm - previousCm).abs();
  final maxCm = kHeightSuddenChangeBaseCm + kHeightSuddenChangeCmPerDay * days;
  return deltaCm > maxCm;
}
