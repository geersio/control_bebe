import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:control_bebe/l10n/app_time_format.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/inline_confirming_button.dart';

/// Tarjeta live de sesión: despierto ↔ durmiendo.
class SleepLiveSessionCard extends StatefulWidget {
  /// Sesión abierta (durmiendo). `null` = despierto.
  final DateTime? sleepingSince;

  /// Último despertar (fin del último sueño cerrado). Si es `null` y está
  /// despierto, se usa [fallbackAwakeSince].
  final DateTime? awakeSince;

  /// Ancla local cuando no hay historial de despertar.
  final DateTime fallbackAwakeSince;

  final Future<bool> Function() onFellAsleep;
  final Future<bool> Function() onWokeUp;
  final ValueChanged<DateTime> onEditAnchorTime;
  final VoidCallback? onSavedVisible;

  const SleepLiveSessionCard({
    super.key,
    required this.sleepingSince,
    required this.awakeSince,
    required this.fallbackAwakeSince,
    required this.onFellAsleep,
    required this.onWokeUp,
    required this.onEditAnchorTime,
    this.onSavedVisible,
  });

  @override
  State<SleepLiveSessionCard> createState() => _SleepLiveSessionCardState();
}

class _SleepLiveSessionCardState extends State<SleepLiveSessionCard>
    with SingleTickerProviderStateMixin {
  Timer? _tick;
  late DateTime _now;
  late final AnimationController _theme;
  late final CurvedAnimation _nightCurve;

  bool get _isSleeping => widget.sleepingSince != null;

  DateTime get _anchor {
    if (_isSleeping) return widget.sleepingSince!;
    return widget.awakeSince ?? widget.fallbackAwakeSince;
  }

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _theme = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
      value: _isSleeping ? 1 : 0,
    );
    _nightCurve = CurvedAnimation(parent: _theme, curve: Curves.easeInOutCubic);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void didUpdateWidget(covariant SleepLiveSessionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasSleeping = oldWidget.sleepingSince != null;
    if (wasSleeping == _isSleeping) return;
    if (_isSleeping) {
      _theme.forward();
    } else {
      _theme.reverse();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _nightCurve.dispose();
    _theme.dispose();
    super.dispose();
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _pickAnchorTime() async {
    final l10n = AppLocalizations.of(context)!;
    final initial = TimeOfDay.fromDateTime(_anchor);
    final TimeOfDay? picked;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      picked = await _showCupertinoTimePicker(context, initial, l10n);
    } else {
      picked = await showTimePicker(context: context, initialTime: initial);
    }
    if (!mounted || picked == null) return;

    var at = DateTime(
      _now.year,
      _now.month,
      _now.day,
      picked.hour,
      picked.minute,
    );
    if (at.isAfter(_now.add(const Duration(minutes: 1)))) {
      at = at.subtract(const Duration(days: 1));
    }
    if (_now.difference(at) > const Duration(hours: 18)) {
      at = at.add(const Duration(days: 1));
      if (at.isAfter(_now)) {
        at = at.subtract(const Duration(days: 1));
      }
    }
    HapticFeedback.selectionClick();
    widget.onEditAnchorTime(at);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final elapsed = _now.difference(_anchor);
    final elapsedMinutes = elapsed.isNegative ? 0 : elapsed.inMinutes;
    final durationLabel = formatMinutesLocalized(l10n, elapsedMinutes);
    final anchorTime = _fmtTime(_anchor);
    final nowTime = _fmtTime(_now);

    final statusLabel =
        _isSleeping ? l10n.sleepStatusSleeping : l10n.sleepStatusAwake;
    final eventLine = _isSleeping
        ? l10n.sleepFellAsleepAt(anchorTime)
        : l10n.sleepWokeUpAt(anchorTime);
    final actionLabel =
        _isSleeping ? l10n.sleepActionWokeUp : l10n.sleepActionFellAsleep;
    final actionEmoji = _isSleeping ? '☀️' : '🌙';
    final buttonBg =
        _isSleeping ? AppTheme.sleepLiveWakeButton : Colors.white;
    final buttonFg = AppTheme.sleepLiveButtonText;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AnimatedBuilder(
        animation: _nightCurve,
        builder: (context, child) {
          final night = _nightCurve.value;
          final primaryText = Color.lerp(
            AppTheme.sleepLiveDayText,
            Colors.white,
            night,
          )!;
          final secondaryText = Color.lerp(
            AppTheme.sleepLiveDayText.withValues(alpha: 0.72),
            Colors.white.withValues(alpha: 0.78),
            night,
          )!;
          final footerText = Color.lerp(
            AppTheme.sleepLiveDayText.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.55),
            night,
          )!;
          final top = Color.lerp(
            AppTheme.sleepLiveDayTop,
            AppTheme.sleepLiveCardTop,
            night,
          )!;
          final bottom = Color.lerp(
            AppTheme.sleepLiveDayBottom,
            AppTheme.sleepLiveCardBottom,
            night,
          )!;

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [top, bottom],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _SkyPainter(nightAmount: night),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      durationLabel,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _pickAnchorTime,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: _EditableEventLine(
                          fullText: eventLine,
                          timeText: anchorTime,
                          primaryColor: primaryText,
                          secondaryColor: secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: child,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        l10n.sleepSavesWithCurrentTime(nowTime),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: footerText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        child: InlineConfirmingButton(
          onPressed: _isSleeping ? widget.onWokeUp : widget.onFellAsleep,
          onSavedVisible: widget.onSavedVisible,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonBg,
            foregroundColor: buttonFg,
            disabledBackgroundColor: buttonBg,
            disabledForegroundColor: buttonFg,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(actionEmoji, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  actionLabel,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableEventLine extends StatelessWidget {
  final String fullText;
  final String timeText;
  final Color primaryColor;
  final Color secondaryColor;

  const _EditableEventLine({
    required this.fullText,
    required this.timeText,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final timeIndex = fullText.lastIndexOf(timeText);
    if (timeIndex < 0) {
      return Text(
        fullText,
        textAlign: TextAlign.left,
        style: TextStyle(
          color: secondaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final prefix = fullText.substring(0, timeIndex);
    final suffix = fullText.substring(timeIndex + timeText.length);
    final base = TextStyle(
      color: secondaryColor,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.25,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: timeText,
            style: base.copyWith(
              fontWeight: FontWeight.w700,
              color: primaryColor.withValues(alpha: 0.92),
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: primaryColor.withValues(alpha: 0.7),
              decorationThickness: 1.4,
            ),
          ),
          TextSpan(text: suffix),
        ],
      ),
      textAlign: TextAlign.left,
    );
  }
}

/// Cielo animado: 0 = día (sol + nubes), 1 = noche (estrellas + blobs).
class _SkyPainter extends CustomPainter {
  final double nightAmount;

  _SkyPainter({required this.nightAmount});

  @override
  void paint(Canvas canvas, Size size) {
    final day = (1 - nightAmount).clamp(0.0, 1.0);
    final night = nightAmount.clamp(0.0, 1.0);

    if (day > 0.01) {
      // Sol.
      final sunCenter = Offset(size.width * 0.86, size.height * 0.18);
      final sunPaint = Paint()
        ..shader = ui.Gradient.radial(
          sunCenter,
          size.width * 0.28,
          [
            AppTheme.sleepLiveDaySun.withValues(alpha: 0.95 * day),
            AppTheme.sleepLiveDaySun.withValues(alpha: 0.35 * day),
            AppTheme.sleepLiveDaySun.withValues(alpha: 0),
          ],
          const [0.0, 0.35, 1.0],
        );
      canvas.drawCircle(sunCenter, size.width * 0.28, sunPaint);
      canvas.drawCircle(
        sunCenter,
        size.width * 0.08,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85 * day),
      );
    }

    if (night > 0.01) {
      final blobPaint = Paint()
        ..color = AppTheme.sleepLiveCardBlob.withValues(alpha: 0.45 * night);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.78, size.height * 0.22),
          width: size.width * 0.55,
          height: size.height * 0.38,
        ),
        blobPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.18, size.height * 0.72),
          width: size.width * 0.42,
          height: size.height * 0.32,
        ),
        blobPaint
          ..color = AppTheme.sleepLiveCardBlob.withValues(alpha: 0.28 * night),
      );

      final starPaint = Paint();
      final rng = math.Random(42);
      for (var i = 0; i < 28; i++) {
        final x = rng.nextDouble() * size.width;
        final y = rng.nextDouble() * size.height;
        final r = 0.6 + rng.nextDouble() * 1.4;
        starPaint.color = Colors.white.withValues(
          alpha: (0.25 + rng.nextDouble() * 0.45) * night,
        );
        canvas.drawCircle(Offset(x, y), r, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) =>
      oldDelegate.nightAmount != nightAmount;
}

Future<TimeOfDay?> _showCupertinoTimePicker(
  BuildContext context,
  TimeOfDay initialTime,
  AppLocalizations l10n,
) {
  var selected = initialTime;
  return showCupertinoModalPopup<TimeOfDay>(
    context: context,
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return Container(
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(ctx),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.commonCancel),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => Navigator.pop(ctx, selected),
                      child: Text(l10n.commonDone),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 216,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: MediaQuery.alwaysUse24HourFormatOf(ctx),
                  initialDateTime: DateTime(
                    2000,
                    1,
                    1,
                    initialTime.hour,
                    initialTime.minute,
                  ),
                  onDateTimeChanged: (dt) {
                    selected = TimeOfDay(hour: dt.hour, minute: dt.minute);
                  },
                ),
              ),
              SizedBox(height: bottom),
            ],
          ),
        ),
      );
    },
  );
}
