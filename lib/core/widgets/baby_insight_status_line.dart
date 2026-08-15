import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Línea de estado tipo «{nombre} está…» compartida por insights del home
/// (alimentación, percentiles de peso/altura).
class BabyInsightStatusLine extends StatelessWidget {
  /// Parte en negrita al inicio (nombre del bebé).
  final String leadingEmphasis;

  /// Texto conector (p. ej. « está comiendo lo habitual a esta hora»).
  final String connector;

  /// Segunda parte en negrita opcional (p. ej. «P50»).
  final String? trailingEmphasis;

  /// Cola tras [trailingEmphasis] (p. ej. « percentile» en EN).
  final String? trailingConnector;

  const BabyInsightStatusLine({
    super.key,
    required this.leadingEmphasis,
    required this.connector,
    this.trailingEmphasis,
    this.trailingConnector,
  });

  @override
  Widget build(BuildContext context) {
    final sizeStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(height: 1.25);
    final connectorStyle = sizeStyle?.copyWith(
      color: AppTheme.primaryBlue,
      fontWeight: FontWeight.w500,
    );
    final emphasisStyle = sizeStyle?.copyWith(
      color: AppTheme.primaryBlue,
      fontWeight: FontWeight.w800,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: leadingEmphasis, style: emphasisStyle),
          TextSpan(text: connector, style: connectorStyle),
          if (trailingEmphasis != null)
            TextSpan(text: trailingEmphasis, style: emphasisStyle),
          if (trailingConnector != null && trailingConnector!.isNotEmpty)
            TextSpan(text: trailingConnector, style: connectorStyle),
        ],
      ),
    );
  }
}
