import 'diaper_spend_insight.dart';
import 'sleep_insight.dart';
import 'sleep_personal_stats.dart';
import 'sleep_usual_pattern.dart';

/// Lookback del trend de tomas desde hoy 00:00 (días hacia atrás).
const int kHomeFeedingTrendLookbackDays = 14;

/// Días de calendario del stream (incluye hoy) para cubrir ese lookback.
const int kHomeFeedingStreamMinCalendarDays =
    kHomeFeedingTrendLookbackDays + 1;

/// 7 días actuales + 7 anteriores del insight de pañales (incluye hoy).
const int kHomeDiaperStreamMinCalendarDays = kDiaperSpendWindowDays * 2;

/// Lookback de sueño del home (aprendizaje personal vs patrón habitual vs barras).
int get kHomeSleepLookbackDays {
  final candidates = [
    kSleepPersonalLookbackDays,
    kSleepInsightUsualDays,
    kSleepUsualPatternHistoryDays,
  ];
  return candidates.reduce((a, b) => a > b ? a : b);
}

/// Días de calendario del stream de sueño (incluye hoy).
int get kHomeSleepStreamMinCalendarDays => kHomeSleepLookbackDays + 1;
