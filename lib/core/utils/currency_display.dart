import 'package:intl/intl.dart';

/// Formatea un importe con el símbolo de la moneda según el locale del usuario.
///
/// Usa [NumberFormat.simpleCurrency] (equivalente a `Intl.NumberFormat` en JS):
/// - `en_US` / `en_GB` + EUR → `€19.99`
/// - `es_ES` / `de_DE` / `fr_FR` + EUR → `19,99 €`
///
/// Nunca deja el código ISO pegado al número (`EUR2,50`). Si `intl` cae al
/// código, se sustituye por el glifo (`€`, `$`…).
///
/// Para precios de suscripción, preferir el `priceString` de StoreKit / Play
/// Billing ([formatStoreOrLocalizedPrice]); esta función es el fallback para
/// importes calculados (equivalente mensual, gasto en pañales, etc.).
String formatCurrencyAmount({
  required double amount,
  required String currencyCode,
  required String localeName,
  int? decimalDigits,
}) {
  final code = currencyCode.toUpperCase();
  final format = NumberFormat.simpleCurrency(
    locale: localeName,
    name: code,
    decimalDigits: decimalDigits,
  );
  final formatted = format.format(amount);
  final intlSymbol = format.currencySymbol;
  final glyph = currencyGlyphFor(code, localeName: localeName);
  if (intlSymbol == glyph) return formatted;
  if (intlSymbol.isEmpty) return formatted;
  return formatted.replaceAll(intlSymbol, glyph);
}

/// Precio para UI: prioriza el string de la tienda (divisa y formato del
/// mercado del usuario) y, si no hay, cae a [formatCurrencyAmount].
String formatStoreOrLocalizedPrice({
  required double amount,
  required String currencyCode,
  required String localeName,
  String? storeFormatted,
  int? decimalDigits,
}) {
  final fromStore = storeFormatted?.trim();
  if (fromStore != null && fromStore.isNotEmpty) return fromStore;
  return formatCurrencyAmount(
    amount: amount,
    currencyCode: currencyCode,
    localeName: localeName,
    decimalDigits: decimalDigits,
  );
}

/// Símbolos seguros cuando intl cae al código ISO en vez del glifo.
const Map<String, String> _kKnownSymbols = {
  'EUR': '€',
  'USD': r'$',
  'GBP': '£',
  'JPY': '¥',
  'CNY': '¥',
  'KRW': '₩',
  'INR': '₹',
  'BRL': r'R$',
  'MXN': r'$',
  'CAD': r'$',
  'AUD': r'$',
  'CHF': 'CHF',
  'PLN': 'zł',
  'CZK': 'Kč',
  'SEK': 'kr',
  'NOK': 'kr',
  'DKK': 'kr',
  'HUF': 'Ft',
  'RON': 'lei',
  'BGN': 'лв',
  'TRY': '₺',
  'ILS': '₪',
  'ARS': r'$',
  'CLP': r'$',
  'COP': r'$',
  'PEN': 'S/',
  'UYU': r'$',
  'NZD': r'$',
  'ZAR': 'R',
  'AED': 'د.إ',
  'SAR': 'ر.س',
};

String _displaySymbol(String code, String fromIntl) {
  if (fromIntl.isNotEmpty && fromIntl.toUpperCase() != code) {
    return fromIntl;
  }
  return _kKnownSymbols[code] ?? (fromIntl.isEmpty ? code : fromIntl);
}

/// Glifo de la moneda (`€`, `$`…), nunca el código ISO si tenemos símbolo.
String currencyGlyphFor(String currencyCode, {String? localeName}) {
  final code = currencyCode.toUpperCase();
  final fromIntl = NumberFormat.simpleCurrency(
    locale: localeName,
    name: code,
  ).currencySymbol;
  return _displaySymbol(code, fromIntl);
}
