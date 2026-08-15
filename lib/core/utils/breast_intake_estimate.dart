import 'dart:math' as math;

import '../models/enums.dart';
import '../models/feeding_record.dart';

/// Estimación de ingesta de pecho (ml) a partir de minutos de lactancia.
/// Misma curva de saturación que la tarjeta de tendencia en Home.
class BreastIntakeEstimate {
  BreastIntakeEstimate._();

  static const double asymptoteMl = 140;
  static const double saturationTauMinutes = 9;

  static double minutesToMl(double minutes) {
    if (minutes <= 0) return 0;
    return asymptoteMl *
        (1 - math.exp(-minutes / saturationTauMinutes));
  }

  static double fromRecord(FeedingRecord record) {
    if (record.type != FeedingType.leftBreast &&
        record.type != FeedingType.rightBreast) {
      return 0;
    }
    return minutesToMl((record.durationSeconds ?? 0) / 60.0);
  }
}
