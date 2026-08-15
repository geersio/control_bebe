import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/sleep_record.dart';
import '../utils/sleep_day_timeline.dart';

/// Barra 00–24 del día: nocturno / siesta (colores de historial) y huecos
/// en despertares. Si hay sesión abierta, se alarga en vivo.
class SleepInsightDayTimeline extends StatefulWidget {
  final List<SleepRecord> records;
  final String todayLabel;
  final String Function(int totalSeconds) formatTotal;

  const SleepInsightDayTimeline({
    super.key,
    required this.records,
    required this.todayLabel,
    required this.formatTotal,
  });

  @override
  State<SleepInsightDayTimeline> createState() =>
      _SleepInsightDayTimelineState();
}

class _SleepInsightDayTimelineState extends State<SleepInsightDayTimeline>
    with WidgetsBindingObserver {
  Timer? _tickTimer;

  bool get _hasOpenSession =>
      widget.records.any((r) => r.isOpen && r.isSleepBlock);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant SleepInsightDayTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records) {
      _syncTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncTimer();
      if (mounted) setState(() {});
    }
  }

  void _syncTimer() {
    _tickTimer?.cancel();
    _tickTimer = null;
    if (!_hasOpenSession) return;
    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final segments = buildSleepDayTimelineSegments(
      records: widget.records,
      now: now,
    );
    final totalSeconds = sleepSecondsToday(widget.records, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.todayLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
            Text(
              widget.formatTotal(totalSeconds),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 12,
          width: double.infinity,
          child: CustomPaint(
            painter: _SleepDayTimelinePainter(segments: segments),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final label in const ['00', '06', '12', '18', '24'])
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SleepDayTimelinePainter extends CustomPainter {
  final List<SleepDayTimelineSegment> segments;

  _SleepDayTimelinePainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(
      track,
      Paint()..color = AppTheme.sleepPurpleSoft.withValues(alpha: 0.85),
    );

    canvas.save();
    canvas.clipRRect(track);

    for (final seg in segments) {
      final left = seg.start * size.width;
      final right = seg.end * size.width;
      if (right - left < 0.5) continue;
      final color = (seg.isNight
              ? AppTheme.sleepHistoryNightAccent
              : AppTheme.sleepHistoryNapAccent)
          .withValues(alpha: 0.4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, 0, right, size.height),
          Radius.circular(size.height / 2),
        ),
        Paint()..color = color,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SleepDayTimelinePainter oldDelegate) =>
      oldDelegate.segments != segments;
}
