/// Formatea minutos a texto legible: "45 min" o "1h 40 min" si >= 60.
String formatMinutes(int totalMinutes) {
  if (totalMinutes < 60) return '$totalMinutes min';
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (m == 0) return '${h}h';
  return '${h}h ${m} min';
}

/// Formatea segundos a texto con horas si >= 3600: "1h 40m 30s" o "90m 30s".
String formatDurationSeconds(int totalSeconds) {
  if (totalSeconds < 3600) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m}m ${s}s';
  }
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  if (s == 0 && m == 0) return '${h}h';
  if (s == 0) return '${h}h ${m}m';
  return '${h}h ${m}m ${s}s';
}
