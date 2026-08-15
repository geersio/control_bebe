import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

import '../models/measurement_units.dart';

const double _mlPerUsFlOz = 29.5735295625;

/// Límite superior razonable al guardar biberón (ml en almacenamiento).
const int kMaxReasonableVolumeMl = 2000;
const double _gramsPerOz = 28.349523125;
const int _ozPerLb = 16;

/// Convierte kg a libras y onzas enteras (onza redondeada).
({int lb, int oz}) kgToLbOz(double kg) {
  final totalGrams = kg * 1000;
  final totalOz = totalGrams / _gramsPerOz;
  var lb = totalOz ~/ _ozPerLb;
  var oz = (totalOz - lb * _ozPerLb).round();
  if (oz == _ozPerLb) {
    lb++;
    oz = 0;
  }
  if (oz < 0 && lb > 0) {
    lb--;
    oz = _ozPerLb - 1;
  }
  return (lb: lb, oz: oz.clamp(0, _ozPerLb - 1));
}

double poundsDecimalToKg(double pounds) => pounds / 2.2046226218;

double mlToUsFlOzNum(int ml) => ml / _mlPerUsFlOz;

int usFlOzToMl(double flOz) => (flOz * _mlPerUsFlOz).round();

String trimFlOzDisplay(double flOz, {int decimals = 1}) {
  final s = flOz.toStringAsFixed(decimals);
  if (decimals == 0) return s;
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Texto de peso a partir de kg guardados.
String formatWeightFromKg(
  double kg,
  MeasurementPrefs prefs,
  AppLocalizations l10n,
) {
  if (prefs.weight == WeightUnitMode.metric) {
    return l10n.formatWeightMetricKg(kg.toStringAsFixed(2));
  }
  final r = kgToLbOz(kg);
  return l10n.formatWeightLbOz(r.lb, r.oz);
}

/// Tendencia diaria (pendiente en g/día) con unidad según preferencia.
String formatWeightTrendGramsPerDay(
  double gramsPerDay,
  MeasurementPrefs prefs,
  AppLocalizations l10n,
) {
  final sign = gramsPerDay >= 0 ? '+' : '';
  final abs = gramsPerDay.abs();
  if (prefs.weight == WeightUnitMode.metric) {
    return l10n.homeWeightTrendGramsPerDay(sign, abs.toStringAsFixed(1));
  }
  final ozPerDay = abs / _gramsPerOz;
  return l10n.homeWeightTrendOuncesPerDay(sign, ozPerDay.toStringAsFixed(1));
}

/// Tendencia diaria de talla (cm/día).
String formatHeightTrendCmPerDay(double cmPerDay, AppLocalizations l10n) {
  final sign = cmPerDay >= 0 ? '+' : '';
  return l10n.homeHeightTrendCmPerDay(sign, cmPerDay.abs().toStringAsFixed(2));
}

/// Valor destacado + unidad para cabeceras de peso (métrico: 1 decimal).
({String value, String unit}) weightHeroDisplayParts(
  double kg,
  MeasurementPrefs prefs,
  AppLocalizations l10n,
) {
  if (prefs.weight == WeightUnitMode.metric) {
    return (value: kg.toStringAsFixed(1), unit: 'kg');
  }
  final formatted = formatWeightFromKg(kg, prefs, l10n);
  return (value: formatted, unit: '');
}

/// Tendencia diaria para la tarjeta de peso (sin «/día»).
String formatWeightTrendCompact(
  double gramsPerDay,
  MeasurementPrefs prefs,
  AppLocalizations l10n,
) {
  final sign = gramsPerDay >= 0 ? '+' : '';
  final abs = gramsPerDay.abs();
  if (prefs.weight == WeightUnitMode.metric) {
    return l10n.weightTrendGramsCompact(sign, abs.toStringAsFixed(1));
  }
  final ozPerDay = abs / _gramsPerOz;
  return l10n.weightTrendOuncesCompact(sign, ozPerDay.toStringAsFixed(1));
}

/// Volumen a partir de ml guardados.
String formatVolumeFromMl(
  int ml,
  MeasurementPrefs prefs,
  AppLocalizations l10n,
) {
  if (prefs.liquid == LiquidUnitMode.milliliters) {
    return l10n.formatVolumeMlOnly(ml);
  }
  final fl = mlToUsFlOzNum(ml);
  return l10n.formatVolumeFlOzOnly(trimFlOzDisplay(fl));
}

/// Interpreta un decimal aceptando coma o punto; rechaza mezclar ambos o
/// varios separadores (`4,5` y `4.5` sí; `4.5,2` no).
double? parseLooseDecimal(String raw) {
  final t = raw.trim().replaceAll(' ', '');
  if (t.isEmpty) return null;
  final commaCount = ','.allMatches(t).length;
  final dotCount = '.'.allMatches(t).length;
  if (commaCount + dotCount > 1) return null;
  final normalized = commaCount == 1 ? t.replaceAll(',', '.') : t;
  return double.tryParse(normalized);
}

/// Texto de campo: quita ceros sobrantes y usa coma o punto según idioma.
String formatDecimalForInput(
  double value, {
  int maxDecimals = 2,
  bool useCommaDecimal = false,
}) {
  var s = value.toStringAsFixed(maxDecimals);
  if (maxDecimals > 0) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
  }
  if (useCommaDecimal) s = s.replaceAll('.', ',');
  return s;
}

/// Dígitos y como mucho un separador decimal (`,` o `.`).
class LooseDecimalInputFormatter extends TextInputFormatter {
  const LooseDecimalInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = newValue.text;
    if (t.isEmpty) return newValue;
    if (RegExp(r'^[0-9]*[.,]?[0-9]*$').hasMatch(t)) return newValue;
    return oldValue;
  }
}

/// Texto inicial del campo de edición de peso según unidad (kg o lb decimales).
String weightInputDisplayFromKg(double kg, MeasurementPrefs prefs) {
  if (prefs.weight == WeightUnitMode.metric) {
    return kg.toStringAsFixed(2);
  }
  final pounds = kg * 2.2046226218;
  return pounds.toStringAsFixed(2);
}

/// Etiqueta corta para resúmenes (p. ej. "120 ml" / "4 fl oz").
String formatVolumeShort(
  int ml,
  MeasurementPrefs prefs,
  AppLocalizations l10n,
) {
  if (prefs.liquid == LiquidUnitMode.milliliters) {
    return '$ml ${l10n.unitMlShort}';
  }
  return formatVolumeFromMl(ml, prefs, l10n);
}

/// Parsea entrada de peso del formulario → kg. Acepta `,` o `.`.
double? parseWeightInputToKg(String raw, MeasurementPrefs prefs) {
  final n = parseLooseDecimal(raw);
  if (n == null || n <= 0) return null;
  if (prefs.weight == WeightUnitMode.metric) {
    return n;
  }
  return poundsDecimalToKg(n);
}

/// Límite superior razonable en la unidad de entrada (validación).
double maxWeightInputForValidation(MeasurementPrefs prefs) {
  return prefs.weight == WeightUnitMode.metric ? 50 : 110;
}

/// Parsea volumen del formulario → ml. Acepta `,` o `.`.
int? parseVolumeInputToMl(String raw, MeasurementPrefs prefs) {
  final n = parseLooseDecimal(raw);
  if (n == null || n <= 0) return null;
  if (prefs.liquid == LiquidUnitMode.milliliters) {
    return n.round();
  }
  return usFlOzToMl(n);
}

/// Dos cantidades (ml) representan el mismo atajo (p. ej. 90 ml ≈ 3 fl oz).
bool bottleQuickAmountsEquivalent(int aMl, int bMl) {
  if (aMl == bMl) return true;
  return (mlToUsFlOzNum(aMl) - mlToUsFlOzNum(bMl)).abs() < 0.06;
}

/// Primer atajo existente equivalente a [candidateMl], o null si es nuevo.
int? findMatchingQuickAmountMl(int candidateMl, Iterable<int> existingMl) {
  for (final existing in existingMl) {
    if (bottleQuickAmountsEquivalent(candidateMl, existing)) return existing;
  }
  return null;
}

/// Si el texto del campo coincide con un atajo de biberón (ml).
bool isBottleQuickAmountSelected(
  int amountMl,
  String fieldText,
  MeasurementPrefs prefs,
) {
  final parsed = parseVolumeInputToMl(fieldText, prefs);
  if (parsed == null) return false;
  if (prefs.liquid == LiquidUnitMode.milliliters) {
    return parsed == amountMl;
  }
  final fieldOz = parseLooseDecimal(fieldText);
  if (fieldOz == null) return false;
  return (fieldOz - mlToUsFlOzNum(amountMl)).abs() < 0.06;
}

/// Hint numérico para biberón según unidad.
String bottleVolumeHint(MeasurementPrefs prefs, AppLocalizations l10n) {
  return prefs.liquid == LiquidUnitMode.milliliters
      ? l10n.hintExampleMl
      : l10n.hintExampleFlOz;
}

/// Hint para registro de peso. Si hay última pesada, usa ese valor.
String weightEntryHint(
  MeasurementPrefs prefs,
  AppLocalizations l10n, {
  double? lastKg,
  bool useCommaDecimal = false,
}) {
  if (lastKg != null && lastKg > 0) {
    final value = prefs.weight == WeightUnitMode.metric
        ? lastKg
        : lastKg * 2.2046226218;
    return formatDecimalForInput(
      value,
      maxDecimals: 2,
      useCommaDecimal: useCommaDecimal,
    );
  }
  return prefs.weight == WeightUnitMode.metric
      ? l10n.hintExampleWeight
      : l10n.hintExampleWeightLb;
}

/// Hint para registro de altura. Si hay última medida, usa ese valor.
String heightEntryHint(
  AppLocalizations l10n, {
  double? lastCm,
  bool useCommaDecimal = false,
}) {
  if (lastCm != null && lastCm > 0) {
    return formatDecimalForInput(
      lastCm,
      maxDecimals: 1,
      useCommaDecimal: useCommaDecimal,
    );
  }
  return l10n.hintExampleHeight;
}

/// Etiqueta del campo de peso en formularios.
String weightFieldLabelForPrefs(MeasurementPrefs prefs, AppLocalizations l10n) {
  return prefs.weight == WeightUnitMode.metric
      ? l10n.weightFieldLabelMetric
      : l10n.weightFieldLabelImperial;
}

String formatHeightFromCm(double heightCm, AppLocalizations l10n) {
  final value = heightCm == heightCm.roundToDouble()
      ? heightCm.round().toString()
      : heightCm.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  return l10n.formatHeightCm(value);
}

String heightInputDisplayFromCm(double heightCm) {
  return heightCm == heightCm.roundToDouble()
      ? heightCm.round().toString()
      : heightCm.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}

/// Parsea entrada de talla → cm. Acepta `,` o `.`.
double? parseHeightInputToCm(String raw) {
  final n = parseLooseDecimal(raw);
  if (n == null || n <= 0) return null;
  return n;
}

/// Texto del control deslizante de peso (segmentos).
String weightSegmentLabel(WeightUnitMode m, AppLocalizations l10n) =>
    m == WeightUnitMode.metric ? l10n.unitSegmentKg : l10n.unitSegmentLbOz;

String liquidSegmentLabel(LiquidUnitMode m, AppLocalizations l10n) =>
    m == LiquidUnitMode.milliliters ? l10n.unitSegmentMl : l10n.unitSegmentFlOz;
