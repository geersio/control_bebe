import 'package:flutter/widgets.dart';

import 'currency_display.dart';

/// Precio medio aproximado de un pañal desechable por país.
/// Fuentes orientativas: packs de marca/media en supermercado (2024–2025).
/// Solo para estimar el insight de gasto; no sustituye precios reales del usuario.
class DiaperCostConfig {
  final String localeName;
  final String currencyCode;
  final double unitCost;
  final int decimalDigits;

  const DiaperCostConfig({
    required this.localeName,
    required this.currencyCode,
    required this.unitCost,
    this.decimalDigits = 2,
  });

  String format(double amount) => formatCurrencyAmount(
        amount: amount,
        currencyCode: currencyCode,
        localeName: localeName,
        decimalDigits: decimalDigits,
      );

  double dailyCost(double diapersPerDay) => diapersPerDay * unitCost;

  double monthlyCost(double diapersPerDay, {int days = 30}) =>
      dailyCost(diapersPerDay) * days;
}

/// ISO 3166-1 alpha-2 → (moneda, precio medio por pañal).
/// España: 0,35 € (referencia acordada en producto).
const Map<String, ({String currency, double unitCost, int decimals})>
    kDiaperUnitCostByCountry = {
  // —— Eurozona y Europa ——
  'ES': (currency: 'EUR', unitCost: 0.35, decimals: 2),
  'PT': (currency: 'EUR', unitCost: 0.32, decimals: 2),
  'FR': (currency: 'EUR', unitCost: 0.38, decimals: 2),
  'DE': (currency: 'EUR', unitCost: 0.36, decimals: 2),
  'IT': (currency: 'EUR', unitCost: 0.34, decimals: 2),
  'NL': (currency: 'EUR', unitCost: 0.37, decimals: 2),
  'BE': (currency: 'EUR', unitCost: 0.36, decimals: 2),
  'AT': (currency: 'EUR', unitCost: 0.36, decimals: 2),
  'IE': (currency: 'EUR', unitCost: 0.38, decimals: 2),
  'FI': (currency: 'EUR', unitCost: 0.40, decimals: 2),
  'GR': (currency: 'EUR', unitCost: 0.33, decimals: 2),
  'LU': (currency: 'EUR', unitCost: 0.39, decimals: 2),
  'MT': (currency: 'EUR', unitCost: 0.34, decimals: 2),
  'CY': (currency: 'EUR', unitCost: 0.35, decimals: 2),
  'SK': (currency: 'EUR', unitCost: 0.31, decimals: 2),
  'SI': (currency: 'EUR', unitCost: 0.34, decimals: 2),
  'EE': (currency: 'EUR', unitCost: 0.33, decimals: 2),
  'LV': (currency: 'EUR', unitCost: 0.32, decimals: 2),
  'LT': (currency: 'EUR', unitCost: 0.31, decimals: 2),
  'GB': (currency: 'GBP', unitCost: 0.28, decimals: 2),
  'CH': (currency: 'CHF', unitCost: 0.34, decimals: 2),
  'SE': (currency: 'SEK', unitCost: 4.0, decimals: 2),
  'NO': (currency: 'NOK', unitCost: 4.1, decimals: 2),
  'DK': (currency: 'DKK', unitCost: 2.6, decimals: 2),
  'PL': (currency: 'PLN', unitCost: 1.65, decimals: 2),
  'CZ': (currency: 'CZK', unitCost: 8.5, decimals: 2),
  'HU': (currency: 'HUF', unitCost: 140, decimals: 0),
  'RO': (currency: 'RON', unitCost: 1.70, decimals: 2),
  'BG': (currency: 'BGN', unitCost: 0.65, decimals: 2),
  'HR': (currency: 'EUR', unitCost: 0.33, decimals: 2),
  // —— América ——
  'US': (currency: 'USD', unitCost: 0.37, decimals: 2),
  'CA': (currency: 'CAD', unitCost: 0.52, decimals: 2),
  'MX': (currency: 'MXN', unitCost: 7.5, decimals: 2),
  'BR': (currency: 'BRL', unitCost: 2.20, decimals: 2),
  'AR': (currency: 'ARS', unitCost: 450, decimals: 0),
  'CL': (currency: 'CLP', unitCost: 380, decimals: 0),
  'CO': (currency: 'COP', unitCost: 1300, decimals: 0),
  'PE': (currency: 'PEN', unitCost: 1.40, decimals: 2),
  'UY': (currency: 'UYU', unitCost: 18, decimals: 0),
  // —— Otros mercados habituales ——
  'AU': (currency: 'AUD', unitCost: 0.58, decimals: 2),
  'NZ': (currency: 'NZD', unitCost: 0.55, decimals: 2),
  'JP': (currency: 'JPY', unitCost: 55, decimals: 0),
  'KR': (currency: 'KRW', unitCost: 650, decimals: 0),
  'IN': (currency: 'INR', unitCost: 18, decimals: 2),
  'ZA': (currency: 'ZAR', unitCost: 6.5, decimals: 2),
  'TR': (currency: 'TRY', unitCost: 12, decimals: 2),
  'IL': (currency: 'ILS', unitCost: 1.35, decimals: 2),
  'AE': (currency: 'AED', unitCost: 1.40, decimals: 2),
  'SA': (currency: 'SAR', unitCost: 1.45, decimals: 2),
};

/// Fallback cuando no hay país en el dispositivo: EUR con media eurozona.
const _kDefaultEuroUnitCost = 0.35;

/// País de referencia al elegir moneda a mano (varias naciones comparten EUR, etc.).
const Map<String, String> kPreferredCountryForCurrency = {
  'EUR': 'ES',
  'USD': 'US',
  'GBP': 'GB',
  'CAD': 'CA',
  'AUD': 'AU',
  'NZD': 'NZ',
  'MXN': 'MX',
  'BRL': 'BR',
  'CHF': 'CH',
  'SEK': 'SE',
  'NOK': 'NO',
  'DKK': 'DK',
  'PLN': 'PL',
  'CZK': 'CZ',
  'HUF': 'HU',
  'RON': 'RO',
  'BGN': 'BG',
  'ARS': 'AR',
  'CLP': 'CL',
  'COP': 'CO',
  'PEN': 'PE',
  'UYU': 'UY',
  'JPY': 'JP',
  'KRW': 'KR',
  'INR': 'IN',
  'ZAR': 'ZA',
  'TRY': 'TR',
  'ILS': 'IL',
  'AED': 'AE',
  'SAR': 'SA',
};

/// Precio medio por moneda (derivado del mapa por país).
final Map<String, ({double unitCost, int decimals})> kDiaperUnitCostByCurrency =
    () {
  final result = <String, ({double unitCost, int decimals})>{};
  for (final entry in kDiaperUnitCostByCountry.entries) {
    result.putIfAbsent(
      entry.value.currency,
      () => (unitCost: entry.value.unitCost, decimals: entry.value.decimals),
    );
  }
  for (final pref in kPreferredCountryForCurrency.entries) {
    final country = kDiaperUnitCostByCountry[pref.value];
    if (country == null) continue;
    result[pref.key] = (
      unitCost: country.unitCost,
      decimals: country.decimals,
    );
  }
  return Map<String, ({double unitCost, int decimals})>.unmodifiable(result);
}();

/// Códigos ISO 4217 seleccionables en Ajustes (orden alfabético).
List<String> get kSelectableCurrencyCodes =>
    kDiaperUnitCostByCurrency.keys.toList()..sort();

/// Nombre de cada moneda en los idiomas soportados por la app.
const Map<String, ({String es, String en})> kCurrencyNames = {
  'EUR': (es: 'Euro', en: 'Euro'),
  'USD': (es: 'Dólar estadounidense', en: 'US dollar'),
  'GBP': (es: 'Libra esterlina', en: 'British pound'),
  'CHF': (es: 'Franco suizo', en: 'Swiss franc'),
  'SEK': (es: 'Corona sueca', en: 'Swedish krona'),
  'NOK': (es: 'Corona noruega', en: 'Norwegian krone'),
  'DKK': (es: 'Corona danesa', en: 'Danish krone'),
  'PLN': (es: 'Esloti polaco', en: 'Polish zloty'),
  'CZK': (es: 'Corona checa', en: 'Czech koruna'),
  'HUF': (es: 'Forinto húngaro', en: 'Hungarian forint'),
  'RON': (es: 'Leu rumano', en: 'Romanian leu'),
  'BGN': (es: 'Lev búlgaro', en: 'Bulgarian lev'),
  'CAD': (es: 'Dólar canadiense', en: 'Canadian dollar'),
  'MXN': (es: 'Peso mexicano', en: 'Mexican peso'),
  'BRL': (es: 'Real brasileño', en: 'Brazilian real'),
  'ARS': (es: 'Peso argentino', en: 'Argentine peso'),
  'CLP': (es: 'Peso chileno', en: 'Chilean peso'),
  'COP': (es: 'Peso colombiano', en: 'Colombian peso'),
  'PEN': (es: 'Sol peruano', en: 'Peruvian sol'),
  'UYU': (es: 'Peso uruguayo', en: 'Uruguayan peso'),
  'AUD': (es: 'Dólar australiano', en: 'Australian dollar'),
  'NZD': (es: 'Dólar neozelandés', en: 'New Zealand dollar'),
  'JPY': (es: 'Yen japonés', en: 'Japanese yen'),
  'KRW': (es: 'Won surcoreano', en: 'South Korean won'),
  'INR': (es: 'Rupia india', en: 'Indian rupee'),
  'ZAR': (es: 'Rand sudafricano', en: 'South African rand'),
  'TRY': (es: 'Lira turca', en: 'Turkish lira'),
  'ILS': (es: 'Séquel israelí', en: 'Israeli shekel'),
  'AED': (es: 'Dírham de EAU', en: 'UAE dirham'),
  'SAR': (es: 'Riyal saudí', en: 'Saudi riyal'),
};

/// El euro no pertenece a un solo país: se muestra con la bandera de la UE.
const Map<String, String> _kFlagCountryOverride = {'EUR': 'EU'};

/// Nombre legible de la moneda; si no está en el mapa, devuelve el código.
String currencyDisplayName(String currencyCode, String languageCode) {
  final code = currencyCode.toUpperCase();
  final entry = kCurrencyNames[code];
  if (entry == null) return code;
  return languageCode == 'en' ? entry.en : entry.es;
}

/// Símbolo de la moneda (`€`, `$`…); cae al código si intl no lo conoce.
String currencySymbolFor(String currencyCode) {
  return currencyGlyphFor(currencyCode);
}

/// Bandera del país de referencia de la moneda, como emoji.
String currencyFlagEmoji(String currencyCode) {
  final code = currencyCode.toUpperCase();
  final country =
      _kFlagCountryOverride[code] ?? kPreferredCountryForCurrency[code];
  if (country == null || country.length != 2) return '';
  const regionalIndicatorBase = 0x1F1E6;
  final upper = country.toUpperCase();
  return String.fromCharCodes([
    regionalIndicatorBase + upper.codeUnitAt(0) - 0x41,
    regionalIndicatorBase + upper.codeUnitAt(1) - 0x41,
  ]);
}

/// Moneda que se aplicaría en modo automático para ese locale.
String automaticCurrencyCode(Locale moneyLocale) =>
    diaperCostConfigForLocale(moneyLocale).currencyCode;

const _kAccentedChars = 'áàäâãéèëêíìïîóòöôõúùüûñç';
const _kPlainChars = 'aaaaaeeeeiiiiooooouuuunc';

/// Normaliza para buscar sin acentos ni mayúsculas ("Dólar" ≈ "dolar").
String normalizeForSearch(String value) {
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final index = _kAccentedChars.indexOf(char);
    buffer.write(index == -1 ? char : _kPlainChars[index]);
  }
  return buffer.toString();
}

String intlLocaleName(Locale locale) {
  final country = locale.countryCode;
  if (country == null || country.isEmpty) return locale.languageCode;
  return '${locale.languageCode}_$country';
}

/// Combina idioma de la app con país del sistema para formatear moneda.
Locale moneyLocaleForContext(BuildContext context) {
  final resolved = Localizations.localeOf(context);
  final platform = WidgetsBinding.instance.platformDispatcher.locale;
  final platformCountry = platform.countryCode;
  if (platformCountry != null && platformCountry.isNotEmpty) {
    return Locale(resolved.languageCode, platformCountry);
  }
  return resolved;
}

/// Etiqueta corta para el picker (p. ej. `EUR (€)`).
String currencyOptionLabel(String currencyCode) {
  final code = currencyCode.toUpperCase();
  final symbol = currencySymbolFor(code);
  if (symbol == code) return code;
  return '$code ($symbol)';
}

DiaperCostConfig diaperCostConfigForLocale(Locale locale) {
  final localeName = intlLocaleName(locale);
  final country = locale.countryCode?.toUpperCase();
  final entry = country != null ? kDiaperUnitCostByCountry[country] : null;
  if (entry != null) {
    return DiaperCostConfig(
      localeName: localeName,
      currencyCode: entry.currency,
      unitCost: entry.unitCost,
      decimalDigits: entry.decimals,
    );
  }
  return DiaperCostConfig(
    localeName: localeName,
    currencyCode: 'EUR',
    unitCost: _kDefaultEuroUnitCost,
  );
}

/// Resuelve el insight de gasto: moneda manual o automática por locale.
DiaperCostConfig resolveDiaperCostConfig({
  required Locale moneyLocale,
  String? currencyCode,
}) {
  final code = currencyCode?.trim().toUpperCase();
  if (code != null && code.isNotEmpty) {
    final entry = kDiaperUnitCostByCurrency[code];
    if (entry != null) {
      return DiaperCostConfig(
        localeName: intlLocaleName(moneyLocale),
        currencyCode: code,
        unitCost: entry.unitCost,
        decimalDigits: entry.decimals,
      );
    }
  }
  return diaperCostConfigForLocale(moneyLocale);
}
