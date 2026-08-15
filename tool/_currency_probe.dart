import 'package:intl/intl.dart';

void main() {
  const amount = 2.4991;
  for (final locale in ['es', 'es_ES', 'en', 'en_US']) {
    final currency = NumberFormat.currency(locale: locale, name: 'EUR');
    final simple = NumberFormat.simpleCurrency(locale: locale, name: 'EUR');
    final simpleUsd = NumberFormat.simpleCurrency(locale: locale, name: 'USD');
    print('$locale  currency=[${currency.format(amount)}]  '
        'simple=[${simple.format(amount)}]  '
        'simpleUSD=[${simpleUsd.format(amount)}]  '
        'digits=${simple.decimalDigits}');
  }
  final decimal = NumberFormat.decimalPatternDigits(
    locale: 'en',
    decimalDigits: 2,
  );
  print('decimalPatternDigits en=[${decimal.format(amount)}]');
}
