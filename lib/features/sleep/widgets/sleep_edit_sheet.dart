import 'package:control_bebe/l10n/app_date_locale.dart';
import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:control_bebe/l10n/app_time_format.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/db/isar_service.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/sleep_record.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/infer_sleep_type.dart';
import '../../../core/widgets/edit_bottom_sheet.dart';
import '../../../core/widgets/edit_list_rows.dart';
import 'sleep_past_sleep_sheet.dart';
import 'sleep_type_segmented_control.dart';

/// Abre el editor compacto de un sueño (o despertar huérfano).
Future<void> showSleepEditSheet(
  BuildContext context, {
  required SleepRecord record,
  List<SleepRecord> wakings = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SleepEditSheet(record: record, wakings: wakings),
  );
}

class _EditableWaking {
  final SleepRecord record;
  DateTime start;
  DateTime end;

  _EditableWaking({
    required this.record,
    required this.start,
    required this.end,
  });

  factory _EditableWaking.fromRecord(SleepRecord record) {
    return _EditableWaking(
      record: record,
      start: record.startDateTime,
      end: record.endDateTime ?? record.startDateTime,
    );
  }

  int get durationMinutes {
    final secs = end.difference(start).inSeconds;
    return secs <= 0 ? 0 : (secs / 60).round();
  }
}

class _SleepEditSheet extends StatefulWidget {
  final SleepRecord record;
  final List<SleepRecord> wakings;

  const _SleepEditSheet({required this.record, required this.wakings});

  @override
  State<_SleepEditSheet> createState() => _SleepEditSheetState();
}

class _SleepEditSheetState extends State<_SleepEditSheet> {
  late DateTime _start;
  late DateTime _end;
  late bool _keepOpen;
  late List<_EditableWaking> _wakings;
  final Set<int> _deletedWakingIds = {};

  bool get _isNightWaking => widget.record.isNightWaking;

  @override
  void initState() {
    super.initState();
    _start = widget.record.startDateTime;
    _end = widget.record.endDateTime ?? DateTime.now();
    _keepOpen = widget.record.isOpen;
    _wakings = widget.wakings.map(_EditableWaking.fromRecord).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  Future<void> _pickStart() async {
    final picked = await pickEditDateTime(context, initial: _start);
    if (!mounted || picked == null) return;
    setState(() {
      _start = picked;
      if (!_keepOpen || _isNightWaking) {
        _end = ensureDateTimeAfter(_start, _end);
      }
    });
  }

  Future<void> _pickEnd() async {
    final picked = await pickEditDateTime(
      context,
      initial: _end.isAfter(_start)
          ? _end
          : _start.add(const Duration(minutes: 1)),
      minimumDate: _start,
    );
    if (!mounted || picked == null) return;
    setState(() => _end = ensureDateTimeAfter(_start, picked));
  }

  Future<void> _editWaking(int index) async {
    final waking = _wakings[index];
    final l10n = AppLocalizations.of(context)!;
    final range = await showSleepRangeCupertinoSheet(
      context,
      startLabel: l10n.sleepWokeUpCaps,
      endLabel: l10n.sleepFellAsleepCaps,
      durationPrefix: l10n.sleepAwakePrefix,
      initialStart: waking.start,
      initialEnd: waking.end,
    );
    if (!mounted || range == null) return;
    if (!range.start.isBefore(range.end)) return;
    setState(() {
      _wakings[index] = _EditableWaking(
        record: waking.record,
        start: range.start,
        end: range.end,
      );
      _wakings.sort((a, b) => a.start.compareTo(b.start));
    });
  }

  void _removeWaking(int index) {
    final id = _wakings[index].record.id;
    setState(() {
      if (id != null) _deletedWakingIds.add(id);
      _wakings.removeAt(index);
    });
  }

  Future<void> _save() async {
    final DateTime? end;
    if (_keepOpen && !_isNightWaking) {
      end = null;
    } else {
      end = ensureDateTimeAfter(_start, _end);
      if (!_start.isBefore(end)) return;
    }

    for (final waking in _wakings) {
      if (!waking.start.isBefore(waking.end) ||
          waking.start.isBefore(_start) ||
          (end != null && waking.end.isAfter(end))) {
        return;
      }
    }
    for (var i = 1; i < _wakings.length; i++) {
      if (_wakings[i].start.isBefore(_wakings[i - 1].end)) return;
    }

    final type = _isNightWaking
        ? SleepType.nightWaking
        : inferSleepType(start: _start, end: end);

    await IsarService.updateSleepRecord(
      widget.record.copyWith(
        startDateTime: _start,
        endDateTime: end,
        type: type,
      ),
    );

    for (final waking in _wakings) {
      await IsarService.updateSleepRecord(
        waking.record.copyWith(
          startDateTime: waking.start,
          endDateTime: waking.end,
        ),
      );
    }
    for (final id in _deletedWakingIds) {
      await IsarService.deleteSleepRecord(id);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showEnd = _keepOpen == false || _isNightWaking;

    return EditBottomSheet(
      title: _isNightWaking ? l10n.sleepNightWakingLabel : l10n.sleepEditRecord,
      onCancel: () => Navigator.pop(context),
      onSave: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EditListCard(
            children: [
              EditInstantRow.dateTime(
                context: context,
                icon: Icons.nightlight_round,
                label: _isNightWaking
                    ? l10n.sleepActionWokeUp
                    : l10n.sleepBedtime,
                value: _start,
                onTap: _pickStart,
                showDivider: showEnd || !_isNightWaking,
              ),
              if (showEnd)
                EditInstantRow.dateTime(
                  context: context,
                  icon: Icons.wb_sunny_outlined,
                  label: _isNightWaking
                      ? l10n.sleepActionFellAsleep
                      : l10n.sleepWake,
                  value: _end,
                  onTap: _pickEnd,
                  showDivider: !_isNightWaking,
                ),
              if (!_isNightWaking)
                EditSwitchRow(
                  leading: SleepNapZzzIcon(size: 18, color: AppTheme.textDark),
                  label: l10n.sleepKeepOpenLabel,
                  value: _keepOpen,
                  showDivider: false,
                  onChanged: (v) => setState(() {
                    _keepOpen = v;
                    if (!v) _end = ensureDateTimeAfter(_start, _end);
                  }),
                ),
            ],
          ),
          if (!_isNightWaking && _wakings.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l10n.sleepNightWakingsSection,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            EditListCard(
              children: [
                for (var i = 0; i < _wakings.length; i++)
                  _WakingRow(
                    waking: _wakings[i],
                    onTap: () => _editWaking(i),
                    onDelete: () => _removeWaking(i),
                    showDivider: i < _wakings.length - 1,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WakingRow extends StatelessWidget {
  final _EditableWaking waking;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool showDivider;

  const _WakingRow({
    required this.waking,
    required this.onTap,
    required this.onDelete,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateCode = dateFormatLanguageCode(context);
    final start = DateFormat('HH:mm', dateCode).format(waking.start);
    final end = DateFormat('HH:mm', dateCode).format(waking.end);
    final duration = formatMinutesLocalized(l10n, waking.durationMinutes);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$start – $end',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  Text(
                    duration,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: AppTheme.textLight.withValues(alpha: 0.9),
                    ),
                    onPressed: onDelete,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 14,
            color: AppTheme.fieldBorder,
          ),
      ],
    );
  }
}
