import '../../../l10n/app_localizations.dart';
import 'feeding_interval_for_age.dart';

/// Edad en resultados: meses (+ días si aplica); a partir de 24 meses, años
/// con precisión de medio año como máximo (sin días).
String onboardingResultAgeLabel(
  AppLocalizations l10n, {
  required int months,
  required int days,
}) {
  final m = months < 0 ? 0 : months;
  final d = days < 0 ? 0 : days;
  if (m == 0) {
    return d == 1
        ? l10n.onboardingFlowResultAgeOneDay
        : l10n.onboardingFlowResultAgeDays(d);
  }
  if (m > 24) {
    final years = m ~/ 12;
    final remainder = m % 12;
    if (remainder >= 6) {
      return years == 1
          ? l10n.onboardingFlowResultAgeOneYearHalf
          : l10n.onboardingFlowResultAgeYearsHalf(years);
    }
    return years == 1
        ? l10n.onboardingFlowResultAgeOneYear
        : l10n.onboardingFlowResultAgeYears(years);
  }
  if (d == 0) return l10n.onboardingFlowResultAgeMonths(m);
  return l10n.onboardingFlowResultAgeMonthsDays(m, d);
}

/// Textos de alimentación / sueño para la pantalla de resultados del onboarding.
class OnboardingAgeCareCopy {
  final String feedingTitle;
  final String feedingValue;
  final String feedingHint;
  final String sleepValue;
  final String sleepHint;

  const OnboardingAgeCareCopy({
    required this.feedingTitle,
    required this.feedingValue,
    required this.feedingHint,
    required this.sleepValue,
    required this.sleepHint,
  });
}

/// Orientación por tramos de edad (no aplica rangos de lactante a toddlers).
OnboardingAgeCareCopy onboardingAgeCareCopy({
  required AppLocalizations l10n,
  required double ageMonths,
  required bool isPregnant,
  required String wakeRange,
  required String dailySleepRange,
  required String intervalLabel,
}) {
  final sleepWake = l10n.onboardingFlowResultSleepWake(wakeRange);

  if (isPregnant) {
    return OnboardingAgeCareCopy(
      feedingTitle: l10n.onboardingFlowResultFeedingTitle,
      feedingValue: l10n.onboardingFlowResultFeedingValue(intervalLabel),
      feedingHint: l10n.onboardingFlowResultFeedingPregnantHint,
      sleepValue: sleepWake,
      sleepHint: l10n.onboardingFlowResultSleepPregnantHint,
    );
  }

  final sleepHint = l10n.onboardingFlowResultSleepTotal(dailySleepRange);

  if (ageMonths < 12) {
    return OnboardingAgeCareCopy(
      feedingTitle: l10n.onboardingFlowResultFeedingTitle,
      feedingValue: l10n.onboardingFlowResultFeedingValue(intervalLabel),
      feedingHint: l10n.onboardingFlowResultFeedingHint,
      sleepValue: sleepWake,
      sleepHint: sleepHint,
    );
  }

  if (ageMonths < 24) {
    return OnboardingAgeCareCopy(
      feedingTitle: l10n.onboardingFlowResultMealsTitle,
      feedingValue: l10n.onboardingFlowResultFeedingMealsTransition,
      feedingHint: usesTimedMilkFeedReminders(ageMonths)
          ? l10n.onboardingFlowResultFeedingMealsTransitionHint
          : l10n.onboardingFlowResultFeedingMealsToddlerHint,
      sleepValue: sleepWake,
      sleepHint: sleepHint,
    );
  }

  return OnboardingAgeCareCopy(
    feedingTitle: l10n.onboardingFlowResultMealsTitle,
    feedingValue: l10n.onboardingFlowResultFeedingMealsToddler,
    feedingHint: l10n.onboardingFlowResultFeedingMealsToddlerHint,
    sleepValue: sleepWake,
    sleepHint: sleepHint,
  );
}
