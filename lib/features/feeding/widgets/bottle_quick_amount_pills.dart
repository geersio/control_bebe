import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../core/models/measurement_units.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/measurement_display.dart';

/// Píldoras de cantidad rápida para el formulario de biberón.
class BottleQuickAmountPills extends StatelessWidget {
  const BottleQuickAmountPills({
    super.key,
    required this.prefs,
    required this.amountsMl,
    this.selectedAmountMl,
    required this.addLabel,
    required this.onAmountTap,
    required this.onAddTap,
    required this.onRemoveAmount,
  });

  final MeasurementPrefs prefs;
  final List<int> amountsMl;
  final int? selectedAmountMl;
  final String addLabel;
  final ValueChanged<int> onAmountTap;
  final VoidCallback onAddTap;
  final Future<void> Function(int ml) onRemoveAmount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final ml in amountsMl)
          _AmountPill(
            label: formatVolumeShort(ml, prefs, l10n),
            selected: selectedAmountMl == ml,
            onTap: () => onAmountTap(ml),
            onLongPress: () => _confirmRemove(context, ml, l10n),
          ),
        _AddAmountPill(label: addLabel, onTap: onAddTap),
      ],
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    int ml,
    AppLocalizations l10n,
  ) async {
    final label = formatVolumeShort(ml, prefs, l10n);
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.bottleQuickAmountRemoveTitle),
        content: Text(l10n.bottleQuickAmountRemoveMessage(label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (remove == true) {
      await onRemoveAmount(ml);
    }
  }
}

class _AmountPill extends StatelessWidget {
  const _AmountPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.softPrimaryFill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppTheme.palettePrimary
                  : AppTheme.cardOutline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.palettePrimary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Atajo «Añadir»: sin relleno y borde discontinuo.
class _AddAmountPill extends StatelessWidget {
  const _AddAmountPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: CustomPaint(
          painter: _DashedPillBorderPainter(
            color: AppTheme.palettePrimary.withValues(alpha: 0.55),
            strokeWidth: 1.5,
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.palettePrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedPillBorderPainter extends CustomPainter {
  const _DashedPillBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashLength = 7,
    this.gapLength = 4,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  static const _radius = 999.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(_radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final segment = draw ? dashLength : gapLength;
        final end = (distance + segment).clamp(0.0, metric.length);
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, end), paint);
        }
        distance = end;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPillBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength;
}
