import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// Campo táctil para seleccionar fecha. Diseñado para iOS (targets grandes).
class DatePickerField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loc = Localizations.localeOf(context);
    final dateLang = loc.languageCode == 'en' ? 'en' : 'es';
    return _TapField(
      icon: Icons.calendar_today,
      label: l10n.commonDate,
      value: DateFormat('d MMM yyyy', dateLang).format(value),
      onTap: () {
        if (!context.mounted) return;
        final min = _dateOnly(firstDate ?? DateTime(2020));
        final max = _dateOnly(
          lastDate ?? DateTime.now().add(const Duration(days: 365)),
        );
        final day = _dateOnly(value);
        final initial = day.isBefore(min)
            ? min
            : (day.isAfter(max) ? max : day);
        final future = defaultTargetPlatform == TargetPlatform.iOS
            ? showCupertinoDatePickerSheet(context, initial, min, max, l10n)
            : showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: min,
                lastDate: max,
                locale: loc,
              );
        future.then((date) {
          if (!context.mounted) return;
          if (date != null) onChanged(date);
        });
      },
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Muestra el selector de fecha nativo de iOS en un `showCupertinoModalPopup`,
/// con header (Cancelar / Listo) y rueda de fecha. Devuelve la fecha
/// seleccionada o `null` si el usuario cancela.
Future<DateTime?> showCupertinoDatePickerSheet(
  BuildContext context,
  DateTime initialDay,
  DateTime minimumDate,
  DateTime maximumDate,
  AppLocalizations l10n,
) {
  var selected = initialDay;
  return showCupertinoModalPopup<DateTime>(
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
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDay,
                  minimumDate: minimumDate,
                  maximumDate: maximumDate,
                  onDateTimeChanged: (dt) {
                    selected = _dateOnly(dt);
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

/// Campo táctil para seleccionar hora. En iOS usa rueda nativa (Cupertino).
class TimePickerField extends StatelessWidget {
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;
  final String? label;

  const TimePickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return _TapField(
      icon: Icons.access_time,
      label: label ?? l10n.commonTime,
      value: text,
      onTap: () {
        if (!context.mounted) return;
        final future = defaultTargetPlatform == TargetPlatform.iOS
            ? _showCupertinoTimePicker(context, value, l10n)
            : showTimePicker(context: context, initialTime: value);
        future.then((time) {
          if (!context.mounted) return;
          if (time != null) onChanged(time);
        });
      },
    );
  }
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

DateTime _minutePrecision(DateTime dt) =>
    DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);

/// Un solo instante: fecha + hora en una rueda (iOS) o sheet Cupertino (todas).
Future<DateTime?> showDateTimePickerSheet(
  BuildContext context, {
  required DateTime initialDateTime,
  DateTime? minimumDate,
  DateTime? maximumDate,
}) {
  final l10n = AppLocalizations.of(context)!;
  final min = minimumDate ?? DateTime(2020);
  final max = maximumDate ?? DateTime.now().add(const Duration(days: 1));
  var initial = _minutePrecision(initialDateTime);
  if (initial.isBefore(min)) initial = min;
  if (initial.isAfter(max)) initial = max;
  return showCupertinoDateTimePickerSheet(context, initial, min, max, l10n);
}

/// Selector nativo de fecha+hora en un popup Cupertino.
Future<DateTime?> showCupertinoDateTimePickerSheet(
  BuildContext context,
  DateTime initialDateTime,
  DateTime minimumDate,
  DateTime maximumDate,
  AppLocalizations l10n,
) {
  var selected = _minutePrecision(initialDateTime);
  return showCupertinoModalPopup<DateTime>(
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
                  mode: CupertinoDatePickerMode.dateAndTime,
                  use24hFormat: MediaQuery.alwaysUse24HourFormatOf(ctx),
                  initialDateTime: selected,
                  minimumDate: minimumDate,
                  maximumDate: maximumDate,
                  onDateTimeChanged: (dt) {
                    selected = _minutePrecision(dt);
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

class _TapField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TapField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: AppTheme.fieldBackground,
                borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                border: Border.all(color: AppTheme.fieldBorder, width: 1),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppTheme.textDark),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textLight,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
