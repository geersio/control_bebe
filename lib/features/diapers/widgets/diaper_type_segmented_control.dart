import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/history_highlight.dart';

/// Segmented Mojado / Sucio / Ambos (misma altura/iconos que los botones previos).
class DiaperTypeSegmentedControl extends StatelessWidget {
  final DiaperType value;
  final ValueChanged<DiaperType> onChanged;
  final String wetLabel;
  final String dirtyLabel;
  final String bothLabel;

  const DiaperTypeSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
    required this.wetLabel,
    required this.dirtyLabel,
    required this.bothLabel,
  });

  /// Aprox. padding 18 + icono 28 + gap 8 + texto (como `_TypeButton`).
  static const double _height = 86;
  static const double _trackPad = 4;

  static Color accentFor(DiaperType type) => diaperHistoryAccent(type);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.cardRadius);
    final thumbRadius = BorderRadius.circular(AppTheme.cardRadius - 4);
    final types = DiaperType.values;
    final index = types.indexOf(value);
    final thumb = accentFor(value);

    return SizedBox(
      height: _height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: radius,
          border: Border.all(color: AppTheme.fieldBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(_trackPad),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segmentW = constraints.maxWidth / types.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    left: index * segmentW,
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
                    children: [
                      for (final type in types)
                        Expanded(
                          child: _DiaperSegment(
                            type: type,
                            label: switch (type) {
                              DiaperType.wet => wetLabel,
                              DiaperType.dirty => dirtyLabel,
                              DiaperType.both => bothLabel,
                            },
                            selected: value == type,
                            radius: thumbRadius,
                            onTap: () {
                              if (value == type) return;
                              HapticFeedback.selectionClick();
                              onChanged(type);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DiaperSegment extends StatelessWidget {
  final DiaperType type;
  final String label;
  final bool selected;
  final BorderRadius radius;
  final VoidCallback onTap;

  const _DiaperSegment({
    required this.type,
    required this.label,
    required this.selected,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppTheme.textLight;
    final (icon, isFa) = switch (type) {
      DiaperType.wet => (Icons.water_drop, false),
      DiaperType.dirty => (FontAwesomeIcons.poo, true),
      DiaperType.both => (Icons.sync, false),
    };

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
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? Colors.white : AppTheme.textDark,
              height: 1.1,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                isFa
                    ? FaIcon(icon, size: 28, color: color)
                    : Icon(icon, size: 28, color: color),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
