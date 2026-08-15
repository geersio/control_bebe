import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  /// Paleta (guía de estilo + azul principal de marca).
  static const Color palettePrimary = Color(0xFF2D6583);
  static const Color paletteSecondary = Color(0xFFA8E6CF);
  static const Color paletteTertiary = Color(0xFFFFD1BA);
  static const Color paletteNeutral = Color(0xFFF7F9F9);

  /// Fondos y superficies.
  static const Color background = paletteNeutral;
  static const Color cardBackground = Colors.white;
  static const Color softPrimaryFill = Color(0xFFE8F1F5);

  /// Navegación inferior: fondo de la píldora al seleccionar (tonalidades de la paleta).
  static const Color navHomeSelectedFill = softPrimaryFill;

  /// Misma píldora que home para todos los tabs.
  static const Color navDiapersSelectedFill = softPrimaryFill;

  /// Misma píldora que home para todos los tabs.
  static const Color navFeedingSelectedFill = softPrimaryFill;

  /// Misma píldora que home para todos los tabs.
  static const Color navSleepSelectedFill = softPrimaryFill;

  /// Misma píldora que home para todos los tabs.
  static const Color navWeightSelectedFill = softPrimaryFill;

  /// Icono y texto de la pestaña activa (mismo azul que home).
  static const Color navHomeSelectedFg = palettePrimary;
  static const Color navDiapersSelectedFg = palettePrimary;
  static const Color navFeedingSelectedFg = palettePrimary;
  static const Color navSleepSelectedFg = palettePrimary;
  static const Color navWeightSelectedFg = palettePrimary;

  /// Icono junto al título en cada sección (punto medio entre fill y fg de la píldora).
  static final Color pageTitleIconDiapers = Color.lerp(
    navDiapersSelectedFill,
    navDiapersSelectedFg,
    0.5,
  )!;
  static final Color pageTitleIconFeeding = Color.lerp(
    navFeedingSelectedFill,
    navFeedingSelectedFg,
    0.5,
  )!;
  static final Color pageTitleIconSleep = Color.lerp(
    navSleepSelectedFill,
    navSleepSelectedFg,
    0.5,
  )!;
  static final Color pageTitleIconWeight = Color.lerp(
    navWeightSelectedFill,
    navWeightSelectedFg,
    0.5,
  )!;

  /// Texto (carbón / secundario accesible ≥4.5:1 sobre fondo).
  static const Color textHeading = Color(0xFF2D6583);
  static const Color textDark = Color(0xFF424242);
  static const Color textLight = Color(0xFF546E7A);

  /// Consejo del día (sobre fondo tertiary).
  static const Color tipText = Color(0xFF5D4037);

  /// Icono de sexo masculino (azul bebé suave).
  static const Color genderMaleBabyBlue = Color(0xFF7DBEE8);

  /// Anillo de perfil / icono hembra (rosa).
  static const Color genderFemalePink = Color(0xFFE85C8A);

  /// Compatibilidad con el resto de la app.
  static const Color primaryBlue = palettePrimary;
  static const Color primaryPink = palettePrimary;
  static const Color primaryGreen = Color(0xFF2D6A4F);

  /// Verde más vivo para deltas positivos (peso, tendencias en Home).
  static const Color trendPositiveGreen = Color(0xFF16A34A);
  static const Color trendNegativeRed = Color(0xFFC62828);
  static const Color primaryOrange = Color(0xFFD4A088);

  /// Pecho izquierdo / derecho en historial de lactancia.
  static const Color breastLeft = palettePrimary;
  static const Color breastRight = Color(0xFFA8E6CF);

  /// Historial de tomas: misma fuerza visual que pañales (azul / verde azulado / tierra).
  static const Color feedingHistoryLeftAccent = Color(0xFF4589B3);
  static const Color feedingHistoryRightAccent = Color(0xFF2A9485);
  static const Color feedingHistoryBottleAccent = Color(0xFF8B6A55);

  /// Alimento sólido en historial.
  static const Color feedingHistorySolidAccent = Color(0xFFC27C3A);

  /// Historial de pañales: mojado / sucio / ambos (tonos cercanos, fáciles de distinguir).
  static const Color diaperHistoryWetAccent = Color(0xFF4589B3);
  static const Color diaperHistoryDirtyAccent = Color(0xFF8B6A55);
  static const Color diaperHistoryBothAccent = Color(0xFF667A92);

  /// Acentos de crecimiento: misma familia visual, distinguibles entre sí.
  static const Color growthWeightAccent = Color(0xFFC65A48);
  static const Color growthHeightAccent = Color(0xFFB7791F);

  /// Acento de la ficha de historial de peso.
  static Color get weightHistoryAccent => growthWeightAccent;

  /// Acento de la ficha de historial de altura.
  static const Color heightHistoryAccent = growthHeightAccent;

  /// Sueño: acentos morados del reloj circular y fichas de historial.
  static const Color sleepPurple = Color(0xFF7E57C2);
  static const Color sleepPurpleDeep = Color(0xFF5E35B1);
  static const Color sleepPurpleSoft = Color(0xFFEDE7F6);
  static const Color sleepClockTrack = Color(0xFFD1C4E9);

  /// Tarjeta live despierto/durmiendo.
  static const Color sleepLiveCardTop = Color(0xFF3A3F78);
  static const Color sleepLiveCardBottom = Color(0xFF2A2F5C);
  static const Color sleepLiveCardBlob = Color(0xFF4A5088);
  static const Color sleepLiveDayTop = Color(0xFF7EC4E8);
  static const Color sleepLiveDayBottom = Color(0xFFB8DFF0);
  static const Color sleepLiveDaySun = Color(0xFFFFE082);
  static const Color sleepLiveDayText = Color(0xFF1E3A5F);
  static const Color sleepLiveWakeButton = Color(0xFFE8B45A);
  static const Color sleepLiveButtonText = Color(0xFF2C2F4A);
  static const Color sleepHistoryAccent = sleepPurple;

  /// Sueño nocturno: azul-morado.
  static const Color sleepHistoryNightAccent = Color(0xFF5C6BC0);

  /// Siesta: morado.
  static const Color sleepHistoryNapAccent = sleepPurple;

  /// Despertar nocturno: violeta suave (entre índigo y púrpura).
  static const Color sleepHistoryNightWakingAccent = Color(0xFF9575CD);

  /// Layout compartido: fichas de historial en alimentación, pañales y peso.
  /// Franja más ancha con degradado a transparente hacia el contenido.
  static const double historyRecordStripeWidth = 22;

  /// Intensidad máxima del borde izquierdo del degradado (el resto funde a transparente).
  static const double historyRecordStripePeakOpacity = 0.28;

  static BoxDecoration historyRecordStripeDecoration(Color accent) {
    final soft = accent.withValues(alpha: historyRecordStripePeakOpacity);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [soft, soft.withValues(alpha: 0)],
      ),
    );
  }

  static const double historyRecordAvatarRadius = 22;
  static const EdgeInsets historyRecordLeadingPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 12,
  );
  static const EdgeInsets historyRecordContentPadding = EdgeInsets.fromLTRB(
    4,
    10,
    8,
    10,
  );
  static const EdgeInsets historyRecordTrailingOuterPadding = EdgeInsets.only(
    right: 2,
  );

  /// Tras el título de tipo (Mojado, Izquierdo…).
  static const double historyRecordAfterTitleGap = 6;

  /// Tras duración / ml / kg hacia la fecha.
  static const double historyRecordDetailToDateGap = 4;

  /// Fondo del avatar en fichas de historial (acento sobre blanco); más alto = menos “lavado”.
  static const double historyRecordAvatarAccentOpacity = 0.32;

  static TextStyle historyRecordTypeTitleStyle(Color accent) =>
      TextStyle(fontWeight: FontWeight.w600, color: accent);

  static TextStyle historyRecordPrimaryValueStyle(Color accent) => TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 15,
    height: 1.2,
    color: accent,
    letterSpacing: 0.15,
  );

  static TextStyle historyRecordDateTimeStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall;
    return (base ?? const TextStyle(fontSize: 12)).copyWith(
      color: textLight,
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
      height: 1.2,
    );
  }

  /// Margen horizontal entre el borde de pantalla y tarjetas / bloques (referencia Home).
  static const double screenEdgePadding = 18;

  /// Padding interior de la tarjeta principal de pestaña (Alimentación, Pañales, Peso).
  static const double sectionCardPadding = 22;

  /// Aire extra bajo el contenido cuando `SafeArea(bottom: false)` (barra de tabs, login, etc.).
  static const double extraBottomSpacing = 8;

  /// Margen fijo bajo el contenido (sin inset del home indicator de iPhone).
  static double safeBottomPadding(BuildContext context) => extraBottomSpacing;

  /// Espacio bajo [MainAppTitleBar] hasta el primer widget (misma referencia que Home).
  static const double contentPaddingTopAfterTitleBar = 8;

  /// Radio de botones, campos y piezas compactas.
  static const double cardRadius = 24;

  /// Radio de fichas / [Card] principales (misma curva que Home).
  static const double homeCardRadius = 32;
  static const double cardElevation = 0.5;

  /// Margen exterior por defecto de [Card] en Material 3 (las pestañas lo aplican; Home debe compensarlo).
  static const double cardOuterMargin = 2;

  /// Contorno fino de tarjetas (misma referencia que historial alimentación/pañales).
  static Color get cardOutline => fieldBorder.withValues(alpha: 0.65);
  static BorderSide get cardOutlineSide =>
      BorderSide(color: cardOutline, width: 1);

  static RoundedRectangleBorder cardShapeRounded([
    double radius = homeCardRadius,
  ]) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: cardOutlineSide,
  );

  static RoundedRectangleBorder get homeCardShapeRounded =>
      cardShapeRounded(homeCardRadius);
  static const double dialogRadius = 28;
  static const double fieldRadius = 18;
  static const Color fieldBackground = Color(0xFFF0F4F5);
  static const Color fieldBorder = Color(0xFFE0E7EA);

  /// Hora, batería y notificaciones legibles sobre fondo claro (iOS + Android).
  static const SystemUiOverlayStyle systemUiForLightBackground =
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: background,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      );

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palettePrimary,
      brightness: Brightness.light,
      primary: palettePrimary,
      surface: cardBackground,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
    );
    final inter = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: textDark, displayColor: textHeading);
    return base.copyWith(
      textTheme: inter.copyWith(
        headlineLarge: inter.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textHeading,
        ),
        headlineMedium: inter.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: textHeading,
        ),
        titleLarge: inter.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textHeading,
        ),
        titleMedium: inter.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textHeading,
        ),
        bodyLarge: inter.bodyLarge?.copyWith(color: textDark),
        bodyMedium: inter.bodyMedium?.copyWith(color: textDark),
        labelLarge: inter.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: textLight,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textHeading,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
        systemOverlayStyle: systemUiForLightBackground,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textHeading,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: cardElevation,
        margin: const EdgeInsets.all(cardOuterMargin),
        shape: cardShapeRounded(homeCardRadius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: palettePrimary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: textHeading,
          foregroundColor: Colors.white,
          elevation: cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
        ),
      ),
    );
  }
}
