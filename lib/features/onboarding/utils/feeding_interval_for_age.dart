import '../../../core/utils/feeding_interval_labels.dart';

/// Intervalo habitual entre tomas de leche (minutos) según edad en meses.
///
/// Solo tiene sentido como “cada X horas” en lactantes. A partir de ~18 meses
/// el ritmo pasa a comidas/tentempiés; el valor se usa como preset suave.
int feedingIntervalMinutesForAgeMonths(double ageInMonths) {
  if (ageInMonths < 0) {
    // Embarazo / fecha futura: preparar ritmo de recién nacido.
    return 150;
  }
  if (ageInMonths < 1) return 150; // ~2,5 h (recién nacido: 2–3 h)
  if (ageInMonths < 3) return 180; // 3 h
  if (ageInMonths < 6) return 210; // 3,5 h
  if (ageInMonths < 12) return 240; // 4 h
  if (ageInMonths < 18) return 300; // 5 h (transición)
  return 360; // preset residual; la UI ya no lo presenta como “cada 6 h”
}

/// True mientras tenga sentido hablar de tomas de leche a intervalos fijos.
bool usesTimedMilkFeedReminders(double ageInMonths) {
  return ageInMonths < 18;
}

/// Elige el preset más cercano de [kFeedingIntervalPresetMinutes].
int feedingIntervalPresetForAgeMonths(double ageInMonths) {
  final target = feedingIntervalMinutesForAgeMonths(ageInMonths);
  var best = kDefaultFeedingIntervalMinutes;
  var bestDelta = 1 << 30;
  for (final m in kFeedingIntervalPresetMinutes) {
    final d = (m - target).abs();
    if (d < bestDelta) {
      bestDelta = d;
      best = m;
    }
  }
  return best;
}
