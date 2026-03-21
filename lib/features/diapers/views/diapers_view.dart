import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/main_app_title_bar.dart';
import '../../../core/theme/edit_dialog_theme.dart';
import '../../../core/db/isar_service.dart';
import '../../../core/providers/record_stream_providers.dart';
import '../../../core/widgets/edit_dialog_fields.dart';
import '../../../core/widgets/edit_bottom_sheet.dart';
import '../../../core/widgets/stream_record_load_error.dart';
import '../../../core/models/diaper_record.dart';
import '../../../core/models/enums.dart';

class DiapersView extends ConsumerStatefulWidget {
  final VoidCallback? onTitleTap;
  final VoidCallback onSettingsTap;
  final ScrollController? scrollController;

  const DiapersView({
    super.key,
    this.onTitleTap,
    required this.onSettingsTap,
    this.scrollController,
  });

  @override
  ConsumerState<DiapersView> createState() => _DiapersViewState();
}

class _DiapersViewState extends ConsumerState<DiapersView> {
  DiaperType _selectedType = DiaperType.dirty;
  DiaperRecord? _optimisticRecord;

  List<DiaperRecord> _mergeOptimistic(List<DiaperRecord> records) {
    final opt = _optimisticRecord;
    if (opt == null) return records;
    final match = records.any(
      (r) =>
          r.type == opt.type &&
          r.dateTime.difference(opt.dateTime).inSeconds.abs() < 2,
    );
    if (match) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _optimisticRecord = null);
      });
      return records;
    }
    return [opt, ...records];
  }

  Widget _diaperHistoryColumn(
    BuildContext context,
    List<DiaperRecord> records,
  ) {
    final sorted = List<DiaperRecord>.from(records)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final grouped = <String, List<DiaperRecord>>{};
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
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        );
    if (sorted.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historial', style: titleStyle),
          const SizedBox(height: 12),
          Text(
            'Todavía no hay registros. Usa «Registrar cambio de pañal» arriba para añadir el primero.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textLight,
                  height: 1.4,
                ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial',
          style: titleStyle,
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
                  '${e.value.length} cambio${e.value.length != 1 ? 's' : ''}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textLight),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...e.value.map(
              (r) => _DiaperRecordTile(
                record: r,
                onDelete: () {
                  if (r.id != null) IsarService.deleteDiaperRecord(r.id!);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final diaperRecordsAsync = ref.watch(diaperRecordsStreamProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
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
                            Icon(
                              MdiIcons.humanBabyChangingTable,
                              color: AppTheme.pageTitleIconDiapers,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Control de Pañales',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Tipo de cambio',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: AppTheme.textLight),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _TypeButton(
                                label: 'Mojado',
                                icon: Icons.water_drop,
                                selected: _selectedType == DiaperType.wet,
                                onTap: () => setState(
                                  () => _selectedType = DiaperType.wet,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TypeButton(
                                label: 'Sucio',
                                icon: FontAwesomeIcons.poo,
                                selected: _selectedType == DiaperType.dirty,
                                onTap: () => setState(
                                  () => _selectedType = DiaperType.dirty,
                                ),
                                isFaIcon: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TypeButton(
                                label: 'Ambos',
                                icon: Icons.sync,
                                selected: _selectedType == DiaperType.both,
                                onTap: () => setState(
                                  () => _selectedType = DiaperType.both,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _registerDiaper,
                            child: const Text('Registrar Cambio de Pañal'),
                          ),
                        ),
                        const SizedBox(height: 32),
                        diaperRecordsAsync.when(
                          skipLoadingOnReload: true,
                          data: (records) => _diaperHistoryColumn(
                            context,
                            _mergeOptimistic(records),
                          ),
                          loading: () {
                            if (_optimisticRecord != null) {
                              return _diaperHistoryColumn(context, [
                                _optimisticRecord!,
                              ]);
                            }
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          error: (e, _) => StreamRecordLoadError(
                            message:
                                'No se pudieron cargar los pañales. Reintenta o comprueba la conexión.',
                            onRetry: () => ref.invalidate(
                              diaperRecordsStreamProvider,
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

  Future<void> _registerDiaper() async {
    final record = DiaperRecord(type: _selectedType, dateTime: DateTime.now());
    setState(() => _optimisticRecord = record);
    await IsarService.addDiaperRecord(record);
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isFaIcon;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isFaIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppTheme.primaryBlue : AppTheme.textLight;
    final surface = selected ? const Color(0xFFF5F5F5) : Colors.white;
    final borderColor = selected
        ? AppTheme.primaryBlue.withValues(alpha: 0.55)
        : AppTheme.fieldBorder;
    final borderWidth = selected ? 2.0 : 1.5;

    return Material(
      color: surface,
      elevation: selected ? 2 : 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        splashColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
        highlightColor: AppTheme.primaryBlue.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
          child: Column(
            children: [
              isFaIcon
                  ? FaIcon(icon, size: 28, color: iconColor)
                  : Icon(icon, size: 28, color: iconColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppTheme.textDark : AppTheme.textLight,
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

class _DiaperRecordTile extends StatelessWidget {
  final DiaperRecord record;
  final VoidCallback onDelete;

  const _DiaperRecordTile({required this.record, required this.onDelete});

  void _showEditDialog(
    BuildContext context,
    DiaperRecord record,
    VoidCallback onDelete,
  ) {
    var selectedType = record.type;
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
          title: 'Editar registro',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tipo',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: DiaperType.values.map((type) {
                  final (icon, label, isFa) = switch (type) {
                    DiaperType.wet => (Icons.water_drop, 'Mojado', false),
                    DiaperType.dirty => (FontAwesomeIcons.poo, 'Sucio', true),
                    DiaperType.both => (Icons.sync, 'Ambos', false),
                  };
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: InkWell(
                        onTap: () => setState(() => selectedType = type),
                        borderRadius: BorderRadius.circular(
                          AppTheme.fieldRadius,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: selectedType == type
                                ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                                : AppTheme.fieldBackground,
                            borderRadius: BorderRadius.circular(
                              AppTheme.fieldRadius,
                            ),
                            border: Border.all(
                              color: selectedType == type
                                  ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                                  : AppTheme.fieldBorder,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              isFa
                                  ? FaIcon(icon, size: 24)
                                  : Icon(icon, size: 24),
                              const SizedBox(height: 6),
                              Text(label, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
            final dt = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );
            await IsarService.updateDiaperRecord(
              record.copyWith(type: selectedType, dateTime: dt),
            );
            if (ctx.mounted) Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (icon, label, isFa, accentColor) = switch (record.type) {
      DiaperType.wet => (
        Icons.water_drop,
        'Mojado',
        false,
        AppTheme.diaperHistoryWetAccent,
      ),
      DiaperType.dirty => (
        FontAwesomeIcons.poo,
        'Sucio',
        true,
        AppTheme.diaperHistoryDirtyAccent,
      ),
      DiaperType.both => (
        Icons.sync,
        'Ambos',
        false,
        AppTheme.diaperHistoryBothAccent,
      ),
    };
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
                    child: isFa
                        ? FaIcon(icon, color: accentColor, size: 20)
                        : Icon(icon, color: accentColor, size: 22),
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: accentColor.withValues(alpha: 0.92),
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('d MMM, HH:mm').format(record.dateTime),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () =>
                            _showEditDialog(context, record, onDelete),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: onDelete,
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
}
