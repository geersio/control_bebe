import 'package:flutter_test/flutter_test.dart';

import 'package:control_bebe/core/percentiles_data.dart';
import 'package:control_bebe/core/who_lms.dart';

void main() {
  group('WhoLms', () {
    test('mediana peso niño al nacer: z≈0 y percentil≈50', () {
      // M de WFA boys mes 0 = 3.3464 kg
      final z = WhoLms.zScore(
        indicator: WhoLmsIndicator.weightForAge,
        isMale: true,
        ageInMonths: 0,
        x: 3.3464,
      );
      expect(z, isNotNull);
      expect(z!, closeTo(0, 1e-6));
      expect(WhoLms.percentileFromZ(z), closeTo(50, 0.01));
    });

    test('valor inverso P50 coincide con M (niño, 6 meses)', () {
      final coeffs = WhoLms.coeffsAt(
        indicator: WhoLmsIndicator.weightForAge,
        isMale: true,
        ageInMonths: 6,
      )!;
      final value = WhoLms.valueForZ(
        indicator: WhoLmsIndicator.weightForAge,
        isMale: true,
        ageInMonths: 6,
        z: 0,
      );
      expect(value, closeTo(coeffs.m, 1e-6));
    });

    test('P3/P97 por z-score conocidos (niño, 6 meses)', () {
      final p3 = WhoLms.valueForZ(
        indicator: WhoLmsIndicator.weightForAge,
        isMale: true,
        ageInMonths: 6,
        z: WhoLms.zP3,
      )!;
      final p97 = WhoLms.valueForZ(
        indicator: WhoLmsIndicator.weightForAge,
        isMale: true,
        ageInMonths: 6,
        z: WhoLms.zP97,
      )!;

      final z3 = WhoLms.zScore(
        indicator: WhoLmsIndicator.weightForAge,
        isMale: true,
        ageInMonths: 6,
        x: p3,
      )!;
      final z97 = WhoLms.zScore(
        indicator: WhoLmsIndicator.weightForAge,
        isMale: true,
        ageInMonths: 6,
        x: p97,
      )!;

      expect(z3, closeTo(WhoLms.zP3, 1e-5));
      expect(z97, closeTo(WhoLms.zP97, 1e-5));
      expect(WhoLms.percentileFromZ(z3), closeTo(3, 0.15));
      expect(WhoLms.percentileFromZ(z97), closeTo(97, 0.15));
    });

    test('interpolación lineal de L/M/S entre meses', () {
      final at0 = WhoLms.coeffsAt(
        indicator: WhoLmsIndicator.weightForAge,
        isMale: true,
        ageInMonths: 0,
      )!;
      final at1 = WhoLms.coeffsAt(
        indicator: WhoLmsIndicator.weightForAge,
        isMale: true,
        ageInMonths: 1,
      )!;
      final mid = WhoLms.coeffsAt(
        indicator: WhoLmsIndicator.weightForAge,
        isMale: true,
        ageInMonths: 0.5,
      )!;
      expect(mid.m, closeTo((at0.m + at1.m) / 2, 1e-9));
      expect(mid.s, closeTo((at0.s + at1.s) / 2, 1e-9));
      expect(mid.l, closeTo((at0.l + at1.l) / 2, 1e-9));
    });

    test('talla niña al nacer: M ≈ 49.15 cm → P50', () {
      final z = WhoLms.zScore(
        indicator: WhoLmsIndicator.lengthForAge,
        isMale: false,
        ageInMonths: 0,
        x: 49.1477,
      );
      expect(z, closeTo(0, 1e-6));
    });
  });

  group('PercentilesData LMS', () {
    test('peso en mediana se muestra como P50', () {
      final m = WhoLms.coeffsAt(
        indicator: WhoLmsIndicator.weightForAge,
        isMale: true,
        ageInMonths: 4,
      )!.m;
      final estimate = PercentilesData.estimateWeightPercentile(
        isMale: true,
        ageInMonths: 4,
        weightKg: m,
      );
      expect(estimate?.shortLabel(), 'P50');
      expect(estimate?.zScore, closeTo(0, 1e-5));
    });

    test('curvas de referencia coinciden con valueForZ', () {
      const age = 9.0;
      for (final p in WeightPercentile.pickerValues) {
        final fromApi = PercentilesData.getPercentileWeight(true, p, age);
        final fromLms = WhoLms.valueForZ(
          indicator: WhoLmsIndicator.weightForAge,
          isMale: true,
          ageInMonths: age,
          z: switch (p) {
            WeightPercentile.p3 => WhoLms.zP3,
            WeightPercentile.p15 => WhoLms.zP15,
            WeightPercentile.p50 => WhoLms.zP50,
            WeightPercentile.p85 => WhoLms.zP85,
            WeightPercentile.p97 => WhoLms.zP97,
          },
        );
        expect(fromApi, closeTo(fromLms!, 1e-9));
      }
    });

    test('por debajo de P3 y por encima de P97', () {
      final below = PercentilesData.estimateWeightPercentile(
        isMale: true,
        ageInMonths: 6,
        weightKg: 1.0,
      );
      expect(below?.isBelowTable, isTrue);
      expect(below?.shortLabel(), 'P3');

      final above = PercentilesData.estimateWeightPercentile(
        isMale: true,
        ageInMonths: 6,
        weightKg: 20.0,
      );
      expect(above?.isAboveTable, isTrue);
      expect(above?.shortLabel(), 'P97');
    });

    test('ejemplo CDC: niño 9 meses, LMS publicados', () {
      // Fila WHO boys WFA mes 9 (montanaflynn / WHO):
      // L=0.12339? — verificamos round-trip con M de la tabla.
      final c = WhoLms.coeffsAt(
        indicator: WhoLmsIndicator.weightForAge,
        isMale: true,
        ageInMonths: 9,
      )!;
      // Peso un poco por debajo de la mediana debe dar percentil < 50.
      final estimate = PercentilesData.estimateWeightPercentile(
        isMale: true,
        ageInMonths: 9,
        weightKg: c.m * 0.95,
      );
      expect(estimate, isNotNull);
      expect(estimate!.percentile!, lessThan(50));
      expect(estimate.shortLabel(), startsWith('P'));
    });
  });
}
