import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:control_bebe/core/utils/diaper_cost_localization.dart';

void main() {
  test('España usa EUR y 0,35 € por pañal', () {
    final config = diaperCostConfigForLocale(const Locale('es', 'ES'));
    expect(config.currencyCode, 'EUR');
    expect(config.unitCost, 0.35);
    final text = config.format(0.35);
    expect(text, contains('0,35'));
    expect(text, contains('€'));
    expect(text, isNot(contains('EUR')));
  });

  test('Reino Unido usa GBP', () {
    final config = diaperCostConfigForLocale(const Locale('en', 'GB'));
    expect(config.currencyCode, 'GBP');
    expect(config.unitCost, 0.28);
    final text = config.format(0.28);
    expect(text, contains('0.28'));
    expect(text, contains('£'));
    expect(text, isNot(contains('GBP')));
  });

  test('Estados Unidos usa USD', () {
    final config = diaperCostConfigForLocale(const Locale('en', 'US'));
    expect(config.currencyCode, 'USD');
    expect(config.unitCost, 0.37);
    final text = config.format(0.37);
    expect(text, contains('0.37'));
    expect(text, contains(r'$'));
    expect(text, isNot(contains('USD')));
  });

  test('EUR con locale en_US: € delante y punto decimal', () {
    final config = resolveDiaperCostConfig(
      moneyLocale: const Locale('en', 'US'),
      currencyCode: 'EUR',
    );
    final text = config.format(1.85);
    expect(text, contains('€'));
    expect(text, contains('1.85'));
    expect(text, startsWith('€'));
    expect(text, isNot(contains('EUR')));
  });

  test('Brasil usa BRL con precio distinto a España', () {
    final config = diaperCostConfigForLocale(const Locale('pt', 'BR'));
    expect(config.currencyCode, 'BRL');
    expect(config.unitCost, greaterThan(1));
  });

  test('País desconocido cae en EUR por defecto', () {
    final config = diaperCostConfigForLocale(const Locale('en', 'XX'));
    expect(config.currencyCode, 'EUR');
    expect(config.unitCost, 0.35);
  });

  test('coste mensual proyecta 30 días', () {
    final config = diaperCostConfigForLocale(const Locale('es', 'ES'));
    expect(config.monthlyCost(6.7), closeTo(6.7 * 0.35 * 30, 0.01));
  });

  test('moneda manual USD ignora el país del locale', () {
    final config = resolveDiaperCostConfig(
      moneyLocale: const Locale('es', 'ES'),
      currencyCode: 'USD',
    );
    expect(config.currencyCode, 'USD');
    expect(config.unitCost, 0.37);
  });

  test('moneda null sigue el locale', () {
    final config = resolveDiaperCostConfig(
      moneyLocale: const Locale('en', 'GB'),
      currencyCode: null,
    );
    expect(config.currencyCode, 'GBP');
    expect(config.unitCost, 0.28);
  });

  test('EUR manual usa precio de referencia ES', () {
    final config = resolveDiaperCostConfig(
      moneyLocale: const Locale('en', 'US'),
      currencyCode: 'EUR',
    );
    expect(config.currencyCode, 'EUR');
    expect(config.unitCost, 0.35);
  });

  test('toda moneda seleccionable tiene nombre y bandera', () {
    for (final code in kSelectableCurrencyCodes) {
      expect(kCurrencyNames.containsKey(code), isTrue, reason: code);
      expect(currencyDisplayName(code, 'es'), isNot(code), reason: code);
      expect(currencyDisplayName(code, 'en'), isNot(code), reason: code);
      expect(currencyFlagEmoji(code), isNotEmpty, reason: code);
    }
  });

  test('la búsqueda ignora acentos y mayúsculas', () {
    expect(
      normalizeForSearch(currencyDisplayName('USD', 'es')),
      contains('dolar'),
    );
    expect(normalizeForSearch('Séquel'), 'sequel');
  });

  test('el modo automático resuelve la moneda del locale', () {
    expect(automaticCurrencyCode(const Locale('es', 'ES')), 'EUR');
    expect(automaticCurrencyCode(const Locale('en', 'US')), 'USD');
  });
}
