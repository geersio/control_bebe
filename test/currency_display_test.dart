import 'package:flutter_test/flutter_test.dart';

import 'package:control_bebe/core/utils/currency_display.dart';

void main() {
  group('formatCurrencyAmount EUR según locale', () {
    test('es_ES: 19,99 € (coma, símbolo detrás)', () {
      final text = formatCurrencyAmount(
        amount: 19.99,
        currencyCode: 'EUR',
        localeName: 'es_ES',
      );
      expect(text, contains('19,99'));
      expect(text, endsWith('€'));
      expect(text, isNot(contains('EUR')));
      expect(text.startsWith('€'), isFalse);
    });

    test('en_US: €19.99 (punto, símbolo delante pegado)', () {
      final text = formatCurrencyAmount(
        amount: 19.99,
        currencyCode: 'EUR',
        localeName: 'en_US',
      );
      expect(text, contains('19.99'));
      expect(text, startsWith('€'));
      expect(text, isNot(contains('EUR')));
      expect(text.contains(' €'), isFalse);
    });

    test('en_GB: €19.99', () {
      final text = formatCurrencyAmount(
        amount: 19.99,
        currencyCode: 'EUR',
        localeName: 'en_GB',
      );
      expect(text, contains('19.99'));
      expect(text, startsWith('€'));
      expect(text, isNot(contains('EUR')));
    });

    test('de_DE: 19,99 €', () {
      final text = formatCurrencyAmount(
        amount: 19.99,
        currencyCode: 'EUR',
        localeName: 'de_DE',
      );
      expect(text, contains('19,99'));
      expect(text, endsWith('€'));
      expect(text, isNot(contains('EUR')));
    });

    test('fr_FR: 19,99 €', () {
      final text = formatCurrencyAmount(
        amount: 19.99,
        currencyCode: 'EUR',
        localeName: 'fr_FR',
      );
      expect(text, contains('19,99'));
      expect(text, endsWith('€'));
      expect(text, isNot(contains('EUR')));
    });
  });

  group('formatStoreOrLocalizedPrice', () {
    test('prioriza el string de la tienda', () {
      final text = formatStoreOrLocalizedPrice(
        amount: 19.99,
        currencyCode: 'EUR',
        localeName: 'es_ES',
        storeFormatted: r'$349.00',
      );
      expect(text, r'$349.00');
    });

    test('cae a locale si no hay string de tienda', () {
      final text = formatStoreOrLocalizedPrice(
        amount: 19.99,
        currencyCode: 'EUR',
        localeName: 'en_US',
        storeFormatted: null,
      );
      expect(text, startsWith('€'));
      expect(text, contains('19.99'));
    });
  });

  group('formatCurrencyAmount otras monedas', () {
    test('USD con locale en_US', () {
      final text = formatCurrencyAmount(
        amount: 2.99,
        currencyCode: 'USD',
        localeName: 'en_US',
      );
      expect(text, contains('2.99'));
      expect(text, contains(r'$'));
      expect(text, isNot(contains('USD')));
    });

    test('GBP con locale en_GB', () {
      final text = formatCurrencyAmount(
        amount: 2.99,
        currencyCode: 'GBP',
        localeName: 'en_GB',
      );
      expect(text, contains('2.99'));
      expect(text, contains('£'));
      expect(text, isNot(contains('GBP')));
    });
  });
}
