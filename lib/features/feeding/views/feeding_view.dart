import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/main_app_title_bar.dart';
import '../../../core/utils/format_duration.dart';
import '../../../core/theme/edit_dialog_theme.dart';
import '../../../core/db/isar_service.dart';
import '../../../core/providers/record_stream_providers.dart';
import '../../../core/widgets/edit_dialog_fields.dart';
import '../../../core/widgets/edit_bottom_sheet.dart';
import '../../../core/widgets/stream_record_load_error.dart';
import '../../../core/models/feeding_record.dart';
import '../../../core/models/lactation_timer.dart';
import '../../../core/models/enums.dart';
import 'bottle_view.dart';

class FeedingView extends ConsumerStatefulWidget {
  final VoidCallback? onTitleTap;
  final VoidCallback onSettingsTap;
  final ScrollController? scrollController;

  const FeedingView({
    super.key,
    this.onTitleTap,
    required this.onSettingsTap,
    this.scrollController,
  });

  @override
  ConsumerState<FeedingView> createState() => _FeedingViewState();
}

class _FeedingViewState extends ConsumerState<FeedingView> {
  Timer? _timer;
  LactationTimer? _activeTimer;

  @override
  void initState() {
    super.initState();
    _loadActiveTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveTimer() async {
    final timer = await IsarService.getActiveLactationTimer();
    if (mounted) {
      setState(() => _activeTimer = timer);
      if (timer != null) _startTick();
    }
  }

  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _startBreast(LactationSide side) async {
    await IsarService.startLactationTimer(side);
    if (mounted) {
      setState(() {
        _activeTimer = LactationTimer(side: side, startedAt: DateTime.now());
        _startTick();
      });
    }
  }

  Future<void> _stopBreast() async {
    final timer = await IsarService.stopLactationTimer();
    _timer?.cancel();
    if (mounted && timer != null) {
      setState(() => _activeTimer = null);
      await IsarService.addFeedingRecord(
        FeedingRecord(
          type: timer.side == LactationSide.left
              ? FeedingType.leftBreast
              : FeedingType.rightBreast,
          dateTime: timer.startedAt,
          durationSeconds: timer.elapsed.inSeconds,
        ),
      );
    }
  }

  Future<void> _openBottle() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BottleView()),
    );
  }

  Widget _feedingHistoryColumn(BuildContext context, List<FeedingRecord> records) {
    final sorted = List<FeedingRecord>.from(records)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final grouped = <String, List<FeedingRecord>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    for (final r in sorted) {
      final d = r.dateTime;
      final day = DateTime(d.year, d.month, d.day);
      String key;
      if (day == today) {
        key = 'Hoy';
      } else if (day == yesterday) {
        key = 'Ayer';
      } else {
        key = DateFormat('d/M').format(d);
      }
      grouped.putIfAbsent(key, () => []).add(r);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...grouped.entries.expand(
          (e) => [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.key,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight,
                      ),
                ),
                Text(
                  '${e.value.length} toma${e.value.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...e.value.map((r) => _FeedingRecordTile(record: r)),
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedingRecordsAsync = ref.watch(feedingRecordsStreamProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MainAppTitleBar(
              onTitleTap: widget.onTitleTap,
              onSettingsTap: widget.onSettingsTap,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenEdgePadding,
                  AppTheme.contentPaddingTopAfterTitleBar,
                  AppTheme.screenEdgePadding,
                  20,
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.utensils,
                              color: AppTheme.pageTitleIconFeeding,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Alimentación',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_activeTimer != null) ...[
                          _ActiveTimerBanner(
                            timer: _activeTimer!,
                            onStop: _stopBreast,
                          ),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          'Tipo de toma',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: AppTheme.textLight),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _TomaTypeButton(
                                label: 'Izquierdo',
                                isActive:
                                    _activeTimer?.side == LactationSide.left,
                                onTap: () async {
                                  if (_activeTimer?.side ==
                                      LactationSide.left) {
                                    await _stopBreast();
                                  } else {
                                    if (_activeTimer != null)
                                      await _stopBreast();
                                    await _startBreast(LactationSide.left);
                                  }
                                },
                                iconBuilder: (c) => FaIcon(
                                  FontAwesomeIcons.personBreastfeeding,
                                  size: 28,
                                  color: c,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TomaTypeButton(
                                label: 'Derecho',
                                isActive:
                                    _activeTimer?.side == LactationSide.right,
                                onTap: () async {
                                  if (_activeTimer?.side ==
                                      LactationSide.right) {
                                    await _stopBreast();
                                  } else {
                                    if (_activeTimer != null)
                                      await _stopBreast();
                                    await _startBreast(LactationSide.right);
                                  }
                                },
                                iconBuilder: (c) => Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.diagonal3Values(-1, 1, 1),
                                  child: FaIcon(
                                    FontAwesomeIcons.personBreastfeeding,
                                    size: 28,
                                    color: c,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TomaTypeButton(
                                label: 'Biberón',
                                isActive: false,
                                onTap: _openBottle,
                                iconBuilder: (c) => Icon(
                                  MdiIcons.babyBottle,
                                  size: 28,
                                  color: c,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        feedingRecordsAsync.when(
                          skipLoadingOnReload: true,
                          data: (records) =>
                              _feedingHistoryColumn(context, records),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, _) => StreamRecordLoadError(
                            message:
                                'No se pudieron cargar las tomas. Reintenta o comprueba la conexión.',
                            onRetry: () => ref.invalidate(
                              feedingRecordsStreamProvider,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTimerBanner extends StatelessWidget {
  final LactationTimer timer;
  final VoidCallback onStop;

  const _ActiveTimerBanner({required this.timer, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final totalSeconds = timer.elapsed.inSeconds;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softPrimaryFill,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Row(
        children: [
          timer.side == LactationSide.left
              ? const FaIcon(
                  FontAwesomeIcons.personBreastfeeding,
                  color: AppTheme.palettePrimary,
                  size: 32,
                )
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(-1, 1, 1),
                  child: const FaIcon(
                    FontAwesomeIcons.personBreastfeeding,
                    color: AppTheme.palettePrimary,
                    size: 32,
                  ),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cronómetro activo: ${timer.side == LactationSide.left ? "Izquierdo" : "Derecho"}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  formatDurationSeconds(totalSeconds),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.palettePrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onStop,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.palettePrimary,
            ),
            child: const Text('Parar'),
          ),
        ],
      ),
    );
  }
}

typedef _TomaIconBuilder = Widget Function(Color iconColor);

/// Izquierdo / Derecho / Biberón: misma tarjeta; el cronómetro marca `isActive` en el pecho.
class _TomaTypeButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final _TomaIconBuilder iconBuilder;

  const _TomaTypeButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive ? AppTheme.palettePrimary : AppTheme.textLight;
    final surface = isActive ? const Color(0xFFF5F5F5) : Colors.white;
    final borderColor = isActive
        ? AppTheme.palettePrimary.withValues(alpha: 0.55)
        : AppTheme.fieldBorder;
    final borderWidth = isActive ? 2.0 : 1.5;

    return Material(
      color: surface,
      elevation: isActive ? 2 : 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        splashColor: AppTheme.palettePrimary.withValues(alpha: 0.12),
        highlightColor: AppTheme.palettePrimary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
          child: Column(
            children: [
              iconBuilder(iconColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppTheme.textDark : AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedingRecordTile extends StatelessWidget {
  final FeedingRecord record;

  const _FeedingRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final (icon, label, accentColor, mirrored) = switch (record.type) {
      FeedingType.leftBreast => (
        FontAwesomeIcons.personBreastfeeding,
        'Izquierdo',
        AppTheme.feedingHistoryLeftAccent,
        false,
      ),
      FeedingType.rightBreast => (
        FontAwesomeIcons.personBreastfeeding,
        'Derecho',
        AppTheme.feedingHistoryRightAccent,
        true,
      ),
      FeedingType.bottle => (
        MdiIcons.babyBottle,
        'Biberón',
        AppTheme.feedingHistoryBottleAccent,
        false,
      ),
    };
    final duration = record.durationSeconds != null
        ? formatDurationSeconds(record.durationSeconds!)
        : null;
    final amount = record.amountMl != null ? '${record.amountMl} ml' : null;
    final borderRadius = BorderRadius.circular(AppTheme.cardRadius);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: AppTheme.fieldBorder.withValues(alpha: 0.65)),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accentColor),
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: accentColor.withValues(alpha: 0.18),
                    child: record.type == FeedingType.bottle
                        ? Icon(icon, color: accentColor, size: 22)
                        : (mirrored
                              ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.diagonal3Values(-1, 1, 1),
                                  child: FaIcon(
                                    icon,
                                    color: accentColor,
                                    size: 20,
                                  ),
                                )
                              : FaIcon(icon, color: accentColor, size: 20)),
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: accentColor.withValues(alpha: 0.92),
                    ),
                  ),
                  subtitle: Text(
                    [
                      DateFormat('d MMM, HH:mm').format(record.dateTime),
                      duration,
                      amount,
                    ].whereType<String>().join(' • '),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditDialog(context, record),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: record.id != null
                            ? () => IsarService.deleteFeedingRecord(record.id!)
                            : () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, FeedingRecord record) {
    if (record.type == FeedingType.bottle) {
      final controller = TextEditingController(text: '${record.amountMl ?? 0}');
      var selectedDate = DateTime(
        record.dateTime.year,
        record.dateTime.month,
        record.dateTime.day,
      );
      var selectedTime = TimeOfDay.fromDateTime(record.dateTime);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) => EditBottomSheet(
            title: 'Editar biberón',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cantidad (ml)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Ej: 120',
                    filled: true,
                    fillColor: AppTheme.fieldBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                      borderSide: const BorderSide(color: AppTheme.fieldBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                      borderSide: const BorderSide(color: AppTheme.fieldBorder),
                    ),
                  ),
                ),
                SizedBox(height: EditDialogTheme.spacingBetweenSections),
                DatePickerField(
                  value: selectedDate,
                  onChanged: (d) => setState(() => selectedDate = d),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                ),
                SizedBox(height: EditDialogTheme.spacingBetweenFields),
                TimePickerField(
                  value: selectedTime,
                  onChanged: (t) => setState(() => selectedTime = t),
                ),
              ],
            ),
            onCancel: () => Navigator.pop(ctx),
            onSave: () async {
              final ml = int.tryParse(controller.text.trim());
              if (ml != null && ml > 0) {
                final dt = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                await IsarService.updateFeedingRecord(
                  record.copyWith(amountMl: ml, dateTime: dt),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
          ),
        ),
      );
    } else {
      final startDt = record.dateTime;
      final endDt = startDt.add(Duration(seconds: record.durationSeconds ?? 0));
      var selectedDate = DateTime(startDt.year, startDt.month, startDt.day);
      var selectedStartTime = TimeOfDay.fromDateTime(startDt);
      var selectedEndTime = TimeOfDay.fromDateTime(endDt);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) => EditBottomSheet(
            title: 'Editar toma',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DatePickerField(
                  value: selectedDate,
                  onChanged: (d) => setState(() => selectedDate = d),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                ),
                SizedBox(height: EditDialogTheme.spacingBetweenFields),
                TimePickerField(
                  value: selectedStartTime,
                  label: 'Hora inicio',
                  onChanged: (t) => setState(() => selectedStartTime = t),
                ),
                SizedBox(height: EditDialogTheme.spacingBetweenFields),
                TimePickerField(
                  value: selectedEndTime,
                  label: 'Hora fin',
                  onChanged: (t) => setState(() => selectedEndTime = t),
                ),
              ],
            ),
            onCancel: () => Navigator.pop(ctx),
            onSave: () async {
              final start = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedStartTime.hour,
                selectedStartTime.minute,
              );
              final end = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedEndTime.hour,
                selectedEndTime.minute,
              );
              var durationSec = end.difference(start).inSeconds;
              if (durationSec < 0) durationSec += 86400;
              await IsarService.updateFeedingRecord(
                record.copyWith(dateTime: start, durationSeconds: durationSec),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ),
      );
    }
  }
}
