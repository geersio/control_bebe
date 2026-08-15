// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MiBebé';

  @override
  String get navHome => 'HOME';

  @override
  String get navDiapers => 'DIAPERS';

  @override
  String get navFeeding => 'FEEDING';

  @override
  String get navSleep => 'SLEEP';

  @override
  String get navWeight => 'GROWTH';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaved => 'Saved';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonDelete => 'Delete';

  @override
  String get deleteRecordConfirmTitle => 'Delete this entry?';

  @override
  String get deleteRecordConfirmBody =>
      'It will be permanently removed. This can’t be undone.';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDate => 'Date';

  @override
  String get commonTime => 'Time';

  @override
  String get commonDateTime => 'Date & time';

  @override
  String get commonTimeStart => 'Start time';

  @override
  String get commonTimeEnd => 'End time';

  @override
  String get commonGenderBoy => 'Boy';

  @override
  String get commonGenderGirl => 'Girl';

  @override
  String get commonGenderUnspecified => 'Prefer not to say';

  @override
  String get commonSend => 'Send';

  @override
  String get commonNext => 'Next';

  @override
  String get commonExit => 'Exit';

  @override
  String get historyTitle => 'History';

  @override
  String get historyScrollLoadMore =>
      'Scroll to the bottom to load three more days of history.';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get timeSuffixMinute => 'min';

  @override
  String get timeSuffixHour => 'h';

  @override
  String get timeSuffixSecond => 's';

  @override
  String timeHoursOnly(Object h) {
    return '${h}h';
  }

  @override
  String timeHoursMinutes(Object h, Object m) {
    return '${h}h $m min';
  }

  @override
  String timeMinutesOnly(Object m) {
    return '$m min';
  }

  @override
  String durationMinutesSeconds(Object m, Object s) {
    return '${m}m ${s}s';
  }

  @override
  String durationHoursMinutes(Object h, Object m) {
    return '${h}h ${m}m';
  }

  @override
  String durationHoursMinutesSeconds(Object h, Object m, Object s) {
    return '${h}h ${m}m ${s}s';
  }

  @override
  String durationHoursOnly(Object h) {
    return '${h}h';
  }

  @override
  String get feedingIntervalHoursOne => '1 hour';

  @override
  String feedingIntervalHoursN(Object n) {
    return '$n hours';
  }

  @override
  String feedingIntervalHoursMinutes(Object h, Object m) {
    return '${h}h ${m}min';
  }

  @override
  String get profileDefaultBabyName => 'Baby';

  @override
  String get sleepTitle => 'Sleep';

  @override
  String get sleepBedtime => 'Falls asleep';

  @override
  String get sleepWake => 'Wakes up';

  @override
  String get sleepNightWakingsSection => 'Night wakings';

  @override
  String get sleepClockModeStart => 'Sleep start';

  @override
  String get sleepClockModeEnd => 'Sleep end';

  @override
  String get sleepClockModeNightWaking => 'Night waking';

  @override
  String get sleepClockCenterStartLabel => 'Start time';

  @override
  String get sleepClockCenterEndLabel => 'End time';

  @override
  String get sleepClockCenterNightWakingLabel => 'Waking duration';

  @override
  String sleepDurationCenterMinutesOnly(Object m) {
    return '$m MIN';
  }

  @override
  String get sleepTypeNight => 'Night sleep';

  @override
  String get sleepTypeNap => 'Nap';

  @override
  String sleepTypeNapNumbered(int number) {
    return 'Nap $number';
  }

  @override
  String get sleepRegisterButton => 'Save sleep';

  @override
  String get sleepRegisterStartButton => 'Save start';

  @override
  String get sleepRegisterEndButton => 'Save end';

  @override
  String get sleepRegisterNightWakingButton => 'Save waking';

  @override
  String get sleepEndPending => 'pending';

  @override
  String get sleepKeepOpenLabel => 'Still sleeping';

  @override
  String get sleepNightWakingLabel => 'Night waking';

  @override
  String sleepWakingsSummary(Object count, Object minutes) {
    return '$count wakings · $minutes min awake';
  }

  @override
  String sleepWakingsSummaryOne(Object minutes) {
    return '1 waking · $minutes min awake';
  }

  @override
  String get sleepNoOpenSessionToEnd =>
      'No sleep in progress. Save the start first.';

  @override
  String get sleepOpenSessionExists =>
      'A sleep is already in progress. Save the end or edit it in history.';

  @override
  String get homeSleepInsightSleepingLabel => 'Sleeping...';

  @override
  String homeSleepInsightSleepingSince(Object time) {
    return 'since $time';
  }

  @override
  String homeSleepInsightSleepingValue(Object duration, Object time) {
    return '$duration · since $time';
  }

  @override
  String get sleepStatusAwake => 'Awake';

  @override
  String get sleepStatusSleeping => 'Sleeping';

  @override
  String get sleepActionFellAsleep => 'Fell asleep';

  @override
  String get sleepActionWokeUp => 'Woke up';

  @override
  String sleepFellAsleepAt(Object time) {
    return 'Fell asleep at $time';
  }

  @override
  String sleepWokeUpAt(Object time) {
    return 'Woke up at $time';
  }

  @override
  String sleepSavesWithCurrentTime(Object time) {
    return 'saves with the current time · $time';
  }

  @override
  String get sleepAddNightWaking => 'Add night waking';

  @override
  String get sleepRegisterPastSleep => 'Add previous sleep';

  @override
  String get sleepFellAsleepCaps => 'FELL ASLEEP';

  @override
  String get sleepWokeUpCaps => 'WOKE UP';

  @override
  String get sleepSleptPrefix => 'Slept';

  @override
  String get sleepAwakePrefix => 'Awake';

  @override
  String get sleepPastRegister => 'Save';

  @override
  String get sleepHistoryEmpty =>
      'No entries yet. Tap “Fell asleep” above to add the first one.';

  @override
  String get sleepStreamError =>
      'Could not load sleep records. Retry or check your connection.';

  @override
  String get sleepEditRecord => 'Edit sleep';

  @override
  String get sleepSessionCountOne => '1 sleep';

  @override
  String sleepSessionCountN(Object n) {
    return '$n sleeps';
  }

  @override
  String sleepDurationCenter(Object h, Object m) {
    return '$h HR $m MIN';
  }

  @override
  String sleepDurationCenterHoursOnly(Object h) {
    return '$h HR';
  }

  @override
  String get profileWeightLabel => 'WEIGHT';

  @override
  String get profileHeightLabel => 'HEIGHT';

  @override
  String get babyAgeMonthsOneDaysOne => '1 MONTH, 1 DAY';

  @override
  String babyAgeMonthsOneDaysN(Object days) {
    return '1 MONTH, $days DAYS';
  }

  @override
  String babyAgeMonthsNDaysOne(Object months) {
    return '$months MONTHS, 1 DAY';
  }

  @override
  String babyAgeMonthsNDaysN(Object days, Object months) {
    return '$months MONTHS, $days DAYS';
  }

  @override
  String get monthiversaryOne => 'Today turns 1 month old!';

  @override
  String monthiversaryN(Object months) {
    return 'Today turns $months months old!';
  }

  @override
  String get monthiversarySemanticsHint =>
      'Tap for confetti; up to twice until it finishes';

  @override
  String get homeSummaryTitle => 'Today\'s summary';

  @override
  String get homeLastFeedLabel => 'LAST FEED';

  @override
  String homeLastFeedAgo(Object time) {
    return '$time ago';
  }

  @override
  String get homeNextFeedSoon => 'Next feed soon';

  @override
  String homeNextFeedIn(Object time) {
    return 'Next feed in $time';
  }

  @override
  String get homeNoFeedingsYet =>
      'No feeds logged yet. Tap to add the first one.';

  @override
  String get homeWeightNoRecords =>
      'No weight entries. Tap to add the first one.';

  @override
  String homeWeightTrendGramsPerDay(Object sign, Object value) {
    return '$sign$value g/day';
  }

  @override
  String homeWeightTrendOuncesPerDay(Object sign, Object value) {
    return '$sign$value oz/day';
  }

  @override
  String homeHeightTrendCmPerDay(Object sign, Object value) {
    return '$sign$value cm/day';
  }

  @override
  String homeWeightLast(Object date) {
    return 'Last: $date';
  }

  @override
  String homeSleepPattern(int nights, int naps) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights nights',
      one: '1 night',
      zero: '0 nights',
    );
    String _temp1 = intl.Intl.pluralLogic(
      naps,
      locale: localeName,
      other: '$naps naps',
      one: '1 nap',
      zero: '0 naps',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get homeDiapersNoRecords =>
      'No diaper changes. Tap to add the first one.';

  @override
  String homeDiapersWetDirty(Object dirty, Object wet) {
    return '$wet wet · $dirty dirty';
  }

  @override
  String get homeDiaperChangesOne => '1 change';

  @override
  String homeDiaperChangesN(Object n) {
    return '$n changes';
  }

  @override
  String get homeInsightsTitle => 'Insights';

  @override
  String get homeFeedingDistributionTitle => 'Feed distribution';

  @override
  String get homeFeedingDistributionSevenDayAverage => '≈ Last 7 days average';

  @override
  String get homeFeedingDistributionInfoTitle =>
      'How feed distribution is calculated';

  @override
  String get homeFeedingDistributionInfoBody =>
      'The chart shows the average proportion of breast, bottle, and solid feeds recorded over the last 7 days.\n\nTo compare feed types, breastfeeding minutes are converted into an approximate ml equivalent. This conversion is only a guide and does not represent an exact measurement of milk intake.';

  @override
  String get homeFeedingDistributionMlPerDay => 'ml/day';

  @override
  String get homeDiaperSpendInsightTitle => 'Diapers and spend';

  @override
  String get homeDiaperSpendInsightDiapersPerDay => 'diapers / day';

  @override
  String homeDiaperSpendInsightWeekDelta(String delta) {
    return '$delta vs last week';
  }

  @override
  String get homeDiaperSpendInsightMoreBadge => 'More than last week';

  @override
  String get homeDiaperSpendInsightLessBadge => 'Less than last week';

  @override
  String get homeDiaperSpendInsightSameBadge => 'Same as last week';

  @override
  String get homeDiaperSpendInsightPerDay => 'Per day';

  @override
  String get homeDiaperSpendInsightPerMonth => 'Per month';

  @override
  String homeDiaperSpendInsightMore(
    String name,
    String average,
    String cost,
    String monthlyCost,
  ) {
    return '$name is using an average of $average diapers per day. More than last week. That is approximately $cost per day and $monthlyCost per month.';
  }

  @override
  String homeDiaperSpendInsightLess(
    String name,
    String average,
    String cost,
    String monthlyCost,
  ) {
    return '$name is using an average of $average diapers per day. Less than last week. That is approximately $cost per day and $monthlyCost per month.';
  }

  @override
  String homeDiaperSpendInsightSame(
    String name,
    String average,
    String cost,
    String monthlyCost,
  ) {
    return '$name is using an average of $average diapers per day. Same as last week. That is approximately $cost per day and $monthlyCost per month.';
  }

  @override
  String get homeDiaperSpendInsightNoData =>
      'Log diapers for a few days to see the average and estimated daily cost.';

  @override
  String get homeDiaperSpendInsightAddFirst => 'Add your baby\'s first diaper';

  @override
  String get homeDiaperSpendInsightInfoTitle => 'Approximate calculation';

  @override
  String homeDiaperSpendInsightInfoBody(String price) {
    return 'Spend is estimated using an average price of $price per diaper. Diapers/day is the mean over the last 7 calendar days (total changes ÷ 7). The label shows the difference from the mean of the previous 7 days. Monthly spend projects that average over 30 days.';
  }

  @override
  String get homeSleepInsightTitle => 'Sleep analysis';

  @override
  String get homeTodaysSleepTitle => 'Today\'s sleep';

  @override
  String get homeSleepInsightNextSleepLabel => 'Next sleep time';

  @override
  String get homeSleepInsightAddFirstSleep => 'Add your baby\'s first sleep';

  @override
  String get homeSleepInsightBedtimeLabel => 'Next bedtime';

  @override
  String homeSleepInsightNextSleepRelative(String duration) {
    return 'In $duration';
  }

  @override
  String homeSleepInsightNextSleepRelativePast(String duration) {
    return '$duration ago';
  }

  @override
  String homeSleepInsightNextSleepValue(String relative, String window) {
    return '$relative · $window';
  }

  @override
  String homeSleepInsightEstimatedWindow(String window) {
    return 'Estimated window · $window';
  }

  @override
  String homeSleepInsightReasonShortNap(int minutes) {
    return 'Window shortened by $minutes min after a short previous nap';
  }

  @override
  String get homeSleepInsightReasonBedtime =>
      'This window is for nighttime bedtime';

  @override
  String get homeSleepInsightReasonCatnap =>
      'Bridge nap: daytime nap windows used up';

  @override
  String get homeSleepInsightReasonEarlyBedtime =>
      'Early bedtime: daytime nap windows used up';

  @override
  String homeSleepInsightReasonDefaultWake(String time) {
    return 'No records today: assuming a $time wake-up';
  }

  @override
  String homeSleepInsightUsualAwakeBeforeNap(String name, String duration) {
    return '$name usually stays awake $duration before this nap.';
  }

  @override
  String homeSleepInsightUsualAwakeBeforeBedtime(String name, String duration) {
    return '$name usually stays awake $duration before bedtime.';
  }

  @override
  String homeSleepInsightAwakeNow(String duration) {
    return 'Right now awake for $duration.';
  }

  @override
  String get homeSleepInsightPersonalizedHint => 'Tuned to your baby’s rhythm';

  @override
  String get homeSleepInsightNoBirthDate =>
      'Add the birth date in Settings to estimate the next sleep.';

  @override
  String get homeSleepInsightTodaySoFar => 'so far today';

  @override
  String get homeSleepInsightUsuallySleeps => 'Daily sleep average';

  @override
  String get homeSleepInsightLast7Days => 'LAST 7 DAYS';

  @override
  String get homeSleepInsightAveragePrefix => 'avg';

  @override
  String get homeSleepInsightChartToday => 'today';

  @override
  String get homeSleepInsightDayTimelineToday => 'Today';

  @override
  String homeSleepInsightDayTimelineTotal(String duration) {
    return '$duration total';
  }

  @override
  String get homeSleepInsightBarNoData => 'No sleep logged';

  @override
  String get homeSleepSlotMorningNap => 'Morning nap';

  @override
  String get homeSleepSlotMiddayNap => 'Midday nap';

  @override
  String get homeSleepSlotAfternoonNap => 'Afternoon nap';

  @override
  String get homeSleepSlotCatnap => 'Catnap';

  @override
  String get homeSleepSlotNightSleep => 'Night sleep';

  @override
  String get homeSleepDurationLabel => 'Duration';

  @override
  String get homeSleepPatternHeaderLast14 => 'Usual schedule (last 14 days)';

  @override
  String homeSleepSlotFrequencyCount(int count, int total) {
    return '$count of $total';
  }

  @override
  String get homeSleepPhraseWaiting => 'Not enough data yet';

  @override
  String homeSleepPhraseFreqWithTime(int days, int total, String time) {
    return '$days of the last $total days, around $time';
  }

  @override
  String homeSleepPhraseFreqOnly(int days, int total) {
    return 'Only $days of the last $total days';
  }

  @override
  String homeSleepPhraseFreqPill(int days, int total) {
    return 'Only $days of the last $total days';
  }

  @override
  String get homeSleepPhraseTrendFewerDays =>
      'Happens on fewer days than last week';

  @override
  String homeSleepPhraseTrendStartsLater(int minutes) {
    return 'Starts about $minutes min later than last week';
  }

  @override
  String get homeSleepPhraseTrendShorter => 'Lasts less than last week';

  @override
  String homeSleepPhraseAlmostAlways(String time) {
    return 'Almost always around $time';
  }

  @override
  String homeSleepPhraseUsuallyBetween(String start, String end) {
    return 'Usually starts between $start and $end';
  }

  @override
  String homeSleepPhraseMayBetween(String start, String end) {
    return 'May start between $start and $end';
  }

  @override
  String homeSleepAbandonedNap(String name) {
    return '$name dropped this nap about two weeks ago';
  }

  @override
  String get homeSleepInsightNoData =>
      'Log sleep for a few days to see the analysis.';

  @override
  String get homeSleepInsightInfoTitle => 'About this analysis';

  @override
  String get homeSleepInsightInfoIntro =>
      'An approximate estimate—not an exact time or medical advice.';

  @override
  String get homeSleepInsightInfoPredictTitle => 'Next sleep';

  @override
  String get homeSleepInsightInfoPredictBody =>
      'It starts from the last wake (end of a nap or night sleep) and adds a wake window based on age and recent history. The time range reflects that variability.\n\nIf a sleep is in progress, you’ll see “Sleeping...” instead of a prediction.';

  @override
  String get homeSleepInsightInfoLoggingTitle => 'How to log';

  @override
  String get homeSleepInsightInfoLoggingBody =>
      'Mark sleep start and end. Nap vs night sleep is detected automatically.\n\nIf they wake overnight and settle back to sleep, use “Night waking” (not another nap).';

  @override
  String get homeSleepInsightInfoMetricsTitle => 'Totals';

  @override
  String get homeSleepInsightInfoMetricsBody =>
      '“Last 7 days” averages only days with logs (a day with no data is left out, not treated as 0). Today’s bar is striped.';

  @override
  String get homeSleepInsightInfoScheduleTitle => 'Usual schedule';

  @override
  String get homeSleepInsightInfoScheduleBody =>
      'Times for each nap and night sleep are the median over the last 14 days, rounded to 5-minute steps.\n\nThe pill next to the name shows how many of those 14 days included that nap (for example, 5 of 14).';

  @override
  String get homeTipTitle => 'Tip of the day';

  @override
  String get homeTipFallback =>
      'Babies can recognize their caregiver\'s voice before birth. Calm talking helps build that bond.';

  @override
  String get homeFeedingTrendTitle => 'TODAY\'S FEEDING TRACK';

  @override
  String homeFeedingTrendLearningDays(int current, int required) {
    return '$current/$required days';
  }

  @override
  String get homeFeedingTrendStatusLearning => 'Learning...';

  @override
  String homeFeedingTrendStatusBelow(String name) {
    return '$name is eating below usual for this time of day';
  }

  @override
  String homeFeedingTrendStatusUsual(String name) {
    return '$name is eating as usual for this time of day';
  }

  @override
  String homeFeedingTrendStatusAbove(String name) {
    return '$name is eating above usual for this time of day';
  }

  @override
  String get homeFeedingTrendStatusPhraseBelow =>
      ' is eating below usual for this time of day';

  @override
  String get homeFeedingTrendStatusPhraseUsual =>
      ' is eating as usual for this time of day';

  @override
  String get homeFeedingTrendStatusPhraseAbove =>
      ' is eating above usual for this time of day';

  @override
  String get homeFeedingTrendHintBelow => 'below usual';

  @override
  String get homeFeedingTrendHintLearning => 'learning';

  @override
  String get homeFeedingTrendHintUsual => 'usual at this time';

  @override
  String get homeFeedingTrendHintAbove => 'above usual';

  @override
  String get homeFeedingTrendTodayTotal => 'today so far';

  @override
  String get homeFeedingTrendUsuallyStill => 'usually still takes';

  @override
  String get homeFeedingTrendInfoTitle => 'How this tracker works';

  @override
  String get homeFeedingTrendInfoBody =>
      'We use the last 14 days of feeds as a reference (bottle and breast; solids aren’t included). At least 2 days with feeds are needed before we leave “learning” and can compare.\n\nAt this time of day, we compare today’s total so far with the usual range from those days: below usual, as usual, or above usual.\n\n“Usually still takes” is an estimate: the median of what they typically reach by end of day, minus what they’ve already taken today.\n\nBreastfeeding can’t be measured in ml like a bottle, so we turn nursing minutes into an approximate equivalent. These figures are a guide, not exact measurements. If anything seems off, check with your pediatrician.';

  @override
  String get homeFeedingTrendInfoButton => 'Got it';

  @override
  String get sabiasQueNoBirthDate =>
      'Add your baby\'s birth date in settings to see age-matched tips.';

  @override
  String get homeConfigureProfileFirst =>
      'Set up your baby\'s profile in Settings first';

  @override
  String get homePickPhoto => 'Choose photo';

  @override
  String get homeRemovePhoto => 'Remove profile photo';

  @override
  String get homePhotoRemoved => 'Profile photo removed';

  @override
  String homePhotoRemoveError(Object error) {
    return 'Could not remove photo: $error';
  }

  @override
  String get homePhotoUpdated => 'Photo updated';

  @override
  String homePhotoUploadError(Object error) {
    return 'Could not upload photo: $error';
  }

  @override
  String get feedingTitle => 'Feeding';

  @override
  String get feedingSessionType => 'Feed type';

  @override
  String get feedingBreast => 'Breast';

  @override
  String get feedingLeft => 'Left';

  @override
  String get feedingRight => 'Right';

  @override
  String get feedingBottle => 'Bottle';

  @override
  String get feedingSolidFood => 'Solids';

  @override
  String get solidFoodTitle => 'Solid food';

  @override
  String get solidFoodNameLabel => 'What they ate';

  @override
  String get solidFoodNameHint => 'e.g. apple purée';

  @override
  String get solidFoodQuantityLabel => 'Amount';

  @override
  String get solidFoodUnitGrams => 'g (grams)';

  @override
  String get solidFoodUnitUnits => 'units';

  @override
  String get solidFoodUnitGramShort => 'g';

  @override
  String get solidFoodUnitUnitsShort => 'u';

  @override
  String get solidFoodQuantityHintGrams => 'e.g. 40 or 0.47 (comma or dot)';

  @override
  String get solidFoodQuantityHintUnits => 'Whole number only, e.g. 2';

  @override
  String get solidFoodValidatorNameEmpty => 'Enter what they ate';

  @override
  String get solidFoodValidatorQuantityEmpty => 'Enter the amount';

  @override
  String solidFoodValidatorQuantityInvalid(Object max) {
    return 'Whole number from 1 to $max';
  }

  @override
  String get solidFoodValidatorQuantityParse =>
      'Invalid format: use digits and at most one decimal comma or dot (e.g. 0.47).';

  @override
  String get solidFoodValidatorUnitsNoDecimals =>
      'For units, use a whole number only (no decimals).';

  @override
  String get solidFoodValidatorGramsPositive =>
      'Weight in grams must be greater than zero.';

  @override
  String solidFoodValidatorGramsRange(Object max) {
    return 'Weight cannot exceed $max g.';
  }

  @override
  String get feedingChooseSideTitle => 'Which side?';

  @override
  String get feedingChooseSideSubtitle => 'Pick a side to start the timer.';

  @override
  String get feedingEditSolid => 'Edit solids';

  @override
  String get feedingStop => 'Stop';

  @override
  String get feedingPause => 'Pause';

  @override
  String get feedingResume => 'Resume';

  @override
  String feedingActiveTimer(Object side) {
    return 'Timer running: $side';
  }

  @override
  String get feedingSideLeft => 'Left';

  @override
  String get feedingSideRight => 'Right';

  @override
  String get feedingHistoryEmpty =>
      'No entries yet. Use “Breast”, “Bottle”, or “Solids” above to add the first one.';

  @override
  String get feedingSessionCountOne => '1 feed';

  @override
  String feedingSessionCountN(Object n) {
    return '$n feeds';
  }

  @override
  String get feedingEditBottle => 'Edit bottle';

  @override
  String get feedingEditSession => 'Edit feed';

  @override
  String get feedingAmountMl => 'Amount (ml)';

  @override
  String get hintExampleMl => 'e.g. 120';

  @override
  String get feedingStreamError =>
      'Could not load feeds. Retry or check your connection.';

  @override
  String lastFeedDetailLeftMinutes(Object minutes) {
    return 'Left • $minutes min';
  }

  @override
  String get lastFeedDetailLeft => 'Left';

  @override
  String lastFeedDetailRightMinutes(Object minutes) {
    return 'Right • $minutes min';
  }

  @override
  String get lastFeedDetailRight => 'Right';

  @override
  String lastFeedDetailBottleVolume(Object volume) {
    return 'Bottle • $volume';
  }

  @override
  String get lastFeedDetailSolid => 'Solids';

  @override
  String get diapersTitle => 'Diaper log';

  @override
  String get diapersChangeType => 'Change type';

  @override
  String get diaperWet => 'Wet';

  @override
  String get diaperDirty => 'Dirty';

  @override
  String get diaperBoth => 'Both';

  @override
  String get diapersRegisterButton => 'Log diaper change';

  @override
  String get diapersHistoryEmpty =>
      'No entries yet. Use “Log diaper change” above to add the first one.';

  @override
  String get diaperChangeCountOne => '1 change';

  @override
  String diaperChangeCountN(Object n) {
    return '$n changes';
  }

  @override
  String get diapersStreamError =>
      'Could not load diapers. Retry or check your connection.';

  @override
  String get diapersEditRecord => 'Edit entry';

  @override
  String get diapersTypeLabel => 'Type';

  @override
  String get weightTitle => 'Weight log';

  @override
  String get weightFieldLabelMetric => 'Weight (kg)';

  @override
  String get weightFieldLabelImperial => 'Weight (lb)';

  @override
  String get hintExampleWeight => 'e.g. 4.5';

  @override
  String get weightRegister => 'Log';

  @override
  String get weightValidatorEmpty => 'Enter weight';

  @override
  String get weightValidatorInvalid => 'Invalid weight';

  @override
  String weightSuddenChangeHint(String value) {
    return 'This is a big change from the last weight ($value). Please double-check.';
  }

  @override
  String get weightStreamError =>
      'Could not load weights. Check connection or retry.';

  @override
  String get growthChartMetricWeight => 'Weight';

  @override
  String get growthChartMetricHeight => 'Height';

  @override
  String get growthEvolution => 'Weight and height trend';

  @override
  String get weightEvolution => 'Weight trend';

  @override
  String get weightChartCaption => 'WHO reference (weight-for-age).';

  @override
  String get weightChartBabyCaption => 'Baby weigh-ins';

  @override
  String get weightChartRangeSelector => 'Range';

  @override
  String get weightChartSource =>
      'Source: World Health Organization (WHO) — Child Growth Standards. who.int/tools/child-growth-standards';

  @override
  String get weightChartInfoTitle => 'Chart source';

  @override
  String get weightChartLoadError => 'Could not load the weight chart.';

  @override
  String get weightHistoryLoadError => 'Could not load weight history.';

  @override
  String get weightHistoryEmpty =>
      'No entries yet. Enter weight and tap “Log” above to add the first one.';

  @override
  String get growthHistoryEmpty =>
      'No entries yet. Enter weight or height and tap “Log” to add the first one.';

  @override
  String get weightCurrentCard => 'Current weight';

  @override
  String get weightTrendCard => 'Daily trend';

  @override
  String weightTrendGramsCompact(Object sign, Object value) {
    return '$sign${value}g';
  }

  @override
  String weightTrendOuncesCompact(Object sign, Object value) {
    return '$sign$value oz';
  }

  @override
  String get weightNoData => 'No data';

  @override
  String get weightDash => '-';

  @override
  String get weightChartEmpty => 'No data yet';

  @override
  String get weightChartNoDataInRange => 'No weigh-ins in this period';

  @override
  String weightChartNeedsMoreRecords(String name) {
    return 'Add one more weigh-in to calculate $name\'s growth line.';
  }

  @override
  String get weightChartRangeAll => 'All';

  @override
  String get weightChartRange7d => '7 days';

  @override
  String get weightChartRange30d => '30 days';

  @override
  String get weightChartRange90d => '3 months';

  @override
  String get weightChartRange365d => '1 year';

  @override
  String weightTooltipAge(String age) {
    return 'Age: $age';
  }

  @override
  String weightTooltipBabyPercentile(String value) {
    return 'WHO percentile (weight/age): $value';
  }

  @override
  String heightTooltipBabyPercentile(String value) {
    return 'WHO percentile (length/age): $value';
  }

  @override
  String weightTooltipPercentile(String label, String value) {
    return '$label (WHO): $value';
  }

  @override
  String weightTooltipWeighIn(Object value) {
    return 'Weigh-in: $value';
  }

  @override
  String get weightChartPercentileSelector => 'Percentile';

  @override
  String weightChartBabyPercentileAt(String name, String percentile) {
    return '$name is at the $percentile percentile';
  }

  @override
  String weightChartBabyPercentileAbove(String name, String percentile) {
    return '$name is above the $percentile percentile';
  }

  @override
  String weightChartBabyPercentileBelow(String name, String percentile) {
    return '$name is below the $percentile percentile';
  }

  @override
  String get weightChartPercentilePhraseBeforeAt => ' is at the ';

  @override
  String get weightChartPercentilePhraseAfterAt => ' percentile';

  @override
  String get weightChartPercentilePhraseBeforeAbove => ' is above the ';

  @override
  String get weightChartPercentilePhraseAfterAbove => ' percentile';

  @override
  String get weightChartPercentilePhraseBeforeBelow => ' is below the ';

  @override
  String get weightChartPercentilePhraseAfterBelow => ' percentile';

  @override
  String get weightEditTitle => 'Edit weight';

  @override
  String get heightTitle => 'Height log';

  @override
  String get hintExampleHeight => 'e.g. 58';

  @override
  String get heightRegister => 'Log';

  @override
  String get heightValidatorEmpty => 'Enter height';

  @override
  String get heightValidatorInvalid => 'Invalid height';

  @override
  String heightSuddenChangeHint(String value) {
    return 'This is a big change from the last height ($value). Please double-check.';
  }

  @override
  String get heightHistoryLoadError => 'Could not load height history.';

  @override
  String get heightEditTitle => 'Edit height';

  @override
  String get heightEvolution => 'Height trend';

  @override
  String get heightChartCaption => 'WHO reference (length/height-for-age).';

  @override
  String get heightChartBabyCaption => 'Baby height measures';

  @override
  String get heightChartLoadError => 'Could not load the height chart.';

  @override
  String get heightChartEmpty => 'No heights yet';

  @override
  String get heightChartNoDataInRange => 'No height measures in this period';

  @override
  String heightChartNeedsMoreRecords(String name) {
    return 'Add one more height measure to calculate $name\'s growth line.';
  }

  @override
  String heightTooltipMeasure(String value) {
    return 'Height: $value';
  }

  @override
  String get bottleTitle => 'Bottle';

  @override
  String get bottleValidatorEmpty => 'Enter amount';

  @override
  String get bottleValidatorInvalid => 'Invalid amount';

  @override
  String get bottleQuickAmountsSectionTitle => 'Quick amounts';

  @override
  String get bottleQuickAmountAdd => 'Add';

  @override
  String get bottleQuickAmountAddTitle => 'Add shortcut';

  @override
  String get bottleQuickAmountDuplicate => 'That amount is already in the list';

  @override
  String get bottleQuickAmountMaxCustom => 'Maximum custom shortcuts reached';

  @override
  String get bottleQuickAmountRemoveTitle => 'Remove shortcut';

  @override
  String bottleQuickAmountRemoveMessage(String amount) {
    return 'Remove $amount from your shortcuts?';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsBabyProfile => 'Baby profile';

  @override
  String get settingsShareFamily => 'Share family';

  @override
  String get settingsSuggestedFeedings => 'Suggested feeds';

  @override
  String get settingsName => 'Name';

  @override
  String get settingsBirthDate => 'Date of birth';

  @override
  String get settingsHeight => 'Height';

  @override
  String get settingsNoProfile => 'No profile configured';

  @override
  String get settingsEditProfile => 'Edit profile';

  @override
  String get settingsShareQrIntro =>
      'Show this code. The other person scans it on their own phone when joining an existing baby.';

  @override
  String get settingsFeedingConfigureFirst =>
      'Set up your baby\'s profile first.';

  @override
  String get settingsFeedingIntro => 'Set how often your baby usually feeds';

  @override
  String get settingsFeedingInterval => 'Time between feeds';

  @override
  String get settingsNotifyTitle => 'Enable notifications';

  @override
  String get settingsNotifySubtitle =>
      'Notifications at the suggested time for the next feed.';

  @override
  String get settingsNotifyPermission =>
      'Turn on notifications in system settings to get reminders.';

  @override
  String get settingsSignOutSection => 'Sign out';

  @override
  String get settingsSignOutButton => 'Sign out';

  @override
  String get settingsSignOutRowSubtitle => 'Sign out on this device';

  @override
  String get settingsDeleteSection => 'Delete account';

  @override
  String get settingsDeleteIntro =>
      'Deletes your account and sign-in data. If you\'re the only family member, all baby data will be removed too.';

  @override
  String get settingsDeleteAccount => 'Delete my account';

  @override
  String get settingsDeleteAccountRowSubtitle =>
      'Delete your account and its data';

  @override
  String get settingsDeleting => 'Deleting...';

  @override
  String get settingsFamilyFirebaseOnly =>
      'Family sharing is only available with Firebase.';

  @override
  String get settingsShowQr => 'Show invite QR';

  @override
  String get settingsHideQr => 'Hide QR';

  @override
  String get settingsQrCaption =>
      'This phone only displays the code. The other person scans it.';

  @override
  String get settingsGroupBaby => 'Baby';

  @override
  String get settingsGroupPreferences => 'Preferences';

  @override
  String get settingsGroupFamily => 'Family';

  @override
  String get settingsGroupAccount => 'Account';

  @override
  String get settingsGroupHelp => 'Help';

  @override
  String get settingsRowContactTitle => 'Contact';

  @override
  String settingsRowContactSubtitle(String email) {
    return '$email';
  }

  @override
  String get settingsContactEmailSubject => 'Question about MiBebé';

  @override
  String settingsContactOpenFail(String email) {
    return 'Couldn\'t open the mail app. Write to us at $email';
  }

  @override
  String get settingsRowProfileTitle => 'Profile details';

  @override
  String get settingsRowProfileSubtitle => 'Name, date of birth and gender';

  @override
  String get settingsRowProfileEmpty => 'Not set';

  @override
  String get settingsRowFeedingInterval => 'Time between feeds';

  @override
  String get settingsRowFeedingNotify => 'Next-feed reminder';

  @override
  String get settingsRowUnitWeight => 'Weight unit';

  @override
  String get settingsRowUnitLiquid => 'Liquid unit';

  @override
  String get settingsRowCurrency => 'Currency';

  @override
  String get settingsCurrencyAuto => 'Automatic';

  @override
  String get settingsCurrencyIntro =>
      'Choose the currency used to estimate diaper spend. Automatic follows your device.';

  @override
  String get settingsCurrencySearchHint => 'Search currency';

  @override
  String settingsCurrencyAutoSubtitle(String currency) {
    return 'Follows your device · $currency';
  }

  @override
  String get settingsCurrencyAllSection => 'All currencies';

  @override
  String settingsCurrencyNoResults(String query) {
    return 'No currency matches “$query”';
  }

  @override
  String get settingsRowFamilyShare => 'Share with family';

  @override
  String get settingsRowFamilyShareSubtitle => 'Show invite QR code';

  @override
  String get settingsValueOn => 'On';

  @override
  String get settingsValueOff => 'Off';

  @override
  String get settingsValueNotSet => '—';

  @override
  String get settingsBabyAgeMonthsOne => '1 month';

  @override
  String settingsBabyAgeMonthsN(int months) {
    return '$months months';
  }

  @override
  String get settingsBabyAgeDaysOne => '1 day';

  @override
  String settingsBabyAgeDaysN(int days) {
    return '$days days';
  }

  @override
  String settingsBabyBornOn(String date) {
    return 'Born on $date';
  }

  @override
  String settingsBabyBornOnFemale(String date) {
    return 'Born on $date';
  }

  @override
  String get settingsSheetUnitWeightTitle => 'Weight unit';

  @override
  String get settingsSheetUnitLiquidTitle => 'Liquid unit';

  @override
  String get settingsSheetCurrencyTitle => 'Currency';

  @override
  String get settingsSheetFeedingIntervalTitle => 'Time between feeds';

  @override
  String get settingsSheetShareTitle => 'Share with family';

  @override
  String get editBabyProfileTitle => 'Edit baby profile';

  @override
  String get labelName => 'Name';

  @override
  String get labelGender => 'Gender';

  @override
  String get heightFieldLabel => 'Height (cm)';

  @override
  String get heightFieldHint => 'Optional, e.g. 58';

  @override
  String get heightInvalid => 'Invalid height';

  @override
  String get heightRangeError => 'Height must be between 25 and 120 cm';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountBody =>
      'This will permanently delete your account and sign-in data. If you\'re the only family member, all baby data will be removed too.\n\nThis can\'t be undone. Are you sure?';

  @override
  String get deleteAccountConfirm => 'Delete account';

  @override
  String deleteAccountError(Object error) {
    return 'Could not delete account: $error';
  }

  @override
  String get signOutTitle => 'Sign out';

  @override
  String get signOutBody => 'Are you sure you want to sign out?';

  @override
  String get signOutConfirm => 'Sign out';

  @override
  String signOutError(Object error) {
    return 'Could not sign out: $error';
  }

  @override
  String get loginForgotPasswordTitle => 'Reset password';

  @override
  String get loginForgotPasswordBody =>
      'We\'ll email you a link to choose a new password.';

  @override
  String get loginEmailHint => 'Your email';

  @override
  String get loginResetInvalidEmail => 'Enter a valid email';

  @override
  String get loginResetCheckEmail =>
      'Check your email (and spam) to reset your password';

  @override
  String get loginResetSendFail => 'Could not send the email. Try again later.';

  @override
  String get loginHeaderTitle => 'MiBebé';

  @override
  String get loginWelcomeBackTitle => 'Welcome back';

  @override
  String get loginWelcomeBackSubtitle =>
      'Your baby\'s data is still safely stored';

  @override
  String get loginContinueApple => 'Continue with Apple';

  @override
  String get loginContinueGoogle => 'Continue with Google';

  @override
  String get loginContinueEmail => 'Continue with email';

  @override
  String loginLastAuthMethod(String method) {
    return 'Last time you signed in with $method';
  }

  @override
  String get loginPasswordHint => 'Your password';

  @override
  String get loginForgotLink => 'Forgot your password?';

  @override
  String get loginValidatorEmailEmpty => 'Enter your email';

  @override
  String get loginValidatorEmailInvalid => 'Invalid email';

  @override
  String get loginValidatorPasswordEmpty => 'Enter your password';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginGuestQr => 'Join with QR code (no account)';

  @override
  String get loginOrWith => 'OR SIGN IN WITH';

  @override
  String get loginNoAccount => 'Don\'t have an account? ';

  @override
  String get loginRegisterLink => 'Sign up';

  @override
  String get loginCreateNewProfile => 'Create a new profile';

  @override
  String get loginErrorGeneric => 'Sign-in error';

  @override
  String get loginErrorGoogle => 'Google sign-in error';

  @override
  String get loginErrorApple => 'Apple sign-in error';

  @override
  String get loginGuestNeedsFirebase =>
      'Firebase is required to join with a QR code';

  @override
  String get loginGuestNotAllowed =>
      'Anonymous sign-in is disabled. In Firebase Console → Authentication → Sign-in method, enable Anonymous.';

  @override
  String get loginGuestFailed => 'Could not sign in as guest';

  @override
  String get authErrorUserNotFound => 'No account exists with this email';

  @override
  String get authErrorWrongPassword => 'Incorrect password';

  @override
  String get authErrorInvalidEmail => 'Invalid email';

  @override
  String get authErrorUserDisabled => 'This account has been disabled';

  @override
  String get authErrorInvalidCredential => 'Invalid credentials';

  @override
  String get authErrorOperationNotAllowed =>
      'This sign-in method is not enabled';

  @override
  String get authErrorGeneric => 'Sign-in error';

  @override
  String get resetErrorInvalidEmail => 'Invalid email';

  @override
  String get resetErrorUserNotFound =>
      'No account with this email. Check the address or sign up.';

  @override
  String get resetErrorUserDisabled => 'This account is disabled';

  @override
  String get resetErrorOpNotAllowed =>
      'Email recovery isn\'t enabled in Firebase (Authentication → Sign-in method → Email).';

  @override
  String get resetErrorGeneric => 'Could not send the email. Try again later.';

  @override
  String get registerTitle => 'Sign up';

  @override
  String get registerHeadline => 'Create your account';

  @override
  String get registerSubtitle => 'Enter your details to sign up';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Password';

  @override
  String get registerConfirmLabel => 'Confirm password';

  @override
  String get registerPasswordHint => 'At least 6 characters';

  @override
  String get registerEmailHint => 'you@email.com';

  @override
  String get registerValidatorEmailEmpty => 'Enter your email';

  @override
  String get registerValidatorPasswordEmpty => 'Enter a password';

  @override
  String get registerValidatorPasswordShort => 'At least 6 characters';

  @override
  String get registerValidatorConfirmEmpty => 'Confirm your password';

  @override
  String get registerValidatorMismatch => 'Passwords don\'t match';

  @override
  String get registerButton => 'Sign up';

  @override
  String get registerHaveAccount => 'Already have an account? ';

  @override
  String get registerSignInLink => 'Sign in';

  @override
  String get registerErrorGeneric =>
      'Sign-up failed. Check your connection and that email sign-up is enabled in Firebase.';

  @override
  String get registerErrorEmailInUse =>
      'An account already exists with this email. Use “Sign in” instead.';

  @override
  String get registerErrorWeakPassword =>
      'Password must be at least 6 characters';

  @override
  String get registerErrorOpNotAllowed =>
      'Email sign-up isn\'t enabled. Turn it on in Firebase Console → Authentication → Sign-in method';

  @override
  String get registerErrorNetwork => 'Network error. Check your internet.';

  @override
  String get registerErrorTooMany => 'Too many attempts. Wait a few minutes.';

  @override
  String get registerErrorInvalidCredential => 'Invalid credentials';

  @override
  String registerErrorUnknown(Object code) {
    return 'Error: $code. Check Firebase Console.';
  }

  @override
  String get onboardingWelcome => 'Welcome to MiBebé';

  @override
  String get onboardingHowStart => 'How would you like to start?';

  @override
  String get onboardingCreateBabyTitle => 'Create baby';

  @override
  String get onboardingCreateBabySubtitle =>
      'Set up a new profile from scratch';

  @override
  String get onboardingScanTitle => 'Scan baby';

  @override
  String get onboardingScanSubtitle =>
      'Join an existing baby by scanning their QR code';

  @override
  String get onboardingScanDisabled => 'Requires Firebase for sharing';

  @override
  String get onboardingExitLogin => 'Exit and return to sign-in';

  @override
  String get onboardingConfigureTitle => 'Set up baby';

  @override
  String get onboardingCreateProfileTitle => 'Create baby profile';

  @override
  String get onboardingCreateProfileSubtitle => 'Enter your baby\'s details';

  @override
  String get onboardingBabyName => 'Baby\'s name';

  @override
  String get onboardingBabyNameHint => 'e.g. Maria, Lucas...';

  @override
  String get onboardingNameRequired => 'Name is required';

  @override
  String get onboardingGender => 'Gender';

  @override
  String get onboardingBirthDate => 'Date of birth';

  @override
  String get onboardingBirthNote => 'Used for WHO percentiles (0–12 months)';

  @override
  String get onboardingHeightTitle => 'Length / height';

  @override
  String get onboardingHeightSubtitle =>
      'Optional. Current height in centimeters (shown on the profile).';

  @override
  String get onboardingHeightHint => 'Leave blank if unknown';

  @override
  String get onboardingHeightInvalid => 'Enter a valid number (e.g. 52.5)';

  @override
  String get onboardingHeightRange => 'Height is usually between 25 and 130 cm';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingEnterName => 'Enter the baby\'s name';

  @override
  String get onboardingHeightReview =>
      'Check height: a number between 25 and 130 cm, or leave the field empty';

  @override
  String get onboardingSaveDenied =>
      'No permission in Firebase (rules or session). Check Firestore.';

  @override
  String onboardingSaveFailed(Object code) {
    return 'Could not save ($code). Check connection and Firebase.';
  }

  @override
  String onboardingSaveError(Object error) {
    return 'Could not save: $error';
  }

  @override
  String get onboardingExitTitle => 'Leave?';

  @override
  String get onboardingExitBody =>
      'You will sign out and return to the sign-in screen.';

  @override
  String onboardingSignOutError(Object error) {
    return 'Could not sign out: $error';
  }

  @override
  String get familyQrTitle => 'Scan QR code';

  @override
  String get familyQrHint => 'Point the camera at the baby\'s QR code';

  @override
  String get familyQrDetailLabel => 'Detail:';

  @override
  String get familyQrJoinFailPermission =>
      'Permission denied in Firebase (Firestore rules or session).';

  @override
  String get familyQrJoinFailUnavailable =>
      'Firebase is unavailable. Check your internet connection.';

  @override
  String get familyQrJoinFailNotFound => 'Resource not found in Firebase.';

  @override
  String familyQrJoinFailFirebase(Object code) {
    return 'Firebase error ($code).';
  }

  @override
  String get familyQrJoinFailFamily =>
      'Family not found. Check that the QR is correct.';

  @override
  String get familyQrJoinFailState => 'Could not process the QR code.';

  @override
  String get familyQrJoinFailUnsupported =>
      'QR join isn\'t available (Firebase is required on this device).';

  @override
  String get familyQrJoinFailGeneric => 'Could not join the family.';

  @override
  String get familyQrDecodeFail => 'Failed to read or decode the code.';

  @override
  String get familyQrInternalCode => 'Internal code:';

  @override
  String get notificationChannelName => 'Next feeds';

  @override
  String get notificationChannelDescription =>
      'Reminder when the next feed is due';

  @override
  String get notificationNextFeedTitle => 'Next feed';

  @override
  String notificationNextFeedBody(Object name) {
    return 'It may be time for another feed for $name.';
  }

  @override
  String formatWeightMetricKg(Object kg) {
    return '$kg kg';
  }

  @override
  String formatWeightLbOz(Object lb, Object oz) {
    return '$lb lb $oz oz';
  }

  @override
  String formatHeightCm(Object cm) {
    return '$cm cm';
  }

  @override
  String formatVolumeMlOnly(Object ml) {
    return '$ml ml';
  }

  @override
  String formatVolumeFlOzOnly(Object flOz) {
    return '$flOz fl oz';
  }

  @override
  String get unitMlShort => 'ml';

  @override
  String get unitMlLong => 'milliliters';

  @override
  String get unitFlOzLong => 'fluid ounces';

  @override
  String get hintExampleWeightLb => 'e.g. 9.5';

  @override
  String get hintExampleFlOz => 'e.g. 4';

  @override
  String get liquidFieldLabelFlOz => 'Amount (US fl oz)';

  @override
  String get settingsUnitsTitle => 'Units';

  @override
  String get settingsUnitsIntro =>
      'Choose how you enter and view weight and bottle amounts. Data is always stored in kg and ml.';

  @override
  String get settingsUnitsWeight => 'Weight';

  @override
  String get settingsUnitsLiquid => 'Liquids';

  @override
  String get unitSegmentKg => 'kg';

  @override
  String get unitSegmentLbOz => 'lb · oz';

  @override
  String get unitSegmentMl => 'mL';

  @override
  String get unitSegmentFlOz => 'fl oz';

  @override
  String get settingsRowPediatricReport => 'Report for the paediatrician';

  @override
  String get settingsRowPediatricReportSubtitle =>
      'Share PDF with WHO growth curves';

  @override
  String get reportShareError =>
      'The report could not be generated. Please try again.';

  @override
  String get reportFileNamePrefix => 'growth-report';

  @override
  String get reportTitle => 'Growth report';

  @override
  String get reportSexLabel => 'Sex';

  @override
  String get reportSexMale => 'Boy';

  @override
  String get reportSexFemale => 'Girl';

  @override
  String get reportSexUnspecified => 'Unspecified';

  @override
  String get reportBirthDateLabel => 'Date of birth';

  @override
  String get reportAgeLabel => 'Age';

  @override
  String get reportDateLabel => 'Report date';

  @override
  String reportAgeMonthsDays(int months, int days) {
    return '$months mo $days d';
  }

  @override
  String reportAgeDays(int days) {
    return '$days days';
  }

  @override
  String get reportChartTitle => 'Weight (kg) for age (months) · WHO curves';

  @override
  String get reportHeightChartTitle =>
      'Length (cm) for age (months) · WHO curves';

  @override
  String reportChartLegendBaby(String name) {
    return '$name\'s weight';
  }

  @override
  String get reportChartLegendWho =>
      'WHO percentiles: P3 · P15 · P50 · P85 · P97';

  @override
  String get reportChartWhoNote =>
      'Curves are WHO reference percentiles; points are the baby\'s measurements.';

  @override
  String get reportWeightTableTitle => 'Latest weigh-ins';

  @override
  String get reportHeightTableTitle => 'Latest lengths';

  @override
  String get reportTableDate => 'Date';

  @override
  String get reportTableAge => 'Age';

  @override
  String get reportTableWeight => 'Weight';

  @override
  String get reportTableHeight => 'Length';

  @override
  String get reportTableChange => 'Change';

  @override
  String get reportNoWeightData => 'No weigh-ins recorded yet.';

  @override
  String get reportNoHeightData => 'No lengths recorded yet.';

  @override
  String get reportFeedingTitle => 'Feeding · last 7 days';

  @override
  String get reportFeedingPerDay => 'Feeds per day';

  @override
  String get reportFeedingBreastPerDay => 'Breast per day';

  @override
  String get reportFeedingBottlePerDay => 'Bottle per day';

  @override
  String get reportFeedingDistribution => 'Distribution';

  @override
  String reportFeedingDistributionValue(int breast, int bottle, int solid) {
    return '$breast% breast · $bottle% bottle · $solid% solids';
  }

  @override
  String get reportDiapersTitle => 'Nappies · last 7 days';

  @override
  String get reportDiapersPerDay => 'Changes per day';

  @override
  String get reportDiapersWet => 'Wet';

  @override
  String get reportDiapersDirty => 'Dirty';

  @override
  String get reportDiapersBoth => 'Mixed';

  @override
  String get reportNoData => 'No data';

  @override
  String reportGeneratedWith(String date) {
    return 'Generated with MiBebé · $date';
  }

  @override
  String get reportTrendsTitle => 'Trends and comparisons';

  @override
  String reportPeriodDays(int days) {
    return 'Last $days days';
  }

  @override
  String reportComparisonTitle(int days) {
    return 'Comparison vs previous $days days';
  }

  @override
  String get reportComparisonMetric => 'Metric';

  @override
  String get reportComparisonCurrent => 'Current';

  @override
  String get reportComparisonPrevious => 'Previous';

  @override
  String get reportComparisonChange => 'Change';

  @override
  String get reportComparisonNew => 'new';

  @override
  String get reportWeightTrendsTitle => 'Weight · trends';

  @override
  String reportWeightTrendDays(int days) {
    return '$days-day trend';
  }

  @override
  String reportWeightGainDays(int days) {
    return '$days-day gain';
  }

  @override
  String get reportExecutiveSummary => 'Summary';

  @override
  String get reportCurrentWeight => 'Current weight';

  @override
  String get reportCurrentHeight => 'Current length';

  @override
  String get reportCurrentPercentile => 'WHO percentile';

  @override
  String get reportWeightForAgePercentile => 'WHO percentile (weight/age)';

  @override
  String get reportLengthForAgePercentile => 'WHO percentile (length/age)';

  @override
  String reportCalculatedPercentileValue(int value) {
    return '$value';
  }

  @override
  String reportPercentileChip(int value) {
    return 'P$value';
  }

  @override
  String get reportPercentileBelow => '< P3';

  @override
  String get reportPercentileAbove => '> P97';

  @override
  String get reportSummaryGrowthGroup => 'Growth';

  @override
  String get reportSummaryRoutineGroup => 'Feeding and nappies';

  @override
  String get reportSummaryMeasuredOn => 'Last measured';

  @override
  String get reportSinceLastWeighIn => 'Since last weigh-in';

  @override
  String get reportDaysSinceWeighIn => 'Days since weigh-in';

  @override
  String get reportDaysSinceHeight => 'Days since length measure';

  @override
  String reportDaysCount(int days) {
    return '$days days';
  }

  @override
  String get reportPercentileChange => 'Percentile change';

  @override
  String get reportHeight => 'Height';

  @override
  String get reportWeightSection => 'Weight';

  @override
  String get reportHeightSection => 'Height';

  @override
  String get reportFeedingSection => 'Feeding';

  @override
  String get reportDiapersSection => 'Nappies';

  @override
  String get reportSleepSection => 'Sleep';

  @override
  String get reportSleepTitle => 'Sleep · last 7 days';

  @override
  String get reportSleepAveragePerRecordedDay => 'Hours per recorded day';

  @override
  String reportSleepHoursValue(String hours) {
    return '$hours h';
  }

  @override
  String get reportSleepTotal => 'Total time asleep';

  @override
  String get reportSleepNaps => 'Naps';

  @override
  String get reportSleepNightWakings => 'Night wakings';

  @override
  String get reportSleepNightWakingTime => 'Total awake time at night';

  @override
  String get reportSleepDailyTitle => 'Sleep by day · last 7 days';

  @override
  String get reportSleepDay => 'Day';

  @override
  String get reportSleepDuration => 'Duration';

  @override
  String get reportSleepNapsPerRecordedDay => 'Naps per recorded day';

  @override
  String get reportSleepWakingsPerRecordedDay => 'Wakings per recorded day';

  @override
  String get reportSleepRecentSessions => 'Recent sleep sessions';

  @override
  String get reportSleepStart => 'Start';

  @override
  String get reportSleepEnd => 'End';

  @override
  String get reportSleepType => 'Type';

  @override
  String get reportSleepInProgress => 'In progress';

  @override
  String get reportWeightOverviewTitle => 'Weight data';

  @override
  String get reportHeightOverviewTitle => 'Length data';

  @override
  String get reportFeedingDetailTitle => 'Breastfeeding detail';

  @override
  String get reportBreastfeedingDetailTitle => 'Breastfeeding detail';

  @override
  String get reportBottleDetailTitle => 'Bottle detail';

  @override
  String get reportBottleFeedsPerDay => 'Bottles per day';

  @override
  String get reportBottleAvgPerFeed => 'Average ml per feed';

  @override
  String reportBottleTotalPeriod(int days) {
    return 'Total in $days days';
  }

  @override
  String get reportComparisonNoData => '—';

  @override
  String get reportComparisonInsufficientHistory =>
      'At least 60 days of records are needed to compare with the previous period.';

  @override
  String get reportFeedingInterval => 'Average interval between feeds';

  @override
  String get reportFeedingLongestGap => 'Longest stretch without feeding';

  @override
  String get reportFeedingBreastBalance => 'Left / right breast balance';

  @override
  String reportFeedingBreastBalanceValue(int left, int right) {
    return '$left% / $right%';
  }

  @override
  String get reportFeedingAvgSession => 'Average breastfeed duration';

  @override
  String get reportFeedingEstimatedBreast => 'Estimated breast milk / day';

  @override
  String get reportFeedingEstimatedBreastStarred =>
      'Estimated breast milk / day*';

  @override
  String get reportEstimatedBreastFootnote =>
      '* Estimate from breastfeeding time (not a measured volume). Conversion: ml = 140 x (1 - e^(-minutes/9)).';

  @override
  String reportCoverageLabel(int logged, int total) {
    return 'Logged: $logged of $total days';
  }

  @override
  String get reportCoverageLowWarning =>
      'Averages may not be representative (incomplete logging).';

  @override
  String get reportLegalDisclaimer =>
      'Personal tracking tool. This data does not replace assessment by a healthcare professional.';

  @override
  String get reportFeedingFirstSolid => 'First solid food';

  @override
  String get reportNoSolidFoodYet => 'No solids recorded';

  @override
  String get reportWetDiapersPerDay => 'Wet nappies per day';

  @override
  String get reportStoolDiapersPerDay => 'Stools per day';

  @override
  String get reportDaysWithoutStool => 'Days without stool';

  @override
  String reportDaysWithoutStoolOfPeriod(int count, int total) {
    return '$count of $total days';
  }

  @override
  String reportComparisonAbsoluteChange(String previous, String current) {
    return '$previous → $current';
  }

  @override
  String get reportDiaperDistribution => 'Distribution';

  @override
  String reportDiaperDistributionValue(int wet, int dirty, int both) {
    return '$wet% wet · $dirty% dirty · $both% mixed';
  }

  @override
  String get premiumUnlockButton => 'Unlock';

  @override
  String get premiumTeaserTitle => 'PREMIUM INSIGHTS';

  @override
  String premiumTeaserSubtitle(String name) {
    return 'What your records can already tell you about $name';
  }

  @override
  String get premiumTeaserCta => 'Try 7 days free';

  @override
  String premiumTeaserAfterPrice(String price) {
    return 'Then $price/year · cancel anytime';
  }

  @override
  String get premiumTeaserCancelAnytime => 'Cancel anytime';

  @override
  String premiumTeaserMoreAnalyses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'And $count more insights',
      one: 'And 1 more insight',
    );
    return '$_temp0';
  }

  @override
  String premiumTeaserBasedOnNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on $count nights logged',
      one: 'Based on 1 night logged',
    );
    return '$_temp0';
  }

  @override
  String premiumTeaserBasedOnFeedingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on $count days of feeds',
      one: 'Based on 1 day of feeds',
    );
    return '$_temp0';
  }

  @override
  String premiumTeaserBasedOnWeights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on $count measurements logged',
      one: 'Based on 1 measurement logged',
    );
    return '$_temp0';
  }

  @override
  String get premiumTeaserFeedingTrendTitle => 'How today\'s feeding is going';

  @override
  String get premiumTeaserFeedingTrendSubtitle =>
      'Compared with their usual days';

  @override
  String premiumTeaserFeedingTrendHeadline(String name) {
    return 'See how $name is feeding today';
  }

  @override
  String get premiumTeaserSleepTitle =>
      'Their best sleep time and usual sleeps';

  @override
  String get premiumTeaserSleepSubtitle => 'From forecast and usual patterns';

  @override
  String premiumTeaserSleepHeadline(String name) {
    return 'Discover how $name sleeps';
  }

  @override
  String get premiumTeaserGrowthTitle => 'WHO weight and height percentiles';

  @override
  String get premiumTeaserGrowthSubtitle => 'Full curve and projection';

  @override
  String premiumTeaserGrowthHeadline(String name) {
    return 'Discover $name\'s WHO weight and height percentiles';
  }

  @override
  String get settingsGroupSubscription => 'Subscription';

  @override
  String get settingsRowManageSubscription => 'Manage subscription';

  @override
  String get settingsRowSubscriptionActive => 'Premium active';

  @override
  String get settingsRowSubscriptionInactive => 'Free plan';

  @override
  String get settingsRowSubscriptionFamily => 'Premium shared by your family';

  @override
  String get settingsRowSubscribe => 'Go premium';

  @override
  String get settingsRowSubscribeSubtitle =>
      'Unlock insights and advanced tracking';

  @override
  String get settingsRowRestorePurchases => 'Restore purchases';

  @override
  String get restorePurchasesSuccess => 'Purchases restored successfully';

  @override
  String get restorePurchasesEmpty => 'No purchases found to restore';

  @override
  String get settingsRowComplimentaryPremium => 'Complimentary Premium';

  @override
  String settingsRowComplimentaryPremiumUntil(String date) {
    return 'Free until $date';
  }

  @override
  String get settingsRowRestorePurchasesGiftHint =>
      'If you purchased a subscription, restore it here';

  @override
  String get restorePurchasesGiftDialogTitle => 'Complimentary Premium';

  @override
  String get restorePurchasesGiftDialogBody =>
      'Your Premium access is a temporary gift from the app. There is no purchase to restore. You can subscribe from settings when it ends if you\'d like to keep Premium.';

  @override
  String get premiumLaunchNoticeTitle => 'Thank you for trusting us!';

  @override
  String premiumLaunchNoticeBodyGift(String date) {
    return 'Behind this app is a family like yours, and as a thank-you for being with us from the start, we\'ve unlocked all the Premium features added in this update completely free for your family until $date.';
  }

  @override
  String get premiumLaunchNoticeBodyEssential =>
      'The essentials will always remain free.';

  @override
  String get premiumLaunchNoticeSignOff => 'A warm hug,';

  @override
  String get premiumLaunchNoticeSignatureName => 'S.';

  @override
  String get premiumLaunchNoticeDismiss => 'Got it!';

  @override
  String get premiumExpiryWarningTitle => 'Your Premium is ending soon';

  @override
  String premiumExpiryWarningBodyDays(int days) {
    return 'You have $days days of Premium left. If you don\'t renew, you\'ll lose insights, evolution charts, PDF reports, and family sharing via QR.';
  }

  @override
  String get premiumExpiryWarningBodyToday =>
      'Your Premium ends today. If you don\'t renew, you\'ll lose insights, evolution charts, PDF reports, and family sharing via QR.';

  @override
  String premiumExpiryWarningBodyGiftDays(int days) {
    return 'You have $days days left of your Premium gift. After that you\'ll return to the free plan as always, with all the essentials intact.\n\nIf these features have made your day-to-day easier, you can keep them by subscribing.';
  }

  @override
  String get premiumExpiryWarningBodyGiftToday =>
      'Your Premium gift ends today. After that you\'ll return to the free plan as always, with all the essentials intact.\n\nIf these features have made your day-to-day easier, you can keep them by subscribing.';

  @override
  String get premiumExpiryWarningRenew => 'Go premium';

  @override
  String get premiumExpiryWarningDismiss => 'Not now';

  @override
  String get paywallTitle => 'Go premium';

  @override
  String get paywallSubtitle =>
      'Everything you were missing to care for and better understand your baby.';

  @override
  String get paywallFeatureInsights => 'All insights and evolution charts';

  @override
  String get paywallFeatureFeedingTrack => 'Daily feeding tracking';

  @override
  String get paywallFeatureSleepTrack =>
      'Sleep analysis and next-sleep prediction';

  @override
  String get paywallFeatureFamily => 'Share with your family via QR';

  @override
  String get paywallFeaturePdf => 'PDF report for the pediatrician';

  @override
  String get paywallBadgeBestValue => 'BEST VALUE';

  @override
  String get paywallBadgeRecommended => 'Recommended';

  @override
  String paywallAnnualMonthlyEquivalent(String price) {
    return 'Just $price/month';
  }

  @override
  String get paywallTrialBadge => '7 days free';

  @override
  String get paywallPlanAnnual => 'Annual';

  @override
  String get paywallPlanMonthly => 'Monthly';

  @override
  String get paywallPlanGeneric => 'Subscription';

  @override
  String get paywallPerYear => '/year';

  @override
  String get paywallPerMonth => '/month';

  @override
  String get paywallPerWeek => '/week';

  @override
  String get paywallCtaTrial => 'Start free trial';

  @override
  String get paywallCtaSubscribe => 'Subscribe';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallTerms => 'Terms';

  @override
  String get paywallPrivacy => 'Privacy';

  @override
  String get paywallLegal =>
      'Auto-renews. Cancel in Settings at least 24h before the period ends.';

  @override
  String get paywallPurchaseError =>
      'The purchase could not be completed. Please try again.';

  @override
  String get paywallLoadError =>
      'Could not load the plans. Check your connection.';

  @override
  String get paywallClose => 'Close';

  @override
  String get onboardingFlowContinue => 'Continue';

  @override
  String get onboardingFlowBornTitle => 'Has your baby been born?';

  @override
  String get onboardingFlowBornSubtitle =>
      'We\'ll prepare their profile in a minute';

  @override
  String get onboardingFlowBornOption => 'Already born';

  @override
  String get onboardingFlowPregnantOption => 'Expecting a baby';

  @override
  String get onboardingFlowHaveAccount => 'I already have an account';

  @override
  String get onboardingFlowQrInvite => 'I\'ve been invited to a family';

  @override
  String get onboardingFlowNameTitle => 'What\'s your baby\'s name?';

  @override
  String get onboardingFlowNameSubtitle =>
      'We\'ll personalize the app with their name';

  @override
  String get onboardingFlowNameHint => 'Baby\'s name';

  @override
  String get onboardingFlowNameUndecided => 'We haven\'t decided yet';

  @override
  String get onboardingFlowGenderTitle => 'Is it a boy or a girl?';

  @override
  String onboardingFlowGenderTitleNamed(String name) {
    return 'Is $name a boy or a girl?';
  }

  @override
  String get onboardingFlowGenderSubtitle =>
      'WHO growth curves are different for boys and girls';

  @override
  String get onboardingFlowBabyGeneric => 'the baby';

  @override
  String get onboardingFlowBabyGenericYour => 'your baby';

  @override
  String get onboardingFlowBabyDefaultName => 'Your baby';

  @override
  String onboardingFlowBirthTitle(String name) {
    return 'When was $name born?';
  }

  @override
  String onboardingFlowDueTitle(String name) {
    return 'When is $name\'s due date?';
  }

  @override
  String get onboardingFlowBirthSubtitle =>
      'We\'ll calculate age and percentiles';

  @override
  String onboardingFlowAgeHasMonthsDays(String name, int months, int days) {
    return '$name is $months months and $days days old';
  }

  @override
  String onboardingFlowAgeHasMonths(String name, int months) {
    return '$name is $months months old';
  }

  @override
  String onboardingFlowAgeHasDays(String name, int days) {
    return '$name is $days days old';
  }

  @override
  String onboardingFlowDueInDays(String name, int days) {
    return '$name will be born in $days days';
  }

  @override
  String onboardingFlowDueInOneDay(String name) {
    return '$name will be born in 1 day';
  }

  @override
  String onboardingFlowDueToday(String name) {
    return '$name is due today';
  }

  @override
  String get onboardingFlowMeasuresTitle => 'Latest checkup measurements';

  @override
  String get onboardingFlowMeasuresSubtitle =>
      'Optional — this helps us show the growth curve';

  @override
  String get onboardingFlowMeasuresLater => 'I\'ll add them later';

  @override
  String get onboardingFlowWeightLabel => 'Weight';

  @override
  String get onboardingFlowHeightLabel => 'Height';

  @override
  String get onboardingFlowWeightRangeHint =>
      'Check the weight: it\'s usually between 0.5 and 30 kg';

  @override
  String get onboardingFlowHeightRangeHint =>
      'Check the height: it\'s usually between 30 and 120 cm';

  @override
  String get onboardingFlowWeightUnitTitle => 'Weight unit';

  @override
  String get onboardingFlowHeightUnitTitle => 'Height unit';

  @override
  String get onboardingFlowHeightUnitCm => 'Centimeters (cm)';

  @override
  String get onboardingFlowHeightUnitIn => 'Inches (in)';

  @override
  String get onboardingFlowWeightUnitKg => 'Kilograms (kg)';

  @override
  String get onboardingFlowWeightUnitLb => 'Pounds (lb)';

  @override
  String get onboardingFlowPreparingTitle => 'Preparing your baby\'s data';

  @override
  String onboardingFlowCalcPercentiles(String name) {
    return 'Calculating WHO percentiles for $name';
  }

  @override
  String onboardingFlowCalcWhoCurve(int months) {
    return 'Calculating WHO curve for $months months';
  }

  @override
  String get onboardingFlowCalcFeeding => 'Calculating feeding rhythm';

  @override
  String get onboardingFlowCalcSleep => 'Calculating sleep routines';

  @override
  String get onboardingFlowCalcDueDate => 'Calculating due date';

  @override
  String get onboardingFlowCalcNewbornReady =>
      'Getting everything ready for birth';

  @override
  String get onboardingFlowCalcNewbornFeeding =>
      'Preparing newborn feeding rhythm';

  @override
  String get onboardingFlowCalcNewbornRoutines =>
      'Preparing newborn sleep routines';

  @override
  String onboardingFlowResultsTitle(String name) {
    return 'All set for $name';
  }

  @override
  String get onboardingFlowResultsSubtitle =>
      'Here\'s what we\'ve prepared for their age';

  @override
  String get onboardingFlowResultsSubtitlePregnant =>
      'Everything will be ready when they arrive';

  @override
  String onboardingFlowResultAgeLabel(String name) {
    return '$name\'s age';
  }

  @override
  String onboardingFlowResultAgeMonths(int months) {
    return '$months months';
  }

  @override
  String onboardingFlowResultAgeMonthsDays(int months, int days) {
    return '$months months and $days days';
  }

  @override
  String get onboardingFlowResultAgeOneDay => '1 day';

  @override
  String onboardingFlowResultAgeDays(int days) {
    return '$days days';
  }

  @override
  String get onboardingFlowResultAgeOneYear => '1 year';

  @override
  String onboardingFlowResultAgeYears(int years) {
    return '$years years';
  }

  @override
  String get onboardingFlowResultAgeOneYearHalf => '1½ years';

  @override
  String onboardingFlowResultAgeYearsHalf(int years) {
    return '$years½ years';
  }

  @override
  String get onboardingFlowResultDueHeroLabel => 'Due in';

  @override
  String onboardingFlowResultDueHeroDays(int days) {
    return '$days days';
  }

  @override
  String get onboardingFlowResultDueHeroOne => '1 day';

  @override
  String get onboardingFlowResultDueHeroToday => 'Today';

  @override
  String onboardingFlowResultDueDateCaption(String date) {
    return 'Due date: $date';
  }

  @override
  String get onboardingFlowResultGrowthTitle => 'WHO growth';

  @override
  String get onboardingFlowResultWeightPct => 'Weight';

  @override
  String get onboardingFlowResultHeightPct => 'Height';

  @override
  String get onboardingFlowResultNoWeight => 'No data';

  @override
  String get onboardingFlowResultNoHeight => 'No data';

  @override
  String get onboardingFlowResultNoWeightHeight =>
      'No weight or height yet. You can add them anytime.';

  @override
  String onboardingFlowResultWhoMedian(String weight, String height) {
    return 'WHO median at this age: $weight · $height';
  }

  @override
  String get onboardingFlowResultPercentileContext =>
      'P3 is within the reference range. What matters is the trend over time, not a single reading.';

  @override
  String get onboardingFlowResultMedicalDisclaimer =>
      'For guidance only, based on WHO curves. Not a substitute for your pediatrician\'s advice.';

  @override
  String get onboardingFlowResultFeedingTitle => 'Feeds';

  @override
  String get onboardingFlowResultMealsTitle => 'Meals';

  @override
  String onboardingFlowResultFeedingValue(String interval) {
    return 'Every $interval';
  }

  @override
  String get onboardingFlowResultFeedingMealsTransition => 'Meals + milk feeds';

  @override
  String get onboardingFlowResultFeedingMealsTransitionHint =>
      'Milk is combined with daytime meals';

  @override
  String get onboardingFlowResultFeedingMealsToddler => '3 meals and 2 snacks';

  @override
  String get onboardingFlowResultFeedingMealsToddlerHint =>
      'At this age feeding is no longer counted every X hours';

  @override
  String get onboardingFlowResultFeedingHint =>
      'We\'ll use this to remind you about the next feed';

  @override
  String get onboardingFlowResultFeedingPregnantHint =>
      'Typical newborn rhythm, ready from day one';

  @override
  String get onboardingFlowResultSleepTitle => 'Sleep';

  @override
  String onboardingFlowResultSleepWake(String range) {
    return 'Wake window: $range';
  }

  @override
  String onboardingFlowResultSleepTotal(String range) {
    return 'About $range of sleep a day';
  }

  @override
  String get onboardingFlowResultSleepPregnantHint =>
      'Short newborn wake windows, ready at birth';

  @override
  String get onboardingFlowResultWhoPregnant =>
      'WHO curves will activate when they are born';

  @override
  String onboardingFlowNotifyTitle(String name) {
    return 'Want to enable notifications so we can remind you about $name\'s next feed?';
  }

  @override
  String onboardingFlowNotifySubtitle(String interval) {
    return 'For their age we\'ve set a feed every $interval, which is typical, but you can customize it anytime in settings.';
  }

  @override
  String onboardingFlowNotifyTitleToddler(String name) {
    return 'Want to enable notifications for $name?';
  }

  @override
  String get onboardingFlowNotifySubtitleToddler =>
      'You can get app reminders. At this age feeding is no longer counted every X hours — customize anytime in settings.';

  @override
  String get onboardingFlowNotifyEnable => 'Enable notifications';

  @override
  String get onboardingFlowNotifyLater => 'Not now';

  @override
  String onboardingFlowSaveTitle(String name) {
    return 'Save $name\'s data';
  }

  @override
  String get onboardingFlowSaveSubtitle =>
      'Don\'t lose your data if you switch phones';

  @override
  String get onboardingFlowContinueApple => 'Continue with Apple';

  @override
  String get onboardingFlowContinueGoogle => 'Continue with Google';

  @override
  String get onboardingFlowContinueEmail => 'Continue with email';

  @override
  String get onboardingFlowDataSafe =>
      'Your baby\'s data is protected, encrypted, and never sold to third parties.';

  @override
  String get onboardingFlowQrNeedsConnection =>
      'A connection is required to join with QR';

  @override
  String get onboardingFlowQrOpenFail => 'Couldn\'t open the QR scanner';

  @override
  String onboardingFlowSaveFail(String error) {
    return 'Couldn\'t save the data: $error';
  }

  @override
  String get onboardingFlowProfileAlreadyExistsTitle =>
      'This account already has a profile';

  @override
  String get onboardingFlowProfileAlreadyExists =>
      'That email or account already has a profile. Use “I already have an account” to sign in, or try a different account so you don’t overwrite existing data.';

  @override
  String get onboardingFlowProfileAlreadyExistsButton => 'Got it';

  @override
  String get onboardingFlowAuthError => 'Authentication error';

  @override
  String get onboardingFlowSignInFail => 'Couldn\'t sign in';
}
