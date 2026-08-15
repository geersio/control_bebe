import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:control_bebe/l10n/app_time_format.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/edit_dialog_theme.dart';

enum _SleepRangeDay { today, yesterday }

/// Sheet Hoy/Ayer + dos CupertinoDatePicker (hora) para un intervalo cerrado.
Future<({DateTime start, DateTime end})?> showSleepRangeCupertinoSheet(
  BuildContext context, {
  required String startLabel,
  required String endLabel,
  required String durationPrefix,
  DateTime? initialStart,
  DateTime? initialEnd,
}) {
  return showModalBottomSheet<({DateTime start, DateTime end})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SleepRangeCupertinoSheet(
      startLabel: startLabel,
      endLabel: endLabel,
      durationPrefix: durationPrefix,
      initialStart: initialStart,
      initialEnd: initialEnd,
    ),
  );
}

/// Sueño pasado: se durmió → se despertó.
Future<({DateTime start, DateTime end})?> showPastSleepSheet(
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context)!;
  final now = DateTime.now();
  return showSleepRangeCupertinoSheet(
    context,
    startLabel: l10n.sleepFellAsleepCaps,
    endLabel: l10n.sleepWokeUpCaps,
    durationPrefix: l10n.sleepSleptPrefix,
    initialStart: now.subtract(const Duration(hours: 2)),
    initialEnd: now,
  );
}

/// Despertar nocturno: se despertó → se volvió a dormir.
Future<({DateTime start, DateTime end})?> showNightWakingSheet(
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context)!;
  final now = DateTime.now();
  return showSleepRangeCupertinoSheet(
    context,
    startLabel: l10n.sleepWokeUpCaps,
    endLabel: l10n.sleepFellAsleepCaps,
    durationPrefix: l10n.sleepAwakePrefix,
    initialStart: now.subtract(const Duration(minutes: 20)),
    initialEnd: now,
  );
}

class _SleepRangeCupertinoSheet extends StatefulWidget {
  final String startLabel;
  final String endLabel;
  final String durationPrefix;
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const _SleepRangeCupertinoSheet({
    required this.startLabel,
    required this.endLabel,
    required this.durationPrefix,
    this.initialStart,
    this.initialEnd,
  });

  @override
  State<_SleepRangeCupertinoSheet> createState() =>
      _SleepRangeCupertinoSheetState();
}

class _SleepRangeCupertinoSheetState extends State<_SleepRangeCupertinoSheet> {
  late _SleepRangeDay _day;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final end = widget.initialEnd ?? now;
    final endDay = DateTime(end.year, end.month, end.day);
    _day = endDay == yesterday
        ? _SleepRangeDay.yesterday
        : _SleepRangeDay.today;
    final start = widget.initialStart ?? now.subtract(const Duration(hours: 2));
    _startTime = TimeOfDay.fromDateTime(start);
    _endTime = TimeOfDay.fromDateTime(end);
  }

  DateTime get _anchorDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _day == _SleepRangeDay.today
        ? today
        : today.subtract(const Duration(days: 1));
  }

  /// Fin en el día elegido; si inicio ≥ fin, el inicio es el día anterior.
  ({DateTime start, DateTime end}) get _range {
    final day = _anchorDay;
    var end = DateTime(
      day.year,
      day.month,
      day.day,
      _endTime.hour,
      _endTime.minute,
    );
    var start = DateTime(
      day.year,
      day.month,
      day.day,
      _startTime.hour,
      _startTime.minute,
    );
    if (!start.isBefore(end)) {
      start = start.subtract(const Duration(days: 1));
    }
    return (start: start, end: end);
  }

  int get _durationMinutes {
    final secs = _range.end.difference(_range.start).inSeconds;
    if (secs <= 0) return 0;
    return (secs / 60).round();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final durationLabel = formatMinutesLocalized(l10n, _durationMinutes);
    final canSave = _durationMinutes > 0;
    final accent = AppTheme.palettePrimary;
    final accentSoft = AppTheme.softPrimaryFill;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF4F6F8),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.dialogRadius),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + safeBottom * 0.25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.textLight.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _DaySegmented(
                  value: _day,
                  todayLabel: l10n.today,
                  yesterdayLabel: l10n.yesterday,
                  onChanged: (d) {
                    HapticFeedback.selectionClick();
                    setState(() => _day = d);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 196,
                  child: Row(
                    children: [
                      Expanded(
                        child: _CupertinoTimeCard(
                          label: widget.startLabel,
                          time: _startTime,
                          onChanged: (t) => setState(() => _startTime = t),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CupertinoTimeCard(
                          label: widget.endLabel,
                          time: _endTime,
                          onChanged: (t) => setState(() => _endTime = t),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: accentSoft,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: accent.withValues(alpha: 0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(text: '${widget.durationPrefix} '),
                        TextSpan(
                          text: durationLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: canSave
                        ? () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context, _range);
                          }
                        : null,
                    style: EditDialogTheme.saveButtonStyle.copyWith(
                      minimumSize: const WidgetStatePropertyAll(
                        Size(double.infinity, 52),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      textStyle: const WidgetStatePropertyAll(
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                    child: Text(l10n.sleepPastRegister),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.commonCancel,
                    style: TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DaySegmented extends StatelessWidget {
  final _SleepRangeDay value;
  final String todayLabel;
  final String yesterdayLabel;
  final ValueChanged<_SleepRangeDay> onChanged;

  const _DaySegmented({
    required this.value,
    required this.todayLabel,
    required this.yesterdayLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAEE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DayChip(
              label: todayLabel,
              selected: value == _SleepRangeDay.today,
              onTap: () => onChanged(_SleepRangeDay.today),
            ),
          ),
          Expanded(
            child: _DayChip(
              label: yesterdayLabel,
              selected: value == _SleepRangeDay.yesterday,
              onTap: () => onChanged(_SleepRangeDay.yesterday),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      elevation: selected ? 1.5 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected ? AppTheme.textDark : AppTheme.textLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _CupertinoTimeCard extends StatefulWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  const _CupertinoTimeCard({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  @override
  State<_CupertinoTimeCard> createState() => _CupertinoTimeCardState();
}

class _CupertinoTimeCardState extends State<_CupertinoTimeCard> {
  late final DateTime _initial;

  @override
  void initState() {
    super.initState();
    _initial = DateTime(2000, 1, 1, widget.time.hour, widget.time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF0),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppTheme.textLight.withValues(alpha: 0.9),
              ),
            ),
          ),
          Expanded(
            child: CupertinoTheme(
              data: CupertinoTheme.of(context).copyWith(
                textTheme: CupertinoTheme.of(context).textTheme.copyWith(
                  dateTimePickerTextStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3A4F),
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: use24h,
                initialDateTime: _initial,
                onDateTimeChanged: (dt) {
                  widget.onChanged(TimeOfDay(hour: dt.hour, minute: dt.minute));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
