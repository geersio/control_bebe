import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:shared_preferences/shared_preferences.dart';

/// Unidad de visualización e introducción de peso (almacenamiento siempre en kg).
enum WeightUnitMode {
  /// Kilogramos (p. ej. 4,52 kg).
  metric,

  /// Libras y onzas (p. ej. 9 lb 5 oz).
  imperial,
}

/// Unidad para biberón / volumen (almacenamiento siempre en ml).
enum LiquidUnitMode {
  milliliters,
  fluidOuncesUs,
}

/// Preferencias de unidades persistidas localmente.
class MeasurementPrefs {
  static const _kWeight = 'measurement_weight_unit';
  static const _kLiquid = 'measurement_liquid_unit';
  static const _kCurrency = 'measurement_currency_code';

  /// Países donde el sistema habitual es imperial (peso/volumen).
  static const Set<String> _imperialCountryCodes = {
    'US', // Estados Unidos
    'LR', // Liberia
    'MM', // Myanmar
  };

  final WeightUnitMode weight;
  final LiquidUnitMode liquid;

  /// Código ISO 4217 (p. ej. `EUR`). `null` = según locale del dispositivo.
  final String? currencyCode;

  const MeasurementPrefs({
    required this.weight,
    required this.liquid,
    this.currencyCode,
  });

  /// Imperial solo por país (no por idioma: en-AU / en-IN → métrico).
  static bool regionUsesImperial([Locale? locale]) {
    final loc = locale ?? PlatformDispatcher.instance.locale;
    final country = (loc.countryCode ?? '').toUpperCase();
    return _imperialCountryCodes.contains(country);
  }

  static MeasurementPrefs defaultsForLocale(Locale locale) {
    final imperial = regionUsesImperial(locale);
    return MeasurementPrefs(
      weight: imperial ? WeightUnitMode.imperial : WeightUnitMode.metric,
      liquid:
          imperial ? LiquidUnitMode.fluidOuncesUs : LiquidUnitMode.milliliters,
    );
  }

  /// Compatibilidad: sin país, asume métrico (salvo que se pase un Locale con country).
  static MeasurementPrefs defaultsForLanguage(String languageCode) {
    return defaultsForLocale(Locale(languageCode));
  }

  static MeasurementPrefs defaultsForDispatcher() {
    return defaultsForLocale(PlatformDispatcher.instance.locale);
  }

  static Future<MeasurementPrefs> load() async {
    final sp = await SharedPreferences.getInstance();
    final def = defaultsForDispatcher();
    final wName = sp.getString(_kWeight);
    final lName = sp.getString(_kLiquid);
    final currencyRaw = sp.getString(_kCurrency);
    WeightUnitMode w;
    LiquidUnitMode l;
    try {
      w = wName != null ? WeightUnitMode.values.byName(wName) : def.weight;
    } catch (_) {
      w = def.weight;
    }
    try {
      l = lName != null ? LiquidUnitMode.values.byName(lName) : def.liquid;
    } catch (_) {
      l = def.liquid;
    }
    final currency = (currencyRaw == null || currencyRaw.isEmpty)
        ? null
        : currencyRaw.toUpperCase();
    return MeasurementPrefs(weight: w, liquid: l, currencyCode: currency);
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kWeight, weight.name);
    await sp.setString(_kLiquid, liquid.name);
    if (currencyCode == null || currencyCode!.isEmpty) {
      await sp.remove(_kCurrency);
    } else {
      await sp.setString(_kCurrency, currencyCode!);
    }
  }

  MeasurementPrefs copyWith({
    WeightUnitMode? weight,
    LiquidUnitMode? liquid,
    String? currencyCode,
    bool clearCurrency = false,
  }) =>
      MeasurementPrefs(
        weight: weight ?? this.weight,
        liquid: liquid ?? this.liquid,
        currencyCode: clearCurrency ? null : (currencyCode ?? this.currencyCode),
      );
}
