import 'who_lms.dart';

/// Curvas de referencia OMS usadas en gráficas (P3…P97).
enum WeightPercentile {
  p3,
  p15,
  p50,
  p85,
  p97;

  /// Texto compacto para etiquetas y selectores (e.g. "P3").
  String get shortLabel => switch (this) {
    WeightPercentile.p3 => 'P3',
    WeightPercentile.p15 => 'P15',
    WeightPercentile.p50 => 'P50',
    WeightPercentile.p85 => 'P85',
    WeightPercentile.p97 => 'P97',
  };

  double get _zScore => switch (this) {
    WeightPercentile.p3 => WhoLms.zP3,
    WeightPercentile.p15 => WhoLms.zP15,
    WeightPercentile.p50 => WhoLms.zP50,
    WeightPercentile.p85 => WhoLms.zP85,
    WeightPercentile.p97 => WhoLms.zP97,
  };

  /// Valores ofrecidos al usuario en el selector.
  static const List<WeightPercentile> pickerValues = [
    WeightPercentile.p3,
    WeightPercentile.p15,
    WeightPercentile.p50,
    WeightPercentile.p85,
    WeightPercentile.p97,
  ];
}

/// Percentiles OMS (peso/talla por edad) vía método LMS oficial.
///
/// Si [isMale] es `null` (sexo no especificado), se usa la media de las
/// tablas de niños y niñas (aproximación «mixta»).
///
/// El usuario solo ve etiquetas tipo `P16`; el cálculo interno usa z-score LMS.
class PercentilesData {
  /// Peso (kg) de la curva de referencia [percentile] a [ageInMonths].
  static double getPercentileWeight(
    bool? isMale,
    WeightPercentile percentile,
    double ageInMonths,
  ) {
    return _valueForZ(
          indicator: WhoLmsIndicator.weightForAge,
          isMale: isMale,
          ageInMonths: ageInMonths,
          z: percentile._zScore,
        ) ??
        0;
  }

  /// Atajo histórico para el percentil 50 (mediana).
  static double getP50Weight(bool? isMale, double ageInMonths) =>
      getPercentileWeight(isMale, WeightPercentile.p50, ageInMonths);

  /// Longitud/talla (cm) de la curva de referencia [percentile].
  static double getPercentileHeightCm(
    bool? isMale,
    WeightPercentile percentile,
    double ageInMonths,
  ) {
    return _valueForZ(
          indicator: WhoLmsIndicator.lengthForAge,
          isMale: isMale,
          ageInMonths: ageInMonths,
          z: percentile._zScore,
        ) ??
        0;
  }

  /// Percentil OMS peso-para-edad (LMS). UI: [WeightForAgePercentileEstimate.shortLabel].
  static WeightForAgePercentileEstimate? estimateWeightPercentile({
    required bool? isMale,
    required double ageInMonths,
    required double weightKg,
  }) {
    return _estimate(
      indicator: WhoLmsIndicator.weightForAge,
      isMale: isMale,
      ageInMonths: ageInMonths,
      value: weightKg,
    );
  }

  /// Percentil OMS talla-para-edad (LMS). UI: [WeightForAgePercentileEstimate.shortLabel].
  static WeightForAgePercentileEstimate? estimateHeightPercentile({
    required bool? isMale,
    required double ageInMonths,
    required double heightCm,
  }) {
    return _estimate(
      indicator: WhoLmsIndicator.lengthForAge,
      isMale: isMale,
      ageInMonths: ageInMonths,
      value: heightCm,
    );
  }

  static double? _valueForZ({
    required WhoLmsIndicator indicator,
    required bool? isMale,
    required double ageInMonths,
    required double z,
  }) {
    if (isMale != null) {
      return WhoLms.valueForZ(
        indicator: indicator,
        isMale: isMale,
        ageInMonths: ageInMonths,
        z: z,
      );
    }
    final boys = WhoLms.valueForZ(
      indicator: indicator,
      isMale: true,
      ageInMonths: ageInMonths,
      z: z,
    );
    final girls = WhoLms.valueForZ(
      indicator: indicator,
      isMale: false,
      ageInMonths: ageInMonths,
      z: z,
    );
    if (boys == null || girls == null) return boys ?? girls;
    return (boys + girls) / 2;
  }

  static WeightForAgePercentileEstimate? _estimate({
    required WhoLmsIndicator indicator,
    required bool? isMale,
    required double ageInMonths,
    required double value,
  }) {
    if (value <= 0 || ageInMonths < 0) return null;

    final double? z;
    if (isMale != null) {
      z = WhoLms.zScore(
        indicator: indicator,
        isMale: isMale,
        ageInMonths: ageInMonths,
        x: value,
      );
    } else {
      final zBoys = WhoLms.zScore(
        indicator: indicator,
        isMale: true,
        ageInMonths: ageInMonths,
        x: value,
      );
      final zGirls = WhoLms.zScore(
        indicator: indicator,
        isMale: false,
        ageInMonths: ageInMonths,
        x: value,
      );
      if (zBoys == null || zGirls == null) {
        z = zBoys ?? zGirls;
      } else {
        z = (zBoys + zGirls) / 2;
      }
    }
    if (z == null || z.isNaN) return null;

    final percentile = WhoLms.percentileFromZ(z);
    if (percentile < 3) {
      return WeightForAgePercentileEstimate.belowTable(zScore: z);
    }
    if (percentile > 97) {
      return WeightForAgePercentileEstimate.aboveTable(zScore: z);
    }
    return WeightForAgePercentileEstimate.at(percentile, zScore: z);
  }
}

/// Resultado de estimación de percentil. La UI muestra [shortLabel] (`P16`).
class WeightForAgePercentileEstimate {
  final double? percentile;
  final double? zScore;
  final bool isBelowTable;
  final bool isAboveTable;

  const WeightForAgePercentileEstimate._({
    this.percentile,
    this.zScore,
    this.isBelowTable = false,
    this.isAboveTable = false,
  });

  const WeightForAgePercentileEstimate.belowTable({double? zScore})
    : this._(isBelowTable: true, zScore: zScore);

  const WeightForAgePercentileEstimate.aboveTable({double? zScore})
    : this._(isAboveTable: true, zScore: zScore);

  const WeightForAgePercentileEstimate.at(double value, {double? zScore})
    : this._(percentile: value, zScore: zScore);

  /// Etiqueta fácil para el usuario: `P16`, o `P3`/`P97` en extremos.
  String shortLabel({int? roundTo}) {
    if (isBelowTable) return 'P3';
    if (isAboveTable) return 'P97';
    final rounded = (percentile ?? 50).round().clamp(1, 99);
    return 'P$rounded';
  }
}
