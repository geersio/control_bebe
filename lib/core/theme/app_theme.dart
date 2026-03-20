import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  /// Ruta del icono de título en AppBar (Home, Alimentación, Peso, Pañales).
  static const String titleIconAsset = 'assets/images/icon_mibebe.png';

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
  /// Crema [#FBF8CC] y familia (antes el menta iba a peso).
  static const Color navDiapersSelectedFill = Color(0xFFFBF8CC);
  /// Familia del melocotón [#FFD1BA] / [paletteTertiary].
  static const Color navFeedingSelectedFill = Color(0xFFFFE8D9);
  /// Familia del menta claro (mismos tonos que tenía pañales).
  static const Color navWeightSelectedFill = Color(0xFFD4F5E6);

  /// Icono y texto de la pestaña activa (contraste sobre cada fondo).
  static const Color navHomeSelectedFg = palettePrimary;
  static const Color navDiapersSelectedFg = Color(0xFF5C5418);
  static const Color navFeedingSelectedFg = Color(0xFF6D4C41);
  static const Color navWeightSelectedFg = Color(0xFF1B5E45);

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
  static final Color pageTitleIconWeight = Color.lerp(
    navWeightSelectedFill,
    navWeightSelectedFg,
    0.5,
  )!;

  /// Texto (carbón / apagado).
  static const Color textHeading = Color(0xFF2D6583);
  static const Color textDark = Color(0xFF424242);
  static const Color textLight = Color(0xFF90A4AE);

  /// Consejo del día (sobre fondo tertiary).
  static const Color tipText = Color(0xFF5D4037);

  /// Icono de sexo masculino (azul bebé suave).
  static const Color genderMaleBabyBlue = Color(0xFF7DBEE8);

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

  /// Historial de tomas: variaciones sutiles (misma familia fría → cálido suave).
  static const Color feedingHistoryLeftAccent = palettePrimary;
  static const Color feedingHistoryRightAccent = Color(0xFF3A8A7A);
  static const Color feedingHistoryBottleAccent = Color(0xFF8B725C);

  /// Historial de pañales: mojado / sucio / ambos (tonos cercanos, fáciles de distinguir).
  static const Color diaperHistoryWetAccent = Color(0xFF4589B3);
  static const Color diaperHistoryDirtyAccent = Color(0xFF8B6A55);
  static const Color diaperHistoryBothAccent = Color(0xFF667A92);

  /// Margen horizontal entre el borde de pantalla y tarjetas / bloques (referencia Home).
  static const double screenEdgePadding = 20;

  /// Espacio bajo [MainAppTitleBar] hasta el primer widget (misma referencia que Home).
  static const double contentPaddingTopAfterTitleBar = 8;

  static const double cardRadius = 24;
  static const double homeCardRadius = 32;
  static const double cardElevation = 0.5;
  static const double dialogRadius = 28;
  static const double fieldRadius = 18;
  static const Color fieldBackground = Color(0xFFF0F4F5);
  static const Color fieldBorder = Color(0xFFE0E7EA);

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
    final inter = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: textDark,
      displayColor: textHeading,
    );
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
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textHeading,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
