import 'dart:math' as math;

import 'package:control_bebe/l10n/app_date_locale.dart';
import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/baby_profile.dart';
import '../../../core/models/height_record.dart';
import '../../../core/percentiles_data.dart';
import '../../../core/providers/record_stream_providers.dart';
import '../../../core/providers/weight_chart_prefs_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/baby_age_calendar.dart';
import '../../../core/utils/height_daily_trend.dart';
import '../../../core/utils/measurement_display.dart';
import '../../../core/who_lms.dart';
import '../../../core/widgets/baby_insight_status_line.dart';
import '../../../core/widgets/home_card_title_row.dart';
import '../../../core/widgets/stream_record_load_error.dart';
import '../models/weight_chart_prefs.dart';
import 'daily_growth_trend_line.dart';

List<HeightRecord> _heightRecordsInChartRange(
  List<HeightRecord> records,
  WeightChartTimeRange range,
) {
  final days = range.trailingDays;
  if (days == null) return records;
  final cutoff = DateTime.now().subtract(Duration(days: days));
  return records.where((r) => !r.dateTime.isBefore(cutoff)).toList();
}

String _babyDisplayName(BabyProfile? baby, AppLocalizations l10n) {
  final raw = baby?.name.trim() ?? '';
  return raw.isEmpty ? l10n.profileDefaultBabyName : raw;
}

enum _PercentileStatusKind { at, above, below }

({String babyName, String percentileLabel, _PercentileStatusKind kind})?
_heightPercentileStatusParts({
  required AppLocalizations l10n,
  required BabyProfile? baby,
  required List<HeightRecord> records,
}) {
  if (baby == null || records.isEmpty) return null;

  final latest = records.first;
  final ageMonths = BabyAgeCalendar.fractionalMonthsAt(
    baby.birthDate,
    latest.dateTime,
  );
  final estimate = PercentilesData.estimateHeightPercentile(
    isMale: baby.isMale,
    ageInMonths: ageMonths,
    heightCm: latest.heightCm,
  );
  if (estimate == null) return null;

  final kind = estimate.isBelowTable
      ? _PercentileStatusKind.below
      : estimate.isAboveTable
      ? _PercentileStatusKind.above
      : _PercentileStatusKind.at;

  return (
    babyName: _babyDisplayName(baby, l10n),
    percentileLabel: estimate.shortLabel(),
    kind: kind,
  );
}

class _PercentileStatusLine extends StatelessWidget {
  final String babyName;
  final String percentileLabel;
  final _PercentileStatusKind kind;

  const _PercentileStatusLine({
    required this.babyName,
    required this.percentileLabel,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (before, after) = switch (kind) {
      _PercentileStatusKind.at => (
        l10n.weightChartPercentilePhraseBeforeAt,
        l10n.weightChartPercentilePhraseAfterAt,
      ),
      _PercentileStatusKind.above => (
        l10n.weightChartPercentilePhraseBeforeAbove,
        l10n.weightChartPercentilePhraseAfterAbove,
      ),
      _PercentileStatusKind.below => (
        l10n.weightChartPercentilePhraseBeforeBelow,
        l10n.weightChartPercentilePhraseAfterBelow,
      ),
    };
    return BabyInsightStatusLine(
      leadingEmphasis: babyName,
      connector: before,
      trailingEmphasis: percentileLabel,
      trailingConnector: after.isEmpty ? null : after,
    );
  }
}

class HeightEvolutionChartCard extends ConsumerWidget {
  final BabyProfile? baby;
  final bool isActive;

  /// Contenido bajo el título (p. ej. selector Peso/Altura unificado).
  final Widget? belowTitle;

  /// Si se indica, sustituye el título por defecto de la tarjeta.
  final String? titleOverride;

  const HeightEvolutionChartCard({
    super.key,
    required this.baby,
    this.isActive = true,
    this.belowTitle,
    this.titleOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final chartPrefs =
        ref.watch(heightChartPrefsProvider).valueOrNull ??
        HeightChartPrefs.defaults;
    final recordsAsync = isActive
        ? ref.watch(heightRecordsStreamProvider)
        : ref.read(heightRecordsStreamProvider);

    return recordsAsync.when(
      skipLoadingOnReload: true,
      data: (records) {
        final visible = records.toList();
        final chartRecords = _heightRecordsInChartRange(
          visible,
          chartPrefs.timeRange,
        );
        final hasEnoughRecordsForLine = chartRecords.length >= 2;
        final percentileStatus = _heightPercentileStatusParts(
          l10n: l10n,
          baby: baby,
          records: visible,
        );
        final dailyTrendCmPerDay = dailyHeightTrendLinearRegressionCmPerDay(
          visible,
        );
        return Material(
          color: AppTheme.cardBackground,
          elevation: AppTheme.cardElevation,
          shadowColor: Colors.black12,
          shape: AppTheme.homeCardShapeRounded,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeCardTitleRow(
                  title: (titleOverride ?? l10n.heightEvolution).toUpperCase(),
                  infoTooltip: l10n.weightChartInfoTitle,
                  onInfoPressed: () => _showHeightChartInfoSheet(context),
                ),
                ?belowTitle,
                if (percentileStatus != null) ...[
                  const SizedBox(height: HomeCardTitleRow.gapAfter),
                  _PercentileStatusLine(
                    babyName: percentileStatus.babyName,
                    percentileLabel: percentileStatus.percentileLabel,
                    kind: percentileStatus.kind,
                  ),
                ],
                if (dailyTrendCmPerDay != null) ...[
                  const SizedBox(height: HomeCardTitleRow.gapAfter),
                  DailyGrowthTrendLine(
                    label: l10n.weightTrendCard,
                    valueLabel: formatHeightTrendCmPerDay(
                      dailyTrendCmPerDay,
                      l10n,
                    ),
                    positive: dailyTrendCmPerDay >= 0,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChartFilterPill<WeightPercentile>(
                      prefix: l10n.weightChartPercentileSelector,
                      value: chartPrefs.percentile,
                      values: WeightPercentile.pickerValues,
                      labelOf: (p) => p.shortLabel,
                      onChanged: (p) => ref
                          .read(heightChartPrefsProvider.notifier)
                          .setPercentile(p),
                    ),
                    _ChartFilterPill<WeightChartTimeRange>(
                      prefix: l10n.weightChartRangeSelector,
                      value: chartPrefs.timeRange,
                      values: WeightChartTimeRange.pickerValues,
                      labelOf: (r) => r.label(l10n),
                      onChanged: (r) => ref
                          .read(heightChartPrefsProvider.notifier)
                          .setTimeRange(r),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: chartRecords.isEmpty
                      ? Center(
                          child: Text(
                            visible.isEmpty
                                ? l10n.heightChartEmpty
                                : l10n.heightChartNoDataInRange,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textLight),
                          ),
                        )
                      : !hasEnoughRecordsForLine
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Text(
                              l10n.heightChartNeedsMoreRecords(
                                _babyDisplayName(baby, l10n),
                              ),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textLight,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                            ),
                          ),
                        )
                      : _HeightChart(
                          records: chartRecords,
                          isMale: baby?.isMale,
                          birthDate: baby?.birthDate ?? DateTime.now(),
                          percentile: chartPrefs.percentile,
                        ),
                ),
                if (hasEnoughRecordsForLine) ...[
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ChartLegendSwatch(
                        color: AppTheme.textLight.withValues(alpha: 0.45),
                        label: l10n.heightChartCaption,
                      ),
                      const SizedBox(height: 8),
                      _ChartLegendSwatch(
                        color: AppTheme.heightHistoryAccent,
                        label: _babyDisplayName(baby, l10n),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => Material(
        color: AppTheme.cardBackground,
        elevation: AppTheme.cardElevation,
        shadowColor: Colors.black12,
        shape: AppTheme.homeCardShapeRounded,
        child: const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Material(
        color: AppTheme.cardBackground,
        elevation: AppTheme.cardElevation,
        shadowColor: Colors.black12,
        shape: AppTheme.homeCardShapeRounded,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamRecordLoadError(
            message: l10n.heightChartLoadError,
            onRetry: () => ref.invalidate(heightRecordsStreamProvider),
          ),
        ),
      ),
    );
  }
}

void _showHeightChartInfoSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.dialogRadius),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom:
                  MediaQuery.viewInsetsOf(sheetCtx).bottom +
                  AppTheme.extraBottomSpacing,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 24),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textLight.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    l10n.weightChartInfoTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    l10n.weightChartSource,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.cardRadius,
                        ),
                      ),
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: Text(
                      l10n.homeFeedingTrendInfoButton,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _HeightChart extends StatelessWidget {
  final List<HeightRecord> records;
  final bool? isMale;
  final DateTime birthDate;
  final WeightPercentile percentile;

  const _HeightChart({
    required this.records,
    required this.isMale,
    required this.birthDate,
    required this.percentile,
  });

  double _ageInMonths(DateTime date) {
    return BabyAgeCalendar.fractionalMonthsAt(birthDate, date);
  }

  static double _daysSince(DateTime origin, DateTime t) {
    return t.difference(origin).inMilliseconds / Duration.millisecondsPerDay;
  }

  static double _bottomTitleInterval(double maxX) {
    if (maxX <= 0.5) return 0.25;
    if (maxX <= 2) return 0.5;
    if (maxX <= 10) return 1;
    if (maxX <= 45) return 7;
    if (maxX <= 120) return 14;
    return math.max(7, maxX / 6);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateCode = dateFormatLanguageCode(context);
    if (records.isEmpty) {
      return Center(
        child: Text(
          l10n.heightChartEmpty,
          style: TextStyle(color: AppTheme.textLight),
        ),
      );
    }

    final sortedRecords = List<HeightRecord>.from(records)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final origin = sortedRecords.first.dateTime;
    final spots = sortedRecords
        .map((r) => FlSpot(_daysSince(origin, r.dateTime), r.heightCm))
        .toList();

    var xMax = spots.map((s) => s.x).reduce(math.max);
    if (xMax < 1e-9) xMax = 1e-6;

    final minHeight = records
        .map((r) => r.heightCm)
        .reduce((a, b) => a < b ? a : b);
    final maxHeight = records
        .map((r) => r.heightCm)
        .reduce((a, b) => a > b ? a : b);

    final minMonth = _ageInMonths(
      sortedRecords.first.dateTime,
    ).clamp(0.0, WhoLms.maxAgeMonths);
    final maxMonth = _ageInMonths(
      sortedRecords.last.dateTime,
    ).clamp(0.0, WhoLms.maxAgeMonths);
    final refMinCm = PercentilesData.getPercentileHeightCm(
      isMale,
      percentile,
      minMonth,
    );
    final refMaxCm = PercentilesData.getPercentileHeightCm(
      isMale,
      percentile,
      maxMonth,
    );
    final refLow = refMinCm < refMaxCm ? refMinCm : refMaxCm;
    final refHigh = refMinCm > refMaxCm ? refMinCm : refMaxCm;

    final dataMinY = minHeight < refLow ? minHeight : refLow;
    final dataMaxY = maxHeight > refHigh ? maxHeight : refHigh;
    var minY = (dataMinY - 2).clamp(35.0, 100.0);
    var maxY = (dataMaxY + 2).clamp(35.0, 100.0);
    if (maxY <= minY) {
      maxY = (minY + 4).clamp(35.0, 110.0);
      if (maxY <= minY) minY = math.max(35.0, maxY - 4);
    }

    final refSpots = sortedRecords.map((r) {
      final age = _ageInMonths(r.dateTime);
      return FlSpot(
        _daysSince(origin, r.dateTime),
        PercentilesData.getPercentileHeightCm(isMale, percentile, age),
      );
    }).toList();

    final bottomInterval = _bottomTitleInterval(xMax);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: xMax,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(color: AppTheme.textLight, fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: bottomInterval,
              getTitlesWidget: (value, meta) {
                if (value < -1e-6 || value > xMax + 1e-6) {
                  return const SizedBox.shrink();
                }
                final labelDate = origin.add(
                  Duration(
                    milliseconds: (value * Duration.millisecondsPerDay).round(),
                  ),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('d/M', dateCode).format(labelDate),
                    style: TextStyle(color: AppTheme.textLight, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          if (refSpots.length > 1)
            LineChartBarData(
              spots: refSpots,
              isCurved: true,
              color: AppTheme.textLight.withValues(alpha: 0.45),
              barWidth: 1.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.heightHistoryAccent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 2,
                    color: AppTheme.heightHistoryAccent,
                    strokeWidth: 0,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.heightHistoryAccent.withValues(alpha: 0.14),
                  AppTheme.heightHistoryAccent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            maxContentWidth: 240,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            tooltipRoundedRadius: 12,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (_) => Colors.white,
            tooltipBorder: BorderSide(
              color: Colors.black.withValues(alpha: 0.12),
            ),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              if (touchedSpots.isEmpty) return [];

              final x = touchedSpots.first.x;
              final touchedDate = origin.add(
                Duration(
                  milliseconds: (x * Duration.millisecondsPerDay).round(),
                ),
              );
              final dateStr = DateFormat(
                'd MMM yyyy, HH:mm',
                dateCode,
              ).format(touchedDate);

              final hasRef = refSpots.length > 1;
              final dataBarIndex = hasRef ? 1 : 0;

              double? dataCm;
              for (final s in touchedSpots) {
                if (s.barIndex == dataBarIndex) dataCm = s.y;
              }

              final age = BabyAgeCalendar.monthsAndDaysAt(
                birthDate,
                touchedDate,
              );
              final ageStr = age.months > 0
                  ? l10n.reportAgeMonthsDays(age.months, age.days)
                  : l10n.reportAgeDays(age.days);

              final lines = <String>[dateStr, l10n.weightTooltipAge(ageStr)];
              if (dataCm != null) {
                lines.add(
                  l10n.heightTooltipMeasure(formatHeightFromCm(dataCm, l10n)),
                );
                final estimate = PercentilesData.estimateHeightPercentile(
                  isMale: isMale,
                  ageInMonths: _ageInMonths(touchedDate),
                  heightCm: dataCm,
                );
                if (estimate != null) {
                  lines.add(
                    l10n.heightTooltipBabyPercentile(estimate.shortLabel()),
                  );
                }
              }

              const tipStyle = TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.4,
              );
              final text = lines.join('\n');

              return touchedSpots.asMap().entries.map((e) {
                if (e.key == 0) {
                  return LineTooltipItem(
                    text,
                    tipStyle,
                    textAlign: TextAlign.left,
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 250),
    );
  }
}

class _ChartLegendSwatch extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendSwatch({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textLight,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ChartFilterPill<T> extends StatelessWidget {
  final String prefix;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const _ChartFilterPill({
    required this.prefix,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final valueLabel = labelOf(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.fieldBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.cardOutline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(16),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppTheme.textLight,
          ),
          selectedItemBuilder: (context) => values
              .map((_) => _FilterPillLabel(prefix: prefix, value: valueLabel))
              .toList(),
          items: values
              .map(
                (v) => DropdownMenuItem<T>(value: v, child: Text(labelOf(v))),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _FilterPillLabel extends StatelessWidget {
  final String prefix;
  final String value;

  const _FilterPillLabel({required this.prefix, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.textLight,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        children: [
          TextSpan(text: '$prefix '),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
