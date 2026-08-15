import 'dart:math' as math;

import '../models/enums.dart';
import '../models/feeding_record.dart';

/// Asíntota de ml estimados por toma de pecho (misma curva que el home).
const double kBreastFeedAsymptoteMl = 140;

/// Tau de saturación (minutos) de la curva pecho → ml.
const double kBreastFeedSaturationTauMinutes = 9;

/// Convierte minutos de pecho en ml orientativos.
double breastMinutesToEstimatedMl(double minutes) {
  if (minutes <= 0) return 0;
  return kBreastFeedAsymptoteMl *
      (1 - math.exp(-minutes / kBreastFeedSaturationTauMinutes));
}

/// Ml contables de un registro (biberón real; pecho estimado; sólidos = 0).
double estimatedFeedingMl(FeedingRecord record) {
  switch (record.type) {
    case FeedingType.bottle:
      return (record.amountMl ?? 0).toDouble();
    case FeedingType.leftBreast:
    case FeedingType.rightBreast:
      final minutes = (record.durationSeconds ?? 0) / 60.0;
      return breastMinutesToEstimatedMl(minutes);
    case FeedingType.solidFood:
      return 0;
  }
}

/// Suma ml del día (biberón + pecho estimado).
double sumEstimatedFeedingMl(Iterable<FeedingRecord> records) {
  var total = 0.0;
  for (final r in records) {
    total += estimatedFeedingMl(r);
  }
  return total;
}
