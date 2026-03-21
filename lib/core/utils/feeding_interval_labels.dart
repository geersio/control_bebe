/// Intervalos sugeridos entre tomas (minutos) y etiquetas en español.
const List<int> kFeedingIntervalPresetMinutes = [
  60,
  90,
  120,
  150,
  180,
  210,
  240,
  300,
  360,
];

/// Valor por defecto si no hay dato guardado (3 h).
const int kDefaultFeedingIntervalMinutes = 180;

String feedingIntervalOptionLabel(int minutes) {
  if (minutes < 60) return '$minutes min';
  if (minutes % 60 == 0) {
    final h = minutes ~/ 60;
    return h == 1 ? '1 hora' : '$h horas';
  }
  final h = minutes ~/ 60;
  final min = minutes % 60;
  return '${h}h ${min}min';
}
