import '../models/weight_record.dart';

double? _linearRegressionGramsPerDay(List<WeightRecord> records) {
  if (records.length < 2) return null;

  final sorted = List<WeightRecord>.from(records)
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  final origin = sorted.first.dateTime;
  final xs = <double>[];
  final ys = <double>[];
  for (final r in sorted) {
    final days =
        r.dateTime.difference(origin).inMilliseconds /
        Duration.millisecondsPerDay.toDouble();
    xs.add(days);
    ys.add(r.weightKg);
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

  final slopeKgPerDay = sxy / sxx;
  return slopeKgPerDay * 1000.0;
}

/// Pendiente de una regresión lineal simple peso (kg) vs tiempo (días),
/// con los registros cuya fecha cae en la ventana de [window] hasta [now].
///
/// Si la ventana actual tiene una sola pesada, la compara con la pesada anterior
/// más cercana aunque sea más antigua que [window]. Si no hay pesadas recientes,
/// devuelve la última tendencia que se pudo calcular con una ventana equivalente
/// del histórico.
///
/// Devuelve gramos por día, o `null` si nunca hubo al menos 2 puntos con tiempo distinto.
double? dailyWeightTrendLinearRegressionGramsPerDay(
  List<WeightRecord> records, {
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
  final currentTrend = _linearRegressionGramsPerDay(inWindow);
  if (currentTrend != null) return currentTrend;

  if (inWindow.isNotEmpty) {
    final latest = inWindow.last;
    final latestIndex = eligibleRecords.lastIndexWhere(
      (r) => r.dateTime.isAtSameMomentAs(latest.dateTime),
    );
    if (latestIndex > 0) {
      final trendWithPrevious = _linearRegressionGramsPerDay([
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
    final historicalTrend = _linearRegressionGramsPerDay(historicalWindow);
    if (historicalTrend != null) return historicalTrend;
  }

  return null;
}
