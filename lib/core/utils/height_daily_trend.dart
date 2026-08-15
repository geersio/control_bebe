import '../models/height_record.dart';

double? _linearRegressionCmPerDay(List<HeightRecord> records) {
  if (records.length < 2) return null;

  final sorted = List<HeightRecord>.from(records)
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  final origin = sorted.first.dateTime;
  final xs = <double>[];
  final ys = <double>[];
  for (final r in sorted) {
    final days =
        r.dateTime.difference(origin).inMilliseconds /
        Duration.millisecondsPerDay.toDouble();
    xs.add(days);
    ys.add(r.heightCm);
  }

  final n = xs.length;
  var sumX = 0.0;
  var sumY = 0.0;
  for (var i = 0; i < n; i++) {
    sumX += xs[i];
    sumY += ys[i];
  }
  final meanX = sumX / n;
  final meanY = sumY / n;

  var sxx = 0.0;
  var sxy = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = xs[i] - meanX;
    final dy = ys[i] - meanY;
    sxx += dx * dx;
    sxy += dx * dy;
  }
  if (sxx <= 1e-18) return null;

  return sxy / sxx;
}

/// Pendiente de regresión lineal talla (cm) vs tiempo (días), misma lógica
/// que [dailyWeightTrendLinearRegressionGramsPerDay] (ventana 7 días por defecto).
///
/// Devuelve cm/día, o `null` si no hay al menos 2 puntos con tiempo distinto.
double? dailyHeightTrendLinearRegressionCmPerDay(
  List<HeightRecord> records, {
  DateTime? now,
  Duration window = const Duration(days: 7),
}) {
  final clock = now ?? DateTime.now();
  final cutoff = clock.subtract(window);
  final eligibleRecords =
      records.where((r) => !r.dateTime.isAfter(clock)).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  final inWindow = eligibleRecords
      .where((r) => !r.dateTime.isBefore(cutoff))
      .toList();
  final currentTrend = _linearRegressionCmPerDay(inWindow);
  if (currentTrend != null) return currentTrend;

  if (inWindow.isNotEmpty) {
    final latest = inWindow.last;
    final latestIndex = eligibleRecords.lastIndexWhere(
      (r) => r.dateTime.isAtSameMomentAs(latest.dateTime),
    );
    if (latestIndex > 0) {
      final trendWithPrevious = _linearRegressionCmPerDay([
        eligibleRecords[latestIndex - 1],
        latest,
      ]);
      if (trendWithPrevious != null) return trendWithPrevious;
    }
  }

  final orderedAnchors = eligibleRecords.map((r) => r.dateTime).toSet().toList()
    ..sort((a, b) => b.compareTo(a));

  for (final anchor in orderedAnchors) {
    final anchorCutoff = anchor.subtract(window);
    final historicalWindow = records
        .where(
          (r) =>
              !r.dateTime.isAfter(anchor) && !r.dateTime.isBefore(anchorCutoff),
        )
        .toList();
    final historicalTrend = _linearRegressionCmPerDay(historicalWindow);
    if (historicalTrend != null) return historicalTrend;
  }

  return null;
}
