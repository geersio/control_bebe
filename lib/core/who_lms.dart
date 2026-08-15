import 'dart:math' as math;

import 'who_lms_tables.dart';

/// Coeficientes LMS en un punto de edad.
class WhoLmsCoeffs {
  final double l;
  final double m;
  final double s;

  const WhoLmsCoeffs({required this.l, required this.m, required this.s});
}

enum WhoLmsIndicator {
  weightForAge,
  lengthForAge,
}

/// Motor LMS OMS Child Growth Standards (0–60 meses).
///
/// z-score vía Box-Cox; el percentil para UI se obtiene con la CDF normal.
/// Las tablas son locales (sin red).
class WhoLms {
  WhoLms._();

  /// z-scores estándar que corresponden a P3 / P15 / P50 / P85 / P97.
  static const double zP3 = -1.880793608;
  static const double zP15 = -1.036433389;
  static const double zP50 = 0.0;
  static const double zP85 = 1.036433389;
  static const double zP97 = 1.880793608;

  static const double maxAgeMonths = 60.0;

  static List<(int, double, double, double)> _table({
    required WhoLmsIndicator indicator,
    required bool isMale,
  }) {
    return switch ((indicator, isMale)) {
      (WhoLmsIndicator.weightForAge, true) => kWhoLmsWfaBoys,
      (WhoLmsIndicator.weightForAge, false) => kWhoLmsWfaGirls,
      (WhoLmsIndicator.lengthForAge, true) => kWhoLmsLhfaBoys,
      (WhoLmsIndicator.lengthForAge, false) => kWhoLmsLhfaGirls,
    };
  }

  /// Interpola L, M, S por edad en meses (exacta / fraccionaria).
  static WhoLmsCoeffs? coeffsAt({
    required WhoLmsIndicator indicator,
    required bool isMale,
    required double ageInMonths,
  }) {
    if (ageInMonths.isNaN || ageInMonths < 0) return null;
    final age = ageInMonths.clamp(0.0, maxAgeMonths);
    final table = _table(indicator: indicator, isMale: isMale);

    final loMonth = age.floor().clamp(0, 60);
    final hiMonth = age.ceil().clamp(0, 60);
    final lo = table[loMonth];
    final hi = table[hiMonth];
    if (loMonth == hiMonth) {
      return WhoLmsCoeffs(l: lo.$2, m: lo.$3, s: lo.$4);
    }
    final t = age - loMonth;
    return WhoLmsCoeffs(
      l: lo.$2 + (hi.$2 - lo.$2) * t,
      m: lo.$3 + (hi.$3 - lo.$3) * t,
      s: lo.$4 + (hi.$4 - lo.$4) * t,
    );
  }

  /// z-score OMS para una medición [x] (kg o cm según indicador).
  static double? zScore({
    required WhoLmsIndicator indicator,
    required bool isMale,
    required double ageInMonths,
    required double x,
  }) {
    if (x <= 0) return null;
    final c = coeffsAt(
      indicator: indicator,
      isMale: isMale,
      ageInMonths: ageInMonths,
    );
    if (c == null || c.m <= 0 || c.s <= 0) return null;

    if (c.l.abs() < 1e-12) {
      return math.log(x / c.m) / c.s;
    }
    final ratio = x / c.m;
    if (ratio <= 0) return null;
    return (math.pow(ratio, c.l).toDouble() - 1.0) / (c.l * c.s);
  }

  /// Valor físico (kg/cm) para un z-score dado (curvas de referencia).
  static double? valueForZ({
    required WhoLmsIndicator indicator,
    required bool isMale,
    required double ageInMonths,
    required double z,
  }) {
    final c = coeffsAt(
      indicator: indicator,
      isMale: isMale,
      ageInMonths: ageInMonths,
    );
    if (c == null || c.m <= 0 || c.s <= 0) return null;

    if (c.l.abs() < 1e-12) {
      return c.m * math.exp(c.s * z);
    }
    final inside = 1.0 + c.l * c.s * z;
    if (inside <= 0) return null;
    return c.m * math.pow(inside, 1.0 / c.l).toDouble();
  }

  /// Percentil 0–100 a partir del z-score (CDF normal estándar).
  static double percentileFromZ(double z) {
    return _normalCdf(z) * 100.0;
  }

  /// Aproximación Abramowitz & Stegun 26.2.17 (error < 7.5e-8).
  static double _normalCdf(double z) {
    if (z.isNaN) return double.nan;
    if (z < -8) return 0;
    if (z > 8) return 1;

    const b1 = 0.319381530;
    const b2 = -0.356563782;
    const b3 = 1.781477937;
    const b4 = -1.821255978;
    const b5 = 1.330274429;
    const p = 0.2316419;
    const c = 0.3989422804014327; // 1/sqrt(2*pi)

    final x = z.abs();
    final t = 1.0 / (1.0 + p * x);
    final pdf = c * math.exp(-0.5 * x * x);
    final poly =
        ((((b5 * t + b4) * t + b3) * t + b2) * t + b1) * t;
    final tail = pdf * poly;
    return z >= 0 ? 1.0 - tail : tail;
  }
}
