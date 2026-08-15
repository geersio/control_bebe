import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/percentiles_data.dart';
import '../../../core/who_lms.dart';

/// Punto de medición del bebé en la gráfica OMS (edad en meses, valor).
class WhoChartPoint {
  final double ageMonths;
  final double value;

  const WhoChartPoint({required this.ageMonths, required this.value});
}

/// Gráfica PDF de crecimiento OMS con bandas, etiquetas al final y
/// última medición destacada. Sirve para peso (kg) o talla (cm).
class WhoGrowthChartPdf {
  WhoGrowthChartPdf._();

  static const PdfColor _grid = PdfColor.fromInt(0xFFE8E8E8);
  static const PdfColor _axis = PdfColor.fromInt(0xFF9E9E9E);
  // Tonos opacos legibles en color y en escala de grises al imprimir.
  static const PdfColor _bandOuter = PdfColor.fromInt(0xFFF0F3F5); // P3–P97
  static const PdfColor _bandInner = PdfColor.fromInt(0xFFE0E7EC); // P15–P85
  static const PdfColor _curveSoft = PdfColor.fromInt(0xFF757575);
  static const PdfColor _curveMedian = PdfColor.fromInt(0xFF424242);
  static const PdfColor _label = PdfColor.fromInt(0xFF616161);

  static const double _chartHeight = 220;
  static const double _leftPad = 28;
  static const double _rightPad = 30;
  static const double _bottomPad = 22;
  static const double _topPad = 10;
  static const double _labelMinGap = 12;

  /// [curveAt] debe devolver el valor OMS para un percentil y edad en meses.
  static pw.Widget build({
    required double ageNowMonths,
    required List<WhoChartPoint> babyPoints,
    required double Function(WeightPercentile percentile, double ageMonths)
        curveAt,
    required String Function(double value) formatValue,
    required String valueUnit,
    required PdfColor accent,
  }) {
    final xMax = math.max(6, (ageNowMonths + 2).ceil()).toDouble();
    final curveXMax = math.min(xMax, WhoLms.maxAgeMonths);

    final samples = _sampleAges(curveXMax);
    final p3 = [for (final a in samples) curveAt(WeightPercentile.p3, a)];
    final p15 = [for (final a in samples) curveAt(WeightPercentile.p15, a)];
    final p50 = [for (final a in samples) curveAt(WeightPercentile.p50, a)];
    final p85 = [for (final a in samples) curveAt(WeightPercentile.p85, a)];
    final p97 = [for (final a in samples) curveAt(WeightPercentile.p97, a)];

    var yMin = p3.reduce(math.min);
    var yMax = p97.reduce(math.max);
    for (final p in babyPoints) {
      yMin = math.min(yMin, p.value);
      yMax = math.max(yMax, p.value);
    }
    final span = math.max(yMax - yMin, 0.2);
    yMin = math.max(0, yMin - span * 0.05);
    yMax = yMax + span * 0.05;

    // Evitar tipografías Unicode: unidad ASCII.
    final lastLabel = babyPoints.isEmpty
        ? null
        : '${formatValue(babyPoints.last.value)} $valueUnit';

    return pw.LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints?.maxWidth ?? 500;
        final font = pw.Font.helvetica().getFont(context);
        final fontBold = pw.Font.helveticaBold().getFont(context);
        return pw.SizedBox(
          width: width,
          height: _chartHeight,
          child: pw.CustomPaint(
            size: PdfPoint(width, _chartHeight),
            painter: (canvas, size) => _paint(
              canvas: canvas,
              size: size,
              font: font,
              fontBold: fontBold,
              xMax: xMax,
              curveXMax: curveXMax,
              yMin: yMin,
              yMax: yMax,
              samples: samples,
              p3: p3,
              p15: p15,
              p50: p50,
              p85: p85,
              p97: p97,
              babyPoints: babyPoints,
              lastLabel: lastLabel,
              accent: accent,
            ),
          ),
        );
      },
    );
  }

  static List<double> _sampleAges(double curveXMax) {
    final out = <double>[];
    const step = 0.25;
    for (var a = 0.0; a <= curveXMax + 1e-9; a += step) {
      out.add(double.parse(a.toStringAsFixed(2)));
    }
    if (out.isEmpty || (out.last - curveXMax).abs() > 1e-6) {
      out.add(curveXMax);
    }
    return out;
  }

  static double _textWidth(PdfFont font, double size, String text) =>
      font.stringMetrics(text).width * size / 1000;

  static void _paint({
    required PdfGraphics canvas,
    required PdfPoint size,
    required PdfFont font,
    required PdfFont fontBold,
    required double xMax,
    required double curveXMax,
    required double yMin,
    required double yMax,
    required List<double> samples,
    required List<double> p3,
    required List<double> p15,
    required List<double> p50,
    required List<double> p85,
    required List<double> p97,
    required List<WhoChartPoint> babyPoints,
    required String? lastLabel,
    required PdfColor accent,
  }) {
    final plotW = size.x - _leftPad - _rightPad;
    final plotH = size.y - _topPad - _bottomPad;

    double px(double age) => _leftPad + (age / xMax) * plotW;
    double py(double value) {
      final t = (value - yMin) / (yMax - yMin);
      return _bottomPad + t.clamp(0.0, 1.0) * plotH;
    }

    // Rejilla horizontal suave
    final yTicks = _axisTicks(yMin, yMax, targetCount: 5);
    canvas
      ..setStrokeColor(_grid)
      ..setLineWidth(0.5)
      ..setLineDashPattern();
    for (final y in yTicks) {
      final yy = py(y);
      canvas.drawLine(_leftPad, yy, _leftPad + plotW, yy);
      canvas.strokePath();
    }

    // Rejilla vertical
    final xStep = xMax <= 8 ? 1.0 : (xMax <= 14 ? 2.0 : 3.0);
    for (var x = 0.0; x <= xMax + 1e-9; x += xStep) {
      final xx = px(x);
      canvas.drawLine(xx, _bottomPad, xx, _bottomPad + plotH);
      canvas.strokePath();
    }

    // Bandas
    _fillBand(canvas, samples, p3, p97, px, py, _bandOuter);
    _fillBand(canvas, samples, p15, p85, px, py, _bandInner);

    // Curvas de referencia
    _strokeCurve(canvas, samples, p15, px, py, _curveSoft, 0.6, dashed: false);
    _strokeCurve(canvas, samples, p85, px, py, _curveSoft, 0.6, dashed: false);
    _strokeCurve(canvas, samples, p50, px, py, _curveMedian, 1.4, dashed: false);
    _strokeCurve(canvas, samples, p3, px, py, _curveSoft, 0.8, dashed: true);
    _strokeCurve(canvas, samples, p97, px, py, _curveSoft, 0.8, dashed: true);

    // Curva del bebé
    if (babyPoints.isNotEmpty) {
      canvas
        ..setStrokeColor(accent)
        ..setFillColor(accent)
        ..setLineWidth(2.0)
        ..setLineDashPattern();
      if (babyPoints.length > 1) {
        canvas.moveTo(px(babyPoints.first.ageMonths), py(babyPoints.first.value));
        for (var i = 1; i < babyPoints.length; i++) {
          canvas.lineTo(px(babyPoints[i].ageMonths), py(babyPoints[i].value));
        }
        canvas.strokePath();
      }
      for (var i = 0; i < babyPoints.length; i++) {
        final p = babyPoints[i];
        final isLast = i == babyPoints.length - 1;
        final r = isLast ? 3.2 : 2.0;
        canvas.drawEllipse(px(p.ageMonths), py(p.value), r, r);
        canvas.fillPath();
        if (isLast) {
          canvas
            ..setStrokeColor(accent)
            ..setLineWidth(1.0)
            ..drawEllipse(px(p.ageMonths), py(p.value), r + 2.2, r + 2.2)
            ..strokePath();
        }
      }

      if (lastLabel != null) {
        final last = babyPoints.last;
        final lx = px(last.ageMonths);
        final ly = py(last.value);
        final textW = _textWidth(fontBold, 7, lastLabel);
        // Preferir etiqueta a la izquierda del punto.
        var tx = lx - textW - 8;
        if (tx < _leftPad) tx = lx + 8;
        final ty = ly + 8;
        canvas
          ..setFillColor(accent)
          ..drawString(fontBold, 7, lastLabel, tx, ty);
      }
    }

    // Ejes
    canvas
      ..setStrokeColor(_axis)
      ..setLineWidth(0.8)
      ..setLineDashPattern()
      ..drawLine(_leftPad, _bottomPad, _leftPad + plotW, _bottomPad)
      ..strokePath()
      ..drawLine(_leftPad, _bottomPad, _leftPad, _bottomPad + plotH)
      ..strokePath();

    // Etiquetas eje X
    canvas.setFillColor(_label);
    for (var x = 0.0; x <= xMax + 1e-9; x += xStep) {
      final label = x.round().toString();
      final tw = _textWidth(font, 7, label);
      canvas.drawString(font, 7, label, px(x) - tw / 2, 6);
    }

    // Etiquetas eje Y
    for (final y in yTicks) {
      final label = y >= 10 || y == y.roundToDouble()
          ? y.round().toString()
          : y.toStringAsFixed(1);
      final tw = _textWidth(font, 7, label);
      canvas.drawString(font, 7, label, _leftPad - tw - 4, py(y) - 2);
    }

    // Etiquetas P3…P97 al borde derecho, con anticolisión
    final rawLabels = <({String text, double y})>[
      (text: 'P3', y: p3.last),
      (text: 'P15', y: p15.last),
      (text: 'P50', y: p50.last),
      (text: 'P85', y: p85.last),
      (text: 'P97', y: p97.last),
    ];
    final placed = _resolveLabelYs(
      rawLabels.map((e) => (text: e.text, py: py(e.y))).toList(),
      minY: _bottomPad,
      maxY: _bottomPad + plotH,
    );
    final labelX = _leftPad + plotW + 3;
    for (final item in placed) {
      canvas.drawString(font, 6.5, item.text, labelX, item.py - 2);
    }
  }

  static List<({String text, double py})> _resolveLabelYs(
    List<({String text, double py})> items, {
    required double minY,
    required double maxY,
  }) {
    final sorted = List<({String text, double py})>.from(items)
      ..sort((a, b) => a.py.compareTo(b.py));
    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1].py;
      if (sorted[i].py - prev < _labelMinGap) {
        sorted[i] = (text: sorted[i].text, py: prev + _labelMinGap);
      }
    }
    // Si se salen por arriba, empujar hacia abajo manteniendo orden.
    if (sorted.isNotEmpty && sorted.last.py > maxY) {
      var overflow = sorted.last.py - maxY;
      for (var i = 0; i < sorted.length; i++) {
        sorted[i] = (text: sorted[i].text, py: sorted[i].py - overflow);
      }
    }
    for (var i = 0; i < sorted.length; i++) {
      if (sorted[i].py < minY) {
        sorted[i] = (text: sorted[i].text, py: minY);
      }
    }
    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1].py;
      if (sorted[i].py - prev < _labelMinGap) {
        sorted[i] = (text: sorted[i].text, py: prev + _labelMinGap);
      }
    }
    return sorted;
  }

  static List<double> _axisTicks(
    double min,
    double max, {
    required int targetCount,
  }) {
    final span = max - min;
    if (span <= 0) return [min];
    final raw = span / targetCount;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final residual = raw / mag;
    final step = residual <= 1
        ? mag
        : residual <= 2
            ? 2 * mag
            : residual <= 5
                ? 5 * mag
                : 10 * mag;
    final start = (min / step).ceil() * step;
    final ticks = <double>[];
    for (var v = start; v <= max + step * 1e-9; v += step) {
      ticks.add(double.parse(v.toStringAsFixed(4)));
    }
    if (ticks.isEmpty) ticks.add(min);
    return ticks;
  }

  static void _fillBand(
    PdfGraphics canvas,
    List<double> ages,
    List<double> low,
    List<double> high,
    double Function(double) px,
    double Function(double) py,
    PdfColor color,
  ) {
    if (ages.length < 2) return;
    canvas
      ..setFillColor(color)
      ..moveTo(px(ages.first), py(low.first));
    for (var i = 1; i < ages.length; i++) {
      canvas.lineTo(px(ages[i]), py(low[i]));
    }
    for (var i = ages.length - 1; i >= 0; i--) {
      canvas.lineTo(px(ages[i]), py(high[i]));
    }
    canvas
      ..closePath()
      ..fillPath();
  }

  static void _strokeCurve(
    PdfGraphics canvas,
    List<double> ages,
    List<double> values,
    double Function(double) px,
    double Function(double) py,
    PdfColor color,
    double width, {
    required bool dashed,
  }) {
    if (ages.length < 2) return;
    canvas
      ..setStrokeColor(color)
      ..setLineWidth(width)
      ..setLineDashPattern(dashed ? const <num>[3, 2] : const <num>[]);
    canvas.moveTo(px(ages.first), py(values.first));
    for (var i = 1; i < ages.length; i++) {
      canvas.lineTo(px(ages[i]), py(values[i]));
    }
    canvas.strokePath();
    canvas.setLineDashPattern();
  }
}
