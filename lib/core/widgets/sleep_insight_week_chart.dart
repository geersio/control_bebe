import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Gráfico de barras «últimos 7 días» para la media de sueño diario.
/// Estilo alineado con el mock (anchos, lavanda #B1A7E3, hoy a rayas).
///
/// Al pulsar una barra se muestra el detalle; al soltar se oculta.
class SleepInsightWeekChart extends StatefulWidget {
  static const double _chartHeight = 100;
  static const double _labelHeight = 24;

  /// Gris de cabecera / iniciales (mock ≈ #9CA6AE).
  static const Color _muted = Color(0xFF9CA6AE);

  /// Valor «media …» en negrita (mock ≈ #2F3439).
  static const Color _valueDark = Color(0xFF2F3439);

  /// Barras de días previos (mock #B1A7E3).
  static const Color pastBar = Color(0xFFB1A7E3);

  /// Relleno / borde de «hoy» (mock #685BCD).
  static const Color todayFill = Color(0xFF685BCD);

  /// Rayas claras de «hoy» (mock #897EDD).
  static const Color todayStripe = Color(0xFF897EDD);

  /// Etiqueta «hoy» (mock ≈ #493FA2).
  static const Color todayLabel = Color(0xFF493FA2);

  final List<int> daySeconds;
  final int averageSeconds;
  final List<String> dayLabels;

  /// Títulos largos para el popup (p. ej. «Lunes 28 jul», «Hoy»).
  final List<String> dayTitles;
  final String Function(int seconds) formatDuration;
  final String emptyDurationLabel;
  final String averageDurationLabel;
  final String headerTitle;
  final String averagePrefix;

  const SleepInsightWeekChart({
    super.key,
    required this.daySeconds,
    required this.averageSeconds,
    required this.dayLabels,
    required this.dayTitles,
    required this.formatDuration,
    required this.emptyDurationLabel,
    required this.averageDurationLabel,
    required this.headerTitle,
    required this.averagePrefix,
  }) : assert(daySeconds.length == 7),
       assert(dayLabels.length == 7),
       assert(dayTitles.length == 7);

  @override
  State<SleepInsightWeekChart> createState() => _SleepInsightWeekChartState();
}

class _SleepInsightWeekChartState extends State<SleepInsightWeekChart> {
  int? _selectedIndex;

  void _clearSelection() {
    if (_selectedIndex == null) return;
    setState(() => _selectedIndex = null);
  }

  void _onPointerDown(Offset local, Size size) {
    final index = _SleepWeekChartLayout.barIndexAt(local, size);
    if (index == null) {
      _clearSelection();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: SleepInsightWeekChart._muted,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      fontSize: 11,
      height: 1.2,
    );
    final avgPrefixStyle = headerStyle?.copyWith(
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
    );
    final avgValueStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: SleepInsightWeekChart._valueDark,
      fontWeight: FontWeight.w800,
      fontSize: 12,
      letterSpacing: 0,
      height: 1.2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(widget.headerTitle, style: headerStyle),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CustomPaint(
                  size: Size(18, 12),
                  painter: _LegendDashPainter(
                    color: SleepInsightWeekChart._muted,
                  ),
                ),
                const SizedBox(width: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${widget.averagePrefix} ',
                        style: avgPrefixStyle,
                      ),
                      TextSpan(
                        text: widget.averageDurationLabel,
                        style: avgValueStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height:
              SleepInsightWeekChart._chartHeight +
              SleepInsightWeekChart._labelHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final selected = _selectedIndex;
              return Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) =>
                    _onPointerDown(event.localPosition, size),
                onPointerUp: (_) => _clearSelection(),
                onPointerCancel: (_) => _clearSelection(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      painter: _SleepWeekChartPainter(
                        daySeconds: widget.daySeconds,
                        averageSeconds: widget.averageSeconds,
                        dayLabels: widget.dayLabels,
                        highlightedIndex: selected,
                        labelStyle: const TextStyle(
                          color: SleepInsightWeekChart._muted,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          height: 1,
                        ),
                        todayLabelStyle: const TextStyle(
                          color: SleepInsightWeekChart.todayLabel,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          height: 1,
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                    if (selected != null)
                      _BarInfoPopup(
                        anchor: _SleepWeekChartLayout.barTopCenter(
                          selected,
                          size,
                          widget.daySeconds[selected],
                          widget.averageSeconds,
                          widget.daySeconds,
                        ),
                        chartWidth: size.width,
                        title: widget.dayTitles[selected],
                        value: widget.daySeconds[selected] <= 0
                            ? widget.emptyDurationLabel
                            : widget.formatDuration(
                                widget.daySeconds[selected],
                              ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BarInfoPopup extends StatelessWidget {
  final Offset anchor;
  final double chartWidth;
  final String title;
  final String value;

  const _BarInfoPopup({
    required this.anchor,
    required this.chartWidth,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const bubbleWidth = 148.0;
    const gap = 8.0;
    final left = (anchor.dx - bubbleWidth / 2)
        .clamp(0.0, math.max(0.0, chartWidth - bubbleWidth))
        .toDouble();
    final top = math.max(0.0, anchor.dy - gap - 56);

    return Positioned(
      left: left,
      top: top,
      width: bubbleWidth,
      child: Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Geometría compartida entre pintura e interacción.
class _SleepWeekChartLayout {
  static const int n = 7;
  static const double labelBand = 24.0;
  static const double chartTop = 4.0;
  static const double barSlotRatio = 0.877;
  static const double barRadius = 8;
  static const double labelGap = 10;

  static double slotWidth(Size size) => size.width / n;

  static double barWidth(Size size) => slotWidth(size) * barSlotRatio;

  static double chartBottom(Size size) => size.height - labelBand;

  static double scaleMax(int averageSeconds, List<int> daySeconds) {
    final maxSeconds = math.max(
      averageSeconds,
      daySeconds.fold<int>(0, math.max),
    );
    return math.max(maxSeconds, 1).toDouble();
  }

  static double barHeight(
    int secs,
    Size size,
    int averageSeconds,
    List<int> daySeconds,
  ) {
    if (secs <= 0) return 0;
    final chartHeight = math.max(1.0, chartBottom(size) - chartTop);
    final scale = scaleMax(averageSeconds, daySeconds);
    return math.max(8.0, (secs / scale) * chartHeight);
  }

  static int? barIndexAt(Offset local, Size size) {
    if (local.dx < 0 || local.dx > size.width) return null;
    if (local.dy < 0 || local.dy > size.height) return null;
    final i = (local.dx / slotWidth(size)).floor();
    if (i < 0 || i >= n) return null;
    return i;
  }

  /// Punto superior central de la barra (o base del eje si no hay datos).
  static Offset barTopCenter(
    int index,
    Size size,
    int secs,
    int averageSeconds,
    List<int> daySeconds,
  ) {
    final cx = slotWidth(size) * (index + 0.5);
    final bottom = chartBottom(size);
    final h = barHeight(secs, size, averageSeconds, daySeconds);
    final top = h <= 0 ? bottom : bottom - h;
    return Offset(cx, top);
  }
}

/// Segmento corto de línea discontinua para la leyenda de la cabecera.
class _LegendDashPainter extends CustomPainter {
  final Color color;

  const _LegendDashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    final y = size.height / 2;
    const dash = 3.5;
    const gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      final end = math.min(x + dash, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _LegendDashPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SleepWeekChartPainter extends CustomPainter {
  final List<int> daySeconds;
  final int averageSeconds;
  final List<String> dayLabels;
  final int? highlightedIndex;
  final TextStyle labelStyle;
  final TextStyle todayLabelStyle;

  _SleepWeekChartPainter({
    required this.daySeconds,
    required this.averageSeconds,
    required this.dayLabels,
    required this.highlightedIndex,
    required this.labelStyle,
    required this.todayLabelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const n = _SleepWeekChartLayout.n;
    final chartBottom = _SleepWeekChartLayout.chartBottom(size);
    const chartTop = _SleepWeekChartLayout.chartTop;
    final chartHeight = math.max(1.0, chartBottom - chartTop);

    final scaleMax = _SleepWeekChartLayout.scaleMax(
      averageSeconds,
      daySeconds,
    );

    final slotWidth = _SleepWeekChartLayout.slotWidth(size);
    final barWidth = _SleepWeekChartLayout.barWidth(size);
    final avgY = chartBottom - (averageSeconds / scaleMax) * chartHeight;

    for (var i = 0; i < n; i++) {
      final secs = daySeconds[i];
      final cx = slotWidth * (i + 0.5);
      final left = cx - barWidth / 2;
      final isToday = i == n - 1;
      final barH = _SleepWeekChartLayout.barHeight(
        secs,
        size,
        averageSeconds,
        daySeconds,
      );
      if (barH <= 0) continue;

      final radius = math.min(_SleepWeekChartLayout.barRadius, barWidth / 2);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, chartBottom - barH, barWidth, barH),
        Radius.circular(radius),
      );

      if (isToday) {
        _paintTodayBar(canvas, rect);
      } else {
        canvas.drawRRect(
          rect,
          Paint()..color = SleepInsightWeekChart.pastBar,
        );
      }

      if (highlightedIndex == i) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // Solo la raya de media; el valor vive en la leyenda de cabecera.
    final dashPaint = Paint()
      ..color = SleepInsightWeekChart._muted.withValues(alpha: 0.85)
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(0, avgY),
      Offset(size.width, avgY),
      dashPaint,
      dash: 3.5,
      gap: 3.5,
    );

    for (var i = 0; i < n; i++) {
      final isToday = i == n - 1;
      final tp = TextPainter(
        text: TextSpan(
          text: dayLabels[i],
          style: isToday ? todayLabelStyle : labelStyle,
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: slotWidth);
      final cx = slotWidth * (i + 0.5);
      tp.paint(
        canvas,
        Offset(cx - tp.width / 2, chartBottom + _SleepWeekChartLayout.labelGap),
      );
    }
  }

  void _paintTodayBar(Canvas canvas, RRect rect) {
    canvas.save();
    canvas.clipRRect(rect);

    canvas.drawRRect(
      rect,
      Paint()..color = SleepInsightWeekChart.todayFill,
    );

    final stripe = Paint()
      ..color = SleepInsightWeekChart.todayStripe
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final bounds = rect.outerRect.inflate(12);
    const step = 8.0;
    for (var x = bounds.left - bounds.height; x < bounds.right + step; x += step) {
      canvas.drawLine(
        Offset(x, bounds.bottom),
        Offset(x + bounds.height, bounds.top),
        stripe,
      );
    }
    canvas.restore();

    canvas.drawRRect(
      rect,
      Paint()
        ..color = SleepInsightWeekChart.todayFill
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    final total = (b - a).distance;
    if (total <= 0) return;
    final direction = (b - a) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final start = a + direction * drawn;
      final end = a + direction * math.min(drawn + dash, total);
      canvas.drawLine(start, end, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _SleepWeekChartPainter oldDelegate) {
    return oldDelegate.daySeconds != daySeconds ||
        oldDelegate.averageSeconds != averageSeconds ||
        oldDelegate.dayLabels != dayLabels ||
        oldDelegate.highlightedIndex != highlightedIndex;
  }
}
