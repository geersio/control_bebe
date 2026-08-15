// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MiBebé';

  @override
  String get navHome => 'INICIO';

  @override
  String get navDiapers => 'PAÑALES';

  @override
  String get navFeeding => 'TOMAS';

  @override
  String get navSleep => 'SUEÑO';

  @override
  String get navWeight => 'CRECER';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSaved => 'Guardado';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get deleteRecordConfirmTitle => '¿Eliminar este registro?';

  @override
  String get deleteRecordConfirmBody =>
      'Se borrará de forma permanente. Esta acción no se puede deshacer.';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonDate => 'Fecha';

  @override
  String get commonTime => 'Hora';

  @override
  String get commonDateTime => 'Fecha y hora';

  @override
  String get commonTimeStart => 'Hora inicio';

  @override
  String get commonTimeEnd => 'Hora fin';

  @override
  String get commonGenderBoy => 'Niño';

  @override
  String get commonGenderGirl => 'Niña';

  @override
  String get commonGenderUnspecified => 'Prefiero no decirlo';

  @override
  String get commonSend => 'Enviar';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonExit => 'Salir';

  @override
  String get historyTitle => 'Historial';

  @override
  String get historyScrollLoadMore =>
      'Desliza hasta el final para cargar tres días más de historial.';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

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
  String get feedingIntervalHoursOne => '1 hora';

  @override
  String feedingIntervalHoursN(Object n) {
    return '$n horas';
  }

  @override
  String feedingIntervalHoursMinutes(Object h, Object m) {
    return '${h}h ${m}min';
  }

  @override
  String get profileDefaultBabyName => 'Bebé';

  @override
  String get sleepTitle => 'Sueño';

  @override
  String get sleepBedtime => 'Se acuesta';

  @override
  String get sleepWake => 'Se despierta';

  @override
  String get sleepNightWakingsSection => 'Despertares nocturnos';

  @override
  String get sleepClockModeStart => 'Inicio sueño';

  @override
  String get sleepClockModeEnd => 'Fin sueño';

  @override
  String get sleepClockModeNightWaking => 'Despertar nocturno';

  @override
  String get sleepClockCenterStartLabel => 'Hora de inicio';

  @override
  String get sleepClockCenterEndLabel => 'Hora de fin';

  @override
  String get sleepClockCenterNightWakingLabel => 'Duración del despertar';

  @override
  String sleepDurationCenterMinutesOnly(Object m) {
    return '$m MIN';
  }

  @override
  String get sleepTypeNight => 'Sueño nocturno';

  @override
  String get sleepTypeNap => 'Siesta';

  @override
  String sleepTypeNapNumbered(int number) {
    return 'Siesta $number';
  }

  @override
  String get sleepRegisterButton => 'Guardar sueño';

  @override
  String get sleepRegisterStartButton => 'Guardar inicio';

  @override
  String get sleepRegisterEndButton => 'Guardar fin';

  @override
  String get sleepRegisterNightWakingButton => 'Guardar despertar';

  @override
  String get sleepEndPending => 'pendiente';

  @override
  String get sleepKeepOpenLabel => 'Sigue durmiendo';

  @override
  String get sleepNightWakingLabel => 'Despertar nocturno';

  @override
  String sleepWakingsSummary(Object count, Object minutes) {
    return '$count despertares · $minutes min desvelo';
  }

  @override
  String sleepWakingsSummaryOne(Object minutes) {
    return '1 despertar · $minutes min desvelo';
  }

  @override
  String get sleepNoOpenSessionToEnd =>
      'No hay un sueño en curso. Guarda primero el inicio.';

  @override
  String get sleepOpenSessionExists =>
      'Ya hay un sueño en curso. Guarda el fin o edítalo en el historial.';

  @override
  String get homeSleepInsightSleepingLabel => 'Durmiendo...';

  @override
  String homeSleepInsightSleepingSince(Object time) {
    return 'desde $time';
  }

  @override
  String homeSleepInsightSleepingValue(Object duration, Object time) {
    return '$duration · desde $time';
  }

  @override
  String get sleepStatusAwake => 'Despierto';

  @override
  String get sleepStatusSleeping => 'Durmiendo';

  @override
  String get sleepActionFellAsleep => 'Se durmió';

  @override
  String get sleepActionWokeUp => 'Se despertó';

  @override
  String sleepFellAsleepAt(Object time) {
    return 'Se durmió a las $time';
  }

  @override
  String sleepWokeUpAt(Object time) {
    return 'Se despertó a las $time';
  }

  @override
  String sleepSavesWithCurrentTime(Object time) {
    return 'se guarda con la hora actual · $time';
  }

  @override
  String get sleepAddNightWaking => 'Añadir despertar nocturno';

  @override
  String get sleepRegisterPastSleep => 'Añadir sueño anterior';

  @override
  String get sleepFellAsleepCaps => 'SE DURMIÓ';

  @override
  String get sleepWokeUpCaps => 'SE DESPERTÓ';

  @override
  String get sleepSleptPrefix => 'Durmió';

  @override
  String get sleepAwakePrefix => 'Despierto';

  @override
  String get sleepPastRegister => 'Registrar';

  @override
  String get sleepHistoryEmpty =>
      'Todavía no hay registros. Pulsa «Se durmió» arriba para añadir el primero.';

  @override
  String get sleepStreamError =>
      'No se pudieron cargar los registros de sueño. Reintenta o comprueba la conexión.';

  @override
  String get sleepEditRecord => 'Editar sueño';

  @override
  String get sleepSessionCountOne => '1 sueño';

  @override
  String sleepSessionCountN(Object n) {
    return '$n sueños';
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
  String get profileWeightLabel => 'PESO';

  @override
  String get profileHeightLabel => 'ALTURA';

  @override
  String get babyAgeMonthsOneDaysOne => '1 MES, 1 DÍA';

  @override
  String babyAgeMonthsOneDaysN(Object days) {
    return '1 MES, $days DÍAS';
  }

  @override
  String babyAgeMonthsNDaysOne(Object months) {
    return '$months MESES, 1 DÍA';
  }

  @override
  String babyAgeMonthsNDaysN(Object days, Object months) {
    return '$months MESES, $days DÍAS';
  }

  @override
  String get monthiversaryOne => '¡Hoy cumple 1 mes!';

  @override
  String monthiversaryN(Object months) {
    return '¡Hoy cumple $months meses!';
  }

  @override
  String get monthiversarySemanticsHint =>
      'Pulsa para confeti; hasta dos veces hasta que termine';

  @override
  String get homeSummaryTitle => 'Resumen de hoy';

  @override
  String get homeLastFeedLabel => 'ÚLTIMA TOMA';

  @override
  String homeLastFeedAgo(Object time) {
    return 'Hace $time';
  }

  @override
  String get homeNextFeedSoon => 'Próxima toma pronto';

  @override
  String homeNextFeedIn(Object time) {
    return 'Próxima toma en $time';
  }

  @override
  String get homeNoFeedingsYet =>
      'Sin tomas registradas aún. Toca para anotar la primera.';

  @override
  String get homeWeightNoRecords =>
      'No hay registros de peso. Toca para añadir el primero.';

  @override
  String homeWeightTrendGramsPerDay(Object sign, Object value) {
    return '$sign$value g/día';
  }

  @override
  String homeWeightTrendOuncesPerDay(Object sign, Object value) {
    return '$sign$value oz/día';
  }

  @override
  String homeHeightTrendCmPerDay(Object sign, Object value) {
    return '$sign$value cm/día';
  }

  @override
  String homeWeightLast(Object date) {
    return 'Último: $date';
  }

  @override
  String homeSleepPattern(int nights, int naps) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights nocturnos',
      one: '1 nocturno',
      zero: '0 nocturnos',
    );
    String _temp1 = intl.Intl.pluralLogic(
      naps,
      locale: localeName,
      other: '$naps siestas',
      one: '1 siesta',
      zero: '0 siestas',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get homeDiapersNoRecords =>
      'No hay pañales registrados. Toca para añadir el primero.';

  @override
  String homeDiapersWetDirty(Object dirty, Object wet) {
    return '$wet mojados · $dirty sucios';
  }

  @override
  String get homeDiaperChangesOne => '1 cambio';

  @override
  String homeDiaperChangesN(Object n) {
    return '$n cambios';
  }

  @override
  String get homeInsightsTitle => 'Análisis';

  @override
  String get homeFeedingDistributionTitle => 'Distribución de tomas';

  @override
  String get homeFeedingDistributionSevenDayAverage =>
      '≈ Media de los últimos 7 días';

  @override
  String get homeFeedingDistributionInfoTitle =>
      'Cómo se calcula la distribución';

  @override
  String get homeFeedingDistributionInfoBody =>
      'El gráfico muestra la proporción media de pecho, biberón y sólidos registrada durante los últimos 7 días.\n\nPara poder comparar los tipos de toma, los minutos de pecho se convierten en un equivalente aproximado en ml. Esta conversión es orientativa y no representa una medición exacta de la leche ingerida.';

  @override
  String get homeFeedingDistributionMlPerDay => 'ml/día';

  @override
  String get homeDiaperSpendInsightTitle => 'Pañales y gasto';

  @override
  String get homeDiaperSpendInsightDiapersPerDay => 'pañales/día';

  @override
  String homeDiaperSpendInsightWeekDelta(String delta) {
    return '$delta vs semana anterior';
  }

  @override
  String get homeDiaperSpendInsightMoreBadge => 'Más que la semana anterior';

  @override
  String get homeDiaperSpendInsightLessBadge => 'Menos que la semana anterior';

  @override
  String get homeDiaperSpendInsightSameBadge => 'Igual que la semana anterior';

  @override
  String get homeDiaperSpendInsightPerDay => 'Al día';

  @override
  String get homeDiaperSpendInsightPerMonth => 'Al mes';

  @override
  String homeDiaperSpendInsightMore(
    String name,
    String average,
    String cost,
    String monthlyCost,
  ) {
    return '$name está gastando de media $average pañales diarios. Más de los que gastó la semana anterior. Eso equivale aproximadamente a $cost al día y $monthlyCost al mes.';
  }

  @override
  String homeDiaperSpendInsightLess(
    String name,
    String average,
    String cost,
    String monthlyCost,
  ) {
    return '$name está gastando de media $average pañales diarios. Menos de los que gastó la semana anterior. Eso equivale aproximadamente a $cost al día y $monthlyCost al mes.';
  }

  @override
  String homeDiaperSpendInsightSame(
    String name,
    String average,
    String cost,
    String monthlyCost,
  ) {
    return '$name está gastando de media $average pañales diarios. Igual que la semana anterior. Eso equivale aproximadamente a $cost al día y $monthlyCost al mes.';
  }

  @override
  String get homeDiaperSpendInsightNoData =>
      'Registra pañales durante unos días para ver la media y el gasto estimado.';

  @override
  String get homeDiaperSpendInsightAddFirst =>
      'Añade el primer pañal de tu bebé';

  @override
  String get homeDiaperSpendInsightInfoTitle => 'Cálculo aproximado';

  @override
  String homeDiaperSpendInsightInfoBody(String price) {
    return 'El gasto se estima usando un precio medio de $price por pañal. Los pañales/día son la media de los últimos 7 días calendario (total de cambios ÷ 7). La etiqueta muestra la diferencia respecto a la media de los 7 días anteriores. El gasto mensual proyecta esa media a 30 días.';
  }

  @override
  String get homeSleepInsightTitle => 'Análisis del sueño';

  @override
  String get homeTodaysSleepTitle => 'Sueño de hoy';

  @override
  String get homeSleepInsightNextSleepLabel => 'Próxima hora de sueño';

  @override
  String get homeSleepInsightAddFirstSleep =>
      'Añade el primer sueño de tu bebé';

  @override
  String get homeSleepInsightBedtimeLabel => 'Próxima hora de acostarse';

  @override
  String homeSleepInsightNextSleepRelative(String duration) {
    return 'En $duration';
  }

  @override
  String homeSleepInsightNextSleepRelativePast(String duration) {
    return 'Hace $duration';
  }

  @override
  String homeSleepInsightNextSleepValue(String relative, String window) {
    return '$relative · $window';
  }

  @override
  String homeSleepInsightEstimatedWindow(String window) {
    return 'Franja estimada · $window';
  }

  @override
  String homeSleepInsightReasonShortNap(int minutes) {
    return 'Ventana acortada $minutes min por siesta corta anterior';
  }

  @override
  String get homeSleepInsightReasonBedtime =>
      'Ventana de acostarse por la noche';

  @override
  String get homeSleepInsightReasonCatnap =>
      'Siesta puente: ventanas del día agotadas';

  @override
  String get homeSleepInsightReasonEarlyBedtime =>
      'Acostarse temprano: ventanas del día agotadas';

  @override
  String homeSleepInsightReasonDefaultWake(String time) {
    return 'Sin registros hoy: se asume despertar a las $time';
  }

  @override
  String homeSleepInsightUsualAwakeBeforeNap(String name, String duration) {
    return '$name suele aguantar despierto $duration antes de esta siesta.';
  }

  @override
  String homeSleepInsightUsualAwakeBeforeBedtime(String name, String duration) {
    return '$name suele aguantar despierto $duration antes de acostarse.';
  }

  @override
  String homeSleepInsightAwakeNow(String duration) {
    return 'Ahora mismo lleva despierto $duration.';
  }

  @override
  String get homeSleepInsightPersonalizedHint =>
      'Ajustado con el ritmo de tu bebé';

  @override
  String get homeSleepInsightNoBirthDate =>
      'Añade la fecha de nacimiento en Ajustes para estimar el próximo sueño.';

  @override
  String get homeSleepInsightTodaySoFar => 'lleva hoy';

  @override
  String get homeSleepInsightUsuallySleeps => 'Media de sueño diario';

  @override
  String get homeSleepInsightLast7Days => 'ÚLTIMOS 7 DÍAS';

  @override
  String get homeSleepInsightAveragePrefix => 'media';

  @override
  String get homeSleepInsightChartToday => 'hoy';

  @override
  String get homeSleepInsightDayTimelineToday => 'Hoy';

  @override
  String homeSleepInsightDayTimelineTotal(String duration) {
    return '$duration en total';
  }

  @override
  String get homeSleepInsightBarNoData => 'Sin registros';

  @override
  String get homeSleepSlotMorningNap => 'Siesta de mañana';

  @override
  String get homeSleepSlotMiddayNap => 'Siesta de mediodía';

  @override
  String get homeSleepSlotAfternoonNap => 'Siesta de tarde';

  @override
  String get homeSleepSlotCatnap => 'Siesta puente';

  @override
  String get homeSleepSlotNightSleep => 'Sueño nocturno';

  @override
  String get homeSleepDurationLabel => 'Duración';

  @override
  String get homeSleepPatternHeaderLast14 =>
      'Horarios habituales (últimos 14 días)';

  @override
  String homeSleepSlotFrequencyCount(int count, int total) {
    return '$count de $total';
  }

  @override
  String get homeSleepPhraseWaiting => 'Aún no hay datos suficientes';

  @override
  String homeSleepPhraseFreqWithTime(int days, int total, String time) {
    return '$days de los últimos $total días, sobre las $time';
  }

  @override
  String homeSleepPhraseFreqOnly(int days, int total) {
    return 'Solo $days de los últimos $total días';
  }

  @override
  String homeSleepPhraseFreqPill(int days, int total) {
    return 'Solo $days de los últimos $total días';
  }

  @override
  String get homeSleepPhraseTrendFewerDays =>
      'Ocurre menos días que la semana pasada';

  @override
  String homeSleepPhraseTrendStartsLater(int minutes) {
    return 'Empieza unos $minutes min más tarde que la semana pasada';
  }

  @override
  String get homeSleepPhraseTrendShorter => 'Dura menos que la semana pasada';

  @override
  String homeSleepPhraseAlmostAlways(String time) {
    return 'Casi siempre sobre las $time';
  }

  @override
  String homeSleepPhraseUsuallyBetween(String start, String end) {
    return 'Suele empezar entre $start y $end';
  }

  @override
  String homeSleepPhraseMayBetween(String start, String end) {
    return 'Puede empezar entre $start y $end';
  }

  @override
  String homeSleepAbandonedNap(String name) {
    return '$name dejó esta siesta hace dos semanas';
  }

  @override
  String get homeSleepInsightNoData =>
      'Registra sueños durante unos días para ver el análisis.';

  @override
  String get homeSleepInsightInfoTitle => 'Sobre este análisis';

  @override
  String get homeSleepInsightInfoIntro =>
      'Estimación orientativa, no una hora exacta ni consejo médico.';

  @override
  String get homeSleepInsightInfoPredictTitle => 'Próximo sueño';

  @override
  String get homeSleepInsightInfoPredictBody =>
      'Parte del último despertar (fin de siesta o de noche) y suma una ventana de vigilia según la edad y tu historial reciente. El rango horario refleja esa variabilidad.\n\nSi hay un sueño en curso, verás «Durmiendo...» en lugar de la predicción.';

  @override
  String get homeSleepInsightInfoLoggingTitle => 'Cómo registrar';

  @override
  String get homeSleepInsightInfoLoggingBody =>
      'Marca inicio y fin del sueño. Siesta o nocturno se detectan solos.\n\nSi se despierta de madrugada y vuelve a dormir, usa «Despertar nocturno» (no otra siesta).';

  @override
  String get homeSleepInsightInfoMetricsTitle => 'Totales';

  @override
  String get homeSleepInsightInfoMetricsBody =>
      '«Últimos 7 días» es la media solo de los días con registros (si un día no tiene datos, no cuenta como 0). La barra de hoy usa rayas.';

  @override
  String get homeSleepInsightInfoScheduleTitle => 'Horarios habituales';

  @override
  String get homeSleepInsightInfoScheduleBody =>
      'Las horas de cada siesta y del nocturno son la mediana de los últimos 14 días, redondeadas a múltiplos de 5 minutos.\n\nLa pastilla junto al nombre indica en cuántos de esos 14 días hizo esa siesta (por ejemplo, 5 de 14).';

  @override
  String get homeTipTitle => 'Consejo del día';

  @override
  String get homeTipFallback =>
      'Los bebés pueden reconocer la voz de su madre desde el útero. Hablarles con calma refuerza ese vínculo.';

  @override
  String get homeFeedingTrendTitle => 'SEGUIMIENTO ALIMENTACIÓN HOY';

  @override
  String homeFeedingTrendLearningDays(int current, int required) {
    return '$current/$required días';
  }

  @override
  String get homeFeedingTrendStatusLearning => 'Aprendiendo...';

  @override
  String homeFeedingTrendStatusBelow(String name) {
    return '$name está comiendo por debajo de lo habitual a esta hora';
  }

  @override
  String homeFeedingTrendStatusUsual(String name) {
    return '$name está comiendo lo habitual a esta hora';
  }

  @override
  String homeFeedingTrendStatusAbove(String name) {
    return '$name está comiendo por encima de lo habitual a esta hora';
  }

  @override
  String get homeFeedingTrendStatusPhraseBelow =>
      ' está comiendo por debajo de lo habitual a esta hora';

  @override
  String get homeFeedingTrendStatusPhraseUsual =>
      ' está comiendo lo habitual a esta hora';

  @override
  String get homeFeedingTrendStatusPhraseAbove =>
      ' está comiendo por encima de lo habitual a esta hora';

  @override
  String get homeFeedingTrendHintBelow => 'Por debajo';

  @override
  String get homeFeedingTrendHintLearning => 'aprendiendo';

  @override
  String get homeFeedingTrendHintUsual => 'lo habitual';

  @override
  String get homeFeedingTrendHintAbove => 'Por encima';

  @override
  String get homeFeedingTrendTodayTotal => 'lleva hoy';

  @override
  String get homeFeedingTrendUsuallyStill => 'suele tomar aún';

  @override
  String get homeFeedingTrendInfoTitle => 'Cómo funciona este seguimiento';

  @override
  String get homeFeedingTrendInfoBody =>
      'Tomamos como referencia los últimos 14 días de tomas (biberón y pecho; los sólidos no entran). Hace falta al menos 2 días con tomas para dejar de “aprender” y poder comparar.\n\nA esta hora del día, comparamos lo que lleva hoy con el rango habitual de esos días: por debajo, lo habitual o por encima.\n\n“Suele tomar aún” es una estimación: la mediana de lo que suele acumular al final del día menos lo que ya lleva hoy.\n\nEl pecho no se mide en ml como un biberón, así que convertimos los minutos en un equivalente aproximado. Son cifras orientativas, no medidas exactas. Ante cualquier duda, consulta con tu pediatra.';

  @override
  String get homeFeedingTrendInfoButton => 'Entendido';

  @override
  String get sabiasQueNoBirthDate =>
      'Añade la fecha de nacimiento del bebé en ajustes para ver consejos según su edad.';

  @override
  String get homeConfigureProfileFirst =>
      'Configura primero el perfil del bebé en Ajustes';

  @override
  String get homePickPhoto => 'Elegir foto';

  @override
  String get homeRemovePhoto => 'Quitar foto del perfil';

  @override
  String get homePhotoRemoved => 'Foto del perfil eliminada';

  @override
  String homePhotoRemoveError(Object error) {
    return 'Error al quitar la foto: $error';
  }

  @override
  String get homePhotoUpdated => 'Foto actualizada';

  @override
  String homePhotoUploadError(Object error) {
    return 'Error al subir la foto: $error';
  }

  @override
  String get feedingTitle => 'Alimentación';

  @override
  String get feedingSessionType => 'Tipo de toma';

  @override
  String get feedingBreast => 'Pecho';

  @override
  String get feedingLeft => 'Izquierdo';

  @override
  String get feedingRight => 'Derecho';

  @override
  String get feedingBottle => 'Biberón';

  @override
  String get feedingSolidFood => 'Sólidos';

  @override
  String get solidFoodTitle => 'Alimento sólido';

  @override
  String get solidFoodNameLabel => 'Qué ha comido';

  @override
  String get solidFoodNameHint => 'Ej: puré de manzana';

  @override
  String get solidFoodQuantityLabel => 'Cantidad';

  @override
  String get solidFoodUnitGrams => 'g (gramos)';

  @override
  String get solidFoodUnitUnits => 'u (unidades)';

  @override
  String get solidFoodUnitGramShort => 'g';

  @override
  String get solidFoodUnitUnitsShort => 'u';

  @override
  String get solidFoodQuantityHintGrams => 'Ej: 40 o 0,47 (coma o punto)';

  @override
  String get solidFoodQuantityHintUnits => 'Solo número entero, ej: 2';

  @override
  String get solidFoodValidatorNameEmpty => 'Indica qué ha comido';

  @override
  String get solidFoodValidatorQuantityEmpty => 'Indica la cantidad';

  @override
  String solidFoodValidatorQuantityInvalid(Object max) {
    return 'Número entero entre 1 y $max';
  }

  @override
  String get solidFoodValidatorQuantityParse =>
      'Formato no válido: solo números y una coma o punto decimal (ej. 0,47).';

  @override
  String get solidFoodValidatorUnitsNoDecimals =>
      'En unidades usa solo números enteros, sin coma ni punto.';

  @override
  String get solidFoodValidatorGramsPositive =>
      'El peso en gramos debe ser mayor que 0.';

  @override
  String solidFoodValidatorGramsRange(Object max) {
    return 'El peso no puede superar $max g.';
  }

  @override
  String get feedingChooseSideTitle => '¿Qué lado?';

  @override
  String get feedingChooseSideSubtitle =>
      'Elige el pecho para iniciar el cronómetro.';

  @override
  String get feedingEditSolid => 'Editar sólidos';

  @override
  String get feedingStop => 'Parar';

  @override
  String get feedingPause => 'Pausa';

  @override
  String get feedingResume => 'Reanudar';

  @override
  String feedingActiveTimer(Object side) {
    return 'Cronómetro activo: $side';
  }

  @override
  String get feedingSideLeft => 'Izquierdo';

  @override
  String get feedingSideRight => 'Derecho';

  @override
  String get feedingHistoryEmpty =>
      'Todavía no hay registros. Usa «Pecho», «Biberón» o «Sólidos» arriba para añadir la primera.';

  @override
  String get feedingSessionCountOne => '1 toma';

  @override
  String feedingSessionCountN(Object n) {
    return '$n tomas';
  }

  @override
  String get feedingEditBottle => 'Editar biberón';

  @override
  String get feedingEditSession => 'Editar toma';

  @override
  String get feedingAmountMl => 'Cantidad (ml)';

  @override
  String get hintExampleMl => 'Ej: 120';

  @override
  String get feedingStreamError =>
      'No se pudieron cargar las tomas. Reintenta o comprueba la conexión.';

  @override
  String lastFeedDetailLeftMinutes(Object minutes) {
    return 'Izquierda • $minutes min';
  }

  @override
  String get lastFeedDetailLeft => 'Izquierda';

  @override
  String lastFeedDetailRightMinutes(Object minutes) {
    return 'Derecha • $minutes min';
  }

  @override
  String get lastFeedDetailRight => 'Derecha';

  @override
  String lastFeedDetailBottleVolume(Object volume) {
    return 'Biberón • $volume';
  }

  @override
  String get lastFeedDetailSolid => 'Sólidos';

  @override
  String get diapersTitle => 'Control de Pañales';

  @override
  String get diapersChangeType => 'Tipo de cambio';

  @override
  String get diaperWet => 'Mojado';

  @override
  String get diaperDirty => 'Sucio';

  @override
  String get diaperBoth => 'Ambos';

  @override
  String get diapersRegisterButton => 'Registrar Cambio de Pañal';

  @override
  String get diapersHistoryEmpty =>
      'Todavía no hay registros. Usa «Registrar cambio de pañal» arriba para añadir el primero.';

  @override
  String get diaperChangeCountOne => '1 cambio';

  @override
  String diaperChangeCountN(Object n) {
    return '$n cambios';
  }

  @override
  String get diapersStreamError =>
      'No se pudieron cargar los pañales. Reintenta o comprueba la conexión.';

  @override
  String get diapersEditRecord => 'Editar registro';

  @override
  String get diapersTypeLabel => 'Tipo';

  @override
  String get weightTitle => 'Control de Peso';

  @override
  String get weightFieldLabelMetric => 'Peso (kg)';

  @override
  String get weightFieldLabelImperial => 'Peso (lb)';

  @override
  String get hintExampleWeight => 'Ej: 4,5';

  @override
  String get weightRegister => 'Registrar';

  @override
  String get weightValidatorEmpty => 'Introduce el peso';

  @override
  String get weightValidatorInvalid => 'Peso inválido';

  @override
  String weightSuddenChangeHint(String value) {
    return 'Cambio muy grande respecto al último peso ($value). Revisa que sea correcto.';
  }

  @override
  String get weightStreamError =>
      'No se pudieron cargar los pesos. Comprueba la conexión o reintenta.';

  @override
  String get growthChartMetricWeight => 'Peso';

  @override
  String get growthChartMetricHeight => 'Altura';

  @override
  String get growthEvolution => 'Tendencia de peso y altura';

  @override
  String get weightEvolution => 'Tendencia de peso';

  @override
  String get weightChartCaption => 'Referencia OMS (peso por edad).';

  @override
  String get weightChartBabyCaption => 'Pesadas del bebé';

  @override
  String get weightChartRangeSelector => 'Rango';

  @override
  String get weightChartSource =>
      'Fuente: Organización Mundial de la Salud (OMS) — Child Growth Standards. who.int/tools/child-growth-standards';

  @override
  String get weightChartInfoTitle => 'Fuente de la gráfica';

  @override
  String get weightChartLoadError => 'No se pudo cargar la gráfica de peso.';

  @override
  String get weightHistoryLoadError =>
      'No se pudo cargar el historial de peso.';

  @override
  String get weightHistoryEmpty =>
      'Todavía no hay registros. Escribe el peso y pulsa «Registrar» arriba para añadir el primero.';

  @override
  String get growthHistoryEmpty =>
      'Todavía no hay registros. Escribe el peso o la altura y pulsa «Registrar» para añadir el primero.';

  @override
  String get weightCurrentCard => 'Peso Actual';

  @override
  String get weightTrendCard => 'Tendencia diaria';

  @override
  String weightTrendGramsCompact(Object sign, Object value) {
    return '$sign${value}g';
  }

  @override
  String weightTrendOuncesCompact(Object sign, Object value) {
    return '$sign$value oz';
  }

  @override
  String get weightNoData => 'Sin datos';

  @override
  String get weightDash => '-';

  @override
  String get weightChartEmpty => 'Sin datos aún';

  @override
  String get weightChartNoDataInRange => 'No hay pesadas en este periodo';

  @override
  String weightChartNeedsMoreRecords(String name) {
    return 'Añade otra pesada para calcular la línea de crecimiento de $name.';
  }

  @override
  String get weightChartRangeAll => 'Todo';

  @override
  String get weightChartRange7d => '7 días';

  @override
  String get weightChartRange30d => '30 días';

  @override
  String get weightChartRange90d => '3 meses';

  @override
  String get weightChartRange365d => '1 año';

  @override
  String weightTooltipAge(String age) {
    return 'Edad: $age';
  }

  @override
  String weightTooltipBabyPercentile(String value) {
    return 'Percentil OMS (peso/edad): $value';
  }

  @override
  String heightTooltipBabyPercentile(String value) {
    return 'Percentil OMS (talla/edad): $value';
  }

  @override
  String weightTooltipPercentile(String label, String value) {
    return '$label (OMS): $value';
  }

  @override
  String weightTooltipWeighIn(Object value) {
    return 'Pesada: $value';
  }

  @override
  String get weightChartPercentileSelector => 'Percentil';

  @override
  String weightChartBabyPercentileAt(String name, String percentile) {
    return '$name está en el percentil $percentile';
  }

  @override
  String weightChartBabyPercentileAbove(String name, String percentile) {
    return '$name está por encima del percentil $percentile';
  }

  @override
  String weightChartBabyPercentileBelow(String name, String percentile) {
    return '$name está por debajo del percentil $percentile';
  }

  @override
  String get weightChartPercentilePhraseBeforeAt => ' está en el percentil ';

  @override
  String get weightChartPercentilePhraseAfterAt => '';

  @override
  String get weightChartPercentilePhraseBeforeAbove =>
      ' está por encima del percentil ';

  @override
  String get weightChartPercentilePhraseAfterAbove => '';

  @override
  String get weightChartPercentilePhraseBeforeBelow =>
      ' está por debajo del percentil ';

  @override
  String get weightChartPercentilePhraseAfterBelow => '';

  @override
  String get weightEditTitle => 'Editar peso';

  @override
  String get heightTitle => 'Control de Altura';

  @override
  String get hintExampleHeight => 'Ej: 58';

  @override
  String get heightRegister => 'Registrar';

  @override
  String get heightValidatorEmpty => 'Introduce la altura';

  @override
  String get heightValidatorInvalid => 'Altura inválida';

  @override
  String heightSuddenChangeHint(String value) {
    return 'Cambio muy grande respecto a la última altura ($value). Revisa que sea correcto.';
  }

  @override
  String get heightHistoryLoadError =>
      'No se pudo cargar el historial de altura.';

  @override
  String get heightEditTitle => 'Editar altura';

  @override
  String get heightEvolution => 'Tendencia de altura';

  @override
  String get heightChartCaption => 'Referencia OMS (longitud/talla por edad).';

  @override
  String get heightChartBabyCaption => 'Medidas de altura del bebé';

  @override
  String get heightChartLoadError => 'No se pudo cargar la gráfica de altura.';

  @override
  String get heightChartEmpty => 'Sin alturas aún';

  @override
  String get heightChartNoDataInRange => 'No hay alturas en este periodo';

  @override
  String heightChartNeedsMoreRecords(String name) {
    return 'Añade otra medida de altura para calcular la línea de crecimiento de $name.';
  }

  @override
  String heightTooltipMeasure(String value) {
    return 'Altura: $value';
  }

  @override
  String get bottleTitle => 'Biberón';

  @override
  String get bottleValidatorEmpty => 'Introduce la cantidad';

  @override
  String get bottleValidatorInvalid => 'Cantidad inválida';

  @override
  String get bottleQuickAmountsSectionTitle => 'Cantidades rápidas';

  @override
  String get bottleQuickAmountAdd => 'Añadir';

  @override
  String get bottleQuickAmountAddTitle => 'Añadir atajo';

  @override
  String get bottleQuickAmountDuplicate => 'Esa cantidad ya está en la lista';

  @override
  String get bottleQuickAmountMaxCustom =>
      'Máximo de atajos personalizados alcanzado';

  @override
  String get bottleQuickAmountRemoveTitle => 'Quitar atajo';

  @override
  String bottleQuickAmountRemoveMessage(String amount) {
    return '¿Eliminar $amount de tus atajos?';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsBabyProfile => 'Perfil del Bebé';

  @override
  String get settingsShareFamily => 'Compartir Familia';

  @override
  String get settingsSuggestedFeedings => 'Tomas sugeridas';

  @override
  String get settingsName => 'Nombre';

  @override
  String get settingsBirthDate => 'Fecha de nacimiento';

  @override
  String get settingsHeight => 'Altura';

  @override
  String get settingsNoProfile => 'Sin perfil configurado';

  @override
  String get settingsEditProfile => 'Editar perfil';

  @override
  String get settingsShareQrIntro =>
      'Tú enseñas este código. Quien se una lo escanea con su propio móvil al unirse a un bebé ya creado.';

  @override
  String get settingsFeedingConfigureFirst =>
      'Configura primero el perfil del bebé.';

  @override
  String get settingsFeedingIntro => 'Define cada cuánto suele comer el bebé';

  @override
  String get settingsFeedingInterval => 'Intervalo entre tomas';

  @override
  String get settingsNotifyTitle => 'Activar notificaciones';

  @override
  String get settingsNotifySubtitle =>
      'Notificaciones en la hora sugerida de la siguiente toma.';

  @override
  String get settingsNotifyPermission =>
      'Activa las notificaciones en los ajustes del sistema para recibir el aviso.';

  @override
  String get settingsSignOutSection => 'Cerrar sesión';

  @override
  String get settingsSignOutButton => 'Cerrar sesión';

  @override
  String get settingsSignOutRowSubtitle => 'Cerrar sesión en este dispositivo';

  @override
  String get settingsDeleteSection => 'Eliminar cuenta';

  @override
  String get settingsDeleteIntro =>
      'Elimina tu cuenta y tus datos de acceso. Si eres el único miembro de la familia, también se eliminarán todos los datos del bebé.';

  @override
  String get settingsDeleteAccount => 'Eliminar mi cuenta';

  @override
  String get settingsDeleteAccountRowSubtitle =>
      'Eliminar la cuenta y sus datos';

  @override
  String get settingsDeleting => 'Eliminando...';

  @override
  String get settingsFamilyFirebaseOnly =>
      'Compartir familia solo disponible con Firebase.';

  @override
  String get settingsShowQr => 'Mostrar QR para invitar';

  @override
  String get settingsHideQr => 'Ocultar QR';

  @override
  String get settingsQrCaption =>
      'Este móvil solo muestra el código. Lo escanea la otra persona.';

  @override
  String get settingsGroupBaby => 'Bebé';

  @override
  String get settingsGroupPreferences => 'Preferencias';

  @override
  String get settingsGroupFamily => 'Familia';

  @override
  String get settingsGroupAccount => 'Cuenta';

  @override
  String get settingsGroupHelp => 'Ayuda';

  @override
  String get settingsRowContactTitle => 'Contacto';

  @override
  String settingsRowContactSubtitle(String email) {
    return '$email';
  }

  @override
  String get settingsContactEmailSubject => 'Consulta sobre MiBebé';

  @override
  String settingsContactOpenFail(String email) {
    return 'No se pudo abrir la app de correo. Escríbenos a $email';
  }

  @override
  String get settingsRowProfileTitle => 'Datos del perfil';

  @override
  String get settingsRowProfileSubtitle => 'Nombre, fecha y nacimiento';

  @override
  String get settingsRowProfileEmpty => 'Sin configurar';

  @override
  String get settingsRowFeedingInterval => 'Intervalo entre tomas';

  @override
  String get settingsRowFeedingNotify => 'Avisar próxima toma';

  @override
  String get settingsRowUnitWeight => 'Unidad de peso';

  @override
  String get settingsRowUnitLiquid => 'Unidad de líquidos';

  @override
  String get settingsRowCurrency => 'Moneda';

  @override
  String get settingsCurrencyAuto => 'Automático';

  @override
  String get settingsCurrencyIntro =>
      'Elige la moneda para estimar el gasto en pañales. Automático usa la del dispositivo.';

  @override
  String get settingsCurrencySearchHint => 'Buscar moneda';

  @override
  String settingsCurrencyAutoSubtitle(String currency) {
    return 'Según tu dispositivo · $currency';
  }

  @override
  String get settingsCurrencyAllSection => 'Todas las monedas';

  @override
  String settingsCurrencyNoResults(String query) {
    return 'No encontramos ninguna moneda con «$query»';
  }

  @override
  String get settingsRowFamilyShare => 'Compartir con familia';

  @override
  String get settingsRowFamilyShareSubtitle =>
      'Mostrar código QR de invitación';

  @override
  String get settingsValueOn => 'Activado';

  @override
  String get settingsValueOff => 'Desactivado';

  @override
  String get settingsValueNotSet => '—';

  @override
  String get settingsBabyAgeMonthsOne => '1 mes';

  @override
  String settingsBabyAgeMonthsN(int months) {
    return '$months meses';
  }

  @override
  String get settingsBabyAgeDaysOne => '1 día';

  @override
  String settingsBabyAgeDaysN(int days) {
    return '$days días';
  }

  @override
  String settingsBabyBornOn(String date) {
    return 'Nacido el $date';
  }

  @override
  String settingsBabyBornOnFemale(String date) {
    return 'Nacida el $date';
  }

  @override
  String get settingsSheetUnitWeightTitle => 'Unidad de peso';

  @override
  String get settingsSheetUnitLiquidTitle => 'Unidad de líquidos';

  @override
  String get settingsSheetCurrencyTitle => 'Moneda';

  @override
  String get settingsSheetFeedingIntervalTitle => 'Intervalo entre tomas';

  @override
  String get settingsSheetShareTitle => 'Compartir con familia';

  @override
  String get editBabyProfileTitle => 'Editar perfil del bebé';

  @override
  String get labelName => 'Nombre';

  @override
  String get labelGender => 'Género';

  @override
  String get heightFieldLabel => 'Altura (cm)';

  @override
  String get heightFieldHint => 'Opcional, ej. 58';

  @override
  String get heightInvalid => 'Altura inválida';

  @override
  String get heightRangeError => 'Altura debe estar entre 25 y 120 cm';

  @override
  String get deleteAccountTitle => 'Eliminar cuenta';

  @override
  String get deleteAccountBody =>
      'Esta acción eliminará permanentemente tu cuenta y tus datos de acceso. Si eres el único miembro de la familia, también se eliminarán todos los datos del bebé.\n\nEsta operación no se puede deshacer. ¿Estás seguro?';

  @override
  String get deleteAccountConfirm => 'Eliminar cuenta';

  @override
  String deleteAccountError(Object error) {
    return 'Error al eliminar la cuenta: $error';
  }

  @override
  String get signOutTitle => 'Cerrar sesión';

  @override
  String get signOutBody => '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get signOutConfirm => 'Cerrar sesión';

  @override
  String signOutError(Object error) {
    return 'Error al cerrar sesión: $error';
  }

  @override
  String get loginForgotPasswordTitle => 'Recuperar contraseña';

  @override
  String get loginForgotPasswordBody =>
      'Te enviaremos un enlace para elegir una contraseña nueva.';

  @override
  String get loginEmailHint => 'Tu correo electrónico';

  @override
  String get loginResetInvalidEmail => 'Introduce un correo válido';

  @override
  String get loginResetCheckEmail =>
      'Revisa tu correo (y spam) para restablecer la contraseña';

  @override
  String get loginResetSendFail =>
      'No se pudo enviar el correo. Inténtalo más tarde.';

  @override
  String get loginHeaderTitle => 'MiBebé';

  @override
  String get loginWelcomeBackTitle => 'Vuelve a entrar';

  @override
  String get loginWelcomeBackSubtitle =>
      'Los datos de tu bebé siguen guardados';

  @override
  String get loginContinueApple => 'Continuar con Apple';

  @override
  String get loginContinueGoogle => 'Continuar con Google';

  @override
  String get loginContinueEmail => 'Continuar con email';

  @override
  String loginLastAuthMethod(String method) {
    return 'La última vez entraste con $method';
  }

  @override
  String get loginPasswordHint => 'Tu contraseña';

  @override
  String get loginForgotLink => '¿Has olvidado tu contraseña?';

  @override
  String get loginValidatorEmailEmpty => 'Introduce tu correo';

  @override
  String get loginValidatorEmailInvalid => 'Correo no válido';

  @override
  String get loginValidatorPasswordEmpty => 'Introduce tu contraseña';

  @override
  String get loginSignIn => 'Iniciar Sesión';

  @override
  String get loginGuestQr => 'Unirme con código QR (sin cuenta)';

  @override
  String get loginOrWith => 'O INICIA SESIÓN CON';

  @override
  String get loginNoAccount => '¿No tienes cuenta? ';

  @override
  String get loginRegisterLink => 'Regístrate';

  @override
  String get loginCreateNewProfile => 'Crear un perfil nuevo';

  @override
  String get loginErrorGeneric => 'Error al iniciar sesión';

  @override
  String get loginErrorGoogle => 'Error al iniciar sesión con Google';

  @override
  String get loginErrorApple => 'Error al iniciar sesión con Apple';

  @override
  String get loginGuestNeedsFirebase =>
      'Hace falta Firebase para unirte con código QR';

  @override
  String get loginGuestNotAllowed =>
      'Invitado no disponible. En Firebase Console → Authentication → Sign-in method, activa \"Anónimo\".';

  @override
  String get loginGuestFailed => 'No se pudo entrar como invitado';

  @override
  String get authErrorUserNotFound => 'No existe una cuenta con este correo';

  @override
  String get authErrorWrongPassword => 'Contraseña incorrecta';

  @override
  String get authErrorInvalidEmail => 'Correo electrónico no válido';

  @override
  String get authErrorUserDisabled => 'Esta cuenta ha sido deshabilitada';

  @override
  String get authErrorInvalidCredential => 'Credenciales inválidas';

  @override
  String get authErrorOperationNotAllowed =>
      'Método de inicio de sesión no habilitado';

  @override
  String get authErrorGeneric => 'Error al iniciar sesión';

  @override
  String get resetErrorInvalidEmail => 'Correo electrónico no válido';

  @override
  String get resetErrorUserNotFound =>
      'No hay cuenta con este correo. Comprueba el email o regístrate.';

  @override
  String get resetErrorUserDisabled => 'Esta cuenta está deshabilitada';

  @override
  String get resetErrorOpNotAllowed =>
      'Recuperación por correo no habilitada en Firebase (Authentication → Sign-in method → Email).';

  @override
  String get resetErrorGeneric =>
      'No se pudo enviar el correo. Inténtalo más tarde.';

  @override
  String get registerTitle => 'Registro';

  @override
  String get registerHeadline => 'Crea tu cuenta';

  @override
  String get registerSubtitle => 'Introduce tus datos para registrarte';

  @override
  String get registerEmailLabel => 'Correo electrónico';

  @override
  String get registerPasswordLabel => 'Contraseña';

  @override
  String get registerConfirmLabel => 'Confirmar contraseña';

  @override
  String get registerPasswordHint => 'Mínimo 6 caracteres';

  @override
  String get registerEmailHint => 'tu@email.com';

  @override
  String get registerValidatorEmailEmpty => 'Introduce tu correo';

  @override
  String get registerValidatorPasswordEmpty => 'Introduce una contraseña';

  @override
  String get registerValidatorPasswordShort => 'Mínimo 6 caracteres';

  @override
  String get registerValidatorConfirmEmpty => 'Confirma tu contraseña';

  @override
  String get registerValidatorMismatch => 'Las contraseñas no coinciden';

  @override
  String get registerButton => 'Registrarse';

  @override
  String get registerHaveAccount => '¿Ya tienes cuenta? ';

  @override
  String get registerSignInLink => 'Inicia sesión';

  @override
  String get registerErrorGeneric =>
      'Error al registrarse. Comprueba tu conexión y que el registro por email esté habilitado en Firebase.';

  @override
  String get registerErrorEmailInUse =>
      'Ya existe una cuenta con este correo. Usa \"Inicia sesión\" en su lugar.';

  @override
  String get registerErrorWeakPassword =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get registerErrorOpNotAllowed =>
      'Registro por email no habilitado. Actívalo en Firebase Console > Authentication > Sign-in method';

  @override
  String get registerErrorNetwork =>
      'Error de conexión. Comprueba tu internet.';

  @override
  String get registerErrorTooMany =>
      'Demasiados intentos. Espera unos minutos.';

  @override
  String get registerErrorInvalidCredential => 'Credenciales inválidas';

  @override
  String registerErrorUnknown(Object code) {
    return 'Error: $code. Revisa Firebase Console.';
  }

  @override
  String get onboardingWelcome => 'Bienvenido a MiBebé';

  @override
  String get onboardingHowStart => '¿Cómo quieres empezar?';

  @override
  String get onboardingCreateBabyTitle => 'Crear bebé';

  @override
  String get onboardingCreateBabySubtitle =>
      'Configura un nuevo perfil desde cero';

  @override
  String get onboardingScanTitle => 'Escanear bebé';

  @override
  String get onboardingScanSubtitle =>
      'Únete a un bebé ya creado escaneando su código QR';

  @override
  String get onboardingScanDisabled => 'Requiere Firebase para compartir';

  @override
  String get onboardingExitLogin => 'Salir y volver al inicio de sesión';

  @override
  String get onboardingConfigureTitle => 'Configurar bebé';

  @override
  String get onboardingCreateProfileTitle => 'Crear perfil del bebé';

  @override
  String get onboardingCreateProfileSubtitle =>
      'Configura los datos de tu bebé';

  @override
  String get onboardingBabyName => 'Nombre del bebé';

  @override
  String get onboardingBabyNameHint => 'Ej: María, Lucas...';

  @override
  String get onboardingNameRequired => 'El nombre es obligatorio';

  @override
  String get onboardingGender => 'Género';

  @override
  String get onboardingBirthDate => 'Fecha de nacimiento';

  @override
  String get onboardingBirthNote =>
      'Se usa para calcular percentiles OMS (0-12 meses)';

  @override
  String get onboardingHeightTitle => 'Talla / altura';

  @override
  String get onboardingHeightSubtitle =>
      'Opcional. La altura actual en centímetros (aparece en el perfil).';

  @override
  String get onboardingHeightHint => 'Dejar vacío si no la conoces';

  @override
  String get onboardingHeightInvalid => 'Introduce un número válido (ej: 52,5)';

  @override
  String get onboardingHeightRange => 'Altura habitual entre 25 y 130 cm';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingStart => 'Comenzar';

  @override
  String get onboardingEnterName => 'Introduce el nombre del bebé';

  @override
  String get onboardingHeightReview =>
      'Revisa la talla: número entre 25 y 130 cm, o deja el campo vacío';

  @override
  String get onboardingSaveDenied =>
      'Sin permiso en Firebase (reglas o sesión). Revisa Firestore.';

  @override
  String onboardingSaveFailed(Object code) {
    return 'No se pudo guardar ($code). Revisa conexión y Firebase.';
  }

  @override
  String onboardingSaveError(Object error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String get onboardingExitTitle => '¿Salir?';

  @override
  String get onboardingExitBody =>
      'Cerrarás sesión y volverás a la pantalla de inicio de sesión.';

  @override
  String onboardingSignOutError(Object error) {
    return 'No se pudo cerrar sesión: $error';
  }

  @override
  String get familyQrTitle => 'Escanear código QR';

  @override
  String get familyQrHint => 'Apunta la cámara al código QR del bebé';

  @override
  String get familyQrDetailLabel => 'Detalle:';

  @override
  String get familyQrJoinFailPermission =>
      'Permiso denegado en Firebase (reglas de Firestore o sesión).';

  @override
  String get familyQrJoinFailUnavailable =>
      'Firebase no está disponible. Revisa la conexión a internet.';

  @override
  String get familyQrJoinFailNotFound => 'Recurso no encontrado en Firebase.';

  @override
  String familyQrJoinFailFirebase(Object code) {
    return 'Error de Firebase ($code).';
  }

  @override
  String get familyQrJoinFailFamily =>
      'Familia no encontrada. Comprueba que el QR sea correcto.';

  @override
  String get familyQrJoinFailState => 'Error al procesar el código del QR.';

  @override
  String get familyQrJoinFailUnsupported =>
      'Unirse por QR no está disponible (hace falta Firebase en este dispositivo).';

  @override
  String get familyQrJoinFailGeneric => 'No se pudo unir a la familia.';

  @override
  String get familyQrDecodeFail => 'Fallo al leer o decodificar el código.';

  @override
  String get familyQrInternalCode => 'Código interno:';

  @override
  String get notificationChannelName => 'Próximas tomas';

  @override
  String get notificationChannelDescription =>
      'Aviso cuando llega la hora sugerida de toma';

  @override
  String get notificationNextFeedTitle => 'Próxima toma';

  @override
  String notificationNextFeedBody(Object name) {
    return 'Podría tocar otra toma para $name.';
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
  String get unitMlLong => 'mililitros';

  @override
  String get unitFlOzLong => 'onzas líquidas';

  @override
  String get hintExampleWeightLb => 'Ej: 9,5';

  @override
  String get hintExampleFlOz => 'Ej: 4';

  @override
  String get liquidFieldLabelFlOz => 'Cantidad (fl oz)';

  @override
  String get settingsUnitsTitle => 'Unidades';

  @override
  String get settingsUnitsIntro =>
      'Elige cómo ver e introducir peso y biberón. Los datos se guardan siempre en kg y ml.';

  @override
  String get settingsUnitsWeight => 'Peso';

  @override
  String get settingsUnitsLiquid => 'Líquidos';

  @override
  String get unitSegmentKg => 'kg';

  @override
  String get unitSegmentLbOz => 'lb · oz';

  @override
  String get unitSegmentMl => 'mL';

  @override
  String get unitSegmentFlOz => 'fl oz';

  @override
  String get settingsRowPediatricReport => 'Informe para el pediatra';

  @override
  String get settingsRowPediatricReportSubtitle =>
      'Compartir PDF con curvas OMS';

  @override
  String get reportShareError =>
      'No se pudo generar el informe. Inténtalo de nuevo.';

  @override
  String get reportFileNamePrefix => 'informe-crecimiento';

  @override
  String get reportTitle => 'Informe de crecimiento';

  @override
  String get reportSexLabel => 'Sexo';

  @override
  String get reportSexMale => 'Niño';

  @override
  String get reportSexFemale => 'Niña';

  @override
  String get reportSexUnspecified => 'No especificado';

  @override
  String get reportBirthDateLabel => 'Nacimiento';

  @override
  String get reportAgeLabel => 'Edad';

  @override
  String get reportDateLabel => 'Fecha del informe';

  @override
  String reportAgeMonthsDays(int months, int days) {
    return '$months m $days d';
  }

  @override
  String reportAgeDays(int days) {
    return '$days días';
  }

  @override
  String get reportChartTitle => 'Peso (kg) por edad (meses) · curvas OMS';

  @override
  String get reportHeightChartTitle =>
      'Talla (cm) por edad (meses) · curvas OMS';

  @override
  String reportChartLegendBaby(String name) {
    return 'Peso de $name';
  }

  @override
  String get reportChartLegendWho =>
      'Percentiles OMS: P3 · P15 · P50 · P85 · P97';

  @override
  String get reportChartWhoNote =>
      'Las curvas son percentiles de referencia OMS; los puntos son las mediciones del bebé.';

  @override
  String get reportWeightTableTitle => 'Últimas pesadas';

  @override
  String get reportHeightTableTitle => 'Últimas tallas';

  @override
  String get reportTableDate => 'Fecha';

  @override
  String get reportTableAge => 'Edad';

  @override
  String get reportTableWeight => 'Peso';

  @override
  String get reportTableHeight => 'Talla';

  @override
  String get reportTableChange => 'Variación';

  @override
  String get reportNoWeightData => 'Todavía no hay pesadas registradas.';

  @override
  String get reportNoHeightData => 'Todavía no hay tallas registradas.';

  @override
  String get reportFeedingTitle => 'Alimentación · últimos 7 días';

  @override
  String get reportFeedingPerDay => 'Tomas por día';

  @override
  String get reportFeedingBreastPerDay => 'Pecho por día';

  @override
  String get reportFeedingBottlePerDay => 'Biberón por día';

  @override
  String get reportFeedingDistribution => 'Distribución';

  @override
  String reportFeedingDistributionValue(int breast, int bottle, int solid) {
    return '$breast% pecho · $bottle% biberón · $solid% sólidos';
  }

  @override
  String get reportDiapersTitle => 'Pañales · últimos 7 días';

  @override
  String get reportDiapersPerDay => 'Cambios por día';

  @override
  String get reportDiapersWet => 'Mojados';

  @override
  String get reportDiapersDirty => 'Sucios';

  @override
  String get reportDiapersBoth => 'Mixtos';

  @override
  String get reportNoData => 'Sin datos';

  @override
  String reportGeneratedWith(String date) {
    return 'Generado con MiBebé · $date';
  }

  @override
  String get reportTrendsTitle => 'Tendencias y comparativas';

  @override
  String reportPeriodDays(int days) {
    return 'Últimos $days días';
  }

  @override
  String reportComparisonTitle(int days) {
    return 'Comparativa vs $days días anteriores';
  }

  @override
  String get reportComparisonMetric => 'Métrica';

  @override
  String get reportComparisonCurrent => 'Actual';

  @override
  String get reportComparisonPrevious => 'Anterior';

  @override
  String get reportComparisonChange => 'Variación';

  @override
  String get reportComparisonNew => 'nuevo';

  @override
  String get reportWeightTrendsTitle => 'Peso · tendencias';

  @override
  String reportWeightTrendDays(int days) {
    return 'Tendencia $days días';
  }

  @override
  String reportWeightGainDays(int days) {
    return 'Ganancia $days días';
  }

  @override
  String get reportExecutiveSummary => 'Resumen';

  @override
  String get reportCurrentWeight => 'Peso actual';

  @override
  String get reportCurrentHeight => 'Talla actual';

  @override
  String get reportCurrentPercentile => 'Percentil OMS';

  @override
  String get reportWeightForAgePercentile => 'Percentil OMS (peso/edad)';

  @override
  String get reportLengthForAgePercentile => 'Percentil OMS (talla/edad)';

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
  String get reportSummaryGrowthGroup => 'Crecimiento';

  @override
  String get reportSummaryRoutineGroup => 'Alimentación y pañales';

  @override
  String get reportSummaryMeasuredOn => 'Última medición';

  @override
  String get reportSinceLastWeighIn => 'Desde última pesada';

  @override
  String get reportDaysSinceWeighIn => 'Días desde pesada';

  @override
  String get reportDaysSinceHeight => 'Días desde talla';

  @override
  String reportDaysCount(int days) {
    return '$days días';
  }

  @override
  String get reportPercentileChange => 'Cambio de percentil';

  @override
  String get reportHeight => 'Altura';

  @override
  String get reportWeightSection => 'Peso';

  @override
  String get reportHeightSection => 'Altura';

  @override
  String get reportFeedingSection => 'Alimentación';

  @override
  String get reportDiapersSection => 'Pañales';

  @override
  String get reportSleepSection => 'Sueño';

  @override
  String get reportSleepTitle => 'Sueño · últimos 7 días';

  @override
  String get reportSleepAveragePerRecordedDay => 'Horas por día registrado';

  @override
  String reportSleepHoursValue(String hours) {
    return '$hours h';
  }

  @override
  String get reportSleepTotal => 'Tiempo total dormido';

  @override
  String get reportSleepNaps => 'Siestas';

  @override
  String get reportSleepNightWakings => 'Despertares nocturnos';

  @override
  String get reportSleepNightWakingTime =>
      'Tiempo total despierto por la noche';

  @override
  String get reportSleepDailyTitle => 'Sueño por día · últimos 7 días';

  @override
  String get reportSleepDay => 'Día';

  @override
  String get reportSleepDuration => 'Duración';

  @override
  String get reportSleepNapsPerRecordedDay => 'Siestas por día registrado';

  @override
  String get reportSleepWakingsPerRecordedDay =>
      'Despertares por día registrado';

  @override
  String get reportSleepRecentSessions => 'Sesiones de sueño recientes';

  @override
  String get reportSleepStart => 'Inicio';

  @override
  String get reportSleepEnd => 'Fin';

  @override
  String get reportSleepType => 'Tipo';

  @override
  String get reportSleepInProgress => 'En curso';

  @override
  String get reportWeightOverviewTitle => 'Datos de peso';

  @override
  String get reportHeightOverviewTitle => 'Datos de talla';

  @override
  String get reportFeedingDetailTitle => 'Detalle de lactancia';

  @override
  String get reportBreastfeedingDetailTitle => 'Detalle de lactancia';

  @override
  String get reportBottleDetailTitle => 'Detalle de biberón';

  @override
  String get reportBottleFeedsPerDay => 'Biberones por día';

  @override
  String get reportBottleAvgPerFeed => 'ml medio por toma';

  @override
  String reportBottleTotalPeriod(int days) {
    return 'Total en $days días';
  }

  @override
  String get reportComparisonNoData => '—';

  @override
  String get reportComparisonInsufficientHistory =>
      'Se necesitan al menos 60 días de registros para comparar con el periodo anterior.';

  @override
  String get reportFeedingInterval => 'Intervalo medio entre tomas';

  @override
  String get reportFeedingLongestGap => 'Tramo más largo sin comer';

  @override
  String get reportFeedingBreastBalance => 'Balance pecho I / D';

  @override
  String reportFeedingBreastBalanceValue(int left, int right) {
    return '$left% / $right%';
  }

  @override
  String get reportFeedingAvgSession => 'Duración media toma pecho';

  @override
  String get reportFeedingEstimatedBreast => 'Pecho estimado / día';

  @override
  String get reportFeedingEstimatedBreastStarred => 'Pecho estimado / día*';

  @override
  String get reportEstimatedBreastFootnote =>
      '* Estimación a partir del tiempo de pecho (no es una medición). Conversión: ml = 140 x (1 - e^(-minutos/9)).';

  @override
  String reportCoverageLabel(int logged, int total) {
    return 'Registro: $logged de $total días';
  }

  @override
  String get reportCoverageLowWarning =>
      'Las medias pueden no ser representativas (registro incompleto).';

  @override
  String get reportLegalDisclaimer =>
      'Herramienta de seguimiento personal. Los datos no sustituyen la valoración de un profesional sanitario.';

  @override
  String get reportFeedingFirstSolid => 'Primera toma de sólidos';

  @override
  String get reportNoSolidFoodYet => 'Sin sólidos registrados';

  @override
  String get reportWetDiapersPerDay => 'Mojados por día';

  @override
  String get reportStoolDiapersPerDay => 'Deposiciones por día';

  @override
  String get reportDaysWithoutStool => 'Días sin deposición';

  @override
  String reportDaysWithoutStoolOfPeriod(int count, int total) {
    return '$count de $total días';
  }

  @override
  String reportComparisonAbsoluteChange(String previous, String current) {
    return '$previous → $current';
  }

  @override
  String get reportDiaperDistribution => 'Distribución';

  @override
  String reportDiaperDistributionValue(int wet, int dirty, int both) {
    return '$wet% mojado · $dirty% sucio · $both% mixto';
  }

  @override
  String get premiumUnlockButton => 'Desbloquear';

  @override
  String get premiumTeaserTitle => 'ANÁLISIS PREMIUM';

  @override
  String premiumTeaserSubtitle(String name) {
    return 'Lo que tus registros ya pueden contarte de $name';
  }

  @override
  String get premiumTeaserCta => 'Prueba 7 días gratis';

  @override
  String premiumTeaserAfterPrice(String price) {
    return 'Después $price/año · cancela cuando quieras';
  }

  @override
  String get premiumTeaserCancelAnytime => 'Cancela cuando quieras';

  @override
  String premiumTeaserMoreAnalyses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Y $count análisis más',
      one: 'Y 1 análisis más',
    );
    return '$_temp0';
  }

  @override
  String premiumTeaserBasedOnNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Basado en $count noches registradas',
      one: 'Basado en 1 noche registrada',
    );
    return '$_temp0';
  }

  @override
  String premiumTeaserBasedOnFeedingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Basado en $count días de tomas',
      one: 'Basado en 1 día de tomas',
    );
    return '$_temp0';
  }

  @override
  String premiumTeaserBasedOnWeights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Basado en $count medidas registradas',
      one: 'Basado en 1 medida registrada',
    );
    return '$_temp0';
  }

  @override
  String get premiumTeaserFeedingTrendTitle => 'Cómo va comiendo hoy';

  @override
  String get premiumTeaserFeedingTrendSubtitle =>
      'Comparado con sus días habituales';

  @override
  String premiumTeaserFeedingTrendHeadline(String name) {
    return 'Descubre cómo va comiendo hoy $name';
  }

  @override
  String get premiumTeaserSleepTitle => 'Su hora óptima y sueños habituales';

  @override
  String get premiumTeaserSleepSubtitle =>
      'Por previsión y patrones habituales';

  @override
  String premiumTeaserSleepHeadline(String name) {
    return 'Descubre cómo duerme $name';
  }

  @override
  String get premiumTeaserGrowthTitle => 'Percentil OMS de peso y talla';

  @override
  String get premiumTeaserGrowthSubtitle => 'Curva completa y proyección';

  @override
  String premiumTeaserGrowthHeadline(String name) {
    return 'Descubre el percentil OMS de peso y talla de $name';
  }

  @override
  String get settingsGroupSubscription => 'Suscripción';

  @override
  String get settingsRowManageSubscription => 'Gestionar suscripción';

  @override
  String get settingsRowSubscriptionActive => 'Premium activo';

  @override
  String get settingsRowSubscriptionInactive => 'Plan gratuito';

  @override
  String get settingsRowSubscriptionFamily =>
      'Premium compartido por tu familia';

  @override
  String get settingsRowSubscribe => 'Hazte premium';

  @override
  String get settingsRowSubscribeSubtitle =>
      'Desbloquea el análisis y el seguimiento avanzado';

  @override
  String get settingsRowRestorePurchases => 'Restaurar compras';

  @override
  String get restorePurchasesSuccess => 'Compras restauradas correctamente';

  @override
  String get restorePurchasesEmpty =>
      'No se encontraron compras para restaurar';

  @override
  String get settingsRowComplimentaryPremium => 'Premium de regalo';

  @override
  String settingsRowComplimentaryPremiumUntil(String date) {
    return 'Gratis hasta el $date';
  }

  @override
  String get settingsRowRestorePurchasesGiftHint =>
      'Si compraste una suscripción, restáurala aquí';

  @override
  String get restorePurchasesGiftDialogTitle => 'Premium de regalo';

  @override
  String get restorePurchasesGiftDialogBody =>
      'Tu acceso Premium es un regalo temporal de la app. No hay ninguna compra que restaurar. Si quieres seguir con Premium cuando termine, podrás suscribirte desde ajustes.';

  @override
  String get premiumLaunchNoticeTitle => '¡Gracias por confiar en nosotros!';

  @override
  String premiumLaunchNoticeBodyGift(String date) {
    return 'Detrás de esta app hay una familia como la tuya, y como agradecimiento por acompañarnos desde el inicio, hemos desbloqueado todas las funciones Premium que hemos añadido en esta actualización totalmente gratis para tu familia hasta el $date.';
  }

  @override
  String get premiumLaunchNoticeBodyEssential =>
      'Lo esencial seguirá siendo gratuito, siempre.';

  @override
  String get premiumLaunchNoticeSignOff => 'Un cálido abrazo,';

  @override
  String get premiumLaunchNoticeSignatureName => 'S.';

  @override
  String get premiumLaunchNoticeDismiss => '¡Entendido!';

  @override
  String get premiumExpiryWarningTitle => 'Tu Premium termina pronto';

  @override
  String premiumExpiryWarningBodyDays(int days) {
    return 'Te quedan $days días de Premium. Si no renuevas, perderás el análisis, gráficos de evolución, informe PDF y compartir familia por QR.';
  }

  @override
  String get premiumExpiryWarningBodyToday =>
      'Hoy termina tu Premium. Si no renuevas, perderás el análisis, gráficos de evolución, informe PDF y compartir familia por QR.';

  @override
  String premiumExpiryWarningBodyGiftDays(int days) {
    return 'Te quedan $days días de tu regalo Premium. Después volverás al plan gratuito de siempre, con todo lo esencial intacto.\n\nSi estas funciones te han facilitado el día a día, puedes conservarlas suscribiéndote.';
  }

  @override
  String get premiumExpiryWarningBodyGiftToday =>
      'Hoy termina tu regalo Premium. Después volverás al plan gratuito de siempre, con todo lo esencial intacto.\n\nSi estas funciones te han facilitado el día a día, puedes conservarlas suscribiéndote.';

  @override
  String get premiumExpiryWarningRenew => 'Hazte premium';

  @override
  String get premiumExpiryWarningDismiss => 'Ahora no';

  @override
  String get paywallTitle => 'Hazte premium';

  @override
  String get paywallSubtitle =>
      'Todo lo que te faltaba para cuidar y entender mejor a tu bebé.';

  @override
  String get paywallFeatureInsights =>
      'Todo el análisis y las gráficas de evolución';

  @override
  String get paywallFeatureFeedingTrack => 'Seguimiento de las tomas diarias';

  @override
  String get paywallFeatureSleepTrack =>
      'Análisis del sueño y predicción del siguiente';

  @override
  String get paywallFeatureFamily => 'Comparte con tu familia por QR';

  @override
  String get paywallFeaturePdf => 'Informe PDF para el pediatra';

  @override
  String get paywallBadgeBestValue => 'MEJOR PRECIO';

  @override
  String get paywallBadgeRecommended => 'Recomendado';

  @override
  String paywallAnnualMonthlyEquivalent(String price) {
    return 'Equivale a $price/mes';
  }

  @override
  String get paywallTrialBadge => '7 días gratis';

  @override
  String get paywallPlanAnnual => 'Anual';

  @override
  String get paywallPlanMonthly => 'Mensual';

  @override
  String get paywallPlanGeneric => 'Suscripción';

  @override
  String get paywallPerYear => '/año';

  @override
  String get paywallPerMonth => '/mes';

  @override
  String get paywallPerWeek => '/semana';

  @override
  String get paywallCtaTrial => 'Empezar prueba gratis';

  @override
  String get paywallCtaSubscribe => 'Suscribirme';

  @override
  String get paywallRestore => 'Restaurar compras';

  @override
  String get paywallTerms => 'Términos';

  @override
  String get paywallPrivacy => 'Privacidad';

  @override
  String get paywallLegal =>
      'Renovación automática. Cancela en Ajustes al menos 24 h antes del fin del periodo.';

  @override
  String get paywallPurchaseError =>
      'No se pudo completar la compra. Inténtalo de nuevo.';

  @override
  String get paywallLoadError =>
      'No se pudieron cargar los planes. Revisa tu conexión.';

  @override
  String get paywallClose => 'Cerrar';

  @override
  String get onboardingFlowContinue => 'Continuar';

  @override
  String get onboardingFlowBornTitle => '¿Ya ha nacido?';

  @override
  String get onboardingFlowBornSubtitle => 'Preparamos su perfil en un minuto';

  @override
  String get onboardingFlowBornOption => 'Ya ha nacido';

  @override
  String get onboardingFlowPregnantOption => 'Esperando un bebé';

  @override
  String get onboardingFlowHaveAccount => 'Ya tengo cuenta';

  @override
  String get onboardingFlowQrInvite => 'Me han invitado a una familia';

  @override
  String get onboardingFlowNameTitle => '¿Cuál es el nombre de tu bebé?';

  @override
  String get onboardingFlowNameSubtitle =>
      'Personalizaremos la app con su nombre';

  @override
  String get onboardingFlowNameHint => 'Nombre del bebé';

  @override
  String get onboardingFlowNameUndecided => 'Todavía no lo hemos decidido';

  @override
  String get onboardingFlowGenderTitle => '¿Es un chico o una chica?';

  @override
  String onboardingFlowGenderTitleNamed(String name) {
    return '¿$name es un chico o una chica?';
  }

  @override
  String get onboardingFlowGenderSubtitle =>
      'Las curvas de crecimiento de la OMS son distintas para niños y niñas';

  @override
  String get onboardingFlowBabyGeneric => 'el bebé';

  @override
  String get onboardingFlowBabyGenericYour => 'tu bebé';

  @override
  String get onboardingFlowBabyDefaultName => 'Tu bebé';

  @override
  String onboardingFlowBirthTitle(String name) {
    return '¿Cuándo nació $name?';
  }

  @override
  String onboardingFlowDueTitle(String name) {
    return '¿Cuándo es la fecha prevista de $name?';
  }

  @override
  String get onboardingFlowBirthSubtitle =>
      'Calcularemos su edad y percentiles';

  @override
  String onboardingFlowAgeHasMonthsDays(String name, int months, int days) {
    return '$name tiene $months meses y $days días';
  }

  @override
  String onboardingFlowAgeHasMonths(String name, int months) {
    return '$name tiene $months meses';
  }

  @override
  String onboardingFlowAgeHasDays(String name, int days) {
    return '$name tiene $days días';
  }

  @override
  String onboardingFlowDueInDays(String name, int days) {
    return '$name nacerá en $days días';
  }

  @override
  String onboardingFlowDueInOneDay(String name) {
    return '$name nacerá en 1 día';
  }

  @override
  String onboardingFlowDueToday(String name) {
    return '$name nacerá hoy';
  }

  @override
  String get onboardingFlowMeasuresTitle => 'Medidas de la última revisión';

  @override
  String get onboardingFlowMeasuresSubtitle =>
      'Opcional, con esto veremos su curva de crecimiento';

  @override
  String get onboardingFlowMeasuresLater => 'Las añado más tarde';

  @override
  String get onboardingFlowWeightLabel => 'Peso';

  @override
  String get onboardingFlowHeightLabel => 'Talla';

  @override
  String get onboardingFlowWeightRangeHint =>
      'Revisa el peso: suele estar entre 0,5 y 30 kg';

  @override
  String get onboardingFlowHeightRangeHint =>
      'Revisa la talla: suele estar entre 30 y 120 cm';

  @override
  String get onboardingFlowWeightUnitTitle => 'Unidad de peso';

  @override
  String get onboardingFlowHeightUnitTitle => 'Unidad de talla';

  @override
  String get onboardingFlowHeightUnitCm => 'Centímetros (cm)';

  @override
  String get onboardingFlowHeightUnitIn => 'Pulgadas (in)';

  @override
  String get onboardingFlowWeightUnitKg => 'Kilogramos (kg)';

  @override
  String get onboardingFlowWeightUnitLb => 'Libras (lb)';

  @override
  String get onboardingFlowPreparingTitle => 'Preparando los datos de tu bebé';

  @override
  String onboardingFlowCalcPercentiles(String name) {
    return 'Calculando percentiles OMS de $name';
  }

  @override
  String onboardingFlowCalcWhoCurve(int months) {
    return 'Calculando curva OMS para $months meses';
  }

  @override
  String get onboardingFlowCalcFeeding => 'Calculando ritmo de tomas';

  @override
  String get onboardingFlowCalcSleep => 'Calculando rutinas del sueño';

  @override
  String get onboardingFlowCalcDueDate => 'Calculando fecha prevista';

  @override
  String get onboardingFlowCalcNewbornReady =>
      'Preparando todo para el nacimiento';

  @override
  String get onboardingFlowCalcNewbornFeeding =>
      'Preparando ritmo de tomas del recién nacido';

  @override
  String get onboardingFlowCalcNewbornRoutines =>
      'Preparando rutinas de sueño del recién nacido';

  @override
  String onboardingFlowResultsTitle(String name) {
    return 'Todo listo para $name';
  }

  @override
  String get onboardingFlowResultsSubtitle =>
      'Esto es lo que hemos preparado para su edad';

  @override
  String get onboardingFlowResultsSubtitlePregnant =>
      'Todo quedará listo para cuando nazca';

  @override
  String onboardingFlowResultAgeLabel(String name) {
    return 'Edad de $name';
  }

  @override
  String onboardingFlowResultAgeMonths(int months) {
    return '$months meses';
  }

  @override
  String onboardingFlowResultAgeMonthsDays(int months, int days) {
    return '$months meses y $days días';
  }

  @override
  String get onboardingFlowResultAgeOneDay => '1 día';

  @override
  String onboardingFlowResultAgeDays(int days) {
    return '$days días';
  }

  @override
  String get onboardingFlowResultAgeOneYear => '1 año';

  @override
  String onboardingFlowResultAgeYears(int years) {
    return '$years años';
  }

  @override
  String get onboardingFlowResultAgeOneYearHalf => '1 año y medio';

  @override
  String onboardingFlowResultAgeYearsHalf(int years) {
    return '$years años y medio';
  }

  @override
  String get onboardingFlowResultDueHeroLabel => 'Faltan';

  @override
  String onboardingFlowResultDueHeroDays(int days) {
    return '$days días';
  }

  @override
  String get onboardingFlowResultDueHeroOne => '1 día';

  @override
  String get onboardingFlowResultDueHeroToday => 'Hoy';

  @override
  String onboardingFlowResultDueDateCaption(String date) {
    return 'Fecha prevista: $date';
  }

  @override
  String get onboardingFlowResultGrowthTitle => 'Crecimiento OMS';

  @override
  String get onboardingFlowResultWeightPct => 'Peso';

  @override
  String get onboardingFlowResultHeightPct => 'Talla';

  @override
  String get onboardingFlowResultNoWeight => 'Sin dato';

  @override
  String get onboardingFlowResultNoHeight => 'Sin dato';

  @override
  String get onboardingFlowResultNoWeightHeight =>
      'Aún no hay peso ni talla. Podrás añadirlos cuando quieras.';

  @override
  String onboardingFlowResultWhoMedian(String weight, String height) {
    return 'Mediana OMS a su edad: $weight · $height';
  }

  @override
  String get onboardingFlowResultPercentileContext =>
      'P3 está dentro del rango de referencia. Lo importante es la evolución, no un dato aislado.';

  @override
  String get onboardingFlowResultMedicalDisclaimer =>
      'Orientativo según curvas OMS. No sustituye el criterio de tu pediatra.';

  @override
  String get onboardingFlowResultFeedingTitle => 'Tomas';

  @override
  String get onboardingFlowResultMealsTitle => 'Alimentación';

  @override
  String onboardingFlowResultFeedingValue(String interval) {
    return 'Cada $interval';
  }

  @override
  String get onboardingFlowResultFeedingMealsTransition =>
      'Comidas + tomas de leche';

  @override
  String get onboardingFlowResultFeedingMealsTransitionHint =>
      'Se combina la leche con las comidas del día';

  @override
  String get onboardingFlowResultFeedingMealsToddler =>
      '3 comidas y 2 tentempiés';

  @override
  String get onboardingFlowResultFeedingMealsToddlerHint =>
      'A esta edad ya no se organiza en tomas cada X horas';

  @override
  String get onboardingFlowResultFeedingHint =>
      'Lo usaremos para avisarte de la siguiente toma';

  @override
  String get onboardingFlowResultFeedingPregnantHint =>
      'Ritmo típico de recién nacido, listo desde el día 1';

  @override
  String get onboardingFlowResultSleepTitle => 'Sueño';

  @override
  String onboardingFlowResultSleepWake(String range) {
    return 'Ventana de vigilia: $range';
  }

  @override
  String onboardingFlowResultSleepTotal(String range) {
    return 'Unas $range de sueño al día';
  }

  @override
  String get onboardingFlowResultSleepPregnantHint =>
      'Ventanas cortas de recién nacido, listas al nacer';

  @override
  String get onboardingFlowResultWhoPregnant =>
      'Las curvas OMS se activarán cuando nazca';

  @override
  String onboardingFlowNotifyTitle(String name) {
    return '¿Quieres activar las notificaciones para que te avisemos de la siguiente toma de $name?';
  }

  @override
  String onboardingFlowNotifySubtitle(String interval) {
    return 'Para su edad te hemos configurado una toma cada $interval, que es lo más habitual, pero lo puedes personalizar desde las opciones.';
  }

  @override
  String onboardingFlowNotifyTitleToddler(String name) {
    return '¿Quieres activar las notificaciones para $name?';
  }

  @override
  String get onboardingFlowNotifySubtitleToddler =>
      'Podrás recibir avisos de la app. A esta edad la alimentación ya no se cuenta en tomas cada X horas; lo personalizas cuando quieras en ajustes.';

  @override
  String get onboardingFlowNotifyEnable => 'Activar notificaciones';

  @override
  String get onboardingFlowNotifyLater => 'Ahora no';

  @override
  String onboardingFlowSaveTitle(String name) {
    return 'Guardar los datos de $name';
  }

  @override
  String get onboardingFlowSaveSubtitle =>
      'No pierdas los datos si cambias de móvil';

  @override
  String get onboardingFlowContinueApple => 'Continuar con Apple';

  @override
  String get onboardingFlowContinueGoogle => 'Continuar con Google';

  @override
  String get onboardingFlowContinueEmail => 'Continuar con email';

  @override
  String get onboardingFlowDataSafe =>
      'Los datos de tu bebé están protegidos, cifrados y nunca se venden a terceros.';

  @override
  String get onboardingFlowQrNeedsConnection =>
      'Se necesita conexión para unirse con QR';

  @override
  String get onboardingFlowQrOpenFail => 'No se pudo abrir el escáner QR';

  @override
  String onboardingFlowSaveFail(String error) {
    return 'No se pudieron guardar los datos: $error';
  }

  @override
  String get onboardingFlowProfileAlreadyExistsTitle =>
      'Esta cuenta ya tiene un perfil';

  @override
  String get onboardingFlowProfileAlreadyExists =>
      'Ese correo o cuenta ya tiene un perfil creado. Usa «Ya tengo cuenta» para entrar, o prueba con otra cuenta para no sobrescribir los datos.';

  @override
  String get onboardingFlowProfileAlreadyExistsButton => 'Entendido';

  @override
  String get onboardingFlowAuthError => 'Error de autenticación';

  @override
  String get onboardingFlowSignInFail => 'No se pudo iniciar sesión';
}
