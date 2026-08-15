import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/baby_profile.dart';
import '../../../core/theme/app_theme.dart';
import 'height_evolution_chart_card.dart';
import 'weight_evolution_chart_card.dart';

enum GrowthChartMetric { weight, height }

final growthChartMetricProvider =
    AsyncNotifierProvider<GrowthChartMetricNotifier, GrowthChartMetric>(
      GrowthChartMetricNotifier.new,
    );

class GrowthChartMetricNotifier extends AsyncNotifier<GrowthChartMetric> {
  static const _kMetric = 'growth_chart_metric';

  @override
  Future<GrowthChartMetric> build() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kMetric);
    if (raw == null) return GrowthChartMetric.weight;
    try {
      return GrowthChartMetric.values.byName(raw);
    } catch (_) {
      return GrowthChartMetric.weight;
    }
  }

  Future<void> setMetric(GrowthChartMetric metric) async {
    final current = await future;
    if (current == metric) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kMetric, metric.name);
    state = AsyncData(metric);
  }
}

/// Una sola tarjeta OMS: selector Peso / Altura + gráfica correspondiente.
class GrowthEvolutionChartCard extends ConsumerWidget {
  final BabyProfile? baby;
  final bool isActive;

  const GrowthEvolutionChartCard({
    super.key,
    required this.baby,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final metric =
        ref.watch(growthChartMetricProvider).valueOrNull ??
        GrowthChartMetric.weight;

    final selector = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _GrowthMetricSegmented(
        value: metric,
        weightLabel: l10n.growthChartMetricWeight,
        heightLabel: l10n.growthChartMetricHeight,
        onChanged: (m) =>
            ref.read(growthChartMetricProvider.notifier).setMetric(m),
      ),
    );

    return switch (metric) {
      GrowthChartMetric.weight => WeightEvolutionChartCard(
        baby: baby,
        isActive: isActive,
        titleOverride: l10n.growthEvolution,
        belowTitle: selector,
      ),
      GrowthChartMetric.height => HeightEvolutionChartCard(
        baby: baby,
        isActive: isActive,
        titleOverride: l10n.growthEvolution,
        belowTitle: selector,
      ),
    };
  }
}

class _GrowthMetricSegmented extends StatelessWidget {
  final GrowthChartMetric value;
  final String weightLabel;
  final String heightLabel;
  final ValueChanged<GrowthChartMetric> onChanged;

  const _GrowthMetricSegmented({
    required this.value,
    required this.weightLabel,
    required this.heightLabel,
    required this.onChanged,
  });

  static const double _height = 36;
  static const double _trackPad = 3;
  static const double _labelHPad = 16;

  static const TextStyle _measureStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.15,
  );

  double _labelWidth(String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _measureStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width + _labelHPad * 2;
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.fieldRadius);
    final thumbRadius = BorderRadius.circular(AppTheme.fieldRadius - 3);
    final segmentW = [
      _labelWidth(weightLabel),
      _labelWidth(heightLabel),
    ].reduce((a, b) => a > b ? a : b);
    final isWeight = value == GrowthChartMetric.weight;
    final thumbLeft = isWeight ? 0.0 : segmentW;
    final accent = AppTheme.palettePrimary;
    final track = Color.lerp(AppTheme.fieldBackground, accent, 0.08)!;

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: _height,
        width: segmentW * 2 + _trackPad * 2,
        child: DecoratedBox(
          decoration: BoxDecoration(color: track, borderRadius: radius),
          child: Padding(
            padding: const EdgeInsets.all(_trackPad),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: thumbLeft,
                  top: 0,
                  bottom: 0,
                  width: segmentW,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: thumbRadius,
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final metric in GrowthChartMetric.values)
                      SizedBox(
                        width: segmentW,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: thumbRadius,
                            onTap: () {
                              if (metric == value) return;
                              HapticFeedback.selectionClick();
                              onChanged(metric);
                            },
                            child: Center(
                              child: Text(
                                metric == GrowthChartMetric.weight
                                    ? weightLabel
                                    : heightLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.15,
                                  color: metric == value
                                      ? Colors.white
                                      : AppTheme.textDark.withValues(
                                          alpha: 0.72,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
