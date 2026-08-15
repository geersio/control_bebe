import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';

/// Segmented estilo Cupertino, con radios de la app ([AppTheme.fieldRadius]).
/// Ambas opciones comparten el mismo ancho (el del texto más largo).
class SleepTypeSegmentedControl extends StatelessWidget {
  final SleepType value;
  final ValueChanged<SleepType> onChanged;
  final String nightLabel;
  final String napLabel;

  const SleepTypeSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
    required this.nightLabel,
    required this.napLabel,
  });

  static const double _height = 42;
  static const double _trackPad = 3;
  static const double _labelHPad = 14;

  /// Estilo de medición (w600) para que el ancho no salte al seleccionar.
  static const TextStyle _measureStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.15,
  );

  static Color accentFor(SleepType type) => switch (type) {
    SleepType.night => AppTheme.sleepHistoryNightAccent,
    SleepType.nap => AppTheme.sleepHistoryNapAccent,
    SleepType.nightWaking => AppTheme.sleepHistoryNightWakingAccent,
  };

  double _labelWidth(String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _measureStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width + _labelHPad * 2;
  }

  TextStyle _labelStyle(SleepType segment, {required bool selected}) {
    final accent = accentFor(segment);
    if (selected) {
      return const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.15,
      );
    }
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: accent.withValues(alpha: 0.72),
      height: 1.15,
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.fieldRadius);
    final thumbRadius = BorderRadius.circular(AppTheme.fieldRadius - 3);
    final thumb = accentFor(value);
    final track = Color.lerp(
      AppTheme.fieldBackground,
      Color.lerp(
        AppTheme.sleepHistoryNightAccent,
        AppTheme.sleepHistoryNapAccent,
        0.5,
      )!,
      0.14,
    )!;

    final segmentW = [
      _labelWidth(nightLabel),
      _labelWidth(napLabel),
    ].reduce((a, b) => a > b ? a : b);
    final isNight = value == SleepType.night;
    final thumbLeft = isNight ? 0.0 : segmentW;

    return Center(
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
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  left: thumbLeft,
                  top: 0,
                  bottom: 0,
                  width: segmentW,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: thumb,
                      borderRadius: thumbRadius,
                      boxShadow: [
                        BoxShadow(
                          color: thumb.withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: segmentW,
                      child: _Segment(
                        label: nightLabel,
                        style: _labelStyle(
                          SleepType.night,
                          selected: isNight,
                        ),
                        radius: thumbRadius,
                        onTap: () {
                          if (value == SleepType.night) return;
                          HapticFeedback.selectionClick();
                          onChanged(SleepType.night);
                        },
                      ),
                    ),
                    SizedBox(
                      width: segmentW,
                      child: _Segment(
                        label: napLabel,
                        style: _labelStyle(SleepType.nap, selected: !isNight),
                        radius: thumbRadius,
                        onTap: () {
                          if (value == SleepType.nap) return;
                          HapticFeedback.selectionClick();
                          onChanged(SleepType.nap);
                        },
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

class _Segment extends StatelessWidget {
  final String label;
  final TextStyle style;
  final BorderRadius radius;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.style,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: Colors.black.withValues(alpha: 0.04),
        highlightColor: Colors.black.withValues(alpha: 0.03),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            style: style,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Icono tipográfico «zzz» para siesta (historial).
class SleepNapZzzIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SleepNapZzzIcon({super.key, this.size = 14, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      'zzz',
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        letterSpacing: -0.6,
        color: color,
        height: 1,
      ),
    );
  }
}
