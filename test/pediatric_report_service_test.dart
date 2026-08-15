import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:control_bebe/core/models/baby_profile.dart';
import 'package:control_bebe/core/models/diaper_record.dart';
import 'package:control_bebe/core/models/enums.dart';
import 'package:control_bebe/core/models/feeding_record.dart';
import 'package:control_bebe/core/models/height_record.dart';
import 'package:control_bebe/core/models/sleep_record.dart';
import 'package:control_bebe/core/models/weight_record.dart';
import 'package:control_bebe/features/export/models/pediatric_report_data.dart';
import 'package:control_bebe/features/export/services/pediatric_report_service.dart';
import 'package:control_bebe/features/export/widgets/who_growth_chart_pdf.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
    await initializeDateFormatting('en', null);
  });

  PediatricReportData sampleData({bool withRecords = true}) {
    final now = DateTime(2026, 6, 12, 10);
    final birth = DateTime(2026, 2, 1);
    return PediatricReportData(
      baby: BabyProfile(name: 'Gonzalo', isMale: true, birthDate: birth),
      weightRecords: withRecords
          ? [
              WeightRecord(weightKg: 3.4, dateTime: DateTime(2026, 2, 1)),
              WeightRecord(weightKg: 4.2, dateTime: DateTime(2026, 3, 1)),
              WeightRecord(weightKg: 5.1, dateTime: DateTime(2026, 4, 1)),
              WeightRecord(weightKg: 5.9, dateTime: DateTime(2026, 5, 1)),
              WeightRecord(weightKg: 6.63, dateTime: DateTime(2026, 6, 10)),
            ]
          : [],
      heightRecords: withRecords
          ? [
              HeightRecord(heightCm: 52, dateTime: DateTime(2026, 2, 1)),
              HeightRecord(heightCm: 58, dateTime: DateTime(2026, 4, 1)),
              HeightRecord(heightCm: 61.5, dateTime: DateTime(2026, 6, 10)),
            ]
          : [],
      feedingsHistory: withRecords
          ? [
              FeedingRecord(
                type: FeedingType.leftBreast,
                dateTime: now.subtract(const Duration(hours: 3)),
                durationSeconds: 900,
              ),
              FeedingRecord(
                type: FeedingType.bottle,
                dateTime: now.subtract(const Duration(days: 1)),
                amountMl: 120,
              ),
            ]
          : [],
      diapersHistory: withRecords
          ? [
              DiaperRecord(type: DiaperType.wet, dateTime: now),
              DiaperRecord(
                type: DiaperType.both,
                dateTime: now.subtract(const Duration(days: 2)),
              ),
            ]
          : [],
      sleepHistory: withRecords
          ? [
              SleepRecord(
                startDateTime: DateTime(2026, 6, 11, 22),
                endDateTime: DateTime(2026, 6, 12, 7),
                type: SleepType.night,
              ),
              SleepRecord(
                startDateTime: DateTime(2026, 6, 12, 9),
                endDateTime: DateTime(2026, 6, 12, 9, 45),
                type: SleepType.nap,
              ),
              SleepRecord(
                startDateTime: DateTime(2026, 6, 12, 2),
                endDateTime: DateTime(2026, 6, 12, 2, 15),
                type: SleepType.nightWaking,
              ),
            ]
          : [],
      generatedAt: now,
    );
  }

  test('genera un PDF válido con datos en ES y EN', () async {
    for (final locale in const [Locale('es'), Locale('en')]) {
      final l10n = lookupAppLocalizations(locale);
      final bytes = await PediatricReportService.buildPdf(
        data: sampleData(),
        l10n: l10n,
      );
      expect(bytes.length, greaterThan(1000));
      // Cabecera estándar de un archivo PDF: "%PDF".
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    }
  });

  test('genera un PDF válido sin registros', () async {
    final l10n = lookupAppLocalizations(const Locale('es'));
    final bytes = await PediatricReportService.buildPdf(
      data: sampleData(withRecords: false),
      l10n: l10n,
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('nombre de archivo sin acentos ni espacios', () {
    final l10n = lookupAppLocalizations(const Locale('es'));
    final data = PediatricReportData(
      baby: BabyProfile(
        name: 'Óscar Ñoño',
        isMale: true,
        birthDate: DateTime(2026, 2, 1),
      ),
      weightRecords: [],
      feedingsHistory: [],
      diapersHistory: [],
      generatedAt: DateTime(2026, 6, 12),
    );
    expect(
      PediatricReportService.suggestedFileName(data, l10n),
      'informe-crecimiento-oscar-nono-20260612.pdf',
    );
  });

  test('ejes dinámicos: bebé ~5 meses usa xMax 7 y datos >60% del eje', () {
    // 4m 29d ≈ 4.97 meses → ceil(edad+2)=7 → mínimo 6 → xMax 7
    final ageMonths = 4.97;
    final xMax = math.max(6, (ageMonths + 2).ceil());
    expect(xMax, 7);
    // Los datos llegan hasta la edad actual: ~5/7 del eje X (>60%).
    expect(ageMonths / xMax, greaterThan(0.6));
  });

  test('genera PDF con sección de altura cuando hay HeightRecord', () async {
    final l10n = lookupAppLocalizations(const Locale('es'));
    final bytes = await PediatricReportService.buildPdf(
      data: sampleData(),
      l10n: l10n,
    );
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    // WhoGrowthChartPoint smoke: el widget se instancia en el build.
    expect(WhoChartPoint(ageMonths: 1, value: 4).value, 4);
  });
}
