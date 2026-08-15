import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Fila compacta de tendencia diaria (g/día o cm/día) para las tarjetas de
/// evolución en Análisis.
class DailyGrowthTrendLine extends StatelessWidget {
  final String label;
  final String valueLabel;
  final bool positive;

  const DailyGrowthTrendLine({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive
        ? AppTheme.trendPositiveGreen
        : AppTheme.trendNegativeRed;
    return Row(
      children: [
        Icon(
          positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label · ',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                TextSpan(
                  text: valueLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
