import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:control_bebe/l10n/app_time_format.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/height_record.dart';
import '../../../core/models/sleep_record.dart';
import '../../../core/models/weight_record.dart';
import '../../../core/percentiles_data.dart';
import '../../../core/utils/baby_age_calendar.dart';
import '../models/pediatric_report_data.dart';
import '../widgets/who_growth_chart_pdf.dart';

/// Genera el informe PDF para el pediatra organizado por secciones:
/// resumen ejecutivo, peso, altura, alimentación, pañales y sueño.
class PediatricReportService {
  PediatricReportService._();

  static const PdfColor _accent = PdfColor.fromInt(0xFF2D6583);
  static const PdfColor _accentFill = PdfColor.fromInt(0xFFE8F1F5);
  static const PdfColor _textLight = PdfColors.grey600;
  static const PdfColor _boxBorder = PdfColors.grey300;
  static const PdfColor _alertFill = PdfColor.fromInt(0xFFFBE9E7);
  static const PdfColor _alertText = PdfColor.fromInt(0xFFA23B2C);

  static const int _maxTableRows = 10;

  static Future<Uint8List> buildPdf({
    required PediatricReportData data,
    required AppLocalizations l10n,
  }) async {
    final doc = pw.Document();
    final dateFormat = DateFormat.yMMMd(l10n.localeName);
    final dateTimeFormat = DateFormat.yMd(l10n.localeName).add_Hm();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
        footer: (ctx) => _footer(ctx, data, l10n, dateFormat),
        build: (ctx) => [
          _header(data, l10n, dateFormat),
          pw.SizedBox(height: 14),
          _executiveSummary(data, l10n, dateFormat),
          pw.SizedBox(height: 18),
          _majorSectionTitle(l10n.reportWeightSection),
          pw.SizedBox(height: 10),
          _weightOverview(data, l10n),
          pw.SizedBox(height: 14),
          _chartSection(data, l10n),
          pw.SizedBox(height: 14),
          _weightTableSection(data, l10n, dateFormat),
          pw.SizedBox(height: 14),
          _weightTrendsSection(data, l10n),
          if (data.heightRecords.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.NewPage(),
            _majorSectionTitle(l10n.reportHeightSection),
            pw.SizedBox(height: 10),
            _heightOverview(data, l10n),
            pw.SizedBox(height: 14),
            _heightChartSection(data, l10n),
            pw.SizedBox(height: 14),
            _heightTableSection(data, l10n, dateFormat),
          ],
          pw.SizedBox(height: 18),
          pw.NewPage(),
          _majorSectionTitle(l10n.reportFeedingSection),
          pw.SizedBox(height: 10),
          _feedingOverview(data, l10n),
          pw.SizedBox(height: 12),
          _breastfeedingDetailBox(data, l10n, dateFormat),
          pw.SizedBox(height: 12),
          _bottleDetailBox(data, l10n),
          pw.SizedBox(height: 12),
          _feedingPeriodRow(data, l10n),
          pw.SizedBox(height: 12),
          _feedingComparisonTable(data, l10n),
          pw.SizedBox(height: 18),
          pw.NewPage(),
          _majorSectionTitle(l10n.reportDiapersSection),
          pw.SizedBox(height: 10),
          _diapersOverview(data, l10n),
          pw.SizedBox(height: 12),
          _diaperPeriodRow(data, l10n),
          pw.SizedBox(height: 12),
          _diaperComparisonTable(data, l10n),
          pw.SizedBox(height: 18),
          pw.NewPage(),
          _majorSectionTitle(l10n.reportSleepSection),
          pw.SizedBox(height: 10),
          _sleepOverview(data, l10n),
          pw.SizedBox(height: 12),
          _sleepDailyTable(data, l10n, dateFormat),
          pw.SizedBox(height: 12),
          _sleepPeriodRow(data, l10n),
          pw.SizedBox(height: 12),
          _sleepComparisonTable(data, l10n),
          pw.SizedBox(height: 12),
          _sleepRecentSessions(data, l10n, dateTimeFormat),
        ],
      ),
    );

    return doc.save();
  }

  static String suggestedFileName(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final name = data.baby.name
        .toLowerCase()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final date = DateFormat('yyyyMMdd').format(data.generatedAt);
    return '${l10n.reportFileNamePrefix}-$name-$date.pdf';
  }

  static String _winAnsiSafe(String text) => text
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('−', '-')
      .replaceAll('→', '->');

  static NumberFormat _avgFormat(AppLocalizations l10n) =>
      NumberFormat.decimalPatternDigits(
        locale: l10n.localeName,
        decimalDigits: 1,
      );

  static NumberFormat _kgFormat(AppLocalizations l10n) =>
      NumberFormat.decimalPatternDigits(
        locale: l10n.localeName,
        decimalDigits: 2,
      );

  // ============================================================
  // Cabecera y resumen
  // ============================================================

  static pw.Widget _header(
    PediatricReportData data,
    AppLocalizations l10n,
    DateFormat dateFormat,
  ) {
    final baby = data.baby;
    final age = BabyAgeCalendar.monthsAndDaysAt(
      baby.birthDate,
      data.generatedAt,
    );
    final ageText = age.months > 0
        ? l10n.reportAgeMonthsDays(age.months, age.days)
        : l10n.reportAgeDays(age.days);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.reportTitle,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          baby.name,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _accent,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _boxBorder, width: 0.8),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            children: [
              _headerItem(
                l10n.reportSexLabel,
                baby.isMale == true
                    ? l10n.reportSexMale
                    : baby.isMale == false
                    ? l10n.reportSexFemale
                    : l10n.reportSexUnspecified,
              ),
              _headerItem(
                l10n.reportBirthDateLabel,
                dateFormat.format(baby.birthDate),
              ),
              _headerItem(l10n.reportAgeLabel, ageText),
              _headerItem(
                l10n.reportDateLabel,
                dateFormat.format(data.generatedAt),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _headerItem(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(fontSize: 7, color: _textLight),
          ),
          pw.SizedBox(height: 2),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  /// El resumen se lee en dos bloques: crecimiento (medidas antropométricas
  /// con su percentil) y rutina diaria de los últimos [kReportActivityDays]
  /// días. Cada bloque usa una rejilla de tarjetas de igual alto y ancho.
  static pw.Widget _executiveSummary(
    PediatricReportData data,
    AppLocalizations l10n,
    DateFormat dateFormat,
  ) {
    final stats = data.periodStats(kReportActivityDays);
    final growth = _summaryGrowthTiles(data, l10n, dateFormat);
    final routine = _summaryRoutineTiles(stats, l10n);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: pw.BoxDecoration(
        color: _accentFill,
        border: pw.Border.all(color: _accent, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l10n.reportExecutiveSummary.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _accent,
              letterSpacing: 0.6,
            ),
          ),
          pw.SizedBox(height: 8),
          if (growth.isEmpty && routine.isEmpty) _noDataLine(l10n),
          if (growth.isNotEmpty) ...[
            _summaryGroupLabel(l10n.reportSummaryGrowthGroup),
            pw.SizedBox(height: 5),
            _summaryTileGrid(growth, columns: growth.length),
          ],
          if (growth.isNotEmpty && routine.isNotEmpty) pw.SizedBox(height: 11),
          if (routine.isNotEmpty) ...[
            _summaryGroupLabel(
              '${_summaryRoutineGroupName(stats, l10n)} · '
              '${l10n.reportPeriodDays(kReportActivityDays)}',
            ),
            pw.SizedBox(height: 5),
            _summaryTileGrid(routine, columns: math.max(routine.length, 3)),
          ],
        ],
      ),
    );
  }

  static List<pw.Widget> _summaryGrowthTiles(
    PediatricReportData data,
    AppLocalizations l10n,
    DateFormat dateFormat,
  ) {
    final numFmt = _kgFormat(l10n);
    final tiles = <pw.Widget>[];

    final weight = data.latestWeight;
    if (weight != null) {
      final trend = data.weightTrendGramsPerDay(kReportActivityDays);
      tiles.add(
        _summaryHeroTile(
          label: l10n.reportCurrentWeight,
          value: '${numFmt.format(weight.weightKg)} kg',
          percentile: data.currentPercentile,
          l10n: l10n,
          details: [
            if (trend != null)
              _summaryDetailLine(
                l10n.reportWeightTrendDays(kReportActivityDays),
                _formatTrendForSummary(trend, l10n),
              ),
            _summaryDetailLine(
              l10n.reportSummaryMeasuredOn,
              dateFormat.format(weight.dateTime),
            ),
          ],
        ),
      );
    }

    final height = data.latestHeight;
    if (height != null) {
      tiles.add(
        _summaryHeroTile(
          label: l10n.reportCurrentHeight,
          value: '${numFmt.format(height.heightCm)} cm',
          percentile: data.currentHeightPercentile,
          l10n: l10n,
          details: [
            _summaryDetailLine(
              l10n.reportSummaryMeasuredOn,
              dateFormat.format(height.dateTime),
            ),
          ],
        ),
      );
    }

    return tiles;
  }

  /// El título solo nombra los apartados con registros, para no anunciar
  /// datos que no aparecen.
  static String _summaryRoutineGroupName(
    ReportPeriodStats stats,
    AppLocalizations l10n,
  ) {
    if (!stats.hasDiaperData) return l10n.reportFeedingSection;
    if (!stats.hasFeedingData) return l10n.reportDiapersSection;
    return l10n.reportSummaryRoutineGroup;
  }

  static List<pw.Widget> _summaryRoutineTiles(
    ReportPeriodStats stats,
    AppLocalizations l10n,
  ) {
    final avgFmt = _avgFormat(l10n);
    final tiles = <pw.Widget>[];

    if (stats.hasFeedingData) {
      tiles.add(
        _summaryKpiTile(
          l10n.reportFeedingPerDay,
          avgFmt.format(stats.averageFeedsPerDay),
        ),
      );
      if (stats.breastFeedCount > 0) {
        tiles.add(
          _summaryKpiTile(
            l10n.reportFeedingBreastPerDay,
            '${stats.averageBreastMinutesPerDay.round()} min',
          ),
        );
      }
      if (stats.bottleFeedCount > 0) {
        tiles.add(
          _summaryKpiTile(
            l10n.reportFeedingBottlePerDay,
            '${stats.averageBottleMlPerDay.round()} ml',
          ),
        );
      }
    }

    if (stats.hasDiaperData) {
      tiles.add(
        _summaryKpiTile(
          l10n.reportWetDiapersPerDay,
          avgFmt.format(stats.averageWetDiapersPerDay),
        ),
      );
      tiles.add(
        _summaryKpiTile(
          l10n.reportStoolDiapersPerDay,
          avgFmt.format(stats.averageStoolDiapersPerDay),
        ),
      );
    }

    return tiles;
  }

  static pw.Widget _summaryGroupLabel(String text) {
    return pw.Text(
      _winAnsiSafe(text).toUpperCase(),
      style: pw.TextStyle(
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
        color: _accent,
        letterSpacing: 0.7,
      ),
    );
  }

  /// Rejilla de una fila: columnas de igual ancho y celdas de igual alto,
  /// para que los valores queden alineados aunque las etiquetas ocupen
  /// distinto número de líneas.
  static pw.Widget _summaryTileGrid(
    List<pw.Widget> tiles, {
    required int columns,
  }) {
    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      columnWidths: {
        for (var i = 0; i < columns; i++) i: const pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          children: [
            for (var i = 0; i < columns; i++)
              if (i < tiles.length)
                pw.Padding(
                  padding: pw.EdgeInsets.only(right: i == columns - 1 ? 0 : 8),
                  child: tiles[i],
                )
              else
                pw.SizedBox(),
          ],
        ),
      ],
    );
  }

  static pw.Widget _summaryTileShell({
    required pw.EdgeInsets padding,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      padding: padding,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _boxBorder, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Tarjeta destacada: medida actual, percentil OMS asociado y, bajo una
  /// línea de separación, el contexto (tendencia y fecha de medición).
  static pw.Widget _summaryHeroTile({
    required String label,
    required String value,
    required WeightForAgePercentileEstimate? percentile,
    required AppLocalizations l10n,
    required List<pw.Widget> details,
  }) {
    return _summaryTileShell(
      padding: const pw.EdgeInsets.fromLTRB(10, 7, 10, 8),
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: _textLight,
                letterSpacing: 0.5,
              ),
            ),
            if (percentile != null) _percentileChip(percentile, l10n),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 17,
            fontWeight: pw.FontWeight.bold,
            color: _accent,
          ),
        ),
        if (details.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Container(height: 0.5, color: _boxBorder),
          pw.SizedBox(height: 2),
          ...details,
        ],
      ],
    );
  }

  /// Tarjeta compacta de la tira de rutina: valor arriba para que todos los
  /// números queden a la misma altura, etiqueta debajo.
  static pw.Widget _summaryKpiTile(String label, String value) {
    return _summaryTileShell(
      padding: const pw.EdgeInsets.fromLTRB(8, 6, 8, 7),
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: _accent,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 7, color: _textLight),
        ),
      ],
    );
  }

  static pw.Widget _summaryDetailLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 7.5, color: _textLight),
          ),
          pw.SizedBox(width: 6),
          pw.Flexible(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Fuera de la banda P3-P97 se marca en tono de aviso para que salte a la
  /// vista sin necesidad de leer el número.
  static pw.Widget _percentileChip(
    WeightForAgePercentileEstimate estimate,
    AppLocalizations l10n,
  ) {
    final outOfRange = estimate.isBelowTable || estimate.isAboveTable;
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          l10n.reportCurrentPercentile,
          style: const pw.TextStyle(fontSize: 7, color: _textLight),
        ),
        pw.SizedBox(width: 4),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: pw.BoxDecoration(
            color: outOfRange ? _alertFill : _accentFill,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            _percentileChipLabel(estimate, l10n),
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: outOfRange ? _alertText : _accent,
            ),
          ),
        ),
      ],
    );
  }

  static String _percentileChipLabel(
    WeightForAgePercentileEstimate estimate,
    AppLocalizations l10n,
  ) {
    if (estimate.isBelowTable) return l10n.reportPercentileBelow;
    if (estimate.isAboveTable) return l10n.reportPercentileAbove;
    final value = (estimate.percentile ?? 50).round().clamp(1, 99);
    return l10n.reportPercentileChip(value);
  }

  static String _formatTrendForSummary(
    double gramsPerDay,
    AppLocalizations l10n,
  ) {
    final sign = gramsPerDay >= 0 ? '+' : '-';
    final abs = _avgFormat(l10n).format(gramsPerDay.abs());
    return l10n.homeWeightTrendGramsPerDay(sign, abs);
  }

  static pw.Widget _majorSectionTitle(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _accentFill,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _accent,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ============================================================
  // Peso
  // ============================================================

  static pw.Widget _weightOverview(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final latest = data.latestWeight;
    if (latest == null) {
      return _statsBox(
        title: l10n.reportWeightOverviewTitle,
        children: [
          pw.Text(
            l10n.reportNoWeightData,
            style: const pw.TextStyle(fontSize: 9, color: _textLight),
          ),
        ],
      );
    }

    final kgFmt = _kgFormat(l10n);
    final lines = <pw.Widget>[
      _statLine(
        l10n.reportCurrentWeight,
        '${kgFmt.format(latest.weightKg)} kg',
      ),
    ];

    final pct = data.currentPercentile;
    if (pct != null) {
      lines.add(
        _statLine(
          l10n.reportWeightForAgePercentile,
          _percentileChipLabel(pct, l10n),
        ),
      );
    }

    final daysSince = data.daysSinceLastWeighIn;
    if (daysSince != null) {
      lines.add(
        _statLine(l10n.reportDaysSinceWeighIn, l10n.reportDaysCount(daysSince)),
      );
    }

    return _statsBox(title: l10n.reportWeightOverviewTitle, children: lines);
  }

  static pw.Widget _chartSection(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final baby = data.baby;
    final kgFmt = _kgFormat(l10n);
    final ageNow = BabyAgeCalendar.fractionalMonthsAt(
      baby.birthDate,
      data.generatedAt,
    );
    final points = [
      for (final r in data.weightRecords)
        WhoChartPoint(
          ageMonths: BabyAgeCalendar.fractionalMonthsAt(
            baby.birthDate,
            r.dateTime,
          ),
          value: r.weightKg,
        ),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.reportChartTitle),
        pw.SizedBox(height: 8),
        WhoGrowthChartPdf.build(
          ageNowMonths: ageNow,
          babyPoints: points,
          curveAt: (p, age) =>
              PercentilesData.getPercentileWeight(baby.isMale, p, age),
          formatValue: kgFmt.format,
          valueUnit: 'kg',
          accent: _accent,
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          _winAnsiSafe(l10n.reportChartWhoNote),
          style: const pw.TextStyle(fontSize: 7.5, color: _textLight),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          _winAnsiSafe(l10n.weightChartSource),
          style: pw.TextStyle(
            fontSize: 7,
            color: _textLight,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
    );
  }

  static pw.Widget _heightOverview(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final latest = data.latestHeight;
    if (latest == null) {
      return _statsBox(
        title: l10n.reportHeightOverviewTitle,
        children: [
          pw.Text(
            l10n.reportNoHeightData,
            style: const pw.TextStyle(fontSize: 9, color: _textLight),
          ),
        ],
      );
    }

    final cmFmt = _kgFormat(l10n);
    final lines = <pw.Widget>[
      _statLine(
        l10n.reportCurrentHeight,
        '${cmFmt.format(latest.heightCm)} cm',
      ),
    ];

    final pct = data.currentHeightPercentile;
    if (pct != null) {
      lines.add(
        _statLine(
          l10n.reportLengthForAgePercentile,
          _percentileChipLabel(pct, l10n),
        ),
      );
    }

    final daysSince = data.daysSinceLastHeight;
    if (daysSince != null) {
      lines.add(
        _statLine(l10n.reportDaysSinceHeight, l10n.reportDaysCount(daysSince)),
      );
    }

    return _statsBox(title: l10n.reportHeightOverviewTitle, children: lines);
  }

  static pw.Widget _heightChartSection(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final baby = data.baby;
    final cmFmt = _kgFormat(l10n);
    final ageNow = BabyAgeCalendar.fractionalMonthsAt(
      baby.birthDate,
      data.generatedAt,
    );
    final points = [
      for (final r in data.heightRecords)
        WhoChartPoint(
          ageMonths: BabyAgeCalendar.fractionalMonthsAt(
            baby.birthDate,
            r.dateTime,
          ),
          value: r.heightCm,
        ),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.reportHeightChartTitle),
        pw.SizedBox(height: 8),
        WhoGrowthChartPdf.build(
          ageNowMonths: ageNow,
          babyPoints: points,
          curveAt: (p, age) =>
              PercentilesData.getPercentileHeightCm(baby.isMale, p, age),
          formatValue: cmFmt.format,
          valueUnit: 'cm',
          accent: _accent,
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          _winAnsiSafe(l10n.reportChartWhoNote),
          style: const pw.TextStyle(fontSize: 7.5, color: _textLight),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          _winAnsiSafe(l10n.weightChartSource),
          style: pw.TextStyle(
            fontSize: 7,
            color: _textLight,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
    );
  }

  static pw.Widget _heightTableSection(
    PediatricReportData data,
    AppLocalizations l10n,
    DateFormat dateFormat,
  ) {
    if (data.heightRecords.isEmpty) return pw.SizedBox();

    final cmFormat = _kgFormat(l10n);
    final all = data.heightRecords;
    final start = math.max(0, all.length - _maxTableRows);
    final rows = <pw.TableRow>[];
    for (var i = all.length - 1; i >= start; i--) {
      final record = all[i];
      final previous = i > 0 ? all[i - 1] : null;
      rows.add(
        pw.TableRow(
          children: [
            _tableCell(dateFormat.format(record.dateTime)),
            _tableCell(_ageAtHeight(record, data, l10n)),
            _tableCell('${cmFormat.format(record.heightCm)} cm'),
            _tableCell(_heightChangeText(record, previous)),
          ],
        ),
      );
    }

    return pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle(l10n.reportHeightTableTitle),
          pw.SizedBox(height: 8),
          pw.Table(
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _boxBorder, width: 0.5),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _tableCell(l10n.reportTableDate, header: true),
                  _tableCell(l10n.reportTableAge, header: true),
                  _tableCell(l10n.reportTableHeight, header: true),
                  _tableCell(l10n.reportTableChange, header: true),
                ],
              ),
              ...rows,
            ],
          ),
        ],
      ),
    );
  }

  static String _ageAtHeight(
    HeightRecord record,
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final age = BabyAgeCalendar.monthsAndDaysAt(
      data.baby.birthDate,
      record.dateTime,
    );
    return age.months > 0
        ? l10n.reportAgeMonthsDays(age.months, age.days)
        : l10n.reportAgeDays(age.days);
  }

  static String _heightChangeText(HeightRecord record, HeightRecord? previous) {
    if (previous == null) return '-';
    final mm = ((record.heightCm - previous.heightCm) * 10).round();
    if (mm == 0) return '0 mm';
    return mm > 0 ? '+$mm mm' : '-${mm.abs()} mm';
  }

  static pw.Widget _weightTableSection(
    PediatricReportData data,
    AppLocalizations l10n,
    DateFormat dateFormat,
  ) {
    if (data.weightRecords.isEmpty) return pw.SizedBox();

    final kgFormat = _kgFormat(l10n);
    final all = data.weightRecords;
    final start = math.max(0, all.length - _maxTableRows);
    final rows = <pw.TableRow>[];
    for (var i = all.length - 1; i >= start; i--) {
      final record = all[i];
      final previous = i > 0 ? all[i - 1] : null;
      rows.add(
        pw.TableRow(
          children: [
            _tableCell(dateFormat.format(record.dateTime)),
            _tableCell(_ageAt(record, data, l10n)),
            _tableCell('${kgFormat.format(record.weightKg)} kg'),
            _tableCell(_changeText(record, previous)),
          ],
        ),
      );
    }

    return pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle(l10n.reportWeightTableTitle),
          pw.SizedBox(height: 8),
          pw.Table(
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _boxBorder, width: 0.5),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _tableCell(l10n.reportTableDate, header: true),
                  _tableCell(l10n.reportTableAge, header: true),
                  _tableCell(l10n.reportTableWeight, header: true),
                  _tableCell(l10n.reportTableChange, header: true),
                ],
              ),
              ...rows,
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _weightTrendsSection(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final trend7 = data.weightTrendGramsPerDay(kReportActivityDays);
    final trend15 = data.weightTrendGramsPerDay(kReportMidPeriodDays);
    final trend30 = data.weightTrendGramsPerDay(kReportLongPeriodDays);
    final gain30 = data.weightGainGrams(kReportLongPeriodDays);

    if (trend7 == null &&
        trend15 == null &&
        trend30 == null &&
        gain30 == null) {
      return pw.SizedBox();
    }

    return _statsBox(
      title: l10n.reportWeightTrendsTitle,
      children: [
        if (trend7 != null)
          _statLine(
            l10n.reportWeightTrendDays(kReportActivityDays),
            _formatGramsPerDay(trend7),
          ),
        if (trend15 != null)
          _statLine(
            l10n.reportWeightTrendDays(kReportMidPeriodDays),
            _formatGramsPerDay(trend15),
          ),
        if (trend30 != null)
          _statLine(
            l10n.reportWeightTrendDays(kReportLongPeriodDays),
            _formatGramsPerDay(trend30),
          ),
        if (gain30 != null)
          _statLine(
            l10n.reportWeightGainDays(kReportLongPeriodDays),
            gain30 >= 0 ? '+$gain30 g' : '$gain30 g',
          ),
      ],
    );
  }

  // ============================================================
  // Alimentación
  // ============================================================

  static pw.Widget _feedingOverview(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final stats = data.periodStats(kReportActivityDays);
    if (!stats.hasFeedingData) {
      return _statsBox(
        title: l10n.reportFeedingTitle,
        children: [_noDataLine(l10n)],
      );
    }

    final avgFmt = _avgFormat(l10n);
    final muted = data.feedingCoverageIsLow(kReportActivityDays);
    final logged = data.daysWithFeeding(kReportActivityDays);
    return _statsBox(
      title: l10n.reportFeedingTitle,
      children: [
        _statLine(
          l10n.reportCoverageLabel(logged, kReportActivityDays),
          '',
          muted: muted,
        ),
        if (muted) _coverageWarningLine(l10n),
        _statLine(
          l10n.reportFeedingDistribution,
          l10n.reportFeedingDistributionValue(
            data.percentOfFeeds(stats.breastFeedCount),
            data.percentOfFeeds(stats.bottleFeedCount),
            data.percentOfFeeds(stats.solidFeedCount),
          ),
        ),
        _statLine(
          l10n.reportFeedingPerDay,
          avgFmt.format(stats.averageFeedsPerDay),
          muted: muted,
        ),
        if (stats.breastFeedCount > 0)
          _statLine(
            l10n.reportFeedingBreastPerDay,
            '${stats.averageBreastMinutesPerDay.round()} min',
            muted: muted,
          ),
        if (stats.bottleFeedCount > 0)
          _statLine(
            l10n.reportFeedingBottlePerDay,
            '${stats.averageBottleMlPerDay.round()} ml',
            muted: muted,
          ),
      ],
    );
  }

  static pw.Widget _breastfeedingDetailBox(
    PediatricReportData data,
    AppLocalizations l10n,
    DateFormat dateFormat,
  ) {
    // Misma ventana que el resumen de alimentación (7 días), no la de 30.
    final stats = data.periodStats(kReportActivityDays);
    if (!stats.hasFeedingData) return pw.SizedBox();

    final lines = <pw.Widget>[];
    var showEstimatedFootnote = false;
    final interval = data.averageFeedIntervalMinutes(kReportActivityDays);
    if (interval != null) {
      lines.add(
        _statLine(
          l10n.reportFeedingInterval,
          _formatDurationMinutes(interval.round()),
        ),
      );
    }

    final longest = data.longestFeedGapMinutes(kReportActivityDays);
    if (longest != null) {
      lines.add(
        _statLine(
          l10n.reportFeedingLongestGap,
          _formatDurationMinutes(longest),
        ),
      );
    }

    if (stats.breastFeedCount > 0) {
      lines.add(
        _statLine(
          l10n.reportFeedingBreastBalance,
          l10n.reportFeedingBreastBalanceValue(
            stats.percentOfBreastSide(stats.leftBreastCount),
            stats.percentOfBreastSide(stats.rightBreastCount),
          ),
        ),
      );

      final avgSession = data.averageBreastSessionMinutes(kReportActivityDays);
      if (avgSession != null) {
        lines.add(
          _statLine(l10n.reportFeedingAvgSession, '${avgSession.round()} min'),
        );
      }

      lines.add(
        _statLine(
          l10n.reportFeedingEstimatedBreastStarred,
          '${stats.estimatedBreastMlPerDay.round()} ml',
        ),
      );
      showEstimatedFootnote = true;
    }

    final firstSolid = data.firstSolidFoodDate;
    lines.add(
      _statLine(
        l10n.reportFeedingFirstSolid,
        firstSolid != null
            ? dateFormat.format(firstSolid)
            : l10n.reportNoSolidFoodYet,
      ),
    );

    if (showEstimatedFootnote) {
      lines.add(pw.SizedBox(height: 4));
      lines.add(
        pw.Text(
          _winAnsiSafe(l10n.reportEstimatedBreastFootnote),
          style: pw.TextStyle(
            fontSize: 7,
            color: _textLight,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }

    if (lines.isEmpty) return pw.SizedBox();

    return _statsBox(
      title: l10n.reportBreastfeedingDetailTitle,
      children: lines,
    );
  }

  static pw.Widget _bottleDetailBox(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    // Misma ventana que el resumen de alimentación (7 días), no la de 30.
    final stats = data.periodStats(kReportActivityDays);
    if (stats.bottleFeedCount == 0) return pw.SizedBox();

    final avgFmt = _avgFormat(l10n);
    final avgMlPerFeed = stats.totalBottleMl / stats.bottleFeedCount;

    return _statsBox(
      title: l10n.reportBottleDetailTitle,
      children: [
        _statLine(
          l10n.reportFeedingBottlePerDay,
          '${stats.averageBottleMlPerDay.round()} ml',
        ),
        _statLine(
          l10n.reportBottleFeedsPerDay,
          avgFmt.format(stats.bottleFeedCount / kReportActivityDays),
        ),
        _statLine(l10n.reportBottleAvgPerFeed, '${avgMlPerFeed.round()} ml'),
        _statLine(
          l10n.reportBottleTotalPeriod(kReportActivityDays),
          '${stats.totalBottleMl} ml',
        ),
      ],
    );
  }

  static String _formatDurationMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  static pw.Widget _feedingPeriodRow(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final avgFmt = _avgFormat(l10n);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _feedingPeriodBox(
            l10n.reportPeriodDays(kReportMidPeriodDays),
            data.periodStats(kReportMidPeriodDays),
            data,
            kReportMidPeriodDays,
            l10n,
            avgFmt,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _feedingPeriodBox(
            l10n.reportPeriodDays(kReportLongPeriodDays),
            data.periodStats(kReportLongPeriodDays),
            data,
            kReportLongPeriodDays,
            l10n,
            avgFmt,
          ),
        ),
      ],
    );
  }

  static pw.Widget _feedingPeriodBox(
    String title,
    ReportPeriodStats stats,
    PediatricReportData data,
    int days,
    AppLocalizations l10n,
    NumberFormat avgFmt,
  ) {
    if (!stats.hasFeedingData) {
      return _statsBox(title: title, children: [_noDataLine(l10n)]);
    }
    final muted = data.feedingCoverageIsLow(days);
    final logged = data.daysWithFeeding(days);
    return _statsBox(
      title: title,
      children: [
        _statLine(l10n.reportCoverageLabel(logged, days), '', muted: muted),
        if (muted) _coverageWarningLine(l10n),
        _statLine(
          l10n.reportFeedingPerDay,
          avgFmt.format(stats.averageFeedsPerDay),
          muted: muted,
        ),
        if (stats.breastFeedCount > 0)
          _statLine(
            l10n.reportFeedingBreastPerDay,
            '${stats.averageBreastMinutesPerDay.round()} min',
            muted: muted,
          ),
        if (stats.bottleFeedCount > 0)
          _statLine(
            l10n.reportFeedingBottlePerDay,
            '${stats.averageBottleMlPerDay.round()} ml',
            muted: muted,
          ),
      ],
    );
  }

  static pw.Widget _feedingComparisonTable(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final title = l10n.reportComparisonTitle(kReportLongPeriodDays);
    if (!data.hasSufficientHistoryForComparison(kReportLongPeriodDays)) {
      return _statsBox(
        title: title,
        children: [
          pw.Text(
            l10n.reportComparisonInsufficientHistory,
            style: const pw.TextStyle(fontSize: 9, color: _textLight),
          ),
        ],
      );
    }
    final current = data.periodStats(kReportLongPeriodDays);
    final previous = data.previousPeriodStats(kReportLongPeriodDays);
    return _comparisonTable(
      title: title,
      l10n: l10n,
      rows: _feedingComparisonRows(current, previous, l10n),
    );
  }

  static List<pw.TableRow> _feedingComparisonRows(
    ReportPeriodStats current,
    ReportPeriodStats previous,
    AppLocalizations l10n,
  ) {
    final avgFmt = _avgFormat(l10n);
    final rows = <pw.TableRow>[];

    if (!current.hasFeedingData && !previous.hasFeedingData) return rows;

    _addComparisonRow(
      rows,
      label: l10n.reportFeedingPerDay,
      current: current.averageFeedsPerDay,
      previous: previous.averageFeedsPerDay,
      previousHadMetric: previous.feedCount > 0,
      l10n: l10n,
      avgFmt: avgFmt,
    );

    if (current.breastFeedCount > 0 || previous.breastFeedCount > 0) {
      _addComparisonRow(
        rows,
        label: l10n.reportFeedingBreastPerDay,
        current: current.averageBreastMinutesPerDay,
        previous: previous.averageBreastMinutesPerDay,
        previousHadMetric: previous.breastFeedCount > 0,
        l10n: l10n,
        avgFmt: avgFmt,
      );
      _addComparisonRow(
        rows,
        label: l10n.reportFeedingEstimatedBreastStarred,
        current: current.estimatedBreastMlPerDay,
        previous: previous.estimatedBreastMlPerDay,
        previousHadMetric: previous.breastFeedCount > 0,
        l10n: l10n,
        avgFmt: avgFmt,
      );
    }

    if (current.bottleFeedCount > 0 || previous.bottleFeedCount > 0) {
      _addComparisonRow(
        rows,
        label: l10n.reportFeedingBottlePerDay,
        current: current.averageBottleMlPerDay,
        previous: previous.averageBottleMlPerDay,
        previousHadMetric: previous.bottleFeedCount > 0,
        l10n: l10n,
        avgFmt: avgFmt,
      );
    }

    return rows;
  }

  // ============================================================
  // Pañales
  // ============================================================

  static pw.Widget _diapersOverview(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final stats = data.periodStats(kReportActivityDays);
    if (!stats.hasDiaperData) {
      return _statsBox(
        title: l10n.reportDiapersTitle,
        children: [_noDataLine(l10n)],
      );
    }

    final avgFmt = _avgFormat(l10n);
    final muted = data.diaperCoverageIsLow(kReportActivityDays);
    final logged = data.daysWithDiaper(kReportActivityDays);
    return _statsBox(
      title: l10n.reportDiapersTitle,
      children: [
        _statLine(
          l10n.reportCoverageLabel(logged, kReportActivityDays),
          '',
          muted: muted,
        ),
        if (muted) _coverageWarningLine(l10n),
        _statLine(
          l10n.reportDiapersPerDay,
          avgFmt.format(stats.averageDiapersPerDay),
          muted: muted,
        ),
        _statLine(
          l10n.reportWetDiapersPerDay,
          avgFmt.format(stats.averageWetDiapersPerDay),
          muted: muted,
        ),
        _statLine(
          l10n.reportStoolDiapersPerDay,
          avgFmt.format(stats.averageStoolDiapersPerDay),
          muted: muted,
        ),
        _statLine(
          l10n.reportDiaperDistribution,
          l10n.reportDiaperDistributionValue(
            stats.percentOfDiapers(stats.wetDiaperCount),
            stats.percentOfDiapers(stats.dirtyDiaperCount),
            stats.percentOfDiapers(stats.bothDiaperCount),
          ),
        ),
        _statLine(
          l10n.reportDaysWithoutStool,
          l10n.reportDaysWithoutStoolOfPeriod(
            data.daysWithoutStool(kReportActivityDays),
            kReportActivityDays,
          ),
        ),
      ],
    );
  }

  static pw.Widget _diaperPeriodRow(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final avgFmt = _avgFormat(l10n);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _diaperPeriodBox(
            l10n.reportPeriodDays(kReportMidPeriodDays),
            data.periodStats(kReportMidPeriodDays),
            data,
            l10n,
            avgFmt,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _diaperPeriodBox(
            l10n.reportPeriodDays(kReportLongPeriodDays),
            data.periodStats(kReportLongPeriodDays),
            data,
            l10n,
            avgFmt,
          ),
        ),
      ],
    );
  }

  static pw.Widget _diaperPeriodBox(
    String title,
    ReportPeriodStats stats,
    PediatricReportData data,
    AppLocalizations l10n,
    NumberFormat avgFmt,
  ) {
    final days = stats.days;
    if (!stats.hasDiaperData) {
      return _statsBox(title: title, children: [_noDataLine(l10n)]);
    }
    final muted = data.diaperCoverageIsLow(days);
    final logged = data.daysWithDiaper(days);
    return _statsBox(
      title: title,
      children: [
        _statLine(l10n.reportCoverageLabel(logged, days), '', muted: muted),
        if (muted) _coverageWarningLine(l10n),
        _statLine(
          l10n.reportDiapersPerDay,
          avgFmt.format(stats.averageDiapersPerDay),
          muted: muted,
        ),
        _statLine(
          l10n.reportWetDiapersPerDay,
          avgFmt.format(stats.averageWetDiapersPerDay),
          muted: muted,
        ),
        _statLine(
          l10n.reportStoolDiapersPerDay,
          avgFmt.format(stats.averageStoolDiapersPerDay),
          muted: muted,
        ),
        _statLine(
          l10n.reportDaysWithoutStool,
          l10n.reportDaysWithoutStoolOfPeriod(
            data.daysWithoutStool(days),
            days,
          ),
        ),
      ],
    );
  }

  static pw.Widget _diaperComparisonTable(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final title = l10n.reportComparisonTitle(kReportLongPeriodDays);
    if (!data.hasSufficientHistoryForComparison(kReportLongPeriodDays)) {
      return _statsBox(
        title: title,
        children: [
          pw.Text(
            l10n.reportComparisonInsufficientHistory,
            style: const pw.TextStyle(fontSize: 9, color: _textLight),
          ),
        ],
      );
    }
    final current = data.periodStats(kReportLongPeriodDays);
    final previous = data.previousPeriodStats(kReportLongPeriodDays);
    return _comparisonTable(
      title: title,
      l10n: l10n,
      rows: _diaperComparisonRows(current, previous, l10n),
    );
  }

  static List<pw.TableRow> _diaperComparisonRows(
    ReportPeriodStats current,
    ReportPeriodStats previous,
    AppLocalizations l10n,
  ) {
    final avgFmt = _avgFormat(l10n);
    final rows = <pw.TableRow>[];

    if (!current.hasDiaperData && !previous.hasDiaperData) return rows;

    _addComparisonRow(
      rows,
      label: l10n.reportDiapersPerDay,
      current: current.averageDiapersPerDay,
      previous: previous.averageDiapersPerDay,
      previousHadMetric: previous.diaperCount > 0,
      l10n: l10n,
      avgFmt: avgFmt,
    );
    _addComparisonRow(
      rows,
      label: l10n.reportWetDiapersPerDay,
      current: current.averageWetDiapersPerDay,
      previous: previous.averageWetDiapersPerDay,
      previousHadMetric: previous.wetDiaperCount > 0,
      l10n: l10n,
      avgFmt: avgFmt,
    );
    _addComparisonRow(
      rows,
      label: l10n.reportStoolDiapersPerDay,
      current: current.averageStoolDiapersPerDay,
      previous: previous.averageStoolDiapersPerDay,
      previousHadMetric: previous.stoolDiaperCount > 0,
      l10n: l10n,
      avgFmt: avgFmt,
    );

    return rows;
  }

  // ============================================================
  // Sueño
  // ============================================================

  static pw.Widget _sleepOverview(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final stats = data.sleepPeriodStats(kReportActivityDays);
    if (!stats.hasSleepData) {
      return _statsBox(
        title: l10n.reportSleepTitle,
        children: [_noDataLine(l10n)],
      );
    }

    final muted = data.sleepCoverageIsLow(kReportActivityDays);
    final avgFmt = _avgFormat(l10n);
    return _statsBox(
      title: l10n.reportSleepTitle,
      children: [
        _statLine(
          l10n.reportCoverageLabel(
            stats.daysWithSleepData,
            kReportActivityDays,
          ),
          '',
          muted: muted,
        ),
        if (muted) _coverageWarningLine(l10n),
        _statLine(
          l10n.reportSleepAveragePerRecordedDay,
          l10n.reportSleepHoursValue(
            avgFmt.format(stats.averageSleepHoursPerRecordedDay),
          ),
          muted: muted,
        ),
        _statLine(
          l10n.reportSleepTotal,
          formatDurationSecondsLocalized(l10n, stats.totalSleepSeconds),
        ),
        _statLine(l10n.reportSleepNaps, stats.napCount.toString()),
        _statLine(
          l10n.reportSleepNightWakings,
          stats.nightWakingCount.toString(),
        ),
        if (stats.nightWakingCount > 0)
          _statLine(
            l10n.reportSleepNightWakingTime,
            formatDurationSecondsLocalized(l10n, stats.totalNightWakingSeconds),
          ),
      ],
    );
  }

  static pw.Widget _sleepDailyTable(
    PediatricReportData data,
    AppLocalizations l10n,
    DateFormat dateFormat,
  ) {
    final seconds = data.sleepSecondsPerDay(kReportActivityDays);
    final start = DateTime(
      data.generatedAt.year,
      data.generatedAt.month,
      data.generatedAt.day,
    ).subtract(const Duration(days: kReportActivityDays - 1));

    return pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle(l10n.reportSleepDailyTitle),
          pw.SizedBox(height: 8),
          pw.Table(
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _boxBorder, width: 0.5),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _tableCell(l10n.reportSleepDay, header: true),
                  _tableCell(l10n.reportSleepDuration, header: true),
                ],
              ),
              for (var i = 0; i < seconds.length; i++)
                pw.TableRow(
                  children: [
                    _tableCell(dateFormat.format(start.add(Duration(days: i)))),
                    _tableCell(
                      seconds[i] == 0
                          ? _winAnsiSafe(l10n.reportComparisonNoData)
                          : formatDurationSecondsLocalized(l10n, seconds[i]),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _sleepPeriodRow(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _sleepPeriodBox(
            data,
            data.sleepPeriodStats(kReportMidPeriodDays),
            l10n,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _sleepPeriodBox(
            data,
            data.sleepPeriodStats(kReportLongPeriodDays),
            l10n,
          ),
        ),
      ],
    );
  }

  static pw.Widget _sleepPeriodBox(
    PediatricReportData data,
    SleepPeriodStats stats,
    AppLocalizations l10n,
  ) {
    final title = l10n.reportPeriodDays(stats.days);
    if (!stats.hasSleepData) {
      return _statsBox(title: title, children: [_noDataLine(l10n)]);
    }

    final muted = data.sleepCoverageIsLow(stats.days);
    final avgFmt = _avgFormat(l10n);
    return _statsBox(
      title: title,
      children: [
        _statLine(
          l10n.reportCoverageLabel(stats.daysWithSleepData, stats.days),
          '',
          muted: muted,
        ),
        if (muted) _coverageWarningLine(l10n),
        _statLine(
          l10n.reportSleepAveragePerRecordedDay,
          l10n.reportSleepHoursValue(
            avgFmt.format(stats.averageSleepHoursPerRecordedDay),
          ),
          muted: muted,
        ),
        _statLine(l10n.reportSleepNaps, stats.napCount.toString()),
        _statLine(
          l10n.reportSleepNightWakings,
          stats.nightWakingCount.toString(),
        ),
      ],
    );
  }

  static pw.Widget _sleepComparisonTable(
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final title = l10n.reportComparisonTitle(kReportLongPeriodDays);
    if (!data.hasSufficientSleepHistoryForComparison(kReportLongPeriodDays)) {
      return _statsBox(
        title: title,
        children: [
          pw.Text(
            l10n.reportComparisonInsufficientHistory,
            style: const pw.TextStyle(fontSize: 9, color: _textLight),
          ),
        ],
      );
    }

    final current = data.sleepPeriodStats(kReportLongPeriodDays);
    final previous = data.previousSleepPeriodStats(kReportLongPeriodDays);
    final rows = <pw.TableRow>[];
    final avgFmt = _avgFormat(l10n);
    if (current.hasSleepData || previous.hasSleepData) {
      _addComparisonRow(
        rows,
        label: l10n.reportSleepAveragePerRecordedDay,
        current: current.averageSleepHoursPerRecordedDay,
        previous: previous.averageSleepHoursPerRecordedDay,
        previousHadMetric: previous.hasSleepData,
        l10n: l10n,
        avgFmt: avgFmt,
      );
      _addComparisonRow(
        rows,
        label: l10n.reportSleepNapsPerRecordedDay,
        current: current.averageNapsPerRecordedDay,
        previous: previous.averageNapsPerRecordedDay,
        previousHadMetric: previous.hasSleepData,
        l10n: l10n,
        avgFmt: avgFmt,
      );
      _addComparisonRow(
        rows,
        label: l10n.reportSleepWakingsPerRecordedDay,
        current: current.averageNightWakingsPerRecordedDay,
        previous: previous.averageNightWakingsPerRecordedDay,
        previousHadMetric: previous.hasSleepData,
        l10n: l10n,
        avgFmt: avgFmt,
      );
    }
    return _comparisonTable(title: title, l10n: l10n, rows: rows);
  }

  static pw.Widget _sleepRecentSessions(
    PediatricReportData data,
    AppLocalizations l10n,
    DateFormat dateTimeFormat,
  ) {
    final sessions =
        data.sleepHistory.where((record) => record.isSleepBlock).toList()
          ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
    final recent = sessions.take(_maxTableRows).toList();
    if (recent.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.reportSleepRecentSessions),
        pw.SizedBox(height: 8),
        pw.Table(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _boxBorder, width: 0.5),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(3),
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableCell(l10n.reportSleepStart, header: true),
                _tableCell(l10n.reportSleepEnd, header: true),
                _tableCell(l10n.reportSleepType, header: true),
                _tableCell(l10n.reportSleepDuration, header: true),
              ],
            ),
            for (final record in recent)
              pw.TableRow(
                children: [
                  _tableCell(dateTimeFormat.format(record.startDateTime)),
                  _tableCell(
                    record.endDateTime == null
                        ? l10n.reportSleepInProgress
                        : dateTimeFormat.format(record.endDateTime!),
                  ),
                  _tableCell(_sleepTypeLabel(record, l10n)),
                  _tableCell(
                    formatDurationSecondsLocalized(
                      l10n,
                      record.durationSeconds(data.generatedAt),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static String _sleepTypeLabel(SleepRecord record, AppLocalizations l10n) {
    return record.type == SleepType.nap
        ? l10n.sleepTypeNap
        : l10n.sleepTypeNight;
  }

  // ============================================================
  // Utilidades compartidas
  // ============================================================

  static void _addComparisonRow(
    List<pw.TableRow> rows, {
    required String label,
    required double current,
    required double previous,
    required bool previousHadMetric,
    required AppLocalizations l10n,
    required NumberFormat avgFmt,
  }) {
    final noData = _winAnsiSafe(l10n.reportComparisonNoData);
    final prevText = previousHadMetric ? avgFmt.format(previous) : noData;
    final changeText = previousHadMetric
        ? _winAnsiSafe(
            _formatComparisonChange(
              current: current,
              previous: previous,
              l10n: l10n,
              avgFmt: avgFmt,
            ),
          )
        : noData;

    rows.add(
      pw.TableRow(
        children: [
          _tableCell(label),
          _tableCell(avgFmt.format(current)),
          _tableCell(prevText),
          _tableCell(changeText, accent: previousHadMetric),
        ],
      ),
    );
  }

  /// Con bases < 1 (p. ej. deposiciones/día), el % es ruido: mostrar absoluto.
  static String _formatComparisonChange({
    required double current,
    required double previous,
    required AppLocalizations l10n,
    required NumberFormat avgFmt,
  }) {
    if (previous.abs() < 1 || current.abs() < 1) {
      return l10n.reportComparisonAbsoluteChange(
        avgFmt.format(previous),
        avgFmt.format(current),
      );
    }
    return _formatPercentChange(
      PediatricReportData.percentChange(current, previous),
      l10n,
    );
  }

  static pw.Widget _comparisonTable({
    required String title,
    required AppLocalizations l10n,
    required List<pw.TableRow> rows,
  }) {
    if (rows.isEmpty) {
      return _statsBox(title: title, children: [_noDataLine(l10n)]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        pw.SizedBox(height: 8),
        pw.Table(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _boxBorder, width: 0.5),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableCell(l10n.reportComparisonMetric, header: true),
                _tableCell(l10n.reportComparisonCurrent, header: true),
                _tableCell(l10n.reportComparisonPrevious, header: true),
                _tableCell(l10n.reportComparisonChange, header: true),
              ],
            ),
            ...rows,
          ],
        ),
      ],
    );
  }

  static String _ageAt(
    WeightRecord record,
    PediatricReportData data,
    AppLocalizations l10n,
  ) {
    final age = BabyAgeCalendar.monthsAndDaysAt(
      data.baby.birthDate,
      record.dateTime,
    );
    return age.months > 0
        ? l10n.reportAgeMonthsDays(age.months, age.days)
        : l10n.reportAgeDays(age.days);
  }

  static String _changeText(WeightRecord record, WeightRecord? previous) {
    if (previous == null) return '-';
    final grams = ((record.weightKg - previous.weightKg) * 1000).round();
    if (grams == 0) return '0 g';
    return grams > 0 ? '+$grams g' : '-${grams.abs()} g';
  }

  static pw.Widget _tableCell(
    String text, {
    bool header = false,
    bool accent = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: header ? 8 : 9,
          fontWeight: header || accent
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          color: header
              ? _textLight
              : accent
              ? _accent
              : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _statsBox({
    required String title,
    required List<pw.Widget> children,
    bool accent = false,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: accent ? _accent : _boxBorder,
          width: accent ? 1 : 0.8,
        ),
        borderRadius: pw.BorderRadius.circular(8),
        color: accent ? _accentFill : null,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [_sectionTitle(title), pw.SizedBox(height: 6), ...children],
      ),
    );
  }

  static pw.Widget _statLine(String label, String value, {bool muted = false}) {
    final color = muted ? PdfColors.grey500 : null;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                color: muted ? PdfColors.grey500 : _textLight,
              ),
            ),
          ),
          if (value.isNotEmpty) ...[
            pw.SizedBox(width: 8),
            pw.Flexible(
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _coverageWarningLine(AppLocalizations l10n) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        l10n.reportCoverageLowWarning,
        style: pw.TextStyle(
          fontSize: 7.5,
          color: PdfColors.grey500,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  static pw.Widget _noDataLine(AppLocalizations l10n) {
    return pw.Text(
      l10n.reportNoData,
      style: const pw.TextStyle(fontSize: 9, color: _textLight),
    );
  }

  static String _formatPercentChange(int? pct, AppLocalizations l10n) {
    if (pct == null) return l10n.reportComparisonNoData;
    if (pct == 0) return '0%';
    return pct > 0 ? '+$pct%' : '$pct%';
  }

  static String _formatGramsPerDay(double grams) {
    final rounded = grams.round();
    if (rounded == 0) return '0 g/d';
    return rounded > 0 ? '+$rounded g/d' : '$rounded g/d';
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: _textLight,
        letterSpacing: 0.6,
      ),
    );
  }

  static pw.Widget _footer(
    pw.Context ctx,
    PediatricReportData data,
    AppLocalizations l10n,
    DateFormat dateFormat,
  ) {
    final isLastPage = ctx.pageNumber == ctx.pagesCount;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (isLastPage) ...[
          pw.Text(
            _winAnsiSafe(l10n.reportLegalDisclaimer),
            style: const pw.TextStyle(fontSize: 6.5, color: _textLight),
          ),
          pw.SizedBox(height: 3),
        ],
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              l10n.reportGeneratedWith(dateFormat.format(data.generatedAt)),
              style: const pw.TextStyle(fontSize: 7, color: _textLight),
            ),
            pw.Text(
              '${ctx.pageNumber} / ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: _textLight),
            ),
          ],
        ),
      ],
    );
  }
}
