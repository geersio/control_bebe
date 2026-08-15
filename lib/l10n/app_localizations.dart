import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'MiBebé'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'INICIO'**
  String get navHome;

  /// No description provided for @navDiapers.
  ///
  /// In es, this message translates to:
  /// **'PAÑALES'**
  String get navDiapers;

  /// No description provided for @navFeeding.
  ///
  /// In es, this message translates to:
  /// **'TOMAS'**
  String get navFeeding;

  /// No description provided for @navSleep.
  ///
  /// In es, this message translates to:
  /// **'SUEÑO'**
  String get navSleep;

  /// No description provided for @navWeight.
  ///
  /// In es, this message translates to:
  /// **'CRECER'**
  String get navWeight;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get commonDone;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardado'**
  String get commonSaved;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @deleteRecordConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este registro?'**
  String get deleteRecordConfirmTitle;

  /// No description provided for @deleteRecordConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrará de forma permanente. Esta acción no se puede deshacer.'**
  String get deleteRecordConfirmBody;

  /// No description provided for @commonEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @commonDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get commonDate;

  /// No description provided for @commonTime.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get commonTime;

  /// No description provided for @commonDateTime.
  ///
  /// In es, this message translates to:
  /// **'Fecha y hora'**
  String get commonDateTime;

  /// No description provided for @commonTimeStart.
  ///
  /// In es, this message translates to:
  /// **'Hora inicio'**
  String get commonTimeStart;

  /// No description provided for @commonTimeEnd.
  ///
  /// In es, this message translates to:
  /// **'Hora fin'**
  String get commonTimeEnd;

  /// No description provided for @commonGenderBoy.
  ///
  /// In es, this message translates to:
  /// **'Niño'**
  String get commonGenderBoy;

  /// No description provided for @commonGenderGirl.
  ///
  /// In es, this message translates to:
  /// **'Niña'**
  String get commonGenderGirl;

  /// No description provided for @commonGenderUnspecified.
  ///
  /// In es, this message translates to:
  /// **'Prefiero no decirlo'**
  String get commonGenderUnspecified;

  /// No description provided for @commonSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get commonSend;

  /// No description provided for @commonNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get commonNext;

  /// No description provided for @commonExit.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get commonExit;

  /// No description provided for @historyTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get historyTitle;

  /// No description provided for @historyScrollLoadMore.
  ///
  /// In es, this message translates to:
  /// **'Desliza hasta el final para cargar tres días más de historial.'**
  String get historyScrollLoadMore;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get yesterday;

  /// No description provided for @timeSuffixMinute.
  ///
  /// In es, this message translates to:
  /// **'min'**
  String get timeSuffixMinute;

  /// No description provided for @timeSuffixHour.
  ///
  /// In es, this message translates to:
  /// **'h'**
  String get timeSuffixHour;

  /// No description provided for @timeSuffixSecond.
  ///
  /// In es, this message translates to:
  /// **'s'**
  String get timeSuffixSecond;

  /// No description provided for @timeHoursOnly.
  ///
  /// In es, this message translates to:
  /// **'{h}h'**
  String timeHoursOnly(Object h);

  /// No description provided for @timeHoursMinutes.
  ///
  /// In es, this message translates to:
  /// **'{h}h {m} min'**
  String timeHoursMinutes(Object h, Object m);

  /// No description provided for @timeMinutesOnly.
  ///
  /// In es, this message translates to:
  /// **'{m} min'**
  String timeMinutesOnly(Object m);

  /// No description provided for @durationMinutesSeconds.
  ///
  /// In es, this message translates to:
  /// **'{m}m {s}s'**
  String durationMinutesSeconds(Object m, Object s);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In es, this message translates to:
  /// **'{h}h {m}m'**
  String durationHoursMinutes(Object h, Object m);

  /// No description provided for @durationHoursMinutesSeconds.
  ///
  /// In es, this message translates to:
  /// **'{h}h {m}m {s}s'**
  String durationHoursMinutesSeconds(Object h, Object m, Object s);

  /// No description provided for @durationHoursOnly.
  ///
  /// In es, this message translates to:
  /// **'{h}h'**
  String durationHoursOnly(Object h);

  /// No description provided for @feedingIntervalHoursOne.
  ///
  /// In es, this message translates to:
  /// **'1 hora'**
  String get feedingIntervalHoursOne;

  /// No description provided for @feedingIntervalHoursN.
  ///
  /// In es, this message translates to:
  /// **'{n} horas'**
  String feedingIntervalHoursN(Object n);

  /// No description provided for @feedingIntervalHoursMinutes.
  ///
  /// In es, this message translates to:
  /// **'{h}h {m}min'**
  String feedingIntervalHoursMinutes(Object h, Object m);

  /// No description provided for @profileDefaultBabyName.
  ///
  /// In es, this message translates to:
  /// **'Bebé'**
  String get profileDefaultBabyName;

  /// No description provided for @sleepTitle.
  ///
  /// In es, this message translates to:
  /// **'Sueño'**
  String get sleepTitle;

  /// No description provided for @sleepBedtime.
  ///
  /// In es, this message translates to:
  /// **'Se acuesta'**
  String get sleepBedtime;

  /// No description provided for @sleepWake.
  ///
  /// In es, this message translates to:
  /// **'Se despierta'**
  String get sleepWake;

  /// No description provided for @sleepNightWakingsSection.
  ///
  /// In es, this message translates to:
  /// **'Despertares nocturnos'**
  String get sleepNightWakingsSection;

  /// No description provided for @sleepClockModeStart.
  ///
  /// In es, this message translates to:
  /// **'Inicio sueño'**
  String get sleepClockModeStart;

  /// No description provided for @sleepClockModeEnd.
  ///
  /// In es, this message translates to:
  /// **'Fin sueño'**
  String get sleepClockModeEnd;

  /// No description provided for @sleepClockModeNightWaking.
  ///
  /// In es, this message translates to:
  /// **'Despertar nocturno'**
  String get sleepClockModeNightWaking;

  /// No description provided for @sleepClockCenterStartLabel.
  ///
  /// In es, this message translates to:
  /// **'Hora de inicio'**
  String get sleepClockCenterStartLabel;

  /// No description provided for @sleepClockCenterEndLabel.
  ///
  /// In es, this message translates to:
  /// **'Hora de fin'**
  String get sleepClockCenterEndLabel;

  /// No description provided for @sleepClockCenterNightWakingLabel.
  ///
  /// In es, this message translates to:
  /// **'Duración del despertar'**
  String get sleepClockCenterNightWakingLabel;

  /// No description provided for @sleepDurationCenterMinutesOnly.
  ///
  /// In es, this message translates to:
  /// **'{m} MIN'**
  String sleepDurationCenterMinutesOnly(Object m);

  /// No description provided for @sleepTypeNight.
  ///
  /// In es, this message translates to:
  /// **'Sueño nocturno'**
  String get sleepTypeNight;

  /// No description provided for @sleepTypeNap.
  ///
  /// In es, this message translates to:
  /// **'Siesta'**
  String get sleepTypeNap;

  /// No description provided for @sleepTypeNapNumbered.
  ///
  /// In es, this message translates to:
  /// **'Siesta {number}'**
  String sleepTypeNapNumbered(int number);

  /// No description provided for @sleepRegisterButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar sueño'**
  String get sleepRegisterButton;

  /// No description provided for @sleepRegisterStartButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar inicio'**
  String get sleepRegisterStartButton;

  /// No description provided for @sleepRegisterEndButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar fin'**
  String get sleepRegisterEndButton;

  /// No description provided for @sleepRegisterNightWakingButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar despertar'**
  String get sleepRegisterNightWakingButton;

  /// No description provided for @sleepEndPending.
  ///
  /// In es, this message translates to:
  /// **'pendiente'**
  String get sleepEndPending;

  /// No description provided for @sleepKeepOpenLabel.
  ///
  /// In es, this message translates to:
  /// **'Sigue durmiendo'**
  String get sleepKeepOpenLabel;

  /// No description provided for @sleepNightWakingLabel.
  ///
  /// In es, this message translates to:
  /// **'Despertar nocturno'**
  String get sleepNightWakingLabel;

  /// No description provided for @sleepWakingsSummary.
  ///
  /// In es, this message translates to:
  /// **'{count} despertares · {minutes} min desvelo'**
  String sleepWakingsSummary(Object count, Object minutes);

  /// No description provided for @sleepWakingsSummaryOne.
  ///
  /// In es, this message translates to:
  /// **'1 despertar · {minutes} min desvelo'**
  String sleepWakingsSummaryOne(Object minutes);

  /// No description provided for @sleepNoOpenSessionToEnd.
  ///
  /// In es, this message translates to:
  /// **'No hay un sueño en curso. Guarda primero el inicio.'**
  String get sleepNoOpenSessionToEnd;

  /// No description provided for @sleepOpenSessionExists.
  ///
  /// In es, this message translates to:
  /// **'Ya hay un sueño en curso. Guarda el fin o edítalo en el historial.'**
  String get sleepOpenSessionExists;

  /// No description provided for @homeSleepInsightSleepingLabel.
  ///
  /// In es, this message translates to:
  /// **'Durmiendo...'**
  String get homeSleepInsightSleepingLabel;

  /// No description provided for @homeSleepInsightSleepingSince.
  ///
  /// In es, this message translates to:
  /// **'desde {time}'**
  String homeSleepInsightSleepingSince(Object time);

  /// No description provided for @homeSleepInsightSleepingValue.
  ///
  /// In es, this message translates to:
  /// **'{duration} · desde {time}'**
  String homeSleepInsightSleepingValue(Object duration, Object time);

  /// No description provided for @sleepStatusAwake.
  ///
  /// In es, this message translates to:
  /// **'Despierto'**
  String get sleepStatusAwake;

  /// No description provided for @sleepStatusSleeping.
  ///
  /// In es, this message translates to:
  /// **'Durmiendo'**
  String get sleepStatusSleeping;

  /// No description provided for @sleepActionFellAsleep.
  ///
  /// In es, this message translates to:
  /// **'Se durmió'**
  String get sleepActionFellAsleep;

  /// No description provided for @sleepActionWokeUp.
  ///
  /// In es, this message translates to:
  /// **'Se despertó'**
  String get sleepActionWokeUp;

  /// No description provided for @sleepFellAsleepAt.
  ///
  /// In es, this message translates to:
  /// **'Se durmió a las {time}'**
  String sleepFellAsleepAt(Object time);

  /// No description provided for @sleepWokeUpAt.
  ///
  /// In es, this message translates to:
  /// **'Se despertó a las {time}'**
  String sleepWokeUpAt(Object time);

  /// No description provided for @sleepSavesWithCurrentTime.
  ///
  /// In es, this message translates to:
  /// **'se guarda con la hora actual · {time}'**
  String sleepSavesWithCurrentTime(Object time);

  /// No description provided for @sleepAddNightWaking.
  ///
  /// In es, this message translates to:
  /// **'Añadir despertar nocturno'**
  String get sleepAddNightWaking;

  /// No description provided for @sleepRegisterPastSleep.
  ///
  /// In es, this message translates to:
  /// **'Añadir sueño anterior'**
  String get sleepRegisterPastSleep;

  /// No description provided for @sleepFellAsleepCaps.
  ///
  /// In es, this message translates to:
  /// **'SE DURMIÓ'**
  String get sleepFellAsleepCaps;

  /// No description provided for @sleepWokeUpCaps.
  ///
  /// In es, this message translates to:
  /// **'SE DESPERTÓ'**
  String get sleepWokeUpCaps;

  /// No description provided for @sleepSleptPrefix.
  ///
  /// In es, this message translates to:
  /// **'Durmió'**
  String get sleepSleptPrefix;

  /// No description provided for @sleepAwakePrefix.
  ///
  /// In es, this message translates to:
  /// **'Despierto'**
  String get sleepAwakePrefix;

  /// No description provided for @sleepPastRegister.
  ///
  /// In es, this message translates to:
  /// **'Registrar'**
  String get sleepPastRegister;

  /// No description provided for @sleepHistoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay registros. Pulsa «Se durmió» arriba para añadir el primero.'**
  String get sleepHistoryEmpty;

  /// No description provided for @sleepStreamError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los registros de sueño. Reintenta o comprueba la conexión.'**
  String get sleepStreamError;

  /// No description provided for @sleepEditRecord.
  ///
  /// In es, this message translates to:
  /// **'Editar sueño'**
  String get sleepEditRecord;

  /// No description provided for @sleepSessionCountOne.
  ///
  /// In es, this message translates to:
  /// **'1 sueño'**
  String get sleepSessionCountOne;

  /// No description provided for @sleepSessionCountN.
  ///
  /// In es, this message translates to:
  /// **'{n} sueños'**
  String sleepSessionCountN(Object n);

  /// No description provided for @sleepDurationCenter.
  ///
  /// In es, this message translates to:
  /// **'{h} HR {m} MIN'**
  String sleepDurationCenter(Object h, Object m);

  /// No description provided for @sleepDurationCenterHoursOnly.
  ///
  /// In es, this message translates to:
  /// **'{h} HR'**
  String sleepDurationCenterHoursOnly(Object h);

  /// No description provided for @profileWeightLabel.
  ///
  /// In es, this message translates to:
  /// **'PESO'**
  String get profileWeightLabel;

  /// No description provided for @profileHeightLabel.
  ///
  /// In es, this message translates to:
  /// **'ALTURA'**
  String get profileHeightLabel;

  /// No description provided for @babyAgeMonthsOneDaysOne.
  ///
  /// In es, this message translates to:
  /// **'1 MES, 1 DÍA'**
  String get babyAgeMonthsOneDaysOne;

  /// No description provided for @babyAgeMonthsOneDaysN.
  ///
  /// In es, this message translates to:
  /// **'1 MES, {days} DÍAS'**
  String babyAgeMonthsOneDaysN(Object days);

  /// No description provided for @babyAgeMonthsNDaysOne.
  ///
  /// In es, this message translates to:
  /// **'{months} MESES, 1 DÍA'**
  String babyAgeMonthsNDaysOne(Object months);

  /// No description provided for @babyAgeMonthsNDaysN.
  ///
  /// In es, this message translates to:
  /// **'{months} MESES, {days} DÍAS'**
  String babyAgeMonthsNDaysN(Object days, Object months);

  /// No description provided for @monthiversaryOne.
  ///
  /// In es, this message translates to:
  /// **'¡Hoy cumple 1 mes!'**
  String get monthiversaryOne;

  /// No description provided for @monthiversaryN.
  ///
  /// In es, this message translates to:
  /// **'¡Hoy cumple {months} meses!'**
  String monthiversaryN(Object months);

  /// No description provided for @monthiversarySemanticsHint.
  ///
  /// In es, this message translates to:
  /// **'Pulsa para confeti; hasta dos veces hasta que termine'**
  String get monthiversarySemanticsHint;

  /// No description provided for @homeSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen de hoy'**
  String get homeSummaryTitle;

  /// No description provided for @homeLastFeedLabel.
  ///
  /// In es, this message translates to:
  /// **'ÚLTIMA TOMA'**
  String get homeLastFeedLabel;

  /// No description provided for @homeLastFeedAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {time}'**
  String homeLastFeedAgo(Object time);

  /// No description provided for @homeNextFeedSoon.
  ///
  /// In es, this message translates to:
  /// **'Próxima toma pronto'**
  String get homeNextFeedSoon;

  /// No description provided for @homeNextFeedIn.
  ///
  /// In es, this message translates to:
  /// **'Próxima toma en {time}'**
  String homeNextFeedIn(Object time);

  /// No description provided for @homeNoFeedingsYet.
  ///
  /// In es, this message translates to:
  /// **'Sin tomas registradas aún. Toca para anotar la primera.'**
  String get homeNoFeedingsYet;

  /// No description provided for @homeWeightNoRecords.
  ///
  /// In es, this message translates to:
  /// **'No hay registros de peso. Toca para añadir el primero.'**
  String get homeWeightNoRecords;

  /// No description provided for @homeWeightTrendGramsPerDay.
  ///
  /// In es, this message translates to:
  /// **'{sign}{value} g/día'**
  String homeWeightTrendGramsPerDay(Object sign, Object value);

  /// No description provided for @homeWeightTrendOuncesPerDay.
  ///
  /// In es, this message translates to:
  /// **'{sign}{value} oz/día'**
  String homeWeightTrendOuncesPerDay(Object sign, Object value);

  /// No description provided for @homeHeightTrendCmPerDay.
  ///
  /// In es, this message translates to:
  /// **'{sign}{value} cm/día'**
  String homeHeightTrendCmPerDay(Object sign, Object value);

  /// No description provided for @homeWeightLast.
  ///
  /// In es, this message translates to:
  /// **'Último: {date}'**
  String homeWeightLast(Object date);

  /// No description provided for @homeSleepPattern.
  ///
  /// In es, this message translates to:
  /// **'{nights, plural, =0{0 nocturnos} one{1 nocturno} other{{nights} nocturnos}} · {naps, plural, =0{0 siestas} one{1 siesta} other{{naps} siestas}}'**
  String homeSleepPattern(int nights, int naps);

  /// No description provided for @homeDiapersNoRecords.
  ///
  /// In es, this message translates to:
  /// **'No hay pañales registrados. Toca para añadir el primero.'**
  String get homeDiapersNoRecords;

  /// No description provided for @homeDiapersWetDirty.
  ///
  /// In es, this message translates to:
  /// **'{wet} mojados · {dirty} sucios'**
  String homeDiapersWetDirty(Object dirty, Object wet);

  /// No description provided for @homeDiaperChangesOne.
  ///
  /// In es, this message translates to:
  /// **'1 cambio'**
  String get homeDiaperChangesOne;

  /// No description provided for @homeDiaperChangesN.
  ///
  /// In es, this message translates to:
  /// **'{n} cambios'**
  String homeDiaperChangesN(Object n);

  /// No description provided for @homeInsightsTitle.
  ///
  /// In es, this message translates to:
  /// **'Análisis'**
  String get homeInsightsTitle;

  /// No description provided for @homeFeedingDistributionTitle.
  ///
  /// In es, this message translates to:
  /// **'Distribución de tomas'**
  String get homeFeedingDistributionTitle;

  /// No description provided for @homeFeedingDistributionSevenDayAverage.
  ///
  /// In es, this message translates to:
  /// **'≈ Media de los últimos 7 días'**
  String get homeFeedingDistributionSevenDayAverage;

  /// No description provided for @homeFeedingDistributionInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo se calcula la distribución'**
  String get homeFeedingDistributionInfoTitle;

  /// No description provided for @homeFeedingDistributionInfoBody.
  ///
  /// In es, this message translates to:
  /// **'El gráfico muestra la proporción media de pecho, biberón y sólidos registrada durante los últimos 7 días.\n\nPara poder comparar los tipos de toma, los minutos de pecho se convierten en un equivalente aproximado en ml. Esta conversión es orientativa y no representa una medición exacta de la leche ingerida.'**
  String get homeFeedingDistributionInfoBody;

  /// No description provided for @homeFeedingDistributionMlPerDay.
  ///
  /// In es, this message translates to:
  /// **'ml/día'**
  String get homeFeedingDistributionMlPerDay;

  /// No description provided for @homeDiaperSpendInsightTitle.
  ///
  /// In es, this message translates to:
  /// **'Pañales y gasto'**
  String get homeDiaperSpendInsightTitle;

  /// No description provided for @homeDiaperSpendInsightDiapersPerDay.
  ///
  /// In es, this message translates to:
  /// **'pañales/día'**
  String get homeDiaperSpendInsightDiapersPerDay;

  /// No description provided for @homeDiaperSpendInsightWeekDelta.
  ///
  /// In es, this message translates to:
  /// **'{delta} vs semana anterior'**
  String homeDiaperSpendInsightWeekDelta(String delta);

  /// No description provided for @homeDiaperSpendInsightMoreBadge.
  ///
  /// In es, this message translates to:
  /// **'Más que la semana anterior'**
  String get homeDiaperSpendInsightMoreBadge;

  /// No description provided for @homeDiaperSpendInsightLessBadge.
  ///
  /// In es, this message translates to:
  /// **'Menos que la semana anterior'**
  String get homeDiaperSpendInsightLessBadge;

  /// No description provided for @homeDiaperSpendInsightSameBadge.
  ///
  /// In es, this message translates to:
  /// **'Igual que la semana anterior'**
  String get homeDiaperSpendInsightSameBadge;

  /// No description provided for @homeDiaperSpendInsightPerDay.
  ///
  /// In es, this message translates to:
  /// **'Al día'**
  String get homeDiaperSpendInsightPerDay;

  /// No description provided for @homeDiaperSpendInsightPerMonth.
  ///
  /// In es, this message translates to:
  /// **'Al mes'**
  String get homeDiaperSpendInsightPerMonth;

  /// No description provided for @homeDiaperSpendInsightMore.
  ///
  /// In es, this message translates to:
  /// **'{name} está gastando de media {average} pañales diarios. Más de los que gastó la semana anterior. Eso equivale aproximadamente a {cost} al día y {monthlyCost} al mes.'**
  String homeDiaperSpendInsightMore(
    String name,
    String average,
    String cost,
    String monthlyCost,
  );

  /// No description provided for @homeDiaperSpendInsightLess.
  ///
  /// In es, this message translates to:
  /// **'{name} está gastando de media {average} pañales diarios. Menos de los que gastó la semana anterior. Eso equivale aproximadamente a {cost} al día y {monthlyCost} al mes.'**
  String homeDiaperSpendInsightLess(
    String name,
    String average,
    String cost,
    String monthlyCost,
  );

  /// No description provided for @homeDiaperSpendInsightSame.
  ///
  /// In es, this message translates to:
  /// **'{name} está gastando de media {average} pañales diarios. Igual que la semana anterior. Eso equivale aproximadamente a {cost} al día y {monthlyCost} al mes.'**
  String homeDiaperSpendInsightSame(
    String name,
    String average,
    String cost,
    String monthlyCost,
  );

  /// No description provided for @homeDiaperSpendInsightNoData.
  ///
  /// In es, this message translates to:
  /// **'Registra pañales durante unos días para ver la media y el gasto estimado.'**
  String get homeDiaperSpendInsightNoData;

  /// No description provided for @homeDiaperSpendInsightAddFirst.
  ///
  /// In es, this message translates to:
  /// **'Añade el primer pañal de tu bebé'**
  String get homeDiaperSpendInsightAddFirst;

  /// No description provided for @homeDiaperSpendInsightInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Cálculo aproximado'**
  String get homeDiaperSpendInsightInfoTitle;

  /// No description provided for @homeDiaperSpendInsightInfoBody.
  ///
  /// In es, this message translates to:
  /// **'El gasto se estima usando un precio medio de {price} por pañal. Los pañales/día son la media de los últimos 7 días calendario (total de cambios ÷ 7). La etiqueta muestra la diferencia respecto a la media de los 7 días anteriores. El gasto mensual proyecta esa media a 30 días.'**
  String homeDiaperSpendInsightInfoBody(String price);

  /// No description provided for @homeSleepInsightTitle.
  ///
  /// In es, this message translates to:
  /// **'Análisis del sueño'**
  String get homeSleepInsightTitle;

  /// No description provided for @homeTodaysSleepTitle.
  ///
  /// In es, this message translates to:
  /// **'Sueño de hoy'**
  String get homeTodaysSleepTitle;

  /// No description provided for @homeSleepInsightNextSleepLabel.
  ///
  /// In es, this message translates to:
  /// **'Próxima hora de sueño'**
  String get homeSleepInsightNextSleepLabel;

  /// No description provided for @homeSleepInsightAddFirstSleep.
  ///
  /// In es, this message translates to:
  /// **'Añade el primer sueño de tu bebé'**
  String get homeSleepInsightAddFirstSleep;

  /// No description provided for @homeSleepInsightBedtimeLabel.
  ///
  /// In es, this message translates to:
  /// **'Próxima hora de acostarse'**
  String get homeSleepInsightBedtimeLabel;

  /// No description provided for @homeSleepInsightNextSleepRelative.
  ///
  /// In es, this message translates to:
  /// **'En {duration}'**
  String homeSleepInsightNextSleepRelative(String duration);

  /// No description provided for @homeSleepInsightNextSleepRelativePast.
  ///
  /// In es, this message translates to:
  /// **'Hace {duration}'**
  String homeSleepInsightNextSleepRelativePast(String duration);

  /// No description provided for @homeSleepInsightNextSleepValue.
  ///
  /// In es, this message translates to:
  /// **'{relative} · {window}'**
  String homeSleepInsightNextSleepValue(String relative, String window);

  /// No description provided for @homeSleepInsightEstimatedWindow.
  ///
  /// In es, this message translates to:
  /// **'Franja estimada · {window}'**
  String homeSleepInsightEstimatedWindow(String window);

  /// No description provided for @homeSleepInsightReasonShortNap.
  ///
  /// In es, this message translates to:
  /// **'Ventana acortada {minutes} min por siesta corta anterior'**
  String homeSleepInsightReasonShortNap(int minutes);

  /// No description provided for @homeSleepInsightReasonBedtime.
  ///
  /// In es, this message translates to:
  /// **'Ventana de acostarse por la noche'**
  String get homeSleepInsightReasonBedtime;

  /// No description provided for @homeSleepInsightReasonCatnap.
  ///
  /// In es, this message translates to:
  /// **'Siesta puente: ventanas del día agotadas'**
  String get homeSleepInsightReasonCatnap;

  /// No description provided for @homeSleepInsightReasonEarlyBedtime.
  ///
  /// In es, this message translates to:
  /// **'Acostarse temprano: ventanas del día agotadas'**
  String get homeSleepInsightReasonEarlyBedtime;

  /// No description provided for @homeSleepInsightReasonDefaultWake.
  ///
  /// In es, this message translates to:
  /// **'Sin registros hoy: se asume despertar a las {time}'**
  String homeSleepInsightReasonDefaultWake(String time);

  /// No description provided for @homeSleepInsightUsualAwakeBeforeNap.
  ///
  /// In es, this message translates to:
  /// **'{name} suele aguantar despierto {duration} antes de esta siesta.'**
  String homeSleepInsightUsualAwakeBeforeNap(String name, String duration);

  /// No description provided for @homeSleepInsightUsualAwakeBeforeBedtime.
  ///
  /// In es, this message translates to:
  /// **'{name} suele aguantar despierto {duration} antes de acostarse.'**
  String homeSleepInsightUsualAwakeBeforeBedtime(String name, String duration);

  /// No description provided for @homeSleepInsightAwakeNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora mismo lleva despierto {duration}.'**
  String homeSleepInsightAwakeNow(String duration);

  /// No description provided for @homeSleepInsightPersonalizedHint.
  ///
  /// In es, this message translates to:
  /// **'Ajustado con el ritmo de tu bebé'**
  String get homeSleepInsightPersonalizedHint;

  /// No description provided for @homeSleepInsightNoBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Añade la fecha de nacimiento en Ajustes para estimar el próximo sueño.'**
  String get homeSleepInsightNoBirthDate;

  /// No description provided for @homeSleepInsightTodaySoFar.
  ///
  /// In es, this message translates to:
  /// **'lleva hoy'**
  String get homeSleepInsightTodaySoFar;

  /// No description provided for @homeSleepInsightUsuallySleeps.
  ///
  /// In es, this message translates to:
  /// **'Media de sueño diario'**
  String get homeSleepInsightUsuallySleeps;

  /// No description provided for @homeSleepInsightLast7Days.
  ///
  /// In es, this message translates to:
  /// **'ÚLTIMOS 7 DÍAS'**
  String get homeSleepInsightLast7Days;

  /// No description provided for @homeSleepInsightAveragePrefix.
  ///
  /// In es, this message translates to:
  /// **'media'**
  String get homeSleepInsightAveragePrefix;

  /// No description provided for @homeSleepInsightChartToday.
  ///
  /// In es, this message translates to:
  /// **'hoy'**
  String get homeSleepInsightChartToday;

  /// No description provided for @homeSleepInsightDayTimelineToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get homeSleepInsightDayTimelineToday;

  /// No description provided for @homeSleepInsightDayTimelineTotal.
  ///
  /// In es, this message translates to:
  /// **'{duration} en total'**
  String homeSleepInsightDayTimelineTotal(String duration);

  /// No description provided for @homeSleepInsightBarNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin registros'**
  String get homeSleepInsightBarNoData;

  /// No description provided for @homeSleepSlotMorningNap.
  ///
  /// In es, this message translates to:
  /// **'Siesta de mañana'**
  String get homeSleepSlotMorningNap;

  /// No description provided for @homeSleepSlotMiddayNap.
  ///
  /// In es, this message translates to:
  /// **'Siesta de mediodía'**
  String get homeSleepSlotMiddayNap;

  /// No description provided for @homeSleepSlotAfternoonNap.
  ///
  /// In es, this message translates to:
  /// **'Siesta de tarde'**
  String get homeSleepSlotAfternoonNap;

  /// No description provided for @homeSleepSlotCatnap.
  ///
  /// In es, this message translates to:
  /// **'Siesta puente'**
  String get homeSleepSlotCatnap;

  /// No description provided for @homeSleepSlotNightSleep.
  ///
  /// In es, this message translates to:
  /// **'Sueño nocturno'**
  String get homeSleepSlotNightSleep;

  /// No description provided for @homeSleepDurationLabel.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get homeSleepDurationLabel;

  /// No description provided for @homeSleepPatternHeaderLast14.
  ///
  /// In es, this message translates to:
  /// **'Horarios habituales (últimos 14 días)'**
  String get homeSleepPatternHeaderLast14;

  /// No description provided for @homeSleepSlotFrequencyCount.
  ///
  /// In es, this message translates to:
  /// **'{count} de {total}'**
  String homeSleepSlotFrequencyCount(int count, int total);

  /// No description provided for @homeSleepPhraseWaiting.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay datos suficientes'**
  String get homeSleepPhraseWaiting;

  /// No description provided for @homeSleepPhraseFreqWithTime.
  ///
  /// In es, this message translates to:
  /// **'{days} de los últimos {total} días, sobre las {time}'**
  String homeSleepPhraseFreqWithTime(int days, int total, String time);

  /// No description provided for @homeSleepPhraseFreqOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo {days} de los últimos {total} días'**
  String homeSleepPhraseFreqOnly(int days, int total);

  /// No description provided for @homeSleepPhraseFreqPill.
  ///
  /// In es, this message translates to:
  /// **'Solo {days} de los últimos {total} días'**
  String homeSleepPhraseFreqPill(int days, int total);

  /// No description provided for @homeSleepPhraseTrendFewerDays.
  ///
  /// In es, this message translates to:
  /// **'Ocurre menos días que la semana pasada'**
  String get homeSleepPhraseTrendFewerDays;

  /// No description provided for @homeSleepPhraseTrendStartsLater.
  ///
  /// In es, this message translates to:
  /// **'Empieza unos {minutes} min más tarde que la semana pasada'**
  String homeSleepPhraseTrendStartsLater(int minutes);

  /// No description provided for @homeSleepPhraseTrendShorter.
  ///
  /// In es, this message translates to:
  /// **'Dura menos que la semana pasada'**
  String get homeSleepPhraseTrendShorter;

  /// No description provided for @homeSleepPhraseAlmostAlways.
  ///
  /// In es, this message translates to:
  /// **'Casi siempre sobre las {time}'**
  String homeSleepPhraseAlmostAlways(String time);

  /// No description provided for @homeSleepPhraseUsuallyBetween.
  ///
  /// In es, this message translates to:
  /// **'Suele empezar entre {start} y {end}'**
  String homeSleepPhraseUsuallyBetween(String start, String end);

  /// No description provided for @homeSleepPhraseMayBetween.
  ///
  /// In es, this message translates to:
  /// **'Puede empezar entre {start} y {end}'**
  String homeSleepPhraseMayBetween(String start, String end);

  /// No description provided for @homeSleepAbandonedNap.
  ///
  /// In es, this message translates to:
  /// **'{name} dejó esta siesta hace dos semanas'**
  String homeSleepAbandonedNap(String name);

  /// No description provided for @homeSleepInsightNoData.
  ///
  /// In es, this message translates to:
  /// **'Registra sueños durante unos días para ver el análisis.'**
  String get homeSleepInsightNoData;

  /// No description provided for @homeSleepInsightInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Sobre este análisis'**
  String get homeSleepInsightInfoTitle;

  /// No description provided for @homeSleepInsightInfoIntro.
  ///
  /// In es, this message translates to:
  /// **'Estimación orientativa, no una hora exacta ni consejo médico.'**
  String get homeSleepInsightInfoIntro;

  /// No description provided for @homeSleepInsightInfoPredictTitle.
  ///
  /// In es, this message translates to:
  /// **'Próximo sueño'**
  String get homeSleepInsightInfoPredictTitle;

  /// No description provided for @homeSleepInsightInfoPredictBody.
  ///
  /// In es, this message translates to:
  /// **'Parte del último despertar (fin de siesta o de noche) y suma una ventana de vigilia según la edad y tu historial reciente. El rango horario refleja esa variabilidad.\n\nSi hay un sueño en curso, verás «Durmiendo...» en lugar de la predicción.'**
  String get homeSleepInsightInfoPredictBody;

  /// No description provided for @homeSleepInsightInfoLoggingTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo registrar'**
  String get homeSleepInsightInfoLoggingTitle;

  /// No description provided for @homeSleepInsightInfoLoggingBody.
  ///
  /// In es, this message translates to:
  /// **'Marca inicio y fin del sueño. Siesta o nocturno se detectan solos.\n\nSi se despierta de madrugada y vuelve a dormir, usa «Despertar nocturno» (no otra siesta).'**
  String get homeSleepInsightInfoLoggingBody;

  /// No description provided for @homeSleepInsightInfoMetricsTitle.
  ///
  /// In es, this message translates to:
  /// **'Totales'**
  String get homeSleepInsightInfoMetricsTitle;

  /// No description provided for @homeSleepInsightInfoMetricsBody.
  ///
  /// In es, this message translates to:
  /// **'«Últimos 7 días» es la media solo de los días con registros (si un día no tiene datos, no cuenta como 0). La barra de hoy usa rayas.'**
  String get homeSleepInsightInfoMetricsBody;

  /// No description provided for @homeSleepInsightInfoScheduleTitle.
  ///
  /// In es, this message translates to:
  /// **'Horarios habituales'**
  String get homeSleepInsightInfoScheduleTitle;

  /// No description provided for @homeSleepInsightInfoScheduleBody.
  ///
  /// In es, this message translates to:
  /// **'Las horas de cada siesta y del nocturno son la mediana de los últimos 14 días, redondeadas a múltiplos de 5 minutos.\n\nLa pastilla junto al nombre indica en cuántos de esos 14 días hizo esa siesta (por ejemplo, 5 de 14).'**
  String get homeSleepInsightInfoScheduleBody;

  /// No description provided for @homeTipTitle.
  ///
  /// In es, this message translates to:
  /// **'Consejo del día'**
  String get homeTipTitle;

  /// No description provided for @homeTipFallback.
  ///
  /// In es, this message translates to:
  /// **'Los bebés pueden reconocer la voz de su madre desde el útero. Hablarles con calma refuerza ese vínculo.'**
  String get homeTipFallback;

  /// No description provided for @homeFeedingTrendTitle.
  ///
  /// In es, this message translates to:
  /// **'SEGUIMIENTO ALIMENTACIÓN HOY'**
  String get homeFeedingTrendTitle;

  /// No description provided for @homeFeedingTrendLearningDays.
  ///
  /// In es, this message translates to:
  /// **'{current}/{required} días'**
  String homeFeedingTrendLearningDays(int current, int required);

  /// No description provided for @homeFeedingTrendStatusLearning.
  ///
  /// In es, this message translates to:
  /// **'Aprendiendo...'**
  String get homeFeedingTrendStatusLearning;

  /// No description provided for @homeFeedingTrendStatusBelow.
  ///
  /// In es, this message translates to:
  /// **'{name} está comiendo por debajo de lo habitual a esta hora'**
  String homeFeedingTrendStatusBelow(String name);

  /// No description provided for @homeFeedingTrendStatusUsual.
  ///
  /// In es, this message translates to:
  /// **'{name} está comiendo lo habitual a esta hora'**
  String homeFeedingTrendStatusUsual(String name);

  /// No description provided for @homeFeedingTrendStatusAbove.
  ///
  /// In es, this message translates to:
  /// **'{name} está comiendo por encima de lo habitual a esta hora'**
  String homeFeedingTrendStatusAbove(String name);

  /// No description provided for @homeFeedingTrendStatusPhraseBelow.
  ///
  /// In es, this message translates to:
  /// **' está comiendo por debajo de lo habitual a esta hora'**
  String get homeFeedingTrendStatusPhraseBelow;

  /// No description provided for @homeFeedingTrendStatusPhraseUsual.
  ///
  /// In es, this message translates to:
  /// **' está comiendo lo habitual a esta hora'**
  String get homeFeedingTrendStatusPhraseUsual;

  /// No description provided for @homeFeedingTrendStatusPhraseAbove.
  ///
  /// In es, this message translates to:
  /// **' está comiendo por encima de lo habitual a esta hora'**
  String get homeFeedingTrendStatusPhraseAbove;

  /// No description provided for @homeFeedingTrendHintBelow.
  ///
  /// In es, this message translates to:
  /// **'Por debajo'**
  String get homeFeedingTrendHintBelow;

  /// No description provided for @homeFeedingTrendHintLearning.
  ///
  /// In es, this message translates to:
  /// **'aprendiendo'**
  String get homeFeedingTrendHintLearning;

  /// No description provided for @homeFeedingTrendHintUsual.
  ///
  /// In es, this message translates to:
  /// **'lo habitual'**
  String get homeFeedingTrendHintUsual;

  /// No description provided for @homeFeedingTrendHintAbove.
  ///
  /// In es, this message translates to:
  /// **'Por encima'**
  String get homeFeedingTrendHintAbove;

  /// No description provided for @homeFeedingTrendTodayTotal.
  ///
  /// In es, this message translates to:
  /// **'lleva hoy'**
  String get homeFeedingTrendTodayTotal;

  /// No description provided for @homeFeedingTrendUsuallyStill.
  ///
  /// In es, this message translates to:
  /// **'suele tomar aún'**
  String get homeFeedingTrendUsuallyStill;

  /// No description provided for @homeFeedingTrendInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo funciona este seguimiento'**
  String get homeFeedingTrendInfoTitle;

  /// No description provided for @homeFeedingTrendInfoBody.
  ///
  /// In es, this message translates to:
  /// **'Tomamos como referencia los últimos 14 días de tomas (biberón y pecho; los sólidos no entran). Hace falta al menos 2 días con tomas para dejar de “aprender” y poder comparar.\n\nA esta hora del día, comparamos lo que lleva hoy con el rango habitual de esos días: por debajo, lo habitual o por encima.\n\n“Suele tomar aún” es una estimación: la mediana de lo que suele acumular al final del día menos lo que ya lleva hoy.\n\nEl pecho no se mide en ml como un biberón, así que convertimos los minutos en un equivalente aproximado. Son cifras orientativas, no medidas exactas. Ante cualquier duda, consulta con tu pediatra.'**
  String get homeFeedingTrendInfoBody;

  /// No description provided for @homeFeedingTrendInfoButton.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get homeFeedingTrendInfoButton;

  /// No description provided for @sabiasQueNoBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Añade la fecha de nacimiento del bebé en ajustes para ver consejos según su edad.'**
  String get sabiasQueNoBirthDate;

  /// No description provided for @homeConfigureProfileFirst.
  ///
  /// In es, this message translates to:
  /// **'Configura primero el perfil del bebé en Ajustes'**
  String get homeConfigureProfileFirst;

  /// No description provided for @homePickPhoto.
  ///
  /// In es, this message translates to:
  /// **'Elegir foto'**
  String get homePickPhoto;

  /// No description provided for @homeRemovePhoto.
  ///
  /// In es, this message translates to:
  /// **'Quitar foto del perfil'**
  String get homeRemovePhoto;

  /// No description provided for @homePhotoRemoved.
  ///
  /// In es, this message translates to:
  /// **'Foto del perfil eliminada'**
  String get homePhotoRemoved;

  /// No description provided for @homePhotoRemoveError.
  ///
  /// In es, this message translates to:
  /// **'Error al quitar la foto: {error}'**
  String homePhotoRemoveError(Object error);

  /// No description provided for @homePhotoUpdated.
  ///
  /// In es, this message translates to:
  /// **'Foto actualizada'**
  String get homePhotoUpdated;

  /// No description provided for @homePhotoUploadError.
  ///
  /// In es, this message translates to:
  /// **'Error al subir la foto: {error}'**
  String homePhotoUploadError(Object error);

  /// No description provided for @feedingTitle.
  ///
  /// In es, this message translates to:
  /// **'Alimentación'**
  String get feedingTitle;

  /// No description provided for @feedingSessionType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de toma'**
  String get feedingSessionType;

  /// No description provided for @feedingBreast.
  ///
  /// In es, this message translates to:
  /// **'Pecho'**
  String get feedingBreast;

  /// No description provided for @feedingLeft.
  ///
  /// In es, this message translates to:
  /// **'Izquierdo'**
  String get feedingLeft;

  /// No description provided for @feedingRight.
  ///
  /// In es, this message translates to:
  /// **'Derecho'**
  String get feedingRight;

  /// No description provided for @feedingBottle.
  ///
  /// In es, this message translates to:
  /// **'Biberón'**
  String get feedingBottle;

  /// No description provided for @feedingSolidFood.
  ///
  /// In es, this message translates to:
  /// **'Sólidos'**
  String get feedingSolidFood;

  /// No description provided for @solidFoodTitle.
  ///
  /// In es, this message translates to:
  /// **'Alimento sólido'**
  String get solidFoodTitle;

  /// No description provided for @solidFoodNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Qué ha comido'**
  String get solidFoodNameLabel;

  /// No description provided for @solidFoodNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: puré de manzana'**
  String get solidFoodNameHint;

  /// No description provided for @solidFoodQuantityLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get solidFoodQuantityLabel;

  /// No description provided for @solidFoodUnitGrams.
  ///
  /// In es, this message translates to:
  /// **'g (gramos)'**
  String get solidFoodUnitGrams;

  /// No description provided for @solidFoodUnitUnits.
  ///
  /// In es, this message translates to:
  /// **'u (unidades)'**
  String get solidFoodUnitUnits;

  /// No description provided for @solidFoodUnitGramShort.
  ///
  /// In es, this message translates to:
  /// **'g'**
  String get solidFoodUnitGramShort;

  /// No description provided for @solidFoodUnitUnitsShort.
  ///
  /// In es, this message translates to:
  /// **'u'**
  String get solidFoodUnitUnitsShort;

  /// No description provided for @solidFoodQuantityHintGrams.
  ///
  /// In es, this message translates to:
  /// **'Ej: 40 o 0,47 (coma o punto)'**
  String get solidFoodQuantityHintGrams;

  /// No description provided for @solidFoodQuantityHintUnits.
  ///
  /// In es, this message translates to:
  /// **'Solo número entero, ej: 2'**
  String get solidFoodQuantityHintUnits;

  /// No description provided for @solidFoodValidatorNameEmpty.
  ///
  /// In es, this message translates to:
  /// **'Indica qué ha comido'**
  String get solidFoodValidatorNameEmpty;

  /// No description provided for @solidFoodValidatorQuantityEmpty.
  ///
  /// In es, this message translates to:
  /// **'Indica la cantidad'**
  String get solidFoodValidatorQuantityEmpty;

  /// No description provided for @solidFoodValidatorQuantityInvalid.
  ///
  /// In es, this message translates to:
  /// **'Número entero entre 1 y {max}'**
  String solidFoodValidatorQuantityInvalid(Object max);

  /// No description provided for @solidFoodValidatorQuantityParse.
  ///
  /// In es, this message translates to:
  /// **'Formato no válido: solo números y una coma o punto decimal (ej. 0,47).'**
  String get solidFoodValidatorQuantityParse;

  /// No description provided for @solidFoodValidatorUnitsNoDecimals.
  ///
  /// In es, this message translates to:
  /// **'En unidades usa solo números enteros, sin coma ni punto.'**
  String get solidFoodValidatorUnitsNoDecimals;

  /// No description provided for @solidFoodValidatorGramsPositive.
  ///
  /// In es, this message translates to:
  /// **'El peso en gramos debe ser mayor que 0.'**
  String get solidFoodValidatorGramsPositive;

  /// No description provided for @solidFoodValidatorGramsRange.
  ///
  /// In es, this message translates to:
  /// **'El peso no puede superar {max} g.'**
  String solidFoodValidatorGramsRange(Object max);

  /// No description provided for @feedingChooseSideTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué lado?'**
  String get feedingChooseSideTitle;

  /// No description provided for @feedingChooseSideSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige el pecho para iniciar el cronómetro.'**
  String get feedingChooseSideSubtitle;

  /// No description provided for @feedingEditSolid.
  ///
  /// In es, this message translates to:
  /// **'Editar sólidos'**
  String get feedingEditSolid;

  /// No description provided for @feedingStop.
  ///
  /// In es, this message translates to:
  /// **'Parar'**
  String get feedingStop;

  /// No description provided for @feedingPause.
  ///
  /// In es, this message translates to:
  /// **'Pausa'**
  String get feedingPause;

  /// No description provided for @feedingResume.
  ///
  /// In es, this message translates to:
  /// **'Reanudar'**
  String get feedingResume;

  /// No description provided for @feedingActiveTimer.
  ///
  /// In es, this message translates to:
  /// **'Cronómetro activo: {side}'**
  String feedingActiveTimer(Object side);

  /// No description provided for @feedingSideLeft.
  ///
  /// In es, this message translates to:
  /// **'Izquierdo'**
  String get feedingSideLeft;

  /// No description provided for @feedingSideRight.
  ///
  /// In es, this message translates to:
  /// **'Derecho'**
  String get feedingSideRight;

  /// No description provided for @feedingHistoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay registros. Usa «Pecho», «Biberón» o «Sólidos» arriba para añadir la primera.'**
  String get feedingHistoryEmpty;

  /// No description provided for @feedingSessionCountOne.
  ///
  /// In es, this message translates to:
  /// **'1 toma'**
  String get feedingSessionCountOne;

  /// No description provided for @feedingSessionCountN.
  ///
  /// In es, this message translates to:
  /// **'{n} tomas'**
  String feedingSessionCountN(Object n);

  /// No description provided for @feedingEditBottle.
  ///
  /// In es, this message translates to:
  /// **'Editar biberón'**
  String get feedingEditBottle;

  /// No description provided for @feedingEditSession.
  ///
  /// In es, this message translates to:
  /// **'Editar toma'**
  String get feedingEditSession;

  /// No description provided for @feedingAmountMl.
  ///
  /// In es, this message translates to:
  /// **'Cantidad (ml)'**
  String get feedingAmountMl;

  /// No description provided for @hintExampleMl.
  ///
  /// In es, this message translates to:
  /// **'Ej: 120'**
  String get hintExampleMl;

  /// No description provided for @feedingStreamError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las tomas. Reintenta o comprueba la conexión.'**
  String get feedingStreamError;

  /// No description provided for @lastFeedDetailLeftMinutes.
  ///
  /// In es, this message translates to:
  /// **'Izquierda • {minutes} min'**
  String lastFeedDetailLeftMinutes(Object minutes);

  /// No description provided for @lastFeedDetailLeft.
  ///
  /// In es, this message translates to:
  /// **'Izquierda'**
  String get lastFeedDetailLeft;

  /// No description provided for @lastFeedDetailRightMinutes.
  ///
  /// In es, this message translates to:
  /// **'Derecha • {minutes} min'**
  String lastFeedDetailRightMinutes(Object minutes);

  /// No description provided for @lastFeedDetailRight.
  ///
  /// In es, this message translates to:
  /// **'Derecha'**
  String get lastFeedDetailRight;

  /// No description provided for @lastFeedDetailBottleVolume.
  ///
  /// In es, this message translates to:
  /// **'Biberón • {volume}'**
  String lastFeedDetailBottleVolume(Object volume);

  /// No description provided for @lastFeedDetailSolid.
  ///
  /// In es, this message translates to:
  /// **'Sólidos'**
  String get lastFeedDetailSolid;

  /// No description provided for @diapersTitle.
  ///
  /// In es, this message translates to:
  /// **'Control de Pañales'**
  String get diapersTitle;

  /// No description provided for @diapersChangeType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de cambio'**
  String get diapersChangeType;

  /// No description provided for @diaperWet.
  ///
  /// In es, this message translates to:
  /// **'Mojado'**
  String get diaperWet;

  /// No description provided for @diaperDirty.
  ///
  /// In es, this message translates to:
  /// **'Sucio'**
  String get diaperDirty;

  /// No description provided for @diaperBoth.
  ///
  /// In es, this message translates to:
  /// **'Ambos'**
  String get diaperBoth;

  /// No description provided for @diapersRegisterButton.
  ///
  /// In es, this message translates to:
  /// **'Registrar Cambio de Pañal'**
  String get diapersRegisterButton;

  /// No description provided for @diapersHistoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay registros. Usa «Registrar cambio de pañal» arriba para añadir el primero.'**
  String get diapersHistoryEmpty;

  /// No description provided for @diaperChangeCountOne.
  ///
  /// In es, this message translates to:
  /// **'1 cambio'**
  String get diaperChangeCountOne;

  /// No description provided for @diaperChangeCountN.
  ///
  /// In es, this message translates to:
  /// **'{n} cambios'**
  String diaperChangeCountN(Object n);

  /// No description provided for @diapersStreamError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los pañales. Reintenta o comprueba la conexión.'**
  String get diapersStreamError;

  /// No description provided for @diapersEditRecord.
  ///
  /// In es, this message translates to:
  /// **'Editar registro'**
  String get diapersEditRecord;

  /// No description provided for @diapersTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get diapersTypeLabel;

  /// No description provided for @weightTitle.
  ///
  /// In es, this message translates to:
  /// **'Control de Peso'**
  String get weightTitle;

  /// No description provided for @weightFieldLabelMetric.
  ///
  /// In es, this message translates to:
  /// **'Peso (kg)'**
  String get weightFieldLabelMetric;

  /// No description provided for @weightFieldLabelImperial.
  ///
  /// In es, this message translates to:
  /// **'Peso (lb)'**
  String get weightFieldLabelImperial;

  /// No description provided for @hintExampleWeight.
  ///
  /// In es, this message translates to:
  /// **'Ej: 4,5'**
  String get hintExampleWeight;

  /// No description provided for @weightRegister.
  ///
  /// In es, this message translates to:
  /// **'Registrar'**
  String get weightRegister;

  /// No description provided for @weightValidatorEmpty.
  ///
  /// In es, this message translates to:
  /// **'Introduce el peso'**
  String get weightValidatorEmpty;

  /// No description provided for @weightValidatorInvalid.
  ///
  /// In es, this message translates to:
  /// **'Peso inválido'**
  String get weightValidatorInvalid;

  /// No description provided for @weightSuddenChangeHint.
  ///
  /// In es, this message translates to:
  /// **'Cambio muy grande respecto al último peso ({value}). Revisa que sea correcto.'**
  String weightSuddenChangeHint(String value);

  /// No description provided for @weightStreamError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los pesos. Comprueba la conexión o reintenta.'**
  String get weightStreamError;

  /// No description provided for @growthChartMetricWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso'**
  String get growthChartMetricWeight;

  /// No description provided for @growthChartMetricHeight.
  ///
  /// In es, this message translates to:
  /// **'Altura'**
  String get growthChartMetricHeight;

  /// No description provided for @growthEvolution.
  ///
  /// In es, this message translates to:
  /// **'Tendencia de peso y altura'**
  String get growthEvolution;

  /// No description provided for @weightEvolution.
  ///
  /// In es, this message translates to:
  /// **'Tendencia de peso'**
  String get weightEvolution;

  /// No description provided for @weightChartCaption.
  ///
  /// In es, this message translates to:
  /// **'Referencia OMS (peso por edad).'**
  String get weightChartCaption;

  /// No description provided for @weightChartBabyCaption.
  ///
  /// In es, this message translates to:
  /// **'Pesadas del bebé'**
  String get weightChartBabyCaption;

  /// No description provided for @weightChartRangeSelector.
  ///
  /// In es, this message translates to:
  /// **'Rango'**
  String get weightChartRangeSelector;

  /// No description provided for @weightChartSource.
  ///
  /// In es, this message translates to:
  /// **'Fuente: Organización Mundial de la Salud (OMS) — Child Growth Standards. who.int/tools/child-growth-standards'**
  String get weightChartSource;

  /// No description provided for @weightChartInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Fuente de la gráfica'**
  String get weightChartInfoTitle;

  /// No description provided for @weightChartLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la gráfica de peso.'**
  String get weightChartLoadError;

  /// No description provided for @weightHistoryLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el historial de peso.'**
  String get weightHistoryLoadError;

  /// No description provided for @weightHistoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay registros. Escribe el peso y pulsa «Registrar» arriba para añadir el primero.'**
  String get weightHistoryEmpty;

  /// No description provided for @growthHistoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay registros. Escribe el peso o la altura y pulsa «Registrar» para añadir el primero.'**
  String get growthHistoryEmpty;

  /// No description provided for @weightCurrentCard.
  ///
  /// In es, this message translates to:
  /// **'Peso Actual'**
  String get weightCurrentCard;

  /// No description provided for @weightTrendCard.
  ///
  /// In es, this message translates to:
  /// **'Tendencia diaria'**
  String get weightTrendCard;

  /// No description provided for @weightTrendGramsCompact.
  ///
  /// In es, this message translates to:
  /// **'{sign}{value}g'**
  String weightTrendGramsCompact(Object sign, Object value);

  /// No description provided for @weightTrendOuncesCompact.
  ///
  /// In es, this message translates to:
  /// **'{sign}{value} oz'**
  String weightTrendOuncesCompact(Object sign, Object value);

  /// No description provided for @weightNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get weightNoData;

  /// No description provided for @weightDash.
  ///
  /// In es, this message translates to:
  /// **'-'**
  String get weightDash;

  /// No description provided for @weightChartEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin datos aún'**
  String get weightChartEmpty;

  /// No description provided for @weightChartNoDataInRange.
  ///
  /// In es, this message translates to:
  /// **'No hay pesadas en este periodo'**
  String get weightChartNoDataInRange;

  /// No description provided for @weightChartNeedsMoreRecords.
  ///
  /// In es, this message translates to:
  /// **'Añade otra pesada para calcular la línea de crecimiento de {name}.'**
  String weightChartNeedsMoreRecords(String name);

  /// No description provided for @weightChartRangeAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get weightChartRangeAll;

  /// No description provided for @weightChartRange7d.
  ///
  /// In es, this message translates to:
  /// **'7 días'**
  String get weightChartRange7d;

  /// No description provided for @weightChartRange30d.
  ///
  /// In es, this message translates to:
  /// **'30 días'**
  String get weightChartRange30d;

  /// No description provided for @weightChartRange90d.
  ///
  /// In es, this message translates to:
  /// **'3 meses'**
  String get weightChartRange90d;

  /// No description provided for @weightChartRange365d.
  ///
  /// In es, this message translates to:
  /// **'1 año'**
  String get weightChartRange365d;

  /// No description provided for @weightTooltipAge.
  ///
  /// In es, this message translates to:
  /// **'Edad: {age}'**
  String weightTooltipAge(String age);

  /// No description provided for @weightTooltipBabyPercentile.
  ///
  /// In es, this message translates to:
  /// **'Percentil OMS (peso/edad): {value}'**
  String weightTooltipBabyPercentile(String value);

  /// No description provided for @heightTooltipBabyPercentile.
  ///
  /// In es, this message translates to:
  /// **'Percentil OMS (talla/edad): {value}'**
  String heightTooltipBabyPercentile(String value);

  /// No description provided for @weightTooltipPercentile.
  ///
  /// In es, this message translates to:
  /// **'{label} (OMS): {value}'**
  String weightTooltipPercentile(String label, String value);

  /// No description provided for @weightTooltipWeighIn.
  ///
  /// In es, this message translates to:
  /// **'Pesada: {value}'**
  String weightTooltipWeighIn(Object value);

  /// No description provided for @weightChartPercentileSelector.
  ///
  /// In es, this message translates to:
  /// **'Percentil'**
  String get weightChartPercentileSelector;

  /// No description provided for @weightChartBabyPercentileAt.
  ///
  /// In es, this message translates to:
  /// **'{name} está en el percentil {percentile}'**
  String weightChartBabyPercentileAt(String name, String percentile);

  /// No description provided for @weightChartBabyPercentileAbove.
  ///
  /// In es, this message translates to:
  /// **'{name} está por encima del percentil {percentile}'**
  String weightChartBabyPercentileAbove(String name, String percentile);

  /// No description provided for @weightChartBabyPercentileBelow.
  ///
  /// In es, this message translates to:
  /// **'{name} está por debajo del percentil {percentile}'**
  String weightChartBabyPercentileBelow(String name, String percentile);

  /// No description provided for @weightChartPercentilePhraseBeforeAt.
  ///
  /// In es, this message translates to:
  /// **' está en el percentil '**
  String get weightChartPercentilePhraseBeforeAt;

  /// No description provided for @weightChartPercentilePhraseAfterAt.
  ///
  /// In es, this message translates to:
  /// **''**
  String get weightChartPercentilePhraseAfterAt;

  /// No description provided for @weightChartPercentilePhraseBeforeAbove.
  ///
  /// In es, this message translates to:
  /// **' está por encima del percentil '**
  String get weightChartPercentilePhraseBeforeAbove;

  /// No description provided for @weightChartPercentilePhraseAfterAbove.
  ///
  /// In es, this message translates to:
  /// **''**
  String get weightChartPercentilePhraseAfterAbove;

  /// No description provided for @weightChartPercentilePhraseBeforeBelow.
  ///
  /// In es, this message translates to:
  /// **' está por debajo del percentil '**
  String get weightChartPercentilePhraseBeforeBelow;

  /// No description provided for @weightChartPercentilePhraseAfterBelow.
  ///
  /// In es, this message translates to:
  /// **''**
  String get weightChartPercentilePhraseAfterBelow;

  /// No description provided for @weightEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar peso'**
  String get weightEditTitle;

  /// No description provided for @heightTitle.
  ///
  /// In es, this message translates to:
  /// **'Control de Altura'**
  String get heightTitle;

  /// No description provided for @hintExampleHeight.
  ///
  /// In es, this message translates to:
  /// **'Ej: 58'**
  String get hintExampleHeight;

  /// No description provided for @heightRegister.
  ///
  /// In es, this message translates to:
  /// **'Registrar'**
  String get heightRegister;

  /// No description provided for @heightValidatorEmpty.
  ///
  /// In es, this message translates to:
  /// **'Introduce la altura'**
  String get heightValidatorEmpty;

  /// No description provided for @heightValidatorInvalid.
  ///
  /// In es, this message translates to:
  /// **'Altura inválida'**
  String get heightValidatorInvalid;

  /// No description provided for @heightSuddenChangeHint.
  ///
  /// In es, this message translates to:
  /// **'Cambio muy grande respecto a la última altura ({value}). Revisa que sea correcto.'**
  String heightSuddenChangeHint(String value);

  /// No description provided for @heightHistoryLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el historial de altura.'**
  String get heightHistoryLoadError;

  /// No description provided for @heightEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar altura'**
  String get heightEditTitle;

  /// No description provided for @heightEvolution.
  ///
  /// In es, this message translates to:
  /// **'Tendencia de altura'**
  String get heightEvolution;

  /// No description provided for @heightChartCaption.
  ///
  /// In es, this message translates to:
  /// **'Referencia OMS (longitud/talla por edad).'**
  String get heightChartCaption;

  /// No description provided for @heightChartBabyCaption.
  ///
  /// In es, this message translates to:
  /// **'Medidas de altura del bebé'**
  String get heightChartBabyCaption;

  /// No description provided for @heightChartLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la gráfica de altura.'**
  String get heightChartLoadError;

  /// No description provided for @heightChartEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin alturas aún'**
  String get heightChartEmpty;

  /// No description provided for @heightChartNoDataInRange.
  ///
  /// In es, this message translates to:
  /// **'No hay alturas en este periodo'**
  String get heightChartNoDataInRange;

  /// No description provided for @heightChartNeedsMoreRecords.
  ///
  /// In es, this message translates to:
  /// **'Añade otra medida de altura para calcular la línea de crecimiento de {name}.'**
  String heightChartNeedsMoreRecords(String name);

  /// No description provided for @heightTooltipMeasure.
  ///
  /// In es, this message translates to:
  /// **'Altura: {value}'**
  String heightTooltipMeasure(String value);

  /// No description provided for @bottleTitle.
  ///
  /// In es, this message translates to:
  /// **'Biberón'**
  String get bottleTitle;

  /// No description provided for @bottleValidatorEmpty.
  ///
  /// In es, this message translates to:
  /// **'Introduce la cantidad'**
  String get bottleValidatorEmpty;

  /// No description provided for @bottleValidatorInvalid.
  ///
  /// In es, this message translates to:
  /// **'Cantidad inválida'**
  String get bottleValidatorInvalid;

  /// No description provided for @bottleQuickAmountsSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Cantidades rápidas'**
  String get bottleQuickAmountsSectionTitle;

  /// No description provided for @bottleQuickAmountAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get bottleQuickAmountAdd;

  /// No description provided for @bottleQuickAmountAddTitle.
  ///
  /// In es, this message translates to:
  /// **'Añadir atajo'**
  String get bottleQuickAmountAddTitle;

  /// No description provided for @bottleQuickAmountDuplicate.
  ///
  /// In es, this message translates to:
  /// **'Esa cantidad ya está en la lista'**
  String get bottleQuickAmountDuplicate;

  /// No description provided for @bottleQuickAmountMaxCustom.
  ///
  /// In es, this message translates to:
  /// **'Máximo de atajos personalizados alcanzado'**
  String get bottleQuickAmountMaxCustom;

  /// No description provided for @bottleQuickAmountRemoveTitle.
  ///
  /// In es, this message translates to:
  /// **'Quitar atajo'**
  String get bottleQuickAmountRemoveTitle;

  /// No description provided for @bottleQuickAmountRemoveMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar {amount} de tus atajos?'**
  String bottleQuickAmountRemoveMessage(String amount);

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsBabyProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil del Bebé'**
  String get settingsBabyProfile;

  /// No description provided for @settingsShareFamily.
  ///
  /// In es, this message translates to:
  /// **'Compartir Familia'**
  String get settingsShareFamily;

  /// No description provided for @settingsSuggestedFeedings.
  ///
  /// In es, this message translates to:
  /// **'Tomas sugeridas'**
  String get settingsSuggestedFeedings;

  /// No description provided for @settingsName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get settingsName;

  /// No description provided for @settingsBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get settingsBirthDate;

  /// No description provided for @settingsHeight.
  ///
  /// In es, this message translates to:
  /// **'Altura'**
  String get settingsHeight;

  /// No description provided for @settingsNoProfile.
  ///
  /// In es, this message translates to:
  /// **'Sin perfil configurado'**
  String get settingsNoProfile;

  /// No description provided for @settingsEditProfile.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get settingsEditProfile;

  /// No description provided for @settingsShareQrIntro.
  ///
  /// In es, this message translates to:
  /// **'Tú enseñas este código. Quien se una lo escanea con su propio móvil al unirse a un bebé ya creado.'**
  String get settingsShareQrIntro;

  /// No description provided for @settingsFeedingConfigureFirst.
  ///
  /// In es, this message translates to:
  /// **'Configura primero el perfil del bebé.'**
  String get settingsFeedingConfigureFirst;

  /// No description provided for @settingsFeedingIntro.
  ///
  /// In es, this message translates to:
  /// **'Define cada cuánto suele comer el bebé'**
  String get settingsFeedingIntro;

  /// No description provided for @settingsFeedingInterval.
  ///
  /// In es, this message translates to:
  /// **'Intervalo entre tomas'**
  String get settingsFeedingInterval;

  /// No description provided for @settingsNotifyTitle.
  ///
  /// In es, this message translates to:
  /// **'Activar notificaciones'**
  String get settingsNotifyTitle;

  /// No description provided for @settingsNotifySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones en la hora sugerida de la siguiente toma.'**
  String get settingsNotifySubtitle;

  /// No description provided for @settingsNotifyPermission.
  ///
  /// In es, this message translates to:
  /// **'Activa las notificaciones en los ajustes del sistema para recibir el aviso.'**
  String get settingsNotifyPermission;

  /// No description provided for @settingsSignOutSection.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsSignOutSection;

  /// No description provided for @settingsSignOutButton.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsSignOutButton;

  /// No description provided for @settingsSignOutRowSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión en este dispositivo'**
  String get settingsSignOutRowSubtitle;

  /// No description provided for @settingsDeleteSection.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get settingsDeleteSection;

  /// No description provided for @settingsDeleteIntro.
  ///
  /// In es, this message translates to:
  /// **'Elimina tu cuenta y tus datos de acceso. Si eres el único miembro de la familia, también se eliminarán todos los datos del bebé.'**
  String get settingsDeleteIntro;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mi cuenta'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountRowSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar la cuenta y sus datos'**
  String get settingsDeleteAccountRowSubtitle;

  /// No description provided for @settingsDeleting.
  ///
  /// In es, this message translates to:
  /// **'Eliminando...'**
  String get settingsDeleting;

  /// No description provided for @settingsFamilyFirebaseOnly.
  ///
  /// In es, this message translates to:
  /// **'Compartir familia solo disponible con Firebase.'**
  String get settingsFamilyFirebaseOnly;

  /// No description provided for @settingsShowQr.
  ///
  /// In es, this message translates to:
  /// **'Mostrar QR para invitar'**
  String get settingsShowQr;

  /// No description provided for @settingsHideQr.
  ///
  /// In es, this message translates to:
  /// **'Ocultar QR'**
  String get settingsHideQr;

  /// No description provided for @settingsQrCaption.
  ///
  /// In es, this message translates to:
  /// **'Este móvil solo muestra el código. Lo escanea la otra persona.'**
  String get settingsQrCaption;

  /// No description provided for @settingsGroupBaby.
  ///
  /// In es, this message translates to:
  /// **'Bebé'**
  String get settingsGroupBaby;

  /// No description provided for @settingsGroupPreferences.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get settingsGroupPreferences;

  /// No description provided for @settingsGroupFamily.
  ///
  /// In es, this message translates to:
  /// **'Familia'**
  String get settingsGroupFamily;

  /// No description provided for @settingsGroupAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get settingsGroupAccount;

  /// No description provided for @settingsGroupHelp.
  ///
  /// In es, this message translates to:
  /// **'Ayuda'**
  String get settingsGroupHelp;

  /// No description provided for @settingsRowContactTitle.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get settingsRowContactTitle;

  /// No description provided for @settingsRowContactSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{email}'**
  String settingsRowContactSubtitle(String email);

  /// No description provided for @settingsContactEmailSubject.
  ///
  /// In es, this message translates to:
  /// **'Consulta sobre MiBebé'**
  String get settingsContactEmailSubject;

  /// No description provided for @settingsContactOpenFail.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la app de correo. Escríbenos a {email}'**
  String settingsContactOpenFail(String email);

  /// No description provided for @settingsRowProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos del perfil'**
  String get settingsRowProfileTitle;

  /// No description provided for @settingsRowProfileSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Nombre, fecha y nacimiento'**
  String get settingsRowProfileSubtitle;

  /// No description provided for @settingsRowProfileEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin configurar'**
  String get settingsRowProfileEmpty;

  /// No description provided for @settingsRowFeedingInterval.
  ///
  /// In es, this message translates to:
  /// **'Intervalo entre tomas'**
  String get settingsRowFeedingInterval;

  /// No description provided for @settingsRowFeedingNotify.
  ///
  /// In es, this message translates to:
  /// **'Avisar próxima toma'**
  String get settingsRowFeedingNotify;

  /// No description provided for @settingsRowUnitWeight.
  ///
  /// In es, this message translates to:
  /// **'Unidad de peso'**
  String get settingsRowUnitWeight;

  /// No description provided for @settingsRowUnitLiquid.
  ///
  /// In es, this message translates to:
  /// **'Unidad de líquidos'**
  String get settingsRowUnitLiquid;

  /// No description provided for @settingsRowCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get settingsRowCurrency;

  /// No description provided for @settingsCurrencyAuto.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get settingsCurrencyAuto;

  /// No description provided for @settingsCurrencyIntro.
  ///
  /// In es, this message translates to:
  /// **'Elige la moneda para estimar el gasto en pañales. Automático usa la del dispositivo.'**
  String get settingsCurrencyIntro;

  /// No description provided for @settingsCurrencySearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar moneda'**
  String get settingsCurrencySearchHint;

  /// No description provided for @settingsCurrencyAutoSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Según tu dispositivo · {currency}'**
  String settingsCurrencyAutoSubtitle(String currency);

  /// No description provided for @settingsCurrencyAllSection.
  ///
  /// In es, this message translates to:
  /// **'Todas las monedas'**
  String get settingsCurrencyAllSection;

  /// No description provided for @settingsCurrencyNoResults.
  ///
  /// In es, this message translates to:
  /// **'No encontramos ninguna moneda con «{query}»'**
  String settingsCurrencyNoResults(String query);

  /// No description provided for @settingsRowFamilyShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir con familia'**
  String get settingsRowFamilyShare;

  /// No description provided for @settingsRowFamilyShareSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Mostrar código QR de invitación'**
  String get settingsRowFamilyShareSubtitle;

  /// No description provided for @settingsValueOn.
  ///
  /// In es, this message translates to:
  /// **'Activado'**
  String get settingsValueOn;

  /// No description provided for @settingsValueOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivado'**
  String get settingsValueOff;

  /// No description provided for @settingsValueNotSet.
  ///
  /// In es, this message translates to:
  /// **'—'**
  String get settingsValueNotSet;

  /// No description provided for @settingsBabyAgeMonthsOne.
  ///
  /// In es, this message translates to:
  /// **'1 mes'**
  String get settingsBabyAgeMonthsOne;

  /// No description provided for @settingsBabyAgeMonthsN.
  ///
  /// In es, this message translates to:
  /// **'{months} meses'**
  String settingsBabyAgeMonthsN(int months);

  /// No description provided for @settingsBabyAgeDaysOne.
  ///
  /// In es, this message translates to:
  /// **'1 día'**
  String get settingsBabyAgeDaysOne;

  /// No description provided for @settingsBabyAgeDaysN.
  ///
  /// In es, this message translates to:
  /// **'{days} días'**
  String settingsBabyAgeDaysN(int days);

  /// No description provided for @settingsBabyBornOn.
  ///
  /// In es, this message translates to:
  /// **'Nacido el {date}'**
  String settingsBabyBornOn(String date);

  /// No description provided for @settingsBabyBornOnFemale.
  ///
  /// In es, this message translates to:
  /// **'Nacida el {date}'**
  String settingsBabyBornOnFemale(String date);

  /// No description provided for @settingsSheetUnitWeightTitle.
  ///
  /// In es, this message translates to:
  /// **'Unidad de peso'**
  String get settingsSheetUnitWeightTitle;

  /// No description provided for @settingsSheetUnitLiquidTitle.
  ///
  /// In es, this message translates to:
  /// **'Unidad de líquidos'**
  String get settingsSheetUnitLiquidTitle;

  /// No description provided for @settingsSheetCurrencyTitle.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get settingsSheetCurrencyTitle;

  /// No description provided for @settingsSheetFeedingIntervalTitle.
  ///
  /// In es, this message translates to:
  /// **'Intervalo entre tomas'**
  String get settingsSheetFeedingIntervalTitle;

  /// No description provided for @settingsSheetShareTitle.
  ///
  /// In es, this message translates to:
  /// **'Compartir con familia'**
  String get settingsSheetShareTitle;

  /// No description provided for @editBabyProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil del bebé'**
  String get editBabyProfileTitle;

  /// No description provided for @labelName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get labelName;

  /// No description provided for @labelGender.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get labelGender;

  /// No description provided for @heightFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Altura (cm)'**
  String get heightFieldLabel;

  /// No description provided for @heightFieldHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional, ej. 58'**
  String get heightFieldHint;

  /// No description provided for @heightInvalid.
  ///
  /// In es, this message translates to:
  /// **'Altura inválida'**
  String get heightInvalid;

  /// No description provided for @heightRangeError.
  ///
  /// In es, this message translates to:
  /// **'Altura debe estar entre 25 y 120 cm'**
  String get heightRangeError;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In es, this message translates to:
  /// **'Esta acción eliminará permanentemente tu cuenta y tus datos de acceso. Si eres el único miembro de la familia, también se eliminarán todos los datos del bebé.\n\nEsta operación no se puede deshacer. ¿Estás seguro?'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountError.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar la cuenta: {error}'**
  String deleteAccountError(Object error);

  /// No description provided for @signOutTitle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres cerrar sesión?'**
  String get signOutBody;

  /// No description provided for @signOutConfirm.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOutConfirm;

  /// No description provided for @signOutError.
  ///
  /// In es, this message translates to:
  /// **'Error al cerrar sesión: {error}'**
  String signOutError(Object error);

  /// No description provided for @loginForgotPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get loginForgotPasswordTitle;

  /// No description provided for @loginForgotPasswordBody.
  ///
  /// In es, this message translates to:
  /// **'Te enviaremos un enlace para elegir una contraseña nueva.'**
  String get loginForgotPasswordBody;

  /// No description provided for @loginEmailHint.
  ///
  /// In es, this message translates to:
  /// **'Tu correo electrónico'**
  String get loginEmailHint;

  /// No description provided for @loginResetInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Introduce un correo válido'**
  String get loginResetInvalidEmail;

  /// No description provided for @loginResetCheckEmail.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu correo (y spam) para restablecer la contraseña'**
  String get loginResetCheckEmail;

  /// No description provided for @loginResetSendFail.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el correo. Inténtalo más tarde.'**
  String get loginResetSendFail;

  /// No description provided for @loginHeaderTitle.
  ///
  /// In es, this message translates to:
  /// **'MiBebé'**
  String get loginHeaderTitle;

  /// No description provided for @loginWelcomeBackTitle.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a entrar'**
  String get loginWelcomeBackTitle;

  /// No description provided for @loginWelcomeBackSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los datos de tu bebé siguen guardados'**
  String get loginWelcomeBackSubtitle;

  /// No description provided for @loginContinueApple.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get loginContinueApple;

  /// No description provided for @loginContinueGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get loginContinueGoogle;

  /// No description provided for @loginContinueEmail.
  ///
  /// In es, this message translates to:
  /// **'Continuar con email'**
  String get loginContinueEmail;

  /// No description provided for @loginLastAuthMethod.
  ///
  /// In es, this message translates to:
  /// **'La última vez entraste con {method}'**
  String loginLastAuthMethod(String method);

  /// No description provided for @loginPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Tu contraseña'**
  String get loginPasswordHint;

  /// No description provided for @loginForgotLink.
  ///
  /// In es, this message translates to:
  /// **'¿Has olvidado tu contraseña?'**
  String get loginForgotLink;

  /// No description provided for @loginValidatorEmailEmpty.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu correo'**
  String get loginValidatorEmailEmpty;

  /// No description provided for @loginValidatorEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Correo no válido'**
  String get loginValidatorEmailInvalid;

  /// No description provided for @loginValidatorPasswordEmpty.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu contraseña'**
  String get loginValidatorPasswordEmpty;

  /// No description provided for @loginSignIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get loginSignIn;

  /// No description provided for @loginGuestQr.
  ///
  /// In es, this message translates to:
  /// **'Unirme con código QR (sin cuenta)'**
  String get loginGuestQr;

  /// No description provided for @loginOrWith.
  ///
  /// In es, this message translates to:
  /// **'O INICIA SESIÓN CON'**
  String get loginOrWith;

  /// No description provided for @loginNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? '**
  String get loginNoAccount;

  /// No description provided for @loginRegisterLink.
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get loginRegisterLink;

  /// No description provided for @loginCreateNewProfile.
  ///
  /// In es, this message translates to:
  /// **'Crear un perfil nuevo'**
  String get loginCreateNewProfile;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar sesión'**
  String get loginErrorGeneric;

  /// No description provided for @loginErrorGoogle.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar sesión con Google'**
  String get loginErrorGoogle;

  /// No description provided for @loginErrorApple.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar sesión con Apple'**
  String get loginErrorApple;

  /// No description provided for @loginGuestNeedsFirebase.
  ///
  /// In es, this message translates to:
  /// **'Hace falta Firebase para unirte con código QR'**
  String get loginGuestNeedsFirebase;

  /// No description provided for @loginGuestNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'Invitado no disponible. En Firebase Console → Authentication → Sign-in method, activa \"Anónimo\".'**
  String get loginGuestNotAllowed;

  /// No description provided for @loginGuestFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo entrar como invitado'**
  String get loginGuestFailed;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In es, this message translates to:
  /// **'No existe una cuenta con este correo'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña incorrecta'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico no válido'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta ha sido deshabilitada'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorInvalidCredential.
  ///
  /// In es, this message translates to:
  /// **'Credenciales inválidas'**
  String get authErrorInvalidCredential;

  /// No description provided for @authErrorOperationNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'Método de inicio de sesión no habilitado'**
  String get authErrorOperationNotAllowed;

  /// No description provided for @authErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar sesión'**
  String get authErrorGeneric;

  /// No description provided for @resetErrorInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico no válido'**
  String get resetErrorInvalidEmail;

  /// No description provided for @resetErrorUserNotFound.
  ///
  /// In es, this message translates to:
  /// **'No hay cuenta con este correo. Comprueba el email o regístrate.'**
  String get resetErrorUserNotFound;

  /// No description provided for @resetErrorUserDisabled.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta está deshabilitada'**
  String get resetErrorUserDisabled;

  /// No description provided for @resetErrorOpNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'Recuperación por correo no habilitada en Firebase (Authentication → Sign-in method → Email).'**
  String get resetErrorOpNotAllowed;

  /// No description provided for @resetErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el correo. Inténtalo más tarde.'**
  String get resetErrorGeneric;

  /// No description provided for @registerTitle.
  ///
  /// In es, this message translates to:
  /// **'Registro'**
  String get registerTitle;

  /// No description provided for @registerHeadline.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta'**
  String get registerHeadline;

  /// No description provided for @registerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Introduce tus datos para registrarte'**
  String get registerSubtitle;

  /// No description provided for @registerEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get registerEmailLabel;

  /// No description provided for @registerPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get registerPasswordLabel;

  /// No description provided for @registerConfirmLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get registerConfirmLabel;

  /// No description provided for @registerPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get registerPasswordHint;

  /// No description provided for @registerEmailHint.
  ///
  /// In es, this message translates to:
  /// **'tu@email.com'**
  String get registerEmailHint;

  /// No description provided for @registerValidatorEmailEmpty.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu correo'**
  String get registerValidatorEmailEmpty;

  /// No description provided for @registerValidatorPasswordEmpty.
  ///
  /// In es, this message translates to:
  /// **'Introduce una contraseña'**
  String get registerValidatorPasswordEmpty;

  /// No description provided for @registerValidatorPasswordShort.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get registerValidatorPasswordShort;

  /// No description provided for @registerValidatorConfirmEmpty.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu contraseña'**
  String get registerValidatorConfirmEmpty;

  /// No description provided for @registerValidatorMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get registerValidatorMismatch;

  /// No description provided for @registerButton.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get registerButton;

  /// No description provided for @registerHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? '**
  String get registerHaveAccount;

  /// No description provided for @registerSignInLink.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get registerSignInLink;

  /// No description provided for @registerErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Error al registrarse. Comprueba tu conexión y que el registro por email esté habilitado en Firebase.'**
  String get registerErrorGeneric;

  /// No description provided for @registerErrorEmailInUse.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con este correo. Usa \"Inicia sesión\" en su lugar.'**
  String get registerErrorEmailInUse;

  /// No description provided for @registerErrorWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get registerErrorWeakPassword;

  /// No description provided for @registerErrorOpNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'Registro por email no habilitado. Actívalo en Firebase Console > Authentication > Sign-in method'**
  String get registerErrorOpNotAllowed;

  /// No description provided for @registerErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión. Comprueba tu internet.'**
  String get registerErrorNetwork;

  /// No description provided for @registerErrorTooMany.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera unos minutos.'**
  String get registerErrorTooMany;

  /// No description provided for @registerErrorInvalidCredential.
  ///
  /// In es, this message translates to:
  /// **'Credenciales inválidas'**
  String get registerErrorInvalidCredential;

  /// No description provided for @registerErrorUnknown.
  ///
  /// In es, this message translates to:
  /// **'Error: {code}. Revisa Firebase Console.'**
  String registerErrorUnknown(Object code);

  /// No description provided for @onboardingWelcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a MiBebé'**
  String get onboardingWelcome;

  /// No description provided for @onboardingHowStart.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo quieres empezar?'**
  String get onboardingHowStart;

  /// No description provided for @onboardingCreateBabyTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear bebé'**
  String get onboardingCreateBabyTitle;

  /// No description provided for @onboardingCreateBabySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Configura un nuevo perfil desde cero'**
  String get onboardingCreateBabySubtitle;

  /// No description provided for @onboardingScanTitle.
  ///
  /// In es, this message translates to:
  /// **'Escanear bebé'**
  String get onboardingScanTitle;

  /// No description provided for @onboardingScanSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Únete a un bebé ya creado escaneando su código QR'**
  String get onboardingScanSubtitle;

  /// No description provided for @onboardingScanDisabled.
  ///
  /// In es, this message translates to:
  /// **'Requiere Firebase para compartir'**
  String get onboardingScanDisabled;

  /// No description provided for @onboardingExitLogin.
  ///
  /// In es, this message translates to:
  /// **'Salir y volver al inicio de sesión'**
  String get onboardingExitLogin;

  /// No description provided for @onboardingConfigureTitle.
  ///
  /// In es, this message translates to:
  /// **'Configurar bebé'**
  String get onboardingConfigureTitle;

  /// No description provided for @onboardingCreateProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear perfil del bebé'**
  String get onboardingCreateProfileTitle;

  /// No description provided for @onboardingCreateProfileSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Configura los datos de tu bebé'**
  String get onboardingCreateProfileSubtitle;

  /// No description provided for @onboardingBabyName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del bebé'**
  String get onboardingBabyName;

  /// No description provided for @onboardingBabyNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: María, Lucas...'**
  String get onboardingBabyNameHint;

  /// No description provided for @onboardingNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre es obligatorio'**
  String get onboardingNameRequired;

  /// No description provided for @onboardingGender.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get onboardingGender;

  /// No description provided for @onboardingBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get onboardingBirthDate;

  /// No description provided for @onboardingBirthNote.
  ///
  /// In es, this message translates to:
  /// **'Se usa para calcular percentiles OMS (0-12 meses)'**
  String get onboardingBirthNote;

  /// No description provided for @onboardingHeightTitle.
  ///
  /// In es, this message translates to:
  /// **'Talla / altura'**
  String get onboardingHeightTitle;

  /// No description provided for @onboardingHeightSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Opcional. La altura actual en centímetros (aparece en el perfil).'**
  String get onboardingHeightSubtitle;

  /// No description provided for @onboardingHeightHint.
  ///
  /// In es, this message translates to:
  /// **'Dejar vacío si no la conoces'**
  String get onboardingHeightHint;

  /// No description provided for @onboardingHeightInvalid.
  ///
  /// In es, this message translates to:
  /// **'Introduce un número válido (ej: 52,5)'**
  String get onboardingHeightInvalid;

  /// No description provided for @onboardingHeightRange.
  ///
  /// In es, this message translates to:
  /// **'Altura habitual entre 25 y 130 cm'**
  String get onboardingHeightRange;

  /// No description provided for @onboardingNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get onboardingStart;

  /// No description provided for @onboardingEnterName.
  ///
  /// In es, this message translates to:
  /// **'Introduce el nombre del bebé'**
  String get onboardingEnterName;

  /// No description provided for @onboardingHeightReview.
  ///
  /// In es, this message translates to:
  /// **'Revisa la talla: número entre 25 y 130 cm, o deja el campo vacío'**
  String get onboardingHeightReview;

  /// No description provided for @onboardingSaveDenied.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso en Firebase (reglas o sesión). Revisa Firestore.'**
  String get onboardingSaveDenied;

  /// No description provided for @onboardingSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar ({code}). Revisa conexión y Firebase.'**
  String onboardingSaveFailed(Object code);

  /// No description provided for @onboardingSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar: {error}'**
  String onboardingSaveError(Object error);

  /// No description provided for @onboardingExitTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Salir?'**
  String get onboardingExitTitle;

  /// No description provided for @onboardingExitBody.
  ///
  /// In es, this message translates to:
  /// **'Cerrarás sesión y volverás a la pantalla de inicio de sesión.'**
  String get onboardingExitBody;

  /// No description provided for @onboardingSignOutError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cerrar sesión: {error}'**
  String onboardingSignOutError(Object error);

  /// No description provided for @familyQrTitle.
  ///
  /// In es, this message translates to:
  /// **'Escanear código QR'**
  String get familyQrTitle;

  /// No description provided for @familyQrHint.
  ///
  /// In es, this message translates to:
  /// **'Apunta la cámara al código QR del bebé'**
  String get familyQrHint;

  /// No description provided for @familyQrDetailLabel.
  ///
  /// In es, this message translates to:
  /// **'Detalle:'**
  String get familyQrDetailLabel;

  /// No description provided for @familyQrJoinFailPermission.
  ///
  /// In es, this message translates to:
  /// **'Permiso denegado en Firebase (reglas de Firestore o sesión).'**
  String get familyQrJoinFailPermission;

  /// No description provided for @familyQrJoinFailUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Firebase no está disponible. Revisa la conexión a internet.'**
  String get familyQrJoinFailUnavailable;

  /// No description provided for @familyQrJoinFailNotFound.
  ///
  /// In es, this message translates to:
  /// **'Recurso no encontrado en Firebase.'**
  String get familyQrJoinFailNotFound;

  /// No description provided for @familyQrJoinFailFirebase.
  ///
  /// In es, this message translates to:
  /// **'Error de Firebase ({code}).'**
  String familyQrJoinFailFirebase(Object code);

  /// No description provided for @familyQrJoinFailFamily.
  ///
  /// In es, this message translates to:
  /// **'Familia no encontrada. Comprueba que el QR sea correcto.'**
  String get familyQrJoinFailFamily;

  /// No description provided for @familyQrJoinFailState.
  ///
  /// In es, this message translates to:
  /// **'Error al procesar el código del QR.'**
  String get familyQrJoinFailState;

  /// No description provided for @familyQrJoinFailUnsupported.
  ///
  /// In es, this message translates to:
  /// **'Unirse por QR no está disponible (hace falta Firebase en este dispositivo).'**
  String get familyQrJoinFailUnsupported;

  /// No description provided for @familyQrJoinFailGeneric.
  ///
  /// In es, this message translates to:
  /// **'No se pudo unir a la familia.'**
  String get familyQrJoinFailGeneric;

  /// No description provided for @familyQrDecodeFail.
  ///
  /// In es, this message translates to:
  /// **'Fallo al leer o decodificar el código.'**
  String get familyQrDecodeFail;

  /// No description provided for @familyQrInternalCode.
  ///
  /// In es, this message translates to:
  /// **'Código interno:'**
  String get familyQrInternalCode;

  /// No description provided for @notificationChannelName.
  ///
  /// In es, this message translates to:
  /// **'Próximas tomas'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In es, this message translates to:
  /// **'Aviso cuando llega la hora sugerida de toma'**
  String get notificationChannelDescription;

  /// No description provided for @notificationNextFeedTitle.
  ///
  /// In es, this message translates to:
  /// **'Próxima toma'**
  String get notificationNextFeedTitle;

  /// No description provided for @notificationNextFeedBody.
  ///
  /// In es, this message translates to:
  /// **'Podría tocar otra toma para {name}.'**
  String notificationNextFeedBody(Object name);

  /// No description provided for @formatWeightMetricKg.
  ///
  /// In es, this message translates to:
  /// **'{kg} kg'**
  String formatWeightMetricKg(Object kg);

  /// No description provided for @formatWeightLbOz.
  ///
  /// In es, this message translates to:
  /// **'{lb} lb {oz} oz'**
  String formatWeightLbOz(Object lb, Object oz);

  /// No description provided for @formatHeightCm.
  ///
  /// In es, this message translates to:
  /// **'{cm} cm'**
  String formatHeightCm(Object cm);

  /// No description provided for @formatVolumeMlOnly.
  ///
  /// In es, this message translates to:
  /// **'{ml} ml'**
  String formatVolumeMlOnly(Object ml);

  /// No description provided for @formatVolumeFlOzOnly.
  ///
  /// In es, this message translates to:
  /// **'{flOz} fl oz'**
  String formatVolumeFlOzOnly(Object flOz);

  /// No description provided for @unitMlShort.
  ///
  /// In es, this message translates to:
  /// **'ml'**
  String get unitMlShort;

  /// No description provided for @unitMlLong.
  ///
  /// In es, this message translates to:
  /// **'mililitros'**
  String get unitMlLong;

  /// No description provided for @unitFlOzLong.
  ///
  /// In es, this message translates to:
  /// **'onzas líquidas'**
  String get unitFlOzLong;

  /// No description provided for @hintExampleWeightLb.
  ///
  /// In es, this message translates to:
  /// **'Ej: 9,5'**
  String get hintExampleWeightLb;

  /// No description provided for @hintExampleFlOz.
  ///
  /// In es, this message translates to:
  /// **'Ej: 4'**
  String get hintExampleFlOz;

  /// No description provided for @liquidFieldLabelFlOz.
  ///
  /// In es, this message translates to:
  /// **'Cantidad (fl oz)'**
  String get liquidFieldLabelFlOz;

  /// No description provided for @settingsUnitsTitle.
  ///
  /// In es, this message translates to:
  /// **'Unidades'**
  String get settingsUnitsTitle;

  /// No description provided for @settingsUnitsIntro.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo ver e introducir peso y biberón. Los datos se guardan siempre en kg y ml.'**
  String get settingsUnitsIntro;

  /// No description provided for @settingsUnitsWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso'**
  String get settingsUnitsWeight;

  /// No description provided for @settingsUnitsLiquid.
  ///
  /// In es, this message translates to:
  /// **'Líquidos'**
  String get settingsUnitsLiquid;

  /// No description provided for @unitSegmentKg.
  ///
  /// In es, this message translates to:
  /// **'kg'**
  String get unitSegmentKg;

  /// No description provided for @unitSegmentLbOz.
  ///
  /// In es, this message translates to:
  /// **'lb · oz'**
  String get unitSegmentLbOz;

  /// No description provided for @unitSegmentMl.
  ///
  /// In es, this message translates to:
  /// **'mL'**
  String get unitSegmentMl;

  /// No description provided for @unitSegmentFlOz.
  ///
  /// In es, this message translates to:
  /// **'fl oz'**
  String get unitSegmentFlOz;

  /// No description provided for @settingsRowPediatricReport.
  ///
  /// In es, this message translates to:
  /// **'Informe para el pediatra'**
  String get settingsRowPediatricReport;

  /// No description provided for @settingsRowPediatricReportSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Compartir PDF con curvas OMS'**
  String get settingsRowPediatricReportSubtitle;

  /// No description provided for @reportShareError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo generar el informe. Inténtalo de nuevo.'**
  String get reportShareError;

  /// No description provided for @reportFileNamePrefix.
  ///
  /// In es, this message translates to:
  /// **'informe-crecimiento'**
  String get reportFileNamePrefix;

  /// No description provided for @reportTitle.
  ///
  /// In es, this message translates to:
  /// **'Informe de crecimiento'**
  String get reportTitle;

  /// No description provided for @reportSexLabel.
  ///
  /// In es, this message translates to:
  /// **'Sexo'**
  String get reportSexLabel;

  /// No description provided for @reportSexMale.
  ///
  /// In es, this message translates to:
  /// **'Niño'**
  String get reportSexMale;

  /// No description provided for @reportSexFemale.
  ///
  /// In es, this message translates to:
  /// **'Niña'**
  String get reportSexFemale;

  /// No description provided for @reportSexUnspecified.
  ///
  /// In es, this message translates to:
  /// **'No especificado'**
  String get reportSexUnspecified;

  /// No description provided for @reportBirthDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Nacimiento'**
  String get reportBirthDateLabel;

  /// No description provided for @reportAgeLabel.
  ///
  /// In es, this message translates to:
  /// **'Edad'**
  String get reportAgeLabel;

  /// No description provided for @reportDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha del informe'**
  String get reportDateLabel;

  /// No description provided for @reportAgeMonthsDays.
  ///
  /// In es, this message translates to:
  /// **'{months} m {days} d'**
  String reportAgeMonthsDays(int months, int days);

  /// No description provided for @reportAgeDays.
  ///
  /// In es, this message translates to:
  /// **'{days} días'**
  String reportAgeDays(int days);

  /// No description provided for @reportChartTitle.
  ///
  /// In es, this message translates to:
  /// **'Peso (kg) por edad (meses) · curvas OMS'**
  String get reportChartTitle;

  /// No description provided for @reportHeightChartTitle.
  ///
  /// In es, this message translates to:
  /// **'Talla (cm) por edad (meses) · curvas OMS'**
  String get reportHeightChartTitle;

  /// No description provided for @reportChartLegendBaby.
  ///
  /// In es, this message translates to:
  /// **'Peso de {name}'**
  String reportChartLegendBaby(String name);

  /// No description provided for @reportChartLegendWho.
  ///
  /// In es, this message translates to:
  /// **'Percentiles OMS: P3 · P15 · P50 · P85 · P97'**
  String get reportChartLegendWho;

  /// No description provided for @reportChartWhoNote.
  ///
  /// In es, this message translates to:
  /// **'Las curvas son percentiles de referencia OMS; los puntos son las mediciones del bebé.'**
  String get reportChartWhoNote;

  /// No description provided for @reportWeightTableTitle.
  ///
  /// In es, this message translates to:
  /// **'Últimas pesadas'**
  String get reportWeightTableTitle;

  /// No description provided for @reportHeightTableTitle.
  ///
  /// In es, this message translates to:
  /// **'Últimas tallas'**
  String get reportHeightTableTitle;

  /// No description provided for @reportTableDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get reportTableDate;

  /// No description provided for @reportTableAge.
  ///
  /// In es, this message translates to:
  /// **'Edad'**
  String get reportTableAge;

  /// No description provided for @reportTableWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso'**
  String get reportTableWeight;

  /// No description provided for @reportTableHeight.
  ///
  /// In es, this message translates to:
  /// **'Talla'**
  String get reportTableHeight;

  /// No description provided for @reportTableChange.
  ///
  /// In es, this message translates to:
  /// **'Variación'**
  String get reportTableChange;

  /// No description provided for @reportNoWeightData.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay pesadas registradas.'**
  String get reportNoWeightData;

  /// No description provided for @reportNoHeightData.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay tallas registradas.'**
  String get reportNoHeightData;

  /// No description provided for @reportFeedingTitle.
  ///
  /// In es, this message translates to:
  /// **'Alimentación · últimos 7 días'**
  String get reportFeedingTitle;

  /// No description provided for @reportFeedingPerDay.
  ///
  /// In es, this message translates to:
  /// **'Tomas por día'**
  String get reportFeedingPerDay;

  /// No description provided for @reportFeedingBreastPerDay.
  ///
  /// In es, this message translates to:
  /// **'Pecho por día'**
  String get reportFeedingBreastPerDay;

  /// No description provided for @reportFeedingBottlePerDay.
  ///
  /// In es, this message translates to:
  /// **'Biberón por día'**
  String get reportFeedingBottlePerDay;

  /// No description provided for @reportFeedingDistribution.
  ///
  /// In es, this message translates to:
  /// **'Distribución'**
  String get reportFeedingDistribution;

  /// No description provided for @reportFeedingDistributionValue.
  ///
  /// In es, this message translates to:
  /// **'{breast}% pecho · {bottle}% biberón · {solid}% sólidos'**
  String reportFeedingDistributionValue(int breast, int bottle, int solid);

  /// No description provided for @reportDiapersTitle.
  ///
  /// In es, this message translates to:
  /// **'Pañales · últimos 7 días'**
  String get reportDiapersTitle;

  /// No description provided for @reportDiapersPerDay.
  ///
  /// In es, this message translates to:
  /// **'Cambios por día'**
  String get reportDiapersPerDay;

  /// No description provided for @reportDiapersWet.
  ///
  /// In es, this message translates to:
  /// **'Mojados'**
  String get reportDiapersWet;

  /// No description provided for @reportDiapersDirty.
  ///
  /// In es, this message translates to:
  /// **'Sucios'**
  String get reportDiapersDirty;

  /// No description provided for @reportDiapersBoth.
  ///
  /// In es, this message translates to:
  /// **'Mixtos'**
  String get reportDiapersBoth;

  /// No description provided for @reportNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get reportNoData;

  /// No description provided for @reportGeneratedWith.
  ///
  /// In es, this message translates to:
  /// **'Generado con MiBebé · {date}'**
  String reportGeneratedWith(String date);

  /// No description provided for @reportTrendsTitle.
  ///
  /// In es, this message translates to:
  /// **'Tendencias y comparativas'**
  String get reportTrendsTitle;

  /// No description provided for @reportPeriodDays.
  ///
  /// In es, this message translates to:
  /// **'Últimos {days} días'**
  String reportPeriodDays(int days);

  /// No description provided for @reportComparisonTitle.
  ///
  /// In es, this message translates to:
  /// **'Comparativa vs {days} días anteriores'**
  String reportComparisonTitle(int days);

  /// No description provided for @reportComparisonMetric.
  ///
  /// In es, this message translates to:
  /// **'Métrica'**
  String get reportComparisonMetric;

  /// No description provided for @reportComparisonCurrent.
  ///
  /// In es, this message translates to:
  /// **'Actual'**
  String get reportComparisonCurrent;

  /// No description provided for @reportComparisonPrevious.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get reportComparisonPrevious;

  /// No description provided for @reportComparisonChange.
  ///
  /// In es, this message translates to:
  /// **'Variación'**
  String get reportComparisonChange;

  /// No description provided for @reportComparisonNew.
  ///
  /// In es, this message translates to:
  /// **'nuevo'**
  String get reportComparisonNew;

  /// No description provided for @reportWeightTrendsTitle.
  ///
  /// In es, this message translates to:
  /// **'Peso · tendencias'**
  String get reportWeightTrendsTitle;

  /// No description provided for @reportWeightTrendDays.
  ///
  /// In es, this message translates to:
  /// **'Tendencia {days} días'**
  String reportWeightTrendDays(int days);

  /// No description provided for @reportWeightGainDays.
  ///
  /// In es, this message translates to:
  /// **'Ganancia {days} días'**
  String reportWeightGainDays(int days);

  /// No description provided for @reportExecutiveSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get reportExecutiveSummary;

  /// No description provided for @reportCurrentWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso actual'**
  String get reportCurrentWeight;

  /// No description provided for @reportCurrentHeight.
  ///
  /// In es, this message translates to:
  /// **'Talla actual'**
  String get reportCurrentHeight;

  /// No description provided for @reportCurrentPercentile.
  ///
  /// In es, this message translates to:
  /// **'Percentil OMS'**
  String get reportCurrentPercentile;

  /// No description provided for @reportWeightForAgePercentile.
  ///
  /// In es, this message translates to:
  /// **'Percentil OMS (peso/edad)'**
  String get reportWeightForAgePercentile;

  /// No description provided for @reportLengthForAgePercentile.
  ///
  /// In es, this message translates to:
  /// **'Percentil OMS (talla/edad)'**
  String get reportLengthForAgePercentile;

  /// No description provided for @reportCalculatedPercentileValue.
  ///
  /// In es, this message translates to:
  /// **'{value}'**
  String reportCalculatedPercentileValue(int value);

  /// No description provided for @reportPercentileChip.
  ///
  /// In es, this message translates to:
  /// **'P{value}'**
  String reportPercentileChip(int value);

  /// No description provided for @reportPercentileBelow.
  ///
  /// In es, this message translates to:
  /// **'< P3'**
  String get reportPercentileBelow;

  /// No description provided for @reportPercentileAbove.
  ///
  /// In es, this message translates to:
  /// **'> P97'**
  String get reportPercentileAbove;

  /// No description provided for @reportSummaryGrowthGroup.
  ///
  /// In es, this message translates to:
  /// **'Crecimiento'**
  String get reportSummaryGrowthGroup;

  /// No description provided for @reportSummaryRoutineGroup.
  ///
  /// In es, this message translates to:
  /// **'Alimentación y pañales'**
  String get reportSummaryRoutineGroup;

  /// No description provided for @reportSummaryMeasuredOn.
  ///
  /// In es, this message translates to:
  /// **'Última medición'**
  String get reportSummaryMeasuredOn;

  /// No description provided for @reportSinceLastWeighIn.
  ///
  /// In es, this message translates to:
  /// **'Desde última pesada'**
  String get reportSinceLastWeighIn;

  /// No description provided for @reportDaysSinceWeighIn.
  ///
  /// In es, this message translates to:
  /// **'Días desde pesada'**
  String get reportDaysSinceWeighIn;

  /// No description provided for @reportDaysSinceHeight.
  ///
  /// In es, this message translates to:
  /// **'Días desde talla'**
  String get reportDaysSinceHeight;

  /// No description provided for @reportDaysCount.
  ///
  /// In es, this message translates to:
  /// **'{days} días'**
  String reportDaysCount(int days);

  /// No description provided for @reportPercentileChange.
  ///
  /// In es, this message translates to:
  /// **'Cambio de percentil'**
  String get reportPercentileChange;

  /// No description provided for @reportHeight.
  ///
  /// In es, this message translates to:
  /// **'Altura'**
  String get reportHeight;

  /// No description provided for @reportWeightSection.
  ///
  /// In es, this message translates to:
  /// **'Peso'**
  String get reportWeightSection;

  /// No description provided for @reportHeightSection.
  ///
  /// In es, this message translates to:
  /// **'Altura'**
  String get reportHeightSection;

  /// No description provided for @reportFeedingSection.
  ///
  /// In es, this message translates to:
  /// **'Alimentación'**
  String get reportFeedingSection;

  /// No description provided for @reportDiapersSection.
  ///
  /// In es, this message translates to:
  /// **'Pañales'**
  String get reportDiapersSection;

  /// No description provided for @reportSleepSection.
  ///
  /// In es, this message translates to:
  /// **'Sueño'**
  String get reportSleepSection;

  /// No description provided for @reportSleepTitle.
  ///
  /// In es, this message translates to:
  /// **'Sueño · últimos 7 días'**
  String get reportSleepTitle;

  /// No description provided for @reportSleepAveragePerRecordedDay.
  ///
  /// In es, this message translates to:
  /// **'Horas por día registrado'**
  String get reportSleepAveragePerRecordedDay;

  /// No description provided for @reportSleepHoursValue.
  ///
  /// In es, this message translates to:
  /// **'{hours} h'**
  String reportSleepHoursValue(String hours);

  /// No description provided for @reportSleepTotal.
  ///
  /// In es, this message translates to:
  /// **'Tiempo total dormido'**
  String get reportSleepTotal;

  /// No description provided for @reportSleepNaps.
  ///
  /// In es, this message translates to:
  /// **'Siestas'**
  String get reportSleepNaps;

  /// No description provided for @reportSleepNightWakings.
  ///
  /// In es, this message translates to:
  /// **'Despertares nocturnos'**
  String get reportSleepNightWakings;

  /// No description provided for @reportSleepNightWakingTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo total despierto por la noche'**
  String get reportSleepNightWakingTime;

  /// No description provided for @reportSleepDailyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sueño por día · últimos 7 días'**
  String get reportSleepDailyTitle;

  /// No description provided for @reportSleepDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get reportSleepDay;

  /// No description provided for @reportSleepDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get reportSleepDuration;

  /// No description provided for @reportSleepNapsPerRecordedDay.
  ///
  /// In es, this message translates to:
  /// **'Siestas por día registrado'**
  String get reportSleepNapsPerRecordedDay;

  /// No description provided for @reportSleepWakingsPerRecordedDay.
  ///
  /// In es, this message translates to:
  /// **'Despertares por día registrado'**
  String get reportSleepWakingsPerRecordedDay;

  /// No description provided for @reportSleepRecentSessions.
  ///
  /// In es, this message translates to:
  /// **'Sesiones de sueño recientes'**
  String get reportSleepRecentSessions;

  /// No description provided for @reportSleepStart.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get reportSleepStart;

  /// No description provided for @reportSleepEnd.
  ///
  /// In es, this message translates to:
  /// **'Fin'**
  String get reportSleepEnd;

  /// No description provided for @reportSleepType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get reportSleepType;

  /// No description provided for @reportSleepInProgress.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get reportSleepInProgress;

  /// No description provided for @reportWeightOverviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de peso'**
  String get reportWeightOverviewTitle;

  /// No description provided for @reportHeightOverviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de talla'**
  String get reportHeightOverviewTitle;

  /// No description provided for @reportFeedingDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle de lactancia'**
  String get reportFeedingDetailTitle;

  /// No description provided for @reportBreastfeedingDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle de lactancia'**
  String get reportBreastfeedingDetailTitle;

  /// No description provided for @reportBottleDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle de biberón'**
  String get reportBottleDetailTitle;

  /// No description provided for @reportBottleFeedsPerDay.
  ///
  /// In es, this message translates to:
  /// **'Biberones por día'**
  String get reportBottleFeedsPerDay;

  /// No description provided for @reportBottleAvgPerFeed.
  ///
  /// In es, this message translates to:
  /// **'ml medio por toma'**
  String get reportBottleAvgPerFeed;

  /// No description provided for @reportBottleTotalPeriod.
  ///
  /// In es, this message translates to:
  /// **'Total en {days} días'**
  String reportBottleTotalPeriod(int days);

  /// No description provided for @reportComparisonNoData.
  ///
  /// In es, this message translates to:
  /// **'—'**
  String get reportComparisonNoData;

  /// No description provided for @reportComparisonInsufficientHistory.
  ///
  /// In es, this message translates to:
  /// **'Se necesitan al menos 60 días de registros para comparar con el periodo anterior.'**
  String get reportComparisonInsufficientHistory;

  /// No description provided for @reportFeedingInterval.
  ///
  /// In es, this message translates to:
  /// **'Intervalo medio entre tomas'**
  String get reportFeedingInterval;

  /// No description provided for @reportFeedingLongestGap.
  ///
  /// In es, this message translates to:
  /// **'Tramo más largo sin comer'**
  String get reportFeedingLongestGap;

  /// No description provided for @reportFeedingBreastBalance.
  ///
  /// In es, this message translates to:
  /// **'Balance pecho I / D'**
  String get reportFeedingBreastBalance;

  /// No description provided for @reportFeedingBreastBalanceValue.
  ///
  /// In es, this message translates to:
  /// **'{left}% / {right}%'**
  String reportFeedingBreastBalanceValue(int left, int right);

  /// No description provided for @reportFeedingAvgSession.
  ///
  /// In es, this message translates to:
  /// **'Duración media toma pecho'**
  String get reportFeedingAvgSession;

  /// No description provided for @reportFeedingEstimatedBreast.
  ///
  /// In es, this message translates to:
  /// **'Pecho estimado / día'**
  String get reportFeedingEstimatedBreast;

  /// No description provided for @reportFeedingEstimatedBreastStarred.
  ///
  /// In es, this message translates to:
  /// **'Pecho estimado / día*'**
  String get reportFeedingEstimatedBreastStarred;

  /// No description provided for @reportEstimatedBreastFootnote.
  ///
  /// In es, this message translates to:
  /// **'* Estimación a partir del tiempo de pecho (no es una medición). Conversión: ml = 140 x (1 - e^(-minutos/9)).'**
  String get reportEstimatedBreastFootnote;

  /// No description provided for @reportCoverageLabel.
  ///
  /// In es, this message translates to:
  /// **'Registro: {logged} de {total} días'**
  String reportCoverageLabel(int logged, int total);

  /// No description provided for @reportCoverageLowWarning.
  ///
  /// In es, this message translates to:
  /// **'Las medias pueden no ser representativas (registro incompleto).'**
  String get reportCoverageLowWarning;

  /// No description provided for @reportLegalDisclaimer.
  ///
  /// In es, this message translates to:
  /// **'Herramienta de seguimiento personal. Los datos no sustituyen la valoración de un profesional sanitario.'**
  String get reportLegalDisclaimer;

  /// No description provided for @reportFeedingFirstSolid.
  ///
  /// In es, this message translates to:
  /// **'Primera toma de sólidos'**
  String get reportFeedingFirstSolid;

  /// No description provided for @reportNoSolidFoodYet.
  ///
  /// In es, this message translates to:
  /// **'Sin sólidos registrados'**
  String get reportNoSolidFoodYet;

  /// No description provided for @reportWetDiapersPerDay.
  ///
  /// In es, this message translates to:
  /// **'Mojados por día'**
  String get reportWetDiapersPerDay;

  /// No description provided for @reportStoolDiapersPerDay.
  ///
  /// In es, this message translates to:
  /// **'Deposiciones por día'**
  String get reportStoolDiapersPerDay;

  /// No description provided for @reportDaysWithoutStool.
  ///
  /// In es, this message translates to:
  /// **'Días sin deposición'**
  String get reportDaysWithoutStool;

  /// No description provided for @reportDaysWithoutStoolOfPeriod.
  ///
  /// In es, this message translates to:
  /// **'{count} de {total} días'**
  String reportDaysWithoutStoolOfPeriod(int count, int total);

  /// No description provided for @reportComparisonAbsoluteChange.
  ///
  /// In es, this message translates to:
  /// **'{previous} → {current}'**
  String reportComparisonAbsoluteChange(String previous, String current);

  /// No description provided for @reportDiaperDistribution.
  ///
  /// In es, this message translates to:
  /// **'Distribución'**
  String get reportDiaperDistribution;

  /// No description provided for @reportDiaperDistributionValue.
  ///
  /// In es, this message translates to:
  /// **'{wet}% mojado · {dirty}% sucio · {both}% mixto'**
  String reportDiaperDistributionValue(int wet, int dirty, int both);

  /// No description provided for @premiumUnlockButton.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear'**
  String get premiumUnlockButton;

  /// No description provided for @premiumTeaserTitle.
  ///
  /// In es, this message translates to:
  /// **'ANÁLISIS PREMIUM'**
  String get premiumTeaserTitle;

  /// No description provided for @premiumTeaserSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lo que tus registros ya pueden contarte de {name}'**
  String premiumTeaserSubtitle(String name);

  /// No description provided for @premiumTeaserCta.
  ///
  /// In es, this message translates to:
  /// **'Prueba 7 días gratis'**
  String get premiumTeaserCta;

  /// No description provided for @premiumTeaserAfterPrice.
  ///
  /// In es, this message translates to:
  /// **'Después {price}/año · cancela cuando quieras'**
  String premiumTeaserAfterPrice(String price);

  /// No description provided for @premiumTeaserCancelAnytime.
  ///
  /// In es, this message translates to:
  /// **'Cancela cuando quieras'**
  String get premiumTeaserCancelAnytime;

  /// No description provided for @premiumTeaserMoreAnalyses.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Y 1 análisis más} other{Y {count} análisis más}}'**
  String premiumTeaserMoreAnalyses(int count);

  /// No description provided for @premiumTeaserBasedOnNights.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Basado en 1 noche registrada} other{Basado en {count} noches registradas}}'**
  String premiumTeaserBasedOnNights(int count);

  /// No description provided for @premiumTeaserBasedOnFeedingDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Basado en 1 día de tomas} other{Basado en {count} días de tomas}}'**
  String premiumTeaserBasedOnFeedingDays(int count);

  /// No description provided for @premiumTeaserBasedOnWeights.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Basado en 1 medida registrada} other{Basado en {count} medidas registradas}}'**
  String premiumTeaserBasedOnWeights(int count);

  /// No description provided for @premiumTeaserFeedingTrendTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo va comiendo hoy'**
  String get premiumTeaserFeedingTrendTitle;

  /// No description provided for @premiumTeaserFeedingTrendSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Comparado con sus días habituales'**
  String get premiumTeaserFeedingTrendSubtitle;

  /// No description provided for @premiumTeaserFeedingTrendHeadline.
  ///
  /// In es, this message translates to:
  /// **'Descubre cómo va comiendo hoy {name}'**
  String premiumTeaserFeedingTrendHeadline(String name);

  /// No description provided for @premiumTeaserSleepTitle.
  ///
  /// In es, this message translates to:
  /// **'Su hora óptima y sueños habituales'**
  String get premiumTeaserSleepTitle;

  /// No description provided for @premiumTeaserSleepSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Por previsión y patrones habituales'**
  String get premiumTeaserSleepSubtitle;

  /// No description provided for @premiumTeaserSleepHeadline.
  ///
  /// In es, this message translates to:
  /// **'Descubre cómo duerme {name}'**
  String premiumTeaserSleepHeadline(String name);

  /// No description provided for @premiumTeaserGrowthTitle.
  ///
  /// In es, this message translates to:
  /// **'Percentil OMS de peso y talla'**
  String get premiumTeaserGrowthTitle;

  /// No description provided for @premiumTeaserGrowthSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Curva completa y proyección'**
  String get premiumTeaserGrowthSubtitle;

  /// No description provided for @premiumTeaserGrowthHeadline.
  ///
  /// In es, this message translates to:
  /// **'Descubre el percentil OMS de peso y talla de {name}'**
  String premiumTeaserGrowthHeadline(String name);

  /// No description provided for @settingsGroupSubscription.
  ///
  /// In es, this message translates to:
  /// **'Suscripción'**
  String get settingsGroupSubscription;

  /// No description provided for @settingsRowManageSubscription.
  ///
  /// In es, this message translates to:
  /// **'Gestionar suscripción'**
  String get settingsRowManageSubscription;

  /// No description provided for @settingsRowSubscriptionActive.
  ///
  /// In es, this message translates to:
  /// **'Premium activo'**
  String get settingsRowSubscriptionActive;

  /// No description provided for @settingsRowSubscriptionInactive.
  ///
  /// In es, this message translates to:
  /// **'Plan gratuito'**
  String get settingsRowSubscriptionInactive;

  /// No description provided for @settingsRowSubscriptionFamily.
  ///
  /// In es, this message translates to:
  /// **'Premium compartido por tu familia'**
  String get settingsRowSubscriptionFamily;

  /// No description provided for @settingsRowSubscribe.
  ///
  /// In es, this message translates to:
  /// **'Hazte premium'**
  String get settingsRowSubscribe;

  /// No description provided for @settingsRowSubscribeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Desbloquea el análisis y el seguimiento avanzado'**
  String get settingsRowSubscribeSubtitle;

  /// No description provided for @settingsRowRestorePurchases.
  ///
  /// In es, this message translates to:
  /// **'Restaurar compras'**
  String get settingsRowRestorePurchases;

  /// No description provided for @restorePurchasesSuccess.
  ///
  /// In es, this message translates to:
  /// **'Compras restauradas correctamente'**
  String get restorePurchasesSuccess;

  /// No description provided for @restorePurchasesEmpty.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron compras para restaurar'**
  String get restorePurchasesEmpty;

  /// No description provided for @settingsRowComplimentaryPremium.
  ///
  /// In es, this message translates to:
  /// **'Premium de regalo'**
  String get settingsRowComplimentaryPremium;

  /// No description provided for @settingsRowComplimentaryPremiumUntil.
  ///
  /// In es, this message translates to:
  /// **'Gratis hasta el {date}'**
  String settingsRowComplimentaryPremiumUntil(String date);

  /// No description provided for @settingsRowRestorePurchasesGiftHint.
  ///
  /// In es, this message translates to:
  /// **'Si compraste una suscripción, restáurala aquí'**
  String get settingsRowRestorePurchasesGiftHint;

  /// No description provided for @restorePurchasesGiftDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Premium de regalo'**
  String get restorePurchasesGiftDialogTitle;

  /// No description provided for @restorePurchasesGiftDialogBody.
  ///
  /// In es, this message translates to:
  /// **'Tu acceso Premium es un regalo temporal de la app. No hay ninguna compra que restaurar. Si quieres seguir con Premium cuando termine, podrás suscribirte desde ajustes.'**
  String get restorePurchasesGiftDialogBody;

  /// No description provided for @premiumLaunchNoticeTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Gracias por confiar en nosotros!'**
  String get premiumLaunchNoticeTitle;

  /// No description provided for @premiumLaunchNoticeBodyGift.
  ///
  /// In es, this message translates to:
  /// **'Detrás de esta app hay una familia como la tuya, y como agradecimiento por acompañarnos desde el inicio, hemos desbloqueado todas las funciones Premium que hemos añadido en esta actualización totalmente gratis para tu familia hasta el {date}.'**
  String premiumLaunchNoticeBodyGift(String date);

  /// No description provided for @premiumLaunchNoticeBodyEssential.
  ///
  /// In es, this message translates to:
  /// **'Lo esencial seguirá siendo gratuito, siempre.'**
  String get premiumLaunchNoticeBodyEssential;

  /// No description provided for @premiumLaunchNoticeSignOff.
  ///
  /// In es, this message translates to:
  /// **'Un cálido abrazo,'**
  String get premiumLaunchNoticeSignOff;

  /// No description provided for @premiumLaunchNoticeSignatureName.
  ///
  /// In es, this message translates to:
  /// **'S.'**
  String get premiumLaunchNoticeSignatureName;

  /// No description provided for @premiumLaunchNoticeDismiss.
  ///
  /// In es, this message translates to:
  /// **'¡Entendido!'**
  String get premiumLaunchNoticeDismiss;

  /// No description provided for @premiumExpiryWarningTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu Premium termina pronto'**
  String get premiumExpiryWarningTitle;

  /// No description provided for @premiumExpiryWarningBodyDays.
  ///
  /// In es, this message translates to:
  /// **'Te quedan {days} días de Premium. Si no renuevas, perderás el análisis, gráficos de evolución, informe PDF y compartir familia por QR.'**
  String premiumExpiryWarningBodyDays(int days);

  /// No description provided for @premiumExpiryWarningBodyToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy termina tu Premium. Si no renuevas, perderás el análisis, gráficos de evolución, informe PDF y compartir familia por QR.'**
  String get premiumExpiryWarningBodyToday;

  /// No description provided for @premiumExpiryWarningBodyGiftDays.
  ///
  /// In es, this message translates to:
  /// **'Te quedan {days} días de tu regalo Premium. Después volverás al plan gratuito de siempre, con todo lo esencial intacto.\n\nSi estas funciones te han facilitado el día a día, puedes conservarlas suscribiéndote.'**
  String premiumExpiryWarningBodyGiftDays(int days);

  /// No description provided for @premiumExpiryWarningBodyGiftToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy termina tu regalo Premium. Después volverás al plan gratuito de siempre, con todo lo esencial intacto.\n\nSi estas funciones te han facilitado el día a día, puedes conservarlas suscribiéndote.'**
  String get premiumExpiryWarningBodyGiftToday;

  /// No description provided for @premiumExpiryWarningRenew.
  ///
  /// In es, this message translates to:
  /// **'Hazte premium'**
  String get premiumExpiryWarningRenew;

  /// No description provided for @premiumExpiryWarningDismiss.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get premiumExpiryWarningDismiss;

  /// No description provided for @paywallTitle.
  ///
  /// In es, this message translates to:
  /// **'Hazte premium'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Todo lo que te faltaba para cuidar y entender mejor a tu bebé.'**
  String get paywallSubtitle;

  /// No description provided for @paywallFeatureInsights.
  ///
  /// In es, this message translates to:
  /// **'Todo el análisis y las gráficas de evolución'**
  String get paywallFeatureInsights;

  /// No description provided for @paywallFeatureFeedingTrack.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento de las tomas diarias'**
  String get paywallFeatureFeedingTrack;

  /// No description provided for @paywallFeatureSleepTrack.
  ///
  /// In es, this message translates to:
  /// **'Análisis del sueño y predicción del siguiente'**
  String get paywallFeatureSleepTrack;

  /// No description provided for @paywallFeatureFamily.
  ///
  /// In es, this message translates to:
  /// **'Comparte con tu familia por QR'**
  String get paywallFeatureFamily;

  /// No description provided for @paywallFeaturePdf.
  ///
  /// In es, this message translates to:
  /// **'Informe PDF para el pediatra'**
  String get paywallFeaturePdf;

  /// No description provided for @paywallBadgeBestValue.
  ///
  /// In es, this message translates to:
  /// **'MEJOR PRECIO'**
  String get paywallBadgeBestValue;

  /// No description provided for @paywallBadgeRecommended.
  ///
  /// In es, this message translates to:
  /// **'Recomendado'**
  String get paywallBadgeRecommended;

  /// No description provided for @paywallAnnualMonthlyEquivalent.
  ///
  /// In es, this message translates to:
  /// **'Equivale a {price}/mes'**
  String paywallAnnualMonthlyEquivalent(String price);

  /// No description provided for @paywallTrialBadge.
  ///
  /// In es, this message translates to:
  /// **'7 días gratis'**
  String get paywallTrialBadge;

  /// No description provided for @paywallPlanAnnual.
  ///
  /// In es, this message translates to:
  /// **'Anual'**
  String get paywallPlanAnnual;

  /// No description provided for @paywallPlanMonthly.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get paywallPlanMonthly;

  /// No description provided for @paywallPlanGeneric.
  ///
  /// In es, this message translates to:
  /// **'Suscripción'**
  String get paywallPlanGeneric;

  /// No description provided for @paywallPerYear.
  ///
  /// In es, this message translates to:
  /// **'/año'**
  String get paywallPerYear;

  /// No description provided for @paywallPerMonth.
  ///
  /// In es, this message translates to:
  /// **'/mes'**
  String get paywallPerMonth;

  /// No description provided for @paywallPerWeek.
  ///
  /// In es, this message translates to:
  /// **'/semana'**
  String get paywallPerWeek;

  /// No description provided for @paywallCtaTrial.
  ///
  /// In es, this message translates to:
  /// **'Empezar prueba gratis'**
  String get paywallCtaTrial;

  /// No description provided for @paywallCtaSubscribe.
  ///
  /// In es, this message translates to:
  /// **'Suscribirme'**
  String get paywallCtaSubscribe;

  /// No description provided for @paywallRestore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar compras'**
  String get paywallRestore;

  /// No description provided for @paywallTerms.
  ///
  /// In es, this message translates to:
  /// **'Términos'**
  String get paywallTerms;

  /// No description provided for @paywallPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get paywallPrivacy;

  /// No description provided for @paywallLegal.
  ///
  /// In es, this message translates to:
  /// **'Renovación automática. Cancela en Ajustes al menos 24 h antes del fin del periodo.'**
  String get paywallLegal;

  /// No description provided for @paywallPurchaseError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la compra. Inténtalo de nuevo.'**
  String get paywallPurchaseError;

  /// No description provided for @paywallLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los planes. Revisa tu conexión.'**
  String get paywallLoadError;

  /// No description provided for @paywallClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get paywallClose;

  /// No description provided for @onboardingFlowContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get onboardingFlowContinue;

  /// No description provided for @onboardingFlowBornTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Ya ha nacido?'**
  String get onboardingFlowBornTitle;

  /// No description provided for @onboardingFlowBornSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Preparamos su perfil en un minuto'**
  String get onboardingFlowBornSubtitle;

  /// No description provided for @onboardingFlowBornOption.
  ///
  /// In es, this message translates to:
  /// **'Ya ha nacido'**
  String get onboardingFlowBornOption;

  /// No description provided for @onboardingFlowPregnantOption.
  ///
  /// In es, this message translates to:
  /// **'Esperando un bebé'**
  String get onboardingFlowPregnantOption;

  /// No description provided for @onboardingFlowHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'Ya tengo cuenta'**
  String get onboardingFlowHaveAccount;

  /// No description provided for @onboardingFlowQrInvite.
  ///
  /// In es, this message translates to:
  /// **'Me han invitado a una familia'**
  String get onboardingFlowQrInvite;

  /// No description provided for @onboardingFlowNameTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuál es el nombre de tu bebé?'**
  String get onboardingFlowNameTitle;

  /// No description provided for @onboardingFlowNameSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Personalizaremos la app con su nombre'**
  String get onboardingFlowNameSubtitle;

  /// No description provided for @onboardingFlowNameHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre del bebé'**
  String get onboardingFlowNameHint;

  /// No description provided for @onboardingFlowNameUndecided.
  ///
  /// In es, this message translates to:
  /// **'Todavía no lo hemos decidido'**
  String get onboardingFlowNameUndecided;

  /// No description provided for @onboardingFlowGenderTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Es un chico o una chica?'**
  String get onboardingFlowGenderTitle;

  /// No description provided for @onboardingFlowGenderTitleNamed.
  ///
  /// In es, this message translates to:
  /// **'¿{name} es un chico o una chica?'**
  String onboardingFlowGenderTitleNamed(String name);

  /// No description provided for @onboardingFlowGenderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Las curvas de crecimiento de la OMS son distintas para niños y niñas'**
  String get onboardingFlowGenderSubtitle;

  /// No description provided for @onboardingFlowBabyGeneric.
  ///
  /// In es, this message translates to:
  /// **'el bebé'**
  String get onboardingFlowBabyGeneric;

  /// No description provided for @onboardingFlowBabyGenericYour.
  ///
  /// In es, this message translates to:
  /// **'tu bebé'**
  String get onboardingFlowBabyGenericYour;

  /// No description provided for @onboardingFlowBabyDefaultName.
  ///
  /// In es, this message translates to:
  /// **'Tu bebé'**
  String get onboardingFlowBabyDefaultName;

  /// No description provided for @onboardingFlowBirthTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo nació {name}?'**
  String onboardingFlowBirthTitle(String name);

  /// No description provided for @onboardingFlowDueTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo es la fecha prevista de {name}?'**
  String onboardingFlowDueTitle(String name);

  /// No description provided for @onboardingFlowBirthSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Calcularemos su edad y percentiles'**
  String get onboardingFlowBirthSubtitle;

  /// No description provided for @onboardingFlowAgeHasMonthsDays.
  ///
  /// In es, this message translates to:
  /// **'{name} tiene {months} meses y {days} días'**
  String onboardingFlowAgeHasMonthsDays(String name, int months, int days);

  /// No description provided for @onboardingFlowAgeHasMonths.
  ///
  /// In es, this message translates to:
  /// **'{name} tiene {months} meses'**
  String onboardingFlowAgeHasMonths(String name, int months);

  /// No description provided for @onboardingFlowAgeHasDays.
  ///
  /// In es, this message translates to:
  /// **'{name} tiene {days} días'**
  String onboardingFlowAgeHasDays(String name, int days);

  /// No description provided for @onboardingFlowDueInDays.
  ///
  /// In es, this message translates to:
  /// **'{name} nacerá en {days} días'**
  String onboardingFlowDueInDays(String name, int days);

  /// No description provided for @onboardingFlowDueInOneDay.
  ///
  /// In es, this message translates to:
  /// **'{name} nacerá en 1 día'**
  String onboardingFlowDueInOneDay(String name);

  /// No description provided for @onboardingFlowDueToday.
  ///
  /// In es, this message translates to:
  /// **'{name} nacerá hoy'**
  String onboardingFlowDueToday(String name);

  /// No description provided for @onboardingFlowMeasuresTitle.
  ///
  /// In es, this message translates to:
  /// **'Medidas de la última revisión'**
  String get onboardingFlowMeasuresTitle;

  /// No description provided for @onboardingFlowMeasuresSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Opcional, con esto veremos su curva de crecimiento'**
  String get onboardingFlowMeasuresSubtitle;

  /// No description provided for @onboardingFlowMeasuresLater.
  ///
  /// In es, this message translates to:
  /// **'Las añado más tarde'**
  String get onboardingFlowMeasuresLater;

  /// No description provided for @onboardingFlowWeightLabel.
  ///
  /// In es, this message translates to:
  /// **'Peso'**
  String get onboardingFlowWeightLabel;

  /// No description provided for @onboardingFlowHeightLabel.
  ///
  /// In es, this message translates to:
  /// **'Talla'**
  String get onboardingFlowHeightLabel;

  /// No description provided for @onboardingFlowWeightRangeHint.
  ///
  /// In es, this message translates to:
  /// **'Revisa el peso: suele estar entre 0,5 y 30 kg'**
  String get onboardingFlowWeightRangeHint;

  /// No description provided for @onboardingFlowHeightRangeHint.
  ///
  /// In es, this message translates to:
  /// **'Revisa la talla: suele estar entre 30 y 120 cm'**
  String get onboardingFlowHeightRangeHint;

  /// No description provided for @onboardingFlowWeightUnitTitle.
  ///
  /// In es, this message translates to:
  /// **'Unidad de peso'**
  String get onboardingFlowWeightUnitTitle;

  /// No description provided for @onboardingFlowHeightUnitTitle.
  ///
  /// In es, this message translates to:
  /// **'Unidad de talla'**
  String get onboardingFlowHeightUnitTitle;

  /// No description provided for @onboardingFlowHeightUnitCm.
  ///
  /// In es, this message translates to:
  /// **'Centímetros (cm)'**
  String get onboardingFlowHeightUnitCm;

  /// No description provided for @onboardingFlowHeightUnitIn.
  ///
  /// In es, this message translates to:
  /// **'Pulgadas (in)'**
  String get onboardingFlowHeightUnitIn;

  /// No description provided for @onboardingFlowWeightUnitKg.
  ///
  /// In es, this message translates to:
  /// **'Kilogramos (kg)'**
  String get onboardingFlowWeightUnitKg;

  /// No description provided for @onboardingFlowWeightUnitLb.
  ///
  /// In es, this message translates to:
  /// **'Libras (lb)'**
  String get onboardingFlowWeightUnitLb;

  /// No description provided for @onboardingFlowPreparingTitle.
  ///
  /// In es, this message translates to:
  /// **'Preparando los datos de tu bebé'**
  String get onboardingFlowPreparingTitle;

  /// No description provided for @onboardingFlowCalcPercentiles.
  ///
  /// In es, this message translates to:
  /// **'Calculando percentiles OMS de {name}'**
  String onboardingFlowCalcPercentiles(String name);

  /// No description provided for @onboardingFlowCalcWhoCurve.
  ///
  /// In es, this message translates to:
  /// **'Calculando curva OMS para {months} meses'**
  String onboardingFlowCalcWhoCurve(int months);

  /// No description provided for @onboardingFlowCalcFeeding.
  ///
  /// In es, this message translates to:
  /// **'Calculando ritmo de tomas'**
  String get onboardingFlowCalcFeeding;

  /// No description provided for @onboardingFlowCalcSleep.
  ///
  /// In es, this message translates to:
  /// **'Calculando rutinas del sueño'**
  String get onboardingFlowCalcSleep;

  /// No description provided for @onboardingFlowCalcDueDate.
  ///
  /// In es, this message translates to:
  /// **'Calculando fecha prevista'**
  String get onboardingFlowCalcDueDate;

  /// No description provided for @onboardingFlowCalcNewbornReady.
  ///
  /// In es, this message translates to:
  /// **'Preparando todo para el nacimiento'**
  String get onboardingFlowCalcNewbornReady;

  /// No description provided for @onboardingFlowCalcNewbornFeeding.
  ///
  /// In es, this message translates to:
  /// **'Preparando ritmo de tomas del recién nacido'**
  String get onboardingFlowCalcNewbornFeeding;

  /// No description provided for @onboardingFlowCalcNewbornRoutines.
  ///
  /// In es, this message translates to:
  /// **'Preparando rutinas de sueño del recién nacido'**
  String get onboardingFlowCalcNewbornRoutines;

  /// No description provided for @onboardingFlowResultsTitle.
  ///
  /// In es, this message translates to:
  /// **'Todo listo para {name}'**
  String onboardingFlowResultsTitle(String name);

  /// No description provided for @onboardingFlowResultsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Esto es lo que hemos preparado para su edad'**
  String get onboardingFlowResultsSubtitle;

  /// No description provided for @onboardingFlowResultsSubtitlePregnant.
  ///
  /// In es, this message translates to:
  /// **'Todo quedará listo para cuando nazca'**
  String get onboardingFlowResultsSubtitlePregnant;

  /// No description provided for @onboardingFlowResultAgeLabel.
  ///
  /// In es, this message translates to:
  /// **'Edad de {name}'**
  String onboardingFlowResultAgeLabel(String name);

  /// No description provided for @onboardingFlowResultAgeMonths.
  ///
  /// In es, this message translates to:
  /// **'{months} meses'**
  String onboardingFlowResultAgeMonths(int months);

  /// No description provided for @onboardingFlowResultAgeMonthsDays.
  ///
  /// In es, this message translates to:
  /// **'{months} meses y {days} días'**
  String onboardingFlowResultAgeMonthsDays(int months, int days);

  /// No description provided for @onboardingFlowResultAgeOneDay.
  ///
  /// In es, this message translates to:
  /// **'1 día'**
  String get onboardingFlowResultAgeOneDay;

  /// No description provided for @onboardingFlowResultAgeDays.
  ///
  /// In es, this message translates to:
  /// **'{days} días'**
  String onboardingFlowResultAgeDays(int days);

  /// No description provided for @onboardingFlowResultAgeOneYear.
  ///
  /// In es, this message translates to:
  /// **'1 año'**
  String get onboardingFlowResultAgeOneYear;

  /// No description provided for @onboardingFlowResultAgeYears.
  ///
  /// In es, this message translates to:
  /// **'{years} años'**
  String onboardingFlowResultAgeYears(int years);

  /// No description provided for @onboardingFlowResultAgeOneYearHalf.
  ///
  /// In es, this message translates to:
  /// **'1 año y medio'**
  String get onboardingFlowResultAgeOneYearHalf;

  /// No description provided for @onboardingFlowResultAgeYearsHalf.
  ///
  /// In es, this message translates to:
  /// **'{years} años y medio'**
  String onboardingFlowResultAgeYearsHalf(int years);

  /// No description provided for @onboardingFlowResultDueHeroLabel.
  ///
  /// In es, this message translates to:
  /// **'Faltan'**
  String get onboardingFlowResultDueHeroLabel;

  /// No description provided for @onboardingFlowResultDueHeroDays.
  ///
  /// In es, this message translates to:
  /// **'{days} días'**
  String onboardingFlowResultDueHeroDays(int days);

  /// No description provided for @onboardingFlowResultDueHeroOne.
  ///
  /// In es, this message translates to:
  /// **'1 día'**
  String get onboardingFlowResultDueHeroOne;

  /// No description provided for @onboardingFlowResultDueHeroToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get onboardingFlowResultDueHeroToday;

  /// No description provided for @onboardingFlowResultDueDateCaption.
  ///
  /// In es, this message translates to:
  /// **'Fecha prevista: {date}'**
  String onboardingFlowResultDueDateCaption(String date);

  /// No description provided for @onboardingFlowResultGrowthTitle.
  ///
  /// In es, this message translates to:
  /// **'Crecimiento OMS'**
  String get onboardingFlowResultGrowthTitle;

  /// No description provided for @onboardingFlowResultWeightPct.
  ///
  /// In es, this message translates to:
  /// **'Peso'**
  String get onboardingFlowResultWeightPct;

  /// No description provided for @onboardingFlowResultHeightPct.
  ///
  /// In es, this message translates to:
  /// **'Talla'**
  String get onboardingFlowResultHeightPct;

  /// No description provided for @onboardingFlowResultNoWeight.
  ///
  /// In es, this message translates to:
  /// **'Sin dato'**
  String get onboardingFlowResultNoWeight;

  /// No description provided for @onboardingFlowResultNoHeight.
  ///
  /// In es, this message translates to:
  /// **'Sin dato'**
  String get onboardingFlowResultNoHeight;

  /// No description provided for @onboardingFlowResultNoWeightHeight.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay peso ni talla. Podrás añadirlos cuando quieras.'**
  String get onboardingFlowResultNoWeightHeight;

  /// No description provided for @onboardingFlowResultWhoMedian.
  ///
  /// In es, this message translates to:
  /// **'Mediana OMS a su edad: {weight} · {height}'**
  String onboardingFlowResultWhoMedian(String weight, String height);

  /// No description provided for @onboardingFlowResultPercentileContext.
  ///
  /// In es, this message translates to:
  /// **'P3 está dentro del rango de referencia. Lo importante es la evolución, no un dato aislado.'**
  String get onboardingFlowResultPercentileContext;

  /// No description provided for @onboardingFlowResultMedicalDisclaimer.
  ///
  /// In es, this message translates to:
  /// **'Orientativo según curvas OMS. No sustituye el criterio de tu pediatra.'**
  String get onboardingFlowResultMedicalDisclaimer;

  /// No description provided for @onboardingFlowResultFeedingTitle.
  ///
  /// In es, this message translates to:
  /// **'Tomas'**
  String get onboardingFlowResultFeedingTitle;

  /// No description provided for @onboardingFlowResultMealsTitle.
  ///
  /// In es, this message translates to:
  /// **'Alimentación'**
  String get onboardingFlowResultMealsTitle;

  /// No description provided for @onboardingFlowResultFeedingValue.
  ///
  /// In es, this message translates to:
  /// **'Cada {interval}'**
  String onboardingFlowResultFeedingValue(String interval);

  /// No description provided for @onboardingFlowResultFeedingMealsTransition.
  ///
  /// In es, this message translates to:
  /// **'Comidas + tomas de leche'**
  String get onboardingFlowResultFeedingMealsTransition;

  /// No description provided for @onboardingFlowResultFeedingMealsTransitionHint.
  ///
  /// In es, this message translates to:
  /// **'Se combina la leche con las comidas del día'**
  String get onboardingFlowResultFeedingMealsTransitionHint;

  /// No description provided for @onboardingFlowResultFeedingMealsToddler.
  ///
  /// In es, this message translates to:
  /// **'3 comidas y 2 tentempiés'**
  String get onboardingFlowResultFeedingMealsToddler;

  /// No description provided for @onboardingFlowResultFeedingMealsToddlerHint.
  ///
  /// In es, this message translates to:
  /// **'A esta edad ya no se organiza en tomas cada X horas'**
  String get onboardingFlowResultFeedingMealsToddlerHint;

  /// No description provided for @onboardingFlowResultFeedingHint.
  ///
  /// In es, this message translates to:
  /// **'Lo usaremos para avisarte de la siguiente toma'**
  String get onboardingFlowResultFeedingHint;

  /// No description provided for @onboardingFlowResultFeedingPregnantHint.
  ///
  /// In es, this message translates to:
  /// **'Ritmo típico de recién nacido, listo desde el día 1'**
  String get onboardingFlowResultFeedingPregnantHint;

  /// No description provided for @onboardingFlowResultSleepTitle.
  ///
  /// In es, this message translates to:
  /// **'Sueño'**
  String get onboardingFlowResultSleepTitle;

  /// No description provided for @onboardingFlowResultSleepWake.
  ///
  /// In es, this message translates to:
  /// **'Ventana de vigilia: {range}'**
  String onboardingFlowResultSleepWake(String range);

  /// No description provided for @onboardingFlowResultSleepTotal.
  ///
  /// In es, this message translates to:
  /// **'Unas {range} de sueño al día'**
  String onboardingFlowResultSleepTotal(String range);

  /// No description provided for @onboardingFlowResultSleepPregnantHint.
  ///
  /// In es, this message translates to:
  /// **'Ventanas cortas de recién nacido, listas al nacer'**
  String get onboardingFlowResultSleepPregnantHint;

  /// No description provided for @onboardingFlowResultWhoPregnant.
  ///
  /// In es, this message translates to:
  /// **'Las curvas OMS se activarán cuando nazca'**
  String get onboardingFlowResultWhoPregnant;

  /// No description provided for @onboardingFlowNotifyTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres activar las notificaciones para que te avisemos de la siguiente toma de {name}?'**
  String onboardingFlowNotifyTitle(String name);

  /// No description provided for @onboardingFlowNotifySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Para su edad te hemos configurado una toma cada {interval}, que es lo más habitual, pero lo puedes personalizar desde las opciones.'**
  String onboardingFlowNotifySubtitle(String interval);

  /// No description provided for @onboardingFlowNotifyTitleToddler.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres activar las notificaciones para {name}?'**
  String onboardingFlowNotifyTitleToddler(String name);

  /// No description provided for @onboardingFlowNotifySubtitleToddler.
  ///
  /// In es, this message translates to:
  /// **'Podrás recibir avisos de la app. A esta edad la alimentación ya no se cuenta en tomas cada X horas; lo personalizas cuando quieras en ajustes.'**
  String get onboardingFlowNotifySubtitleToddler;

  /// No description provided for @onboardingFlowNotifyEnable.
  ///
  /// In es, this message translates to:
  /// **'Activar notificaciones'**
  String get onboardingFlowNotifyEnable;

  /// No description provided for @onboardingFlowNotifyLater.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get onboardingFlowNotifyLater;

  /// No description provided for @onboardingFlowSaveTitle.
  ///
  /// In es, this message translates to:
  /// **'Guardar los datos de {name}'**
  String onboardingFlowSaveTitle(String name);

  /// No description provided for @onboardingFlowSaveSubtitle.
  ///
  /// In es, this message translates to:
  /// **'No pierdas los datos si cambias de móvil'**
  String get onboardingFlowSaveSubtitle;

  /// No description provided for @onboardingFlowContinueApple.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get onboardingFlowContinueApple;

  /// No description provided for @onboardingFlowContinueGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get onboardingFlowContinueGoogle;

  /// No description provided for @onboardingFlowContinueEmail.
  ///
  /// In es, this message translates to:
  /// **'Continuar con email'**
  String get onboardingFlowContinueEmail;

  /// No description provided for @onboardingFlowDataSafe.
  ///
  /// In es, this message translates to:
  /// **'Los datos de tu bebé están protegidos, cifrados y nunca se venden a terceros.'**
  String get onboardingFlowDataSafe;

  /// No description provided for @onboardingFlowQrNeedsConnection.
  ///
  /// In es, this message translates to:
  /// **'Se necesita conexión para unirse con QR'**
  String get onboardingFlowQrNeedsConnection;

  /// No description provided for @onboardingFlowQrOpenFail.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el escáner QR'**
  String get onboardingFlowQrOpenFail;

  /// No description provided for @onboardingFlowSaveFail.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron guardar los datos: {error}'**
  String onboardingFlowSaveFail(String error);

  /// No description provided for @onboardingFlowProfileAlreadyExistsTitle.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta ya tiene un perfil'**
  String get onboardingFlowProfileAlreadyExistsTitle;

  /// No description provided for @onboardingFlowProfileAlreadyExists.
  ///
  /// In es, this message translates to:
  /// **'Ese correo o cuenta ya tiene un perfil creado. Usa «Ya tengo cuenta» para entrar, o prueba con otra cuenta para no sobrescribir los datos.'**
  String get onboardingFlowProfileAlreadyExists;

  /// No description provided for @onboardingFlowProfileAlreadyExistsButton.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get onboardingFlowProfileAlreadyExistsButton;

  /// No description provided for @onboardingFlowAuthError.
  ///
  /// In es, this message translates to:
  /// **'Error de autenticación'**
  String get onboardingFlowAuthError;

  /// No description provided for @onboardingFlowSignInFail.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión'**
  String get onboardingFlowSignInFail;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
